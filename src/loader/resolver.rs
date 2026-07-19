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
pub(crate) struct ImportResolver<'a> {
    project_root: PathBuf,
    cache: &'a mut IncrementalCache,
    expanded_cache: HashMap<PathBuf, Vec<ExpandedStatement>>,
    active_stack: HashSet<PathBuf>,
    pub(crate) files: HashMap<PathBuf, LoadedFile>,
    pub(crate) sources: HashMap<PathBuf, String>,
    import_mode: ImportMode,
    manifest_dependencies: HashMap<String, MireDependency>,
    package_registry: HashMap<String, PackageEntry>,
}

impl<'a> ImportResolver<'a> {
    pub(crate) fn new(
        project_root: PathBuf,
        cache: &'a mut IncrementalCache,
        import_mode: ImportMode,
        manifest_dependencies: HashMap<String, MireDependency>,
    ) -> Self {
        Self {
            project_root,
            cache,
            expanded_cache: HashMap::new(),
            active_stack: HashSet::new(),
            files: HashMap::new(),
            sources: HashMap::new(),
            import_mode,
            manifest_dependencies,
            package_registry: HashMap::new(),
        }
    }

    pub(crate) fn load_file(&mut self, path: &Path) -> Result<Vec<ExpandedStatement>> {
        let canonical = path.canonicalize().map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: format!("Could not resolve '{}': {}", path.display(), err),
            })
        })?;

        if let Some(cached) = self.expanded_cache.get(&canonical) {
            return Ok(cached.clone());
        }

        if !self.active_stack.insert(canonical.clone()) {
            return Err(MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: format!("Cyclic local load detected at '{}'", canonical.display()),
            }));
        }

        let parsed = self.load_or_parse_file(&canonical)?;
        let imported_symbol_candidates = collect_program_dependency_candidates(&parsed.program);
        let mut expanded = Vec::new();
        let mut direct_dependencies = Vec::new();
        let mut dep_set = HashSet::new();
        for statement in parsed.program.statements {
            match statement {
                Statement::Load { path, alias, items }
                    if !path.is_empty() && !path[0].starts_with("__") =>
                {
                    let target = self.resolve_load_path(&path)?;

                    let selected = if items.is_some() {
                        items
                    } else if matches!(self.import_mode, ImportMode::Reachable) {
                        self.infer_reachable_import_items(
                            &target,
                            None,
                            &imported_symbol_candidates,
                        )?
                    } else {
                        None
                    };

                    let imported = if selected.is_some() {
                        self.load_selected_imports(&target, selected.as_deref())?
                    } else {
                        self.load_file(&target)?
                    };

                    let prefix = alias.unwrap_or_else(|| {
                        if path.len() == 1 && path[0] == "kioto" {
                            return String::new();
                        }
                        path.last().cloned().unwrap_or_default()
                    });

                    if prefix.is_empty() {
                        if dep_set.insert(target.clone()) {
                            direct_dependencies.push(target);
                        }
                        expanded.extend(imported);
                    } else {
                        let prefixed = prefix_loaded_statements_scoped(imported, &prefix, &target);
                        if dep_set.insert(target.clone()) {
                            direct_dependencies.push(target);
                        }
                        expanded.extend(prefixed);
                    }
                }
                Statement::LoadLocal { rel_path, absolute } => {
                    let target = self.resolve_local_path(&rel_path, absolute, &canonical)?;
                    let imported = self.load_selected_imports(&target, None)?;
                    let prefix = rel_path.last().cloned().unwrap_or_default();
                    let prefixed = prefix_loaded_statements_scoped(imported, &prefix, &target);
                    if dep_set.insert(target.clone()) {
                        direct_dependencies.push(target);
                    }
                    // Keep the `LoadLocal` statement in the program so later
                    // stages (typeck `use!` enforcement) can identify the
                    // module namespaces introduced by `load!`.
                    expanded.push(ExpandedStatement {
                        statement: Statement::LoadLocal {
                            rel_path: rel_path.clone(),
                            absolute,
                        },
                        origin: canonical.clone(),
                    });
                    expanded.extend(prefixed);
                }
                other => expanded.push(ExpandedStatement {
                    statement: other,
                    origin: canonical.clone(),
                }),
            }
        }

        self.active_stack.remove(&canonical);
        self.files.insert(
            canonical.clone(),
            LoadedFile {
                hash: parsed.hash,
                direct_dependencies,
            },
        );
        self.expanded_cache
            .insert(canonical.clone(), expanded.clone());
        Ok(expanded)
    }

    fn resolve_package(&mut self, name: &str) -> Result<(PathBuf, String)> {
        if let Some(entry) = self.package_registry.get(name) {
            return Ok((entry.root.clone(), entry.entry.clone()));
        }
        let package_root = if let Some(dep) = self.manifest_dependencies.get(name) {
            match dep {
                MireDependency::PathOnly { path } | MireDependency::WithPath { path, .. } => {
                    let p = PathBuf::from(path);
                    if p.is_absolute() {
                        p
                    } else {
                        self.project_root.join(p)
                    }
                }
                MireDependency::Simple { .. } => owl_home_modules().join(name),
            }
        } else if name == "kioto" {
            let home_path = owl_home_modules().join("kioto");
            if home_path.exists() {
                home_path
            } else {
                let crate_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
                let dev_path = crate_dir.join("../kioto");
                if dev_path.exists() {
                    dev_path
                } else {
                    self.project_root.join("../kioto")
                }
            }
        } else {
            return Err(MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: format!(
                    "Package '{}' not found in [dependencies] of {}",
                    name,
                    self.project_root.join("owl.toml").display()
                ),
            }));
        };

        let canonical_root = package_root.canonicalize().map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: format!(
                    "Could not resolve package '{}' at '{}': {}",
                    name,
                    package_root.display(),
                    err
                ),
            })
        })?;

        let manifest = load_project_manifest(&canonical_root)?;
        let entry = manifest
            .as_ref()
            .map(|m| m.project.entry.clone())
            .unwrap_or_else(|| "mod.mire".to_string());

        if let Some(ref m) = manifest {
            for (dep_name, dep) in &m.dependencies.entries {
                self.manifest_dependencies
                    .entry(dep_name.clone())
                    .or_insert_with(|| dep.clone());
            }
        }

        self.package_registry.insert(
            name.to_string(),
            PackageEntry {
                root: canonical_root.clone(),
                entry: entry.clone(),
            },
        );

        Ok((canonical_root, entry))
    }

    fn resolve_local_path(
        &self,
        rel_path: &[String],
        absolute: bool,
        importing_file: &Path,
    ) -> Result<PathBuf> {
        let project_root = find_project_root(importing_file).ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: "load! has not found a project root within the allowed depth \
                          (Note: load! only searches up to 2 levels below owl.toml)"
                    .to_string(),
            })
        })?;

        let base = if absolute {
            project_root.clone()
        } else {
            importing_file
                .parent()
                .map(|p| p.to_path_buf())
                .unwrap_or_else(|| project_root.clone())
        };

        let mut target = base.join(rel_path.iter().collect::<PathBuf>());

        if target.is_dir() {
            if target.join("main.mire").exists() {
                target = target.join("main.mire");
            } else if target.join("mod.mire").exists() {
                target = target.join("mod.mire");
            } else {
                return Err(MireError::new(ErrorKind::Runtime {
                    line: 0,
                    column: 0,
                    message: format!(
                        "load! target '{}' is a directory with no main.mire/mod.mire entry",
                        target.display()
                    ),
                }));
            }
        } else if !target.exists() && target.extension().is_none() {
            target = target.with_extension("mire");
        }

        if !target.exists() {
            return Err(MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: format!("load! target not found: '{}'", target.display()),
            }));
        }

        let canonical = target
            .canonicalize()
            .map_err(|_| {
                MireError::new(ErrorKind::Runtime {
                    line: 0,
                    column: 0,
                    message: format!("load! target not found: '{}'", target.display()),
                })
            })?;

        // Depth limit: must stay within `project_root` and not descend more
        // than 2 levels below it.
        let rel = canonical
            .strip_prefix(&project_root)
            .map_err(|_| {
                MireError::new(ErrorKind::Runtime {
                    line: 0,
                    column: 0,
                    message: "load! has not found a project root within the allowed depth \
                              (Note: load! only searches up to 2 levels below owl.toml)"
                        .to_string(),
                })
            })?;
        if rel.components().count() > 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                line: 0,
                column: 0,
                message: "load! has not found a project root within the allowed depth \
                          (Note: load! only searches up to 2 levels below owl.toml)"
                    .to_string(),
            }));
        }

        Ok(canonical)
    }

    fn resolve_load_path(&mut self, segments: &[String]) -> Result<PathBuf> {
        let (mut current_root, entry) = self.resolve_package(&segments[0])?;
        let mut current_exports = load_exports(&current_root).unwrap_or_default();

        if segments.len() == 1 {
            let direct = current_root.join(&entry);
            if direct.exists() {
                return Ok(direct);
            }
            if let Some(export_path) =
                resolve_export_path(&current_exports, &current_root, &segments[0])
                && export_path.exists()
            {
                return Ok(export_path);
            }
            return Ok(direct);
        }

        for i in 1..segments.len() {
            let segment = &segments[i];
            let is_last = i == segments.len() - 1;

            let target =
                resolve_export_path(&current_exports, &current_root, segment).ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        line: 0,
                        column: 0,
                        message: format!("Package '{}' has no export '{}'", segments[0], segment),
                    })
                })?;

            if is_last {
                return Ok(target);
            }

            let parent = if target.is_dir() {
                target.clone()
            } else {
                target.parent().unwrap_or(&current_root).to_path_buf()
            };

            if parent.join("owl.toml").exists() {
                current_exports = load_exports(&parent).unwrap_or_default();
                current_root = parent;
            } else {
                return Err(MireError::new(ErrorKind::Runtime {
                    line: 0,
                    column: 0,
                    message: format!(
                        "Cannot resolve '{}': '{}' has no sub-exports",
                        segments[i + 1..].join("::"),
                        segment
                    ),
                }));
            }
        }

        unreachable!()
    }

    fn infer_reachable_import_items(
        &mut self,
        path: &Path,
        module_prefix: Option<&str>,
        candidates: &HashSet<String>,
    ) -> Result<Option<Vec<String>>> {
        let parsed = self.load_or_parse_file(path)?;
        if parsed.exports.is_empty() {
            return Ok(None);
        }

        let mut selected = Vec::new();
        for export in &parsed.exports {
            let export_tail = export
                .rsplit_once('.')
                .map_or(export.as_str(), |(_, tail)| tail);
            let prefixed = module_prefix.map(|prefix| format!("{prefix}.{export_tail}"));
            let prefixed_double_colon =
                module_prefix.map(|prefix| format!("{prefix}::{export_tail}"));
            if candidates.contains(export)
                || candidates.contains(export_tail)
                || prefixed
                    .as_ref()
                    .is_some_and(|value| candidates.contains(value))
                || prefixed_double_colon
                    .as_ref()
                    .is_some_and(|value| candidates.contains(value))
            {
                selected.push(export_tail.to_string());
            }
        }

        if selected.is_empty() {
            return Ok(None);
        }
        selected.sort();
        selected.dedup();
        Ok(Some(selected))
    }

    fn load_or_parse_file(&mut self, path: &Path) -> Result<ResolvedFile> {
        let source = read_source_file(path)?;
        self.sources.insert(path.to_path_buf(), source.clone());
        let hash = source_hash(&source);
        let hash2 = source_hash2(&source);
        if let Some(cached) = self.cache.cached_file(path, hash, hash2) {
            return Ok(ResolvedFile {
                hash,
                program: cached.program,
                exports: cached.exports,
            });
        }

        let program = parse(&source).map_err(|err| {
            err.with_source(source.clone())
                .with_filename(path.display().to_string())
        })?;
        let exports: Vec<String> = program
            .statements
            .iter()
            .filter_map(statement_export_name)
            .map(ToString::to_string)
            .collect();
        self.cache.store_file(
            path,
            CachedParsedFile {
                hash,
                hash2,
                exports: exports.clone(),
                local_imports: Vec::new(),
                program: program.clone(),
            },
        )?;
        Ok(ResolvedFile {
            hash,
            program,
            exports,
        })
    }

    fn load_selected_imports(
        &mut self,
        path: &Path,
        items: Option<&[String]>,
    ) -> Result<Vec<ExpandedStatement>> {
        let parsed = self.load_or_parse_file(path)?;
        let has_loads = parsed
            .program
            .statements
            .iter()
            .any(|stmt| matches!(stmt, Statement::Load { .. }));
        if has_loads {
            let loaded = self.load_file(path)?;
            return select_imported_statements(&loaded, items, path);
        }
        self.files.insert(
            path.to_path_buf(),
            LoadedFile {
                hash: parsed.hash,
                direct_dependencies: Vec::new(),
            },
        );
        let expanded: Vec<ExpandedStatement> = parsed
            .program
            .statements
            .into_iter()
            .map(|statement| ExpandedStatement {
                statement,
                origin: path.to_path_buf(),
            })
            .collect();
        select_imported_statements(&expanded, items, path)
    }
}

fn collect_program_dependency_candidates(program: &Program) -> HashSet<String> {
    let mut candidates = HashSet::new();
    let mut local_bindings = HashSet::new();
    for statement in &program.statements {
        if matches!(statement, Statement::Load { .. }) {
            continue;
        }
        let mut deps = Vec::new();
        collect_statement_dependencies(statement, &mut deps);
        for dep in deps {
            candidates.insert(dep.clone());
            if let Some((_, tail)) = dep.rsplit_once('.') {
                candidates.insert(tail.to_string());
            }
            if let Some((_, tail)) = dep.rsplit_once("::") {
                candidates.insert(tail.to_string());
            }
        }
        let mut bindings = Vec::new();
        collect_statement_bindings(statement, &mut bindings);
        for b in bindings {
            local_bindings.insert(b);
        }
    }
    // Remove local variable names that would otherwise falsely match
    // external module exports (e.g. parameter name "min" matching a
    // function export "min" from another module).
    candidates.retain(|c| !local_bindings.contains(c));
    candidates
}
