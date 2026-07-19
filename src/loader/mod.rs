pub(crate) mod resolver;
pub(crate) mod renamer;
pub(crate) mod prefix;
pub(crate) mod source;

pub(crate) use resolver::*;
pub(crate) use renamer::*;
pub(crate) use prefix::*;
pub(crate) use source::*;

use crate::avens::{
    ImportMode, MireDependency, find_project_root, load_exports, load_manifest_dependencies,
    load_project_manifest, resolve_export_path,
};
use crate::error::{ErrorKind, MireError, Result};
use crate::incremental::{
    CacheSettings, CachedParsedFile, IncrementalCache, LoadedFile, LoadedProgram,
    collect_statement_bindings, collect_statement_dependencies, source_hash, source_hash2,
    statement_export_name,
};
use crate::parser::ast::{AssignmentTarget, DataType, Expression, Identifier, Literal, Statement};
use crate::parser::{Program, parse};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone)]
pub(crate) struct PackageEntry {
    root: PathBuf,
    entry: String,
}

#[derive(Clone)]
pub(crate) struct ExpandedStatement {
    statement: Statement,
    origin: PathBuf,
}

pub(crate) struct ResolvedFile {
    hash: u64,
    program: Program,
    exports: Vec<String>,
}

pub fn load_program_from_file(path: &Path) -> Result<Program> {
    Ok(load_program_with_metadata(path)?.program)
}

pub fn load_program_with_metadata(path: &Path) -> Result<LoadedProgram> {
    let settings = CacheSettings::resolve_for(path, Default::default())?;
    load_program_with_metadata_with_settings(path, settings, ImportMode::Reachable)
}

pub fn load_program_with_metadata_with_settings(
    path: &Path,
    settings: CacheSettings,
    import_mode: ImportMode,
) -> Result<LoadedProgram> {
    let canonical = path.canonicalize().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            line: 0,
            column: 0,
            message: format!("Could not resolve '{}': {}", path.display(), err),
        })
    })?;

    let project_root = if let Some(root) =
        find_project_root(canonical.parent().unwrap_or_else(|| Path::new(".")))
    {
        root
    } else {
        let fallback = canonical
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        let manifest_dependencies = HashMap::new();
        let mut cache = IncrementalCache::load_with_settings(&canonical, settings)?;
        let mut resolver = ImportResolver::new(
            fallback.clone(),
            &mut cache,
            import_mode,
            manifest_dependencies,
        );
        let statements = resolver.load_file(&canonical)?;
        let statement_origins = statements.iter().map(|stmt| stmt.origin.clone()).collect();
        let program_statements: Vec<Statement> = statements.into_iter().map(|stmt| stmt.statement).collect();
        let files = std::mem::take(&mut resolver.files);
        let sources = std::mem::take(&mut resolver.sources);
        drop(resolver);
        cache.save()?;
        return Ok(LoadedProgram {
            program: Program {
                file_attributes: vec![],
                annotations: vec![],
                statements: program_statements,
            },
            files,
            statement_origins,
            sources,
        });
    };

    let manifest_dependencies = load_manifest_dependencies(&project_root).unwrap_or_default();
    let mut cache = IncrementalCache::load_with_settings(&canonical, settings)?;
    let mut resolver =
        ImportResolver::new(project_root, &mut cache, import_mode, manifest_dependencies);
    let statements = resolver.load_file(&canonical)?;
    let statement_origins = statements.iter().map(|stmt| stmt.origin.clone()).collect();
    let program_statements: Vec<Statement> = statements.into_iter().map(|stmt| stmt.statement).collect();
    let files = std::mem::take(&mut resolver.files);
    let sources = std::mem::take(&mut resolver.sources);
    drop(resolver);
    cache.save()?;
    Ok(LoadedProgram {
        program: Program {
            file_attributes: vec![],
            annotations: vec![],
            statements: program_statements,
        },
        files,
        statement_origins,
        sources,
    })
}

/// Load program using an already-loaded cache instance.
/// This avoids loading the cache twice when the caller already has one.
pub fn load_program_with_cache(
    path: &Path,
    cache: &mut IncrementalCache,
    import_mode: ImportMode,
) -> Result<LoadedProgram> {
    let canonical = path.canonicalize().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            line: 0,
            column: 0,
            message: format!("Could not resolve '{}': {}", path.display(), err),
        })
    })?;

    let project_root = if let Some(root) =
        find_project_root(canonical.parent().unwrap_or_else(|| Path::new(".")))
    {
        root
    } else {
        let fallback = canonical
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        let manifest_dependencies = HashMap::new();
        let mut resolver =
            ImportResolver::new(fallback.clone(), cache, import_mode, manifest_dependencies);
        let statements = resolver.load_file(&canonical)?;
        let statement_origins = statements.iter().map(|stmt| stmt.origin.clone()).collect();
        let program_statements: Vec<Statement> = statements.into_iter().map(|stmt| stmt.statement).collect();
        return Ok(LoadedProgram {
            program: Program {
                file_attributes: vec![],
                annotations: vec![],
                statements: program_statements,
            },
            files: resolver.files,
            statement_origins,
            sources: resolver.sources,
        });
    };

    let manifest_dependencies = load_manifest_dependencies(&project_root).unwrap_or_default();
    let mut resolver = ImportResolver::new(project_root, cache, import_mode, manifest_dependencies);
    let statements = resolver.load_file(&canonical)?;
    let statement_origins = statements.iter().map(|stmt| stmt.origin.clone()).collect();
    let program_statements: Vec<Statement> = statements.into_iter().map(|stmt| stmt.statement).collect();
    Ok(LoadedProgram {
        program: Program {
            file_attributes: vec![],
            annotations: vec![],
            statements: program_statements,
        },
        files: resolver.files,
        statement_origins,
        sources: resolver.sources,
    })
}

fn owl_home_modules() -> PathBuf {
    if let Some(home) = std::env::var_os("MIRE_OWL_HOME") {
        return PathBuf::from(home);
    }
    let home = std::env::var("HOME").unwrap_or_else(|_| "~".to_string());
    PathBuf::from(home).join(".owl").join("modules")
}
