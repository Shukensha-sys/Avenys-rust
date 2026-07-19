use crate::loader::*;
use crate::avens::{
    ImportMode, MireDependency, find_project_root, load_exports, load_manifest_dependencies,
    load_project_manifest, resolve_export_path,
};
use crate::error::{ErrorKind, MireError, Result};
use crate::incremental::{
    CacheSettings, CachedParsedFile, IncrementalCache, LoadedFile, collect_statement_bindings,
    collect_statement_dependencies, source_hash, source_hash2, statement_export_name,
};
use crate::parser::ast::{AssignmentTarget, DataType, Expression, Identifier, Literal, Statement};
use crate::parser::{Program, parse};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
pub(crate) fn read_source_file(path: &Path) -> Result<String> {
    fs::read_to_string(path).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            line: 0,
            column: 0,
            message: format!("Could not read '{}': {}", path.display(), err),
        })
    })
}
