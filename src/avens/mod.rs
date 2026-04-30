use crate::compiler::{
    AnalysisSelection, analyze_program_with_origins, analyze_program_with_origins_partial,
};
use crate::error::{ErrorKind, MireError, Result};
use crate::incremental::{
    AnalysisInvalidationReport, BuildCacheEntry, CacheOverrides, CacheSettings, CachedAnalysis,
    CachedAnalysisSnapshot, IncrementalCache, analysis_child_unit_key, analysis_unit_key,
    analysis_units_for_program, build_fingerprint, compute_invalidation_report,
};
use crate::loader::load_program_with_metadata_with_settings;
use crate::parser::ast::{
    AssignmentTarget, DataType, Expression, Identifier, Literal, Program, Statement,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

fn prepare_program_with_partial_analysis_reuse(
    current_program: &mut Program,
    cached: CachedAnalysisSnapshot,
) -> (AnalysisSelection, AnalysisInvalidationReport) {
    let report = compute_partial_reuse_report(current_program, &cached.units);
    if report.invalidated_units.is_empty() {
        current_program.statements = cached.program.statements;
        return (
            AnalysisSelection {
                statement_mask: vec![false; current_program.statements.len()],
                ..AnalysisSelection::default()
            },
            report,
        );
    }

    let previous_by_key: HashMap<_, _> = cached
        .program
        .statements
        .into_iter()
        .map(|statement| (analysis_unit_key(&statement), statement))
        .collect();
    let invalidated_units: std::collections::HashSet<_> =
        report.invalidated_units.iter().cloned().collect();

    let mut selection = AnalysisSelection {
        statement_mask: Vec::with_capacity(current_program.statements.len()),
        ..AnalysisSelection::default()
    };
    for statement in current_program.statements.iter_mut() {
        let unit_key = analysis_unit_key(statement);
        let should_recheck = invalidated_units.contains(&unit_key);
        if !should_recheck && let Some(previous) = previous_by_key.get(&unit_key) {
            *statement = previous.clone();
            selection.statement_mask.push(false);
            continue;
        }

        if let Some(previous) = previous_by_key.get(&unit_key)
            && let Some(child_mask) =
                prepare_nested_reuse(&unit_key, statement, previous, &invalidated_units)
        {
            selection
                .nested_statement_masks
                .insert(unit_key.clone(), child_mask);
        }
        selection.statement_mask.push(true);
    }

    (selection, report)
}

fn prepare_nested_reuse(
    parent_key: &str,
    current: &mut Statement,
    previous: &Statement,
    invalidated_units: &std::collections::HashSet<String>,
) -> Option<Vec<bool>> {
    let (current_children, previous_children) = match (
        container_children_mut(current),
        container_children(previous),
    ) {
        (Some(current_children), Some(previous_children)) => (current_children, previous_children),
        _ => return None,
    };

    let previous_by_key: HashMap<_, _> = previous_children
        .iter()
        .enumerate()
        .map(|(index, statement)| {
            (
                analysis_child_unit_key(parent_key, statement, index),
                statement.clone(),
            )
        })
        .collect();

    let mut child_mask = Vec::with_capacity(current_children.len());
    for (child_index, child) in current_children.iter_mut().enumerate() {
        let child_key = analysis_child_unit_key(parent_key, child, child_index);
        let should_recheck = invalidated_units.contains(&child_key);
        if !should_recheck && let Some(previous_child) = previous_by_key.get(&child_key) {
            *child = previous_child.clone();
            child_mask.push(false);
            continue;
        }
        child_mask.push(true);
    }

    child_mask
        .iter()
        .any(|should_check| !should_check)
        .then_some(child_mask)
}

fn container_children(statement: &Statement) -> Option<&[Statement]> {
    match statement {
        Statement::Type { fields, .. } => Some(fields.as_slice()),
        Statement::Class { methods, .. }
        | Statement::Code { methods, .. }
        | Statement::Impl { methods, .. } => Some(methods.as_slice()),
        _ => None,
    }
}

fn container_children_mut(statement: &mut Statement) -> Option<&mut Vec<Statement>> {
    match statement {
        Statement::Type { fields, .. } => Some(fields),
        Statement::Class { methods, .. }
        | Statement::Code { methods, .. }
        | Statement::Impl { methods, .. } => Some(methods),
        _ => None,
    }
}

fn compute_partial_reuse_report(
    current_program: &Program,
    previous_units: &[crate::incremental::AnalysisUnitMetadata],
) -> AnalysisInvalidationReport {
    let current_units = analysis_units_for_program(current_program);
    compute_invalidation_report(previous_units, &current_units)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum BuildMode {
    Debug,
    Release,
}

#[derive(Debug, Clone)]
pub struct BuildOptions {
    pub mode: BuildMode,
    pub debug_dump: bool,
    pub output: Option<PathBuf>,
    pub emit_binary: bool,
    pub persist_ir: bool,
    pub cache: CacheOverrides,
}

#[derive(Debug, Clone)]
pub struct BuildResult {
    pub binary_path: PathBuf,
    pub ir_path: Option<PathBuf>,
    pub optimized_ir_path: Option<PathBuf>,
    pub used_optimizations: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MireManifest {
    #[serde(alias = "package")]
    pub project: MireProject,
    #[serde(default)]
    pub cache: Option<MireCacheConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MireProject {
    pub name: String,
    pub version: String,
    pub entry: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct MireCacheConfig {
    pub max_units: Option<usize>,
    pub analysis_cache: Option<bool>,
    pub compression: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MireLock {
    #[serde(alias = "package")]
    pub project: MireLockProject,
    pub build: MireLockBuild,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MireLockProject {
    pub name: String,
    pub version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MireLockBuild {
    pub llvm_version: String,
    pub profile: String,
}

pub fn load_project_manifest(cwd: &Path) -> Result<Option<MireManifest>> {
    let manifest_path = project_manifest_path(cwd);
    if !manifest_path.exists() {
        let legacy = cwd.join("Mire.toml");
        if !legacy.exists() {
            return Ok(None);
        }
        return load_manifest_file(&legacy);
    }

    load_manifest_file(&manifest_path)
}

fn load_manifest_file(manifest_path: &Path) -> Result<Option<MireManifest>> {
    if !manifest_path.exists() {
        return Ok(None);
    }

    let raw = fs::read_to_string(manifest_path).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Could not read '{}': {}", manifest_path.display(), err),
        })
    })?;

    let manifest: MireManifest = toml::from_str(&raw).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Invalid Mire.toml: {}", err),
        })
    })?;

    Ok(Some(manifest))
}

pub fn write_lock_file(cwd: &Path, manifest: &MireManifest, mode: BuildMode) -> Result<()> {
    let llvm_version = llvm_version()?;
    let lock = MireLock {
        project: MireLockProject {
            name: manifest.project.name.clone(),
            version: manifest.project.version.clone(),
        },
        build: MireLockBuild {
            llvm_version,
            profile: match mode {
                BuildMode::Debug => "debug".to_string(),
                BuildMode::Release => "release".to_string(),
            },
        },
    };

    let raw = toml::to_string_pretty(&lock).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Could not serialize Mire.lock: {}", err),
        })
    })?;

    fs::write(project_lock_path(cwd), raw).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Could not write project.lock: {}", err),
        })
    })?;

    Ok(())
}

pub fn compile_file_with_avenys(source_path: &Path, options: &BuildOptions) -> Result<BuildResult> {
    let source = fs::read_to_string(source_path)?;
    let source_filename = source_path.display().to_string();
    let output_dir = default_output_dir(source_path, options.mode);
    fs::create_dir_all(&output_dir).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!(
                "Could not create build directory '{}': {}",
                output_dir.display(),
                err
            ),
        })
    })?;

    let stem = source_path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("main");
    let binary_path = options
        .output
        .clone()
        .unwrap_or_else(|| output_dir.join(stem));
    let ir_path = options
        .persist_ir
        .then(|| output_dir.join(format!("{stem}.ll")));
    let optimized_ir_path = options
        .persist_ir
        .then(|| output_dir.join(format!("{stem}.opt.ll")));
    let runtime_support =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("src/avens/runtime_support.c");
    let runtime_support_source = fs::read_to_string(&runtime_support).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Could not read '{}': {}", runtime_support.display(), err),
        })
    })?;
    let cache_settings = CacheSettings::resolve_for(source_path, options.cache)?;
    let mut cache = IncrementalCache::load_with_settings(source_path, cache_settings)?;
    let loaded = load_program_with_metadata_with_settings(source_path, cache_settings)?;
    if options.debug_dump
        && let Some(report) = cache.analysis_invalidation_report(source_path, &loaded.program)
    {
        eprintln!(
            "[AVENYS][incremental] changed_units={} invalidated_units={} added_units={} removed_units={}",
            report.changed_units.len(),
            report.invalidated_units.len(),
            report.added_units.len(),
            report.removed_units.len(),
        );
    }
    let fingerprint = build_fingerprint(
        source_path,
        &loaded.files,
        options.mode,
        options.emit_binary,
        &runtime_support_source,
    );

    if let Some(entry) = cache.build_entry(
        source_path,
        options.mode,
        options.emit_binary,
        options.persist_ir,
    ) && entry.fingerprint == fingerprint
        && (!options.emit_binary || entry.binary_path.exists())
        && entry.binary_path == binary_path
        && entry.ir_path == ir_path
        && entry.optimized_ir_path == optimized_ir_path
        && entry.ir_path.as_ref().is_none_or(|path| path.exists())
        && entry
            .optimized_ir_path
            .as_ref()
            .is_none_or(|path| path.exists())
    {
        cache.record_build_hit();
        if options.debug_dump {
            let metrics = cache.metrics();
            eprintln!(
                "[AVENYS][incremental] cache_metrics file_hit={} file_miss={} analysis_hit={} analysis_miss={} build_hit={} build_miss={} evictions={}",
                metrics.file_hits,
                metrics.file_misses,
                metrics.analysis_hits,
                metrics.analysis_misses,
                metrics.build_hits,
                metrics.build_misses,
                metrics.evictions,
            );
        }
        return Ok(BuildResult {
            binary_path,
            ir_path,
            optimized_ir_path,
            used_optimizations: matches!(options.mode, BuildMode::Release),
        });
    }
    cache.record_build_miss();

    let program = if let Some(cached) = cache.cached_analysis(source_path, fingerprint) {
        match cached {
            CachedAnalysis::Success(program) => program,
            CachedAnalysis::Error(error) => return Err(error),
        }
    } else {
        let mut program = loaded.program;
        let analysis_result = if let Some(cached) = cache.latest_successful_analysis(source_path) {
            let (selection, _) = prepare_program_with_partial_analysis_reuse(&mut program, cached);
            if selection
                .statement_mask
                .iter()
                .all(|should_check| !should_check)
            {
                Ok(())
            } else {
                analyze_program_with_origins_partial(
                    &mut program,
                    &source,
                    &loaded.statement_origins,
                    &loaded.sources,
                    &selection,
                )
                .map(|_| ())
            }
        } else {
            analyze_program_with_origins(
                &mut program,
                &source,
                &loaded.statement_origins,
                &loaded.sources,
            )
            .map(|_| ())
        };

        if let Err(err) = analysis_result {
            let err = if err.source().is_none() {
                err.with_source(source.clone())
            } else {
                err
            };
            let err = if err.filename().is_none() {
                err.with_filename(source_filename.clone())
            } else {
                err
            };
            cache.store_analysis_error(source_path, fingerprint, &program, &err)?;
            cache.save()?;
            return Err(err);
        }
        cache.store_analysis(source_path, fingerprint, &program)?;
        program
    };

    let ir = LlvmIrGen::new().compile_program(&program).map_err(|err| {
        let err = if err.source().is_none() {
            err.with_source(source.clone())
        } else {
            err
        };
        if err.filename().is_none() {
            err.with_filename(source_filename.clone())
        } else {
            err
        }
    })?;
    if let Some(path) = &ir_path {
        fs::write(path, &ir).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Could not write '{}': {}", path.display(), err),
            })
        })?;
    }

    let final_ir = if matches!(options.mode, BuildMode::Release) {
        optimize_ir(&ir)?
    } else {
        ir
    };

    if let Some(path) = &optimized_ir_path {
        fs::write(path, &final_ir).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Could not write '{}': {}", path.display(), err),
            })
        })?;
    }

    if options.emit_binary {
        compile_binary_from_ir(&final_ir, &runtime_support, &binary_path, options.mode)?;
    }

    cache.store_build(
        source_path,
        BuildCacheEntry {
            fingerprint,
            mode: options.mode,
            emit_binary: options.emit_binary,
            persist_ir: options.persist_ir,
            binary_path: binary_path.clone(),
            ir_path: ir_path.clone(),
            optimized_ir_path: optimized_ir_path.clone(),
        },
    );
    if options.debug_dump {
        let metrics = cache.metrics();
        eprintln!(
            "[AVENYS][incremental] cache_metrics file_hit={} file_miss={} analysis_hit={} analysis_miss={} build_hit={} build_miss={} evictions={}",
            metrics.file_hits,
            metrics.file_misses,
            metrics.analysis_hits,
            metrics.analysis_misses,
            metrics.build_hits,
            metrics.build_misses,
            metrics.evictions,
        );
    }
    cache.save()?;

    Ok(BuildResult {
        binary_path,
        ir_path,
        optimized_ir_path,
        used_optimizations: matches!(options.mode, BuildMode::Release),
    })
}

pub fn default_output_dir(source_path: &Path, mode: BuildMode) -> PathBuf {
    if let Some(project_root) =
        find_project_root(source_path.parent().unwrap_or_else(|| Path::new(".")))
    {
        return project_root.join("bin").join(match mode {
            BuildMode::Debug => "debug",
            BuildMode::Release => "release",
        });
    }

    source_path
        .parent()
        .unwrap_or_else(|| Path::new("."))
        .join(match mode {
            BuildMode::Debug => "debug",
            BuildMode::Release => "release",
        })
}

fn optimize_ir(ir: &str) -> Result<String> {
    let mut command = Command::new("opt");
    command
        .arg("-S")
        .arg("-O3")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped());
    let mut child = command.spawn().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Failed to run opt: {}", err),
        })
    })?;
    if let Some(stdin) = child.stdin.as_mut() {
        stdin.write_all(ir.as_bytes()).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Failed to stream IR into opt: {}", err),
            })
        })?;
    }
    let output = child.wait_with_output().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Failed to wait for opt: {}", err),
        })
    })?;
    if !output.status.success() {
        return Err(MireError::new(ErrorKind::Runtime {
            message: format!(
                "opt failed with status {}.\nstderr:\n{}",
                output.status,
                String::from_utf8_lossy(&output.stderr).trim()
            ),
        }));
    }
    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

fn compile_binary_from_ir(
    ir: &str,
    runtime_support: &Path,
    binary_path: &Path,
    mode: BuildMode,
) -> Result<()> {
    let mut clang = Command::new("clang");
    clang
        .arg("-x")
        .arg("ir")
        .arg("-")
        .arg("-x")
        .arg("c")
        .arg(runtime_support)
        .arg("-o")
        .arg(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    if matches!(mode, BuildMode::Release) {
        clang.arg("-O3");
    } else {
        clang.arg("-O0");
    }

    let mut child = clang.spawn().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Failed to run clang: {}", err),
        })
    })?;
    if let Some(stdin) = child.stdin.as_mut() {
        stdin.write_all(ir.as_bytes()).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Failed to stream IR into clang: {}", err),
            })
        })?;
    }
    let output = child.wait_with_output().map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Failed to wait for clang: {}", err),
        })
    })?;
    if output.status.success() {
        return Ok(());
    }

    Err(MireError::new(ErrorKind::Runtime {
        message: format!(
            "clang failed with status {}.\nstdout:\n{}\nstderr:\n{}",
            output.status,
            String::from_utf8_lossy(&output.stdout).trim(),
            String::from_utf8_lossy(&output.stderr).trim()
        ),
    }))
}

pub fn find_project_root(start: &Path) -> Option<PathBuf> {
    let mut current = Some(start);
    while let Some(path) = current {
        if project_manifest_path(path).exists() || path.join("Mire.toml").exists() {
            return Some(path.to_path_buf());
        }
        current = path.parent();
    }
    None
}

pub fn project_manifest_path(cwd: &Path) -> PathBuf {
    cwd.join("project.toml")
}

pub fn project_lock_path(cwd: &Path) -> PathBuf {
    cwd.join("project.lock")
}

fn llvm_version() -> Result<String> {
    let output = Command::new("llvm-config")
        .arg("--version")
        .output()
        .map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Failed to run llvm-config: {}", err),
            })
        })?;
    if !output.status.success() {
        return Err(MireError::new(ErrorKind::Runtime {
            message: "llvm-config --version failed".to_string(),
        }));
    }
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum LlType {
    I64,
    I1,
    F64,
    Ptr,
}

#[derive(Debug, Clone)]
struct LlValue {
    ty: LlType,
    repr: String,
    owned: bool,
}

#[derive(Debug, Clone)]
struct VarInfo {
    ptr: String,
    ty: LlType,
    data_type: DataType,
    owns_heap_string: bool,
    struct_name: Option<String>,
}

#[derive(Debug, Clone)]
struct FnInfo {
    llvm_name: String,
    params: Vec<LlType>,
    ret: LlType,
    returns_value: bool,
}

#[derive(Debug, Clone)]
struct LoopLabels {
    break_label: String,
    continue_label: String,
}

#[derive(Debug, Clone)]
struct StructInfo {
    fields: Vec<LlType>,
    field_data_types: Vec<DataType>,
    field_indices: HashMap<String, usize>,
}

#[derive(Debug, Clone)]
struct EnumInfo {
    llvm_type: String,
    variants: HashMap<String, VariantInfo>,
}

#[derive(Debug, Clone)]
struct VariantInfo {
    tag: u32,
    payload_types: Vec<LlType>,
}

struct LlvmIrGen {
    strings: Vec<String>,
    functions: Vec<String>,
    entry_allocas: Vec<String>,
    body: Vec<String>,
    vars: HashMap<String, VarInfo>,
    user_functions: HashMap<String, FnInfo>,
    user_structs: HashMap<String, StructInfo>,
    user_enums: HashMap<String, EnumInfo>,
    loop_stack: Vec<LoopLabels>,
    current_return: LlType,
    next_tmp: usize,
    next_label: usize,
}

impl LlvmIrGen {
    fn new() -> Self {
        Self {
            strings: Vec::new(),
            functions: Vec::new(),
            entry_allocas: Vec::new(),
            body: Vec::new(),
            vars: HashMap::new(),
            user_functions: HashMap::new(),
            user_structs: HashMap::new(),
            user_enums: HashMap::new(),
            loop_stack: Vec::new(),
            current_return: LlType::I64,
            next_tmp: 0,
            next_label: 0,
        }
    }

    fn compile_program(mut self, program: &Program) -> Result<String> {
        // First pass: collect struct definitions
        for stmt in &program.statements {
            if let Statement::Type { name, fields, .. } = stmt {
                let mut field_types = Vec::new();
                let mut field_data_types = Vec::new();
                let mut field_indices = HashMap::new();

                for (idx, field_stmt) in fields.iter().enumerate() {
                    if let Statement::Let {
                        name: field_name,
                        data_type,
                        ..
                    } = field_stmt
                    {
                        field_types.push(self.map_type(data_type)?);
                        field_data_types.push(data_type.clone());
                        field_indices.insert(field_name.clone(), idx);
                    }
                }

                self.user_structs.insert(
                    name.clone(),
                    StructInfo {
                        fields: field_types,
                        field_data_types,
                        field_indices,
                    },
                );
            }
            // First pass: collect enum definitions
            if let Statement::Enum { name, variants } = stmt {
                let mut max_payload_size = 1usize;
                let mut variant_infos = HashMap::new();
                for (idx, variant) in variants.iter().enumerate() {
                    let payload_types: Vec<LlType> = variant
                        .data_types
                        .iter()
                        .filter_map(|dt| self.map_type(dt).ok())
                        .collect();
                    max_payload_size = max_payload_size.max(payload_types.len().max(1));
                    variant_infos.insert(
                        variant.name.clone(),
                        VariantInfo {
                            tag: idx as u32,
                            payload_types,
                        },
                    );
                }
                self.user_enums.insert(
                    name.clone(),
                    EnumInfo {
                        llvm_type: format!("{{ i32, [{} x i64] }}", max_payload_size),
                        variants: variant_infos,
                    },
                );
                self.vars.insert(
                    name.clone(),
                    VarInfo {
                        ptr: format!("@enum_{}", sanitize_symbol(name)),
                        ty: LlType::Ptr,
                        data_type: DataType::EnumNamed(name.clone()),
                        owns_heap_string: false,
                        struct_name: None,
                    },
                );
            }
        }

        // Second pass: collect function signatures
        for stmt in &program.statements {
            if let Statement::Function {
                name,
                params,
                return_type,
                ..
            } = stmt
            {
                let llvm_name = if name == "main" {
                    "@mire_main".to_string()
                } else {
                    format!("@fn_{}", sanitize_symbol(name))
                };
                let param_types = params
                    .iter()
                    .map(|(_, ty)| self.map_type(ty))
                    .collect::<Result<Vec<_>>>()?;
                let ret = if name == "main" {
                    LlType::I64
                } else {
                    self.map_type(return_type)?
                };
                self.user_functions.insert(
                    name.clone(),
                    FnInfo {
                        llvm_name,
                        params: param_types,
                        ret,
                        returns_value: *return_type != DataType::None,
                    },
                );
            }
            if let Statement::Impl {
                type_name, methods, ..
            } = stmt
            {
                for method in methods {
                    if let Statement::Function {
                        name,
                        params,
                        return_type,
                        ..
                    } = method
                    {
                        let full_name = format!("{}.{}", type_name, name);
                        self.user_functions.insert(
                            full_name.clone(),
                            FnInfo {
                                llvm_name: format!("@fn_{}", sanitize_symbol(&full_name)),
                                params: params
                                    .iter()
                                    .map(|(param_name, ty)| {
                                        if param_name == "self" {
                                            Ok(LlType::Ptr)
                                        } else {
                                            self.map_type(ty)
                                        }
                                    })
                                    .collect::<Result<Vec<_>>>()?,
                                ret: self.map_type(return_type)?,
                                returns_value: *return_type != DataType::None,
                            },
                        );
                    }
                }
            }
        }

        for stmt in &program.statements {
            if let Statement::Function {
                name,
                params,
                body,
                return_type,
                ..
            } = stmt
            {
                let ret = if name == "main" {
                    LlType::I64
                } else {
                    self.map_type(return_type)?
                };
                let fn_ir = self.compile_function_ir(name, params, body, ret)?;
                self.functions.push(fn_ir);
            }
            if let Statement::Impl {
                type_name, methods, ..
            } = stmt
            {
                for method in methods {
                    if let Statement::Function {
                        name,
                        params,
                        body,
                        return_type,
                        ..
                    } = method
                    {
                        let full_name = format!("{}.{}", type_name, name);
                        let fn_ir = self.compile_function_ir(
                            &full_name,
                            params,
                            body,
                            self.map_type(return_type)?,
                        )?;
                        self.functions.push(fn_ir);
                    }
                }
            }
        }

        if let Some(Statement::Function { body, .. }) = program.statements.iter().find(
            |stmt| matches!(stmt, Statement::Function { name, params, .. } if name == "main" && params.is_empty()),
        ) {
            self.body.push("  %call_main = call i64 @mire_main()".to_string());
            if body.iter().all(|stmt| !matches!(stmt, Statement::Return(_))) {
                self.body.push("  ret i32 0".to_string());
            }
        } else {
            for stmt in &program.statements {
                self.compile_statement(stmt)?;
            }
            self.body.push("  ret i32 0".to_string());
        }

        let mut out = vec![
            "declare i32 @printf(ptr, ...)".to_string(),
            "declare i32 @scanf(ptr, ...)".to_string(),
            "declare i64 @strlen(ptr)".to_string(),
            "declare i64 @clock()".to_string(),
            "declare ptr @malloc(i64)".to_string(),
            "declare void @free(ptr)".to_string(),
            "declare ptr @realloc(ptr, i64)".to_string(),
            "declare ptr @memcpy(ptr, ptr, i64)".to_string(),
            "declare i32 @memcmp(ptr, ptr, i64)".to_string(),
            "declare i32 @strcmp(ptr, ptr)".to_string(),
            "declare i32 @getpagesize()".to_string(),
            "declare i64 @getpid()".to_string(),
            "declare i64 @mire_wall_mark_ns()".to_string(),
            "declare i64 @mire_wall_elapsed_ms(i64)".to_string(),
            "declare ptr @mire_wall_elapsed_ms_str(i64)".to_string(),
            "declare i64 @mire_cpu_mark_ns()".to_string(),
            "declare i64 @mire_cpu_elapsed_ms(i64)".to_string(),
            "declare ptr @mire_cpu_elapsed_ms_str(i64)".to_string(),
            "declare i64 @mire_cpu_cycles_est(i64)".to_string(),
            "declare i64 @mire_mem_process_bytes()".to_string(),
            "declare ptr @mire_mem_format(i64)".to_string(),
            "declare ptr @mire_gpu_snapshot()".to_string(),
            "declare ptr @mire_i64_to_string(i64)".to_string(),
            "declare ptr @mire_bool_to_string(i64)".to_string(),
            "declare ptr @mire_f64_to_string(double)".to_string(),
            "declare ptr @mire_string_copy(ptr)".to_string(),
            "declare ptr @mire_string_concat(ptr, ptr)".to_string(),
            "declare ptr @mire_string_append_owned(ptr, ptr)".to_string(),
            "declare void @mire_string_free(ptr)".to_string(),
            "declare ptr @mire_string_to_upper(ptr)".to_string(),
            "declare ptr @mire_string_to_lower(ptr)".to_string(),
            "declare ptr @mire_strings_replace(ptr, ptr, ptr)".to_string(),
            "declare ptr @mire_strings_split(ptr, ptr)".to_string(),
            "declare ptr @mire_strings_split_list(ptr, ptr)".to_string(),
            "declare ptr @mire_strings_join(ptr, i64, ptr)".to_string(),
            "declare ptr @mire_strings_trim(ptr)".to_string(),
            "declare ptr @mire_list_create(i64, i64)".to_string(),
            "declare ptr @mire_list_push_i64(ptr, i64)".to_string(),
            "declare ptr @mire_list_new()".to_string(),
            "declare ptr @mire_list_push_scalar(ptr, i64, i64)".to_string(),
            "declare ptr @mire_list_push_ptr(ptr, ptr)".to_string(),
            "declare ptr @mire_list_concat(ptr, ptr)".to_string(),
            "declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64)".to_string(),
            "declare ptr @mire_dict_get_ptr(ptr, i64, i64, ptr, ptr)".to_string(),
            "declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64)".to_string(),
            "declare ptr @mire_dict_set_ptr(ptr, i64, i64, i64, ptr, ptr)".to_string(),
            "declare ptr @mire_dict_to_string(ptr)".to_string(),
            "declare ptr @mire_dict_keys(ptr)".to_string(),
            "declare ptr @mire_dict_values(ptr)".to_string(),
            "declare ptr @mire_list_slice(ptr, i64, i64)".to_string(),
            "declare void @mire_runtime_panic(ptr)".to_string(),
            "declare ptr @fgets(ptr, i64, ptr)".to_string(),
            "@.fmt_i64 = private unnamed_addr constant [5 x i8] c\"%ld\\0A\\00\"".to_string(),
            "@.fmt_str = private unnamed_addr constant [4 x i8] c\"%s\\0A\\00\"".to_string(),
            "@.fmt_float = private unnamed_addr constant [4 x i8] c\"%f\\0A\\00\"".to_string(),
            "@.fmt_f64 = private unnamed_addr constant [6 x i8] c\"%.6g\\0A\\00\"".to_string(),
            "@.fmt_bool_true = private unnamed_addr constant [5 x i8] c\"true\\00\"".to_string(),
            "@.fmt_bool_false = private unnamed_addr constant [6 x i8] c\"false\\00\"".to_string(),
            "@.fmt_i32 = private unnamed_addr constant [4 x i8] c\"%d\\0A\\00\"".to_string(),
            "@.fmt_prompt = private unnamed_addr constant [3 x i8] c\"%s\\00\"".to_string(),
            "@.scanf_str = private unnamed_addr constant [3 x i8] c\"%s\\00\"".to_string(),
            "@.scanf_i64 = private unnamed_addr constant [4 x i8] c\"%ld\\00\"".to_string(),
        ];
        out.extend(self.strings);
        out.push(String::new());
        let has_functions = !self.functions.is_empty();
        out.extend(self.functions);
        if has_functions {
            out.push(String::new());
        }
        out.push("define i32 @main() {".to_string());
        out.push("entry:".to_string());
        out.extend(self.entry_allocas);
        out.extend(self.body);
        out.push("}".to_string());
        out.push(String::new());
        Ok(out.join("\n"))
    }

    fn compile_statement(&mut self, stmt: &Statement) -> Result<()> {
        match stmt {
            Statement::Use { .. } => Ok(()),
            Statement::Function { .. } => Ok(()),
            Statement::Let {
                name,
                data_type,
                value,
                ..
            } => {
                let ll_ty = self.map_type(data_type)?;
                let ptr = self.tmp();
                self.entry_allocas
                    .push(format!("  {ptr} = alloca {}", self.ty(ll_ty.clone())));
                self.vars.insert(
                    name.clone(),
                    VarInfo {
                        ptr: ptr.clone(),
                        ty: ll_ty.clone(),
                        data_type: data_type.clone(),
                        owns_heap_string: false,
                        struct_name: value
                            .as_ref()
                            .and_then(|expr| self.struct_name_from_expr(expr)),
                    },
                );
                let init = if let Some(expr) = value {
                    self.compile_expr(expr)?
                } else {
                    self.default_value(ll_ty.clone())
                };
                self.store_variable(name, &ptr, ll_ty, data_type.clone(), init)?;
                Ok(())
            }
            Statement::Assignment { target, value, .. } => match target {
                AssignmentTarget::Field(path) => self.compile_field_assignment(path, value),
                AssignmentTarget::Index { target, index } => {
                    self.compile_index_assignment(target, index, value)
                }
                AssignmentTarget::Variable(name) => {
                    let var = self.vars.get(name).cloned().ok_or_else(|| {
                        MireError::new(ErrorKind::Runtime {
                            message: format!("Avenys does not know variable '{}'", name),
                        })
                    })?;
                    if self.try_compile_in_place_string_append(name, &var, value)? {
                        return Ok(());
                    }
                    let compiled = self.compile_expr(value)?;
                    self.store_variable(name, &var.ptr, var.ty, var.data_type.clone(), compiled)?;
                    let struct_name = self.struct_name_from_expr(value);
                    if let Some(slot) = self.vars.get_mut(name) {
                        slot.struct_name = struct_name;
                    }
                    Ok(())
                }
            },
            Statement::While { condition, body } => {
                let cond_label = self.label("while_cond");
                let body_label = self.label("while_body");
                let end_label = self.label("while_end");
                self.body.push(format!("  br label %{cond_label}"));
                self.body.push(format!("{cond_label}:"));
                let cond_val = self.compile_expr(condition)?;
                let cond = self.cast_to_i1(cond_val)?;
                self.body.push(format!(
                    "  br i1 {}, label %{body_label}, label %{end_label}",
                    cond.repr
                ));
                self.body.push(format!("{body_label}:"));
                self.loop_stack.push(LoopLabels {
                    break_label: end_label.clone(),
                    continue_label: cond_label.clone(),
                });
                for stmt in body {
                    self.compile_statement(stmt)?;
                }
                self.loop_stack.pop();
                self.body.push(format!("  br label %{cond_label}"));
                self.body.push(format!("{end_label}:"));
                Ok(())
            }
            Statement::For {
                variable,
                iterable,
                body,
            } => self.compile_for_range(variable, iterable, body),
            Statement::If {
                condition,
                then_branch,
                else_branch,
            } => {
                let then_label = self.label("if_then");
                let else_label = self.label("if_else");
                let end_label = self.label("if_end");
                let cond_val = self.compile_expr(condition)?;
                let cond = self.cast_to_i1(cond_val)?;
                self.body.push(format!(
                    "  br i1 {}, label %{then_label}, label %{else_label}",
                    cond.repr
                ));
                self.body.push(format!("{then_label}:"));
                for stmt in then_branch {
                    self.compile_statement(stmt)?;
                }
                self.body.push(format!("  br label %{end_label}"));
                self.body.push(format!("{else_label}:"));
                if let Some(else_branch) = else_branch {
                    for stmt in else_branch {
                        self.compile_statement(stmt)?;
                    }
                }
                self.body.push(format!("  br label %{end_label}"));
                self.body.push(format!("{end_label}:"));
                Ok(())
            }
            Statement::Match {
                value,
                cases,
                default,
            } => self.compile_match_statement(value, cases, default),
            Statement::Expression(Expression::Call { name, args, .. }) if name == "__do_while" => {
                self.compile_do_while(args)
            }
            Statement::Expression(Expression::Call { name, args, .. }) if name == "dasu" => {
                for arg in args {
                    self.emit_dasu_expr(arg)?;
                }
                Ok(())
            }
            Statement::Expression(expr) => {
                let _ = self.compile_expr(expr)?;
                Ok(())
            }
            Statement::Break => {
                let labels = self.loop_stack.last().cloned().ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: "Avenys found `break` outside of a loop".to_string(),
                    })
                })?;
                self.body
                    .push(format!("  br label %{}", labels.break_label));
                Ok(())
            }
            Statement::Continue => {
                let labels = self.loop_stack.last().cloned().ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: "Avenys found `continue` outside of a loop".to_string(),
                    })
                })?;
                self.body
                    .push(format!("  br label %{}", labels.continue_label));
                Ok(())
            }
            Statement::Return(expr) => {
                let ret_ty = self.current_return.clone();
                let value = if let Some(expr) = expr {
                    self.compile_expr(expr)?
                } else {
                    self.default_value(ret_ty.clone())
                };
                let ret = self.cast_to_type(value, ret_ty.clone())?;
                self.body
                    .push(format!("  ret {} {}", self.ty(ret_ty), ret.repr));
                Ok(())
            }
            other => Err(MireError::new(ErrorKind::Backend {
                message: format!("Avenys does not yet lower statement {:?}", other),
            })),
        }
    }

    fn compile_expr(&mut self, expr: &Expression) -> Result<LlValue> {
        match expr {
            Expression::Literal(Literal::Int(value)) => Ok(LlValue {
                ty: LlType::I64,
                repr: value.to_string(),
                owned: false,
            }),
            Expression::Literal(Literal::Float(value)) => Ok(LlValue {
                ty: LlType::F64,
                repr: value.to_string(),
                owned: false,
            }),
            Expression::Literal(Literal::Bool(value)) => Ok(LlValue {
                ty: LlType::I1,
                repr: if *value {
                    "1".to_string()
                } else {
                    "0".to_string()
                },
                owned: false,
            }),
            Expression::Literal(Literal::Str(value)) => Ok(self.string_value(value)),
            Expression::Literal(Literal::None) => Ok(LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            }),
            Expression::Reference { expr, .. } => self.compile_reference_expr(expr),
            Expression::Dereference { expr, data_type } => {
                self.compile_dereference_expr(expr, data_type)
            }
            Expression::Identifier(Identifier { name, .. }) => {
                let var = self.vars.get(name).cloned().ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: format!("Avenys unknown identifier '{}'", name),
                    })
                })?;
                let tmp = self.tmp();
                let var_ty = var.ty.clone();
                self.body.push(format!(
                    "  {tmp} = load {}, ptr {}",
                    self.ty(var_ty.clone()),
                    var.ptr
                ));
                Ok(LlValue {
                    ty: var_ty,
                    repr: tmp,
                    owned: var.owns_heap_string,
                })
            }
            Expression::BinaryOp {
                operator,
                left,
                right,
                data_type,
            } if operator == "+" && *data_type == DataType::Str => {
                if matches!(&**left, Expression::Literal(Literal::Str(value)) if value.is_empty()) {
                    return self.compile_expr(right);
                }
                if matches!(&**right, Expression::Literal(Literal::Str(value)) if value.is_empty())
                {
                    return self.compile_expr(left);
                }
                if let (
                    Expression::Literal(Literal::Str(lhs)),
                    Expression::Literal(Literal::Str(rhs)),
                ) = (&**left, &**right)
                {
                    return Ok(self.string_value(&format!("{lhs}{rhs}")));
                }
                let lhs = self.compile_expr(left)?;
                let rhs = self.compile_expr(right)?;
                Ok(self.concat_values(lhs, rhs))
            }
            Expression::BinaryOp {
                operator,
                left,
                right,
                data_type,
                ..
            } => {
                if operator == "&&" || operator == "||" {
                    return self.compile_logical_short_circuit(operator, left, right, data_type);
                }

                let lhs = self.compile_expr(left)?;
                let rhs = self.compile_expr(right)?;

                let left_is_list = matches!(data_type, DataType::Vector { .. } | DataType::List);
                let right_is_list = matches!(data_type, DataType::Vector { .. } | DataType::List);

                if operator == "+" && left_is_list && right_is_list {
                    let result = self.tmp();
                    self.body.push(format!(
                        "  {result} = call ptr @mire_list_concat(ptr {}, ptr {})",
                        lhs.repr, rhs.repr
                    ));
                    return Ok(LlValue {
                        ty: LlType::Ptr,
                        repr: result,
                        owned: true,
                    });
                }

                self.compile_binary(operator, lhs, rhs, data_type)
            }
            Expression::UnaryOp {
                operator, operand, ..
            } => {
                let value = self.compile_expr(operand)?;
                self.compile_unary(operator, value)
            }
            Expression::Call { name, args, .. } if name == "str" => {
                let value = self.compile_expr(&args[0])?;
                let arg_type = self.expression_data_type(&args[0]);
                match arg_type {
                    DataType::Str => Ok(value),
                    DataType::Dict | DataType::Map { .. } => {
                        let tmp = self.tmp();
                        self.body.push(format!(
                            "  {tmp} = call ptr @mire_dict_to_string(ptr {})",
                            value.repr
                        ));
                        Ok(LlValue {
                            ty: LlType::Ptr,
                            repr: tmp,
                            owned: true,
                        })
                    }
                    DataType::Bool => {
                        let i64_value = self.cast_to_i64(value)?;
                        let tmp = self.tmp();
                        self.body.push(format!(
                            "  {tmp} = call ptr @mire_bool_to_string(i64 {})",
                            i64_value.repr
                        ));
                        Ok(LlValue {
                            ty: LlType::Ptr,
                            repr: tmp,
                            owned: true,
                        })
                    }
                    DataType::F64 => {
                        let tmp = self.tmp();
                        self.body.push(format!(
                            "  {tmp} = call ptr @mire_f64_to_string(double {})",
                            value.repr
                        ));
                        Ok(LlValue {
                            ty: LlType::Ptr,
                            repr: tmp,
                            owned: true,
                        })
                    }
                    _ => match value.ty {
                        LlType::Ptr => Ok(value),
                        LlType::I64 => {
                            let tmp = self.tmp();
                            self.body.push(format!(
                                "  {tmp} = call ptr @mire_i64_to_string(i64 {})",
                                value.repr
                            ));
                            Ok(LlValue {
                                ty: LlType::Ptr,
                                repr: tmp,
                                owned: true,
                            })
                        }
                        LlType::I1 => {
                            let i64_value = self.cast_to_i64(value)?;
                            let tmp = self.tmp();
                            self.body.push(format!(
                                "  {tmp} = call ptr @mire_bool_to_string(i64 {})",
                                i64_value.repr
                            ));
                            Ok(LlValue {
                                ty: LlType::Ptr,
                                repr: tmp,
                                owned: true,
                            })
                        }
                        LlType::F64 => {
                            let tmp = self.tmp();
                            self.body.push(format!(
                                "  {tmp} = call ptr @mire_f64_to_string(double {})",
                                value.repr
                            ));
                            Ok(LlValue {
                                ty: LlType::Ptr,
                                repr: tmp,
                                owned: true,
                            })
                        }
                    },
                }
            }
            Expression::Call { name, args, .. } if name == "len" => self.compile_len(args),
            Expression::Call { name, args, .. } if name == "dasu" => {
                for arg in args {
                    self.emit_dasu_expr(arg)?;
                }
                Ok(self.string_value(""))
            }
            Expression::Call {
                name,
                args,
                data_type,
            } if name == "ireru" => self.compile_input_expr(args, data_type),
            Expression::Call {
                name,
                args,
                data_type,
            } if name == "__if_expr" => self.compile_if_expr(args, data_type),
            Expression::Match {
                value,
                cases,
                default,
                data_type,
            } => self.compile_match_expr(value, cases, default, data_type),
            Expression::List {
                elements,
                element_type,
                ..
            } => self.compile_list_literal(elements, element_type),
            Expression::Dict { entries, .. } => self.compile_dict_literal(entries),
            Expression::Index {
                target,
                index,
                data_type,
            } => {
                let target_val = self.compile_expr(target)?;
                let index_val = self.compile_expr(index)?;
                let target_type = self.expression_data_type(target);
                let effective_type =
                    if matches!(target_type, DataType::Vector { dynamic: false, .. }) {
                        target_type.clone()
                    } else {
                        target_type
                    };
                self.compile_index(target_val, index_val, &effective_type, data_type)
            }
            Expression::MemberAccess { target, member, .. } => {
                self.compile_member_access(target, member)
            }
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                ..
            } => self.compile_enum_variant_path(enum_name, variant_name),
            Expression::EnumVariant {
                enum_name,
                variant_name,
                payloads,
                ..
            } => self.compile_enum_variant(enum_name, variant_name, payloads),
            Expression::Call { name, args, .. } if name == "lists.push" => {
                self.compile_lists_push(args)
            }
            Expression::Call { name, args, .. } if name == "lists.slice" => {
                self.compile_lists_slice(args)
            }
            Expression::Call { name, args, .. } if name == "lists.len" => {
                self.compile_list_len(args)
            }
            Expression::Call { name, args, .. } if name == "lists.get" => {
                self.compile_list_get(args)
            }
            Expression::Call { name, args, .. } if name == "pop" => self.compile_list_pop(args),
            Expression::Call { name, args, .. } if name == "dicts.get" => {
                self.compile_dict_get(args)
            }
            Expression::Call { name, args, .. } if name == "dicts.set" => {
                self.compile_dict_set(args)
            }
            Expression::Call { name, args, .. } if name == "contains" => {
                self.compile_contains(args)
            }
            Expression::Call { name, args, .. } if name == "dicts.keys" => {
                self.compile_dict_keys(args)
            }
            Expression::Call { name, args, .. } if name == "dicts.values" => {
                self.compile_dict_values(args)
            }
            Expression::Call { name, args, .. } if name == "float" => self.compile_float(args),
            Expression::Call { name, args, .. } if name == "int" => self.compile_int(args),
            Expression::Call { name, args, .. } if name == "bool" => self.compile_bool(args),
            Expression::Call { name, args, .. } if name == "concat" => self.compile_concat(args),
            Expression::Call { name, args, .. } if name == "strings.replace" => {
                self.compile_replace(args)
            }
            Expression::Call { name, args, .. } if name == "strings.split" => {
                self.compile_split(args)
            }
            Expression::Call { name, args, .. } if name == "strings.join" => {
                self.compile_join(args)
            }
            Expression::Call { name, args, .. } if name == "strings.to_upper" => {
                self.compile_to_upper(args)
            }
            Expression::Call { name, args, .. } if name == "strings.to_lower" => {
                self.compile_to_lower(args)
            }
            Expression::Call { name, args, .. } if name == "strings.trim" => {
                self.compile_trim(args)
            }
            Expression::Call { name, args, .. } if name == "strings.to_string" => {
                self.compile_to_string(args)
            }
            Expression::Call { name, args, .. } if name == "abs" => self.compile_abs(args),
            Expression::Call { name, args, .. } if name == "sqrt" => self.compile_sqrt(args),
            Expression::Call { name, args, .. } if name == "pow" => self.compile_pow(args),
            Expression::Call { name, args, .. } if name == "floor" => self.compile_floor(args),
            Expression::Call { name, args, .. } if name == "ceil" => self.compile_ceil(args),
            Expression::Call { name, args, .. } if name == "round" => self.compile_round(args),
            Expression::Call { name, args, .. } if name == "min" => self.compile_min(args),
            Expression::Call { name, args, .. } if name == "max" => self.compile_max(args),
            Expression::Call { name, args, .. } if name == "range" => self.compile_range(args),
            Expression::Call { name, args, .. } if name == "sleep" => self.compile_sleep(args),
            Expression::Call { name, args, .. } if name == "exit" => self.compile_exit(args),
            Expression::Call { name, args, .. } if name == "time.mark" => {
                self.compile_time_mark(args)
            }
            Expression::Call { name, args, .. } if name == "time.elapsed_ms" => {
                self.compile_time_elapsed_ms(args)
            }
            Expression::Call { name, args, .. } if name == "cpu.mark" => {
                self.compile_cpu_mark(args)
            }
            Expression::Call { name, args, .. } if name == "cpu.elapsed_ms" => {
                self.compile_cpu_elapsed_ms(args)
            }
            Expression::Call { name, args, .. } if name == "cpu.cycles_est" => {
                self.compile_cpu_cycles_est(args)
            }
            Expression::Call { name, args, .. } if name == "gpu.snapshot" => {
                self.compile_gpu_snapshot(args)
            }
            Expression::Call { name, args, .. } if name == "mem.format" => {
                self.compile_mem_format(args)
            }
            Expression::Call { name, args, .. } if name == "mem.process" => {
                self.compile_mem_process(args)
            }
            Expression::Call { name, args, .. } if name == "lists.fold" => {
                self.compile_lists_fold(args)
            }
            Expression::Call { name, args, .. } if name == "lists.map" => {
                self.compile_lists_map(args)
            }
            Expression::Call { name, args, .. } if name == "lists.filter" => {
                self.compile_lists_filter(args)
            }
            Expression::Call { name, args, .. } if name == "math.sum" => {
                self.compile_math_sum(args)
            }
            Expression::Call {
                name,
                args,
                data_type,
            } => {
                // Check if this is a struct constructor call
                if data_type.is_struct_like() && self.user_structs.contains_key(name) {
                    return self.compile_struct_constructor(name, args);
                }

                let mut resolved_name = name.clone();
                let mut prepend_receiver = None;

                if let Some((receiver_name, method_name)) = name.split_once('.')
                    && let Some(struct_name) = self
                        .vars
                        .get(receiver_name)
                        .and_then(|info| info.struct_name.clone())
                {
                    let candidate_name = format!("{}.{}", struct_name, method_name);
                    if let Some(candidate_info) = self.user_functions.get(&candidate_name)
                        && candidate_info.params.len() == args.len() + 1
                    {
                        resolved_name = candidate_name;
                        prepend_receiver = Some(Expression::Identifier(Identifier {
                            name: receiver_name.to_string(),
                            data_type: DataType::StructNamed(struct_name.clone()),
                            line: 0,
                            column: 0,
                        }));
                    }
                }

                let fn_info = self
                    .user_functions
                    .get(&resolved_name)
                    .cloned()
                    .ok_or_else(|| {
                        MireError::new(ErrorKind::Backend {
                            message: format!("Avenys does not yet lower call '{}'", name),
                        })
                    })?;

                let mut resolved_args =
                    Vec::with_capacity(args.len() + usize::from(prepend_receiver.is_some()));
                if let Some(receiver_expr) = prepend_receiver {
                    resolved_args.push(receiver_expr);
                }
                resolved_args.extend(args.iter().cloned());

                if fn_info.params.len() != resolved_args.len() {
                    return Err(MireError::new(ErrorKind::Runtime {
                        message: format!(
                            "Avenys function '{}' expects {} args, got {}",
                            resolved_name,
                            fn_info.params.len(),
                            resolved_args.len()
                        ),
                    }));
                }
                let mut rendered_args = Vec::with_capacity(resolved_args.len());
                for (arg_expr, expected_ty) in resolved_args.iter().zip(fn_info.params.iter()) {
                    let value = self.compile_expr(arg_expr)?;
                    let casted = match expected_ty {
                        LlType::I64 => self.cast_to_i64(value)?,
                        LlType::I1 => self.cast_to_i1(value)?,
                        LlType::F64 => value,
                        LlType::Ptr if value.ty == LlType::Ptr => value,
                        LlType::Ptr => {
                            return Err(MireError::new(ErrorKind::Runtime {
                                message: format!(
                                    "Avenys cannot cast argument for function '{}'",
                                    resolved_name
                                ),
                            }));
                        }
                    };
                    let expected_ty = expected_ty.clone();
                    rendered_args.push(format!("{} {}", self.ty(expected_ty.clone()), casted.repr));
                }
                let tmp = self.tmp();
                let ret_ty = fn_info.ret.clone();
                self.body.push(format!(
                    "  {tmp} = call {} {}({})",
                    self.ty(ret_ty.clone()),
                    fn_info.llvm_name,
                    rendered_args.join(", ")
                ));
                Ok(LlValue {
                    ty: ret_ty,
                    repr: tmp,
                    owned: false,
                })
            }
            Expression::Pipeline {
                input, stage, safe, ..
            } => {
                let input_val = self.compile_expr(input)?;

                match stage.as_ref() {
                    Expression::Call {
                        name,
                        args,
                        data_type: _,
                    } => {
                        if name == "len" {
                            return self.compile_pipeline_len(input, input_val);
                        }

                        let mut all_args = vec![input_val];
                        for arg in args {
                            let arg_val = self.compile_expr(arg)?;
                            all_args.push(arg_val);
                        }

                        if *safe {
                            let tmp = self.tmp();
                            self.body.push(format!(
                                "  {tmp} = call ptr @mire_option_wrap(i64 {})",
                                all_args[1].repr
                            ));
                            return Ok(LlValue {
                                ty: LlType::Ptr,
                                repr: tmp,
                                owned: true,
                            });
                        }

                        let fn_info = self.user_functions.get(name).cloned().ok_or_else(|| {
                            MireError::new(ErrorKind::Backend {
                                message: format!("Avenys does not yet lower call '{}'", name),
                            })
                        })?;

                        let mut rendered_args = Vec::with_capacity(all_args.len());
                        for (arg_val, expected_ty) in all_args.iter().zip(fn_info.params.iter()) {
                            let casted = match expected_ty {
                                LlType::I64 => self.cast_to_i64(arg_val.clone())?,
                                LlType::I1 => self.cast_to_i1(arg_val.clone())?,
                                _ => arg_val.clone(),
                            };
                            rendered_args.push(format!(
                                "{} {}",
                                self.ty(expected_ty.clone()),
                                casted.repr
                            ));
                        }

                        let tmp = self.tmp();
                        let ret_ty = fn_info.ret.clone();
                        self.body.push(format!(
                            "  {tmp} = call {} {}({})",
                            self.ty(ret_ty.clone()),
                            fn_info.llvm_name,
                            rendered_args.join(", ")
                        ));
                        Ok(LlValue {
                            ty: ret_ty,
                            repr: tmp,
                            owned: false,
                        })
                    }
                    Expression::Identifier(Identifier { name, .. }) => {
                        if name == "len" {
                            return self.compile_pipeline_len(input, input_val);
                        }

                        let all_args = [input_val];

                        if *safe {
                            let tmp = self.tmp();
                            self.body.push(format!(
                                "  {tmp} = call ptr @mire_option_wrap(i64 {})",
                                all_args[0].repr
                            ));
                            return Ok(LlValue {
                                ty: LlType::Ptr,
                                repr: tmp,
                                owned: true,
                            });
                        }

                        let fn_info = self.user_functions.get(name).cloned().ok_or_else(|| {
                            MireError::new(ErrorKind::Backend {
                                message: format!("Avenys does not yet lower call '{}'", name),
                            })
                        })?;

                        let mut rendered_args = Vec::with_capacity(all_args.len());
                        for (arg_val, expected_ty) in all_args.iter().zip(fn_info.params.iter()) {
                            let casted = match expected_ty {
                                LlType::I64 => self.cast_to_i64(arg_val.clone())?,
                                LlType::I1 => self.cast_to_i1(arg_val.clone())?,
                                _ => arg_val.clone(),
                            };
                            rendered_args.push(format!(
                                "{} {}",
                                self.ty(expected_ty.clone()),
                                casted.repr
                            ));
                        }

                        let tmp = self.tmp();
                        let ret_ty = fn_info.ret.clone();
                        self.body.push(format!(
                            "  {tmp} = call {} {}({})",
                            self.ty(ret_ty.clone()),
                            fn_info.llvm_name,
                            rendered_args.join(", ")
                        ));
                        Ok(LlValue {
                            ty: ret_ty,
                            repr: tmp,
                            owned: false,
                        })
                    }
                    Expression::Closure {
                        params,
                        body,
                        return_type,
                        capture: _,
                    } => self.compile_pipeline_closure(input_val, params, body, return_type),
                    _ => Err(MireError::new(ErrorKind::Runtime {
                        message: "Pipeline stage must be a function call, identifier, or closure"
                            .to_string(),
                    })),
                }
            }
            other => Err(MireError::new(ErrorKind::Backend {
                message: format!("Avenys does not yet lower expression {:?}", other),
            })),
        }
    }

    fn compile_list_len(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.len expects 1 argument".to_string(),
            }));
        }
        let list = self.compile_expr(&args[0])?;
        self.compile_list_len_value(list)
    }

    fn compile_list_len_value(&mut self, list: LlValue) -> Result<LlValue> {
        let is_null = self.tmp();
        let loaded_len = self.tmp();
        let len = self.tmp();
        let null_label = self.label("list_len_null");
        let load_label = self.label("list_len_load");
        let end_label = self.label("list_len_end");
        let result_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {result_ptr} = alloca i64"));

        self.body
            .push(format!("  {is_null} = icmp eq ptr {}, null", list.repr));
        self.body.push(format!(
            "  br i1 {is_null}, label %{null_label}, label %{load_label}"
        ));

        self.body.push(format!("{null_label}:"));
        self.body.push(format!("  store i64 0, ptr {result_ptr}"));
        self.body.push(format!("  br label %{end_label}"));

        self.body.push(format!("{load_label}:"));
        self.body
            .push(format!("  {loaded_len} = load i64, ptr {}", list.repr));
        self.body
            .push(format!("  store i64 {loaded_len}, ptr {result_ptr}"));
        self.body.push(format!("  br label %{end_label}"));

        self.body.push(format!("{end_label}:"));
        self.body
            .push(format!("  {len} = load i64, ptr {result_ptr}"));
        Ok(LlValue {
            ty: LlType::I64,
            repr: len,
            owned: false,
        })
    }

    fn compile_pipeline_len(&mut self, input: &Expression, value: LlValue) -> Result<LlValue> {
        match self.expression_data_type(input) {
            DataType::Str => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = call i64 @strlen(ptr {})", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: tmp,
                    owned: false,
                })
            }
            DataType::List | DataType::Vector { .. } => self.compile_list_len_value(value),
            _ => match value.ty {
                LlType::Ptr => self.compile_list_len_value(value),
                LlType::I64 | LlType::I1 | LlType::F64 => Ok(LlValue {
                    ty: LlType::I64,
                    repr: "0".to_string(),
                    owned: false,
                }),
            },
        }
    }

    fn compile_pipeline_closure(
        &mut self,
        input_val: LlValue,
        params: &[(String, DataType)],
        body: &[Statement],
        return_type: &DataType,
    ) -> Result<LlValue> {
        if params.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Pipeline closure must have exactly 1 parameter".to_string(),
            }));
        }

        let param_name = &params[0].0;
        let param_type = params[0].1.clone();
        let result_element_type = if *return_type == DataType::Unknown {
            param_type.clone()
        } else {
            return_type.clone()
        };
        let elem_size = self.element_size(&result_element_type);

        let var_ptr = self.tmp();
        self.entry_allocas.push(format!("  {var_ptr} = alloca i64"));

        let list_result_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {list_result_ptr} = alloca ptr"));

        let index_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {index_ptr} = alloca i64"));

        let initial_list = self.tmp();
        self.body.push(format!(
            "  {initial_list} = call ptr @mire_list_create(i64 4, i64 {})",
            elem_size
        ));
        self.body
            .push(format!("  store ptr {initial_list}, ptr {list_result_ptr}"));
        self.body.push(format!("  store i64 0, ptr {index_ptr}"));

        let is_null = self.tmp();
        let loop_cond_label = self.label("pl_closure_cond");
        let loop_body_label = self.label("pl_closure_body");
        let end_label = self.label("pl_closure_end");
        self.body
            .push(format!("  {is_null} = icmp eq ptr {initial_list}, null"));
        self.body.push(format!(
            "  br i1 {is_null}, label %{end_label}, label %{loop_cond_label}"
        ));

        self.body.push(format!("{loop_cond_label}:"));
        let input_len = self.tmp();
        let index = self.tmp();
        let has_more = self.tmp();
        let current_list = self.tmp();

        self.body.push(format!(
            "  {current_list} = load ptr, ptr {list_result_ptr}"
        ));
        self.body
            .push(format!("  {input_len} = load i64, ptr {}", input_val.repr));
        self.body
            .push(format!("  {index} = load i64, ptr {index_ptr}"));
        self.body
            .push(format!("  {has_more} = icmp slt i64 {index}, {input_len}"));
        self.body.push(format!(
            "  br i1 {has_more}, label %{loop_body_label}, label %{end_label}"
        ));

        self.body.push(format!("{loop_body_label}:"));
        let data_ptr = self.tmp();
        let offset = self.tmp();
        let elem_ptr = self.tmp();

        self.body.push(format!(
            "  {data_ptr} = getelementptr i8, ptr {}, i64 8",
            input_val.repr
        ));
        self.body
            .push(format!("  {offset} = mul i64 {index}, {}", elem_size));
        self.body.push(format!(
            "  {elem_ptr} = getelementptr i8, ptr {data_ptr}, i64 {offset}"
        ));

        let elem_val = self.tmp();
        match param_type {
            DataType::Bool => {
                let raw = self.tmp();
                self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
                self.body
                    .push(format!("  {elem_val} = trunc i8 {raw} to i1"));
            }
            DataType::I8 | DataType::U8 => {
                let raw = self.tmp();
                self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
                self.body
                    .push(format!("  {elem_val} = zext i8 {raw} to i64"));
            }
            DataType::I16 | DataType::U16 => {
                let raw = self.tmp();
                self.body
                    .push(format!("  {raw} = load i16, ptr {elem_ptr}"));
                self.body
                    .push(format!("  {elem_val} = zext i16 {raw} to i64"));
            }
            DataType::I32 | DataType::U32 => {
                let raw = self.tmp();
                self.body
                    .push(format!("  {raw} = load i32, ptr {elem_ptr}"));
                self.body
                    .push(format!("  {elem_val} = zext i32 {raw} to i64"));
            }
            _ => {
                self.body
                    .push(format!("  {elem_val} = load i64, ptr {elem_ptr}"));
            }
        }

        let param_var_ptr = var_ptr.clone();
        let old_vars = self.vars.clone();
        self.vars.insert(
            param_name.clone(),
            VarInfo {
                ptr: param_var_ptr.clone(),
                ty: LlType::I64,
                data_type: param_type.clone(),
                owns_heap_string: false,
                struct_name: None,
            },
        );

        self.body
            .push(format!("  store i64 {}, ptr {}", elem_val, param_var_ptr));

        let result_val = self.compile_closure_body(body, return_type);
        self.vars = old_vars;

        let result_i64 = self.cast_to_i64(result_val)?;
        let result_i64_repr = result_i64.repr.clone();

        let result_list_new = self.tmp();
        if elem_size == 8 {
            self.body.push(format!(
                "  {result_list_new} = call ptr @mire_list_push_i64(ptr {current_list}, i64 {result_i64_repr})"
            ));
        } else {
            self.body.push(format!(
                "  {result_list_new} = call ptr @mire_list_push_scalar(ptr {current_list}, i64 {result_i64_repr}, i64 {})",
                elem_size
            ));
        }
        self.body.push(format!(
            "  store ptr {result_list_new}, ptr {list_result_ptr}"
        ));

        let next_index = self.tmp();
        self.body
            .push(format!("  {next_index} = add i64 {index}, 1"));
        self.body
            .push(format!("  store i64 {next_index}, ptr {index_ptr}"));
        self.body.push(format!("  br label %{loop_cond_label}"));

        self.body.push(format!("{end_label}:"));
        let final_list = self.tmp();
        self.body
            .push(format!("  {final_list} = load ptr, ptr {list_result_ptr}"));

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: final_list,
            owned: true,
        })
    }

    fn compile_closure_body(&mut self, body: &[Statement], _expected_type: &DataType) -> LlValue {
        if body.is_empty() {
            return LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            };
        }

        for stmt in body.iter().take(body.len() - 1) {
            let _ = self.compile_statement(stmt);
        }

        if let Some(last) = body.last() {
            match last {
                Statement::Return(Some(expr)) => self.compile_expr(expr).unwrap_or(LlValue {
                    ty: LlType::I64,
                    repr: "0".to_string(),
                    owned: false,
                }),
                Statement::Expression(expr) => self.compile_expr(expr).unwrap_or(LlValue {
                    ty: LlType::I64,
                    repr: "0".to_string(),
                    owned: false,
                }),
                _ => {
                    let _ = self.compile_statement(last);
                    LlValue {
                        ty: LlType::I64,
                        repr: "0".to_string(),
                        owned: false,
                    }
                }
            }
        } else {
            LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            }
        }
    }

    fn compile_bound_closure(
        &mut self,
        params: &[(String, DataType)],
        bound_values: &[LlValue],
        body: &[Statement],
        return_type: &DataType,
    ) -> Result<LlValue> {
        let old_vars = self.vars.clone();

        for ((name, data_type), value) in params.iter().zip(bound_values.iter()) {
            let ll_ty = self.map_type(data_type)?;
            let ptr = self.tmp();
            self.entry_allocas
                .push(format!("  {ptr} = alloca {}", self.ty(ll_ty.clone())));
            self.store_casted(&ptr, ll_ty.clone(), value.clone())?;
            self.vars.insert(
                name.clone(),
                VarInfo {
                    ptr,
                    ty: ll_ty,
                    data_type: data_type.clone(),
                    owns_heap_string: false,
                    struct_name: data_type.struct_name().map(ToOwned::to_owned),
                },
            );
        }

        let result = self.compile_closure_body(body, return_type);
        self.vars = old_vars;
        Ok(result)
    }

    fn load_list_element_unchecked(
        &mut self,
        list_ptr: &str,
        index_repr: &str,
        element_type: &DataType,
    ) -> Result<LlValue> {
        let base_ptr = self.tmp();
        let offset = self.tmp();
        let elem_ptr = self.tmp();
        let elem_size = self.element_size(element_type);

        self.body.push(format!(
            "  {base_ptr} = getelementptr i8, ptr {list_ptr}, i64 8"
        ));
        self.body
            .push(format!("  {offset} = mul i64 {index_repr}, {elem_size}"));
        self.body.push(format!(
            "  {elem_ptr} = getelementptr i8, ptr {base_ptr}, i64 {offset}"
        ));

        let elem_ty = self.map_type(element_type)?;
        if elem_ty == LlType::Ptr {
            let val = self.tmp();
            self.body
                .push(format!("  {val} = load ptr, ptr {elem_ptr}"));
            return Ok(LlValue {
                ty: LlType::Ptr,
                repr: val,
                owned: false,
            });
        }

        if matches!(element_type, DataType::Bool) {
            let raw = self.tmp();
            let val = self.tmp();
            self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
            self.body.push(format!("  {val} = icmp ne i8 {raw}, 0"));
            return Ok(LlValue {
                ty: LlType::I1,
                repr: val,
                owned: false,
            });
        }

        let raw_ty = self.scalar_storage_ir_type(element_type);
        let raw = self.tmp();
        self.body
            .push(format!("  {raw} = load {raw_ty}, ptr {elem_ptr}"));
        let val = match raw_ty {
            "i8" => {
                let widened = self.tmp();
                let ext = if matches!(element_type, DataType::U8) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i8 {raw} to i64"));
                widened
            }
            "i16" => {
                let widened = self.tmp();
                let ext = if matches!(element_type, DataType::U16) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i16 {raw} to i64"));
                widened
            }
            "i32" => {
                let widened = self.tmp();
                let ext = if matches!(element_type, DataType::U32) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i32 {raw} to i64"));
                widened
            }
            _ => raw,
        };

        Ok(LlValue {
            ty: LlType::I64,
            repr: val,
            owned: false,
        })
    }

    fn load_slot_value(&mut self, ptr: &str, data_type: &DataType) -> Result<LlValue> {
        let ll_ty = self.map_type(data_type)?;
        let tmp = self.tmp();
        self.body.push(format!(
            "  {tmp} = load {}, ptr {ptr}",
            self.ty(ll_ty.clone())
        ));
        Ok(LlValue {
            ty: ll_ty,
            repr: tmp,
            owned: false,
        })
    }

    fn push_list_value(
        &mut self,
        list: LlValue,
        value: LlValue,
        data_type: &DataType,
    ) -> Result<LlValue> {
        let result = self.tmp();
        let ll_ty = self.map_type(data_type)?;
        let elem_size = self.element_size(data_type);

        if ll_ty == LlType::I64 && elem_size == 8 {
            let casted = self.cast_to_i64(value)?;
            self.body.push(format!(
                "  {result} = call ptr @mire_list_push_i64(ptr {}, i64 {})",
                list.repr, casted.repr
            ));
        } else {
            let casted = self.cast_to_i64(value)?;
            self.body.push(format!(
                "  {result} = call ptr @mire_list_push_scalar(ptr {}, i64 {}, i64 {})",
                list.repr, casted.repr, elem_size
            ));
        }

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_field_assignment(&mut self, target: &str, value: &Expression) -> Result<()> {
        let (field_ptr, field_ty, field_data_type) =
            self.resolve_struct_field_ptr_from_target(target)?;
        let compiled = self.compile_expr(value)?;

        if field_data_type == DataType::Str && field_ty == LlType::Ptr {
            let owned_value = if compiled.owned {
                compiled
            } else {
                let copied = self.tmp();
                self.body.push(format!(
                    "  {copied} = call ptr @mire_string_copy(ptr {})",
                    compiled.repr
                ));
                LlValue {
                    ty: LlType::Ptr,
                    repr: copied,
                    owned: true,
                }
            };
            self.store_casted(&field_ptr, field_ty, owned_value)?;
            return Ok(());
        }

        self.store_casted(&field_ptr, field_ty, compiled)
    }

    fn compile_reference_expr(&mut self, expr: &Expression) -> Result<LlValue> {
        let (ptr, _) = self.resolve_lvalue_ptr(expr)?;
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: ptr,
            owned: false,
        })
    }

    fn compile_dereference_expr(
        &mut self,
        expr: &Expression,
        data_type: &DataType,
    ) -> Result<LlValue> {
        let ptr = self.compile_expr(expr)?;
        if ptr.ty != LlType::Ptr {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cannot dereference non-pointer value".to_string(),
            }));
        }
        self.load_from_ptr(&ptr.repr, data_type)
    }

    fn compile_index_assignment(
        &mut self,
        target: &Expression,
        index: &Expression,
        value: &Expression,
    ) -> Result<()> {
        let target_data_type = self.expression_data_type(target);
        let element_data_type = match &target_data_type {
            DataType::Array { element_type, .. }
            | DataType::Slice { element_type }
            | DataType::Vector { element_type, .. } => *element_type.clone(),
            _ => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Indexed assignment is not supported for type {:?}",
                        target_data_type
                    ),
                }));
            }
        };
        let (elem_ptr, elem_ty) =
            self.resolve_index_ptr(target, index, &target_data_type, &element_data_type)?;
        let compiled = self.compile_expr(value)?;
        self.store_casted(&elem_ptr, elem_ty, compiled)
    }

    fn resolve_index_ptr(
        &mut self,
        target: &Expression,
        index: &Expression,
        target_data_type: &DataType,
        element_data_type: &DataType,
    ) -> Result<(String, LlType)> {
        let target_val = self.compile_expr(target)?;
        if target_val.ty != LlType::Ptr {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cannot assign through non-pointer index target".to_string(),
            }));
        }
        let compiled_index = self.compile_expr(index)?;
        let index_val = self.cast_to_i64(compiled_index)?;
        let elem_size = self.element_size(element_data_type);
        let (base_ptr, do_bounds_check) = match target_data_type {
            DataType::Array { size, .. } => {
                let len_val = LlValue {
                    ty: LlType::I64,
                    repr: size.to_string(),
                    owned: false,
                };
                self.emit_bounds_check(index_val.clone(), len_val, "index out of bounds");
                let base = self.tmp();
                self.body.push(format!(
                    "  {base} = getelementptr inbounds i8, ptr {}, i64 8",
                    target_val.repr
                ));
                (base, false)
            }
            DataType::Vector { .. } | DataType::Slice { .. } => {
                let base = self.tmp();
                self.body.push(format!(
                    "  {base} = getelementptr inbounds i8, ptr {}, i64 8",
                    target_val.repr
                ));
                (base, true)
            }
            other => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!("Type {:?} does not support indexed assignment", other),
                }));
            }
        };
        if do_bounds_check {
            let len = self.compile_list_len_value(target_val)?;
            self.emit_bounds_check(index_val.clone(), len, "index out of bounds");
        }
        let offset = self.tmp();
        self.body.push(format!(
            "  {offset} = mul i64 {}, {}",
            index_val.repr, elem_size
        ));
        let elem_ptr = self.tmp();
        self.body.push(format!(
            "  {elem_ptr} = getelementptr inbounds i8, ptr {base_ptr}, i64 {offset}"
        ));
        Ok((elem_ptr, self.map_type(element_data_type)?))
    }

    fn resolve_lvalue_ptr(&mut self, expr: &Expression) -> Result<(String, DataType)> {
        match expr {
            Expression::Identifier(Identifier { name, .. }) => {
                let var = self.vars.get(name).cloned().ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: format!("Avenys unknown identifier '{}'", name),
                    })
                })?;
                Ok((var.ptr, var.data_type))
            }
            Expression::MemberAccess { target, member, .. } => {
                let (field_ptr, _, field_data_type) =
                    self.resolve_struct_field_ptr(target, &[member.as_str()])?;
                Ok((field_ptr, field_data_type))
            }
            Expression::Index {
                target,
                index,
                data_type,
            } => {
                let target_data_type = self.expression_data_type(target);
                let element_data_type = if *data_type != DataType::Unknown {
                    data_type.clone()
                } else {
                    self.expression_data_type(expr)
                };
                let (elem_ptr, _) =
                    self.resolve_index_ptr(target, index, &target_data_type, &element_data_type)?;
                Ok((elem_ptr, element_data_type))
            }
            other => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Avenys cannot take a reference to expression {:?}", other),
            })),
        }
    }

    fn load_from_ptr(&mut self, ptr: &str, data_type: &DataType) -> Result<LlValue> {
        let ll_ty = self.map_type(data_type)?;
        if ll_ty == LlType::Ptr {
            let value = self.tmp();
            self.body.push(format!("  {value} = load ptr, ptr {ptr}"));
            return Ok(LlValue {
                ty: LlType::Ptr,
                repr: value,
                owned: false,
            });
        }
        if ll_ty == LlType::I1 {
            let value = self.tmp();
            self.body.push(format!("  {value} = load i1, ptr {ptr}"));
            return Ok(LlValue {
                ty: LlType::I1,
                repr: value,
                owned: false,
            });
        }

        let raw_ty = self.scalar_storage_ir_type(data_type);
        let raw = self.tmp();
        self.body
            .push(format!("  {raw} = load {raw_ty}, ptr {ptr}"));
        let value = match raw_ty {
            "i8" => {
                let widened = self.tmp();
                let ext = if matches!(data_type, DataType::U8) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i8 {raw} to i64"));
                widened
            }
            "i16" => {
                let widened = self.tmp();
                let ext = if matches!(data_type, DataType::U16) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i16 {raw} to i64"));
                widened
            }
            "i32" => {
                let widened = self.tmp();
                let ext = if matches!(data_type, DataType::U32) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {widened} = {ext} i32 {raw} to i64"));
                widened
            }
            _ => raw,
        };

        Ok(LlValue {
            ty: LlType::I64,
            repr: value,
            owned: false,
        })
    }

    fn resolve_struct_field_ptr_from_target(
        &mut self,
        target: &str,
    ) -> Result<(String, LlType, DataType)> {
        let mut segments = target.split('.');
        let owner = segments.next().ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Invalid field assignment target '{}'", target),
            })
        })?;
        let fields: Vec<_> = segments.collect();
        if fields.is_empty() {
            return Err(MireError::new(ErrorKind::Runtime {
                message: format!("Field assignment target '{}' has no field path", target),
            }));
        }

        let owner_expr = if owner == "self" {
            Expression::Identifier(Identifier {
                name: "self".to_string(),
                data_type: self
                    .vars
                    .get("self")
                    .map(|var| var.data_type.clone())
                    .unwrap_or(DataType::Unknown),
                line: 0,
                column: 0,
            })
        } else {
            let var = self.vars.get(owner).ok_or_else(|| {
                MireError::new(ErrorKind::Runtime {
                    message: format!("Avenys does not know variable '{}'", owner),
                })
            })?;
            Expression::Identifier(Identifier {
                name: owner.to_string(),
                data_type: var.data_type.clone(),
                line: 0,
                column: 0,
            })
        };

        self.resolve_struct_field_ptr(&owner_expr, &fields)
    }

    fn resolve_struct_field_ptr(
        &mut self,
        target: &Expression,
        fields: &[&str],
    ) -> Result<(String, LlType, DataType)> {
        let target_val = self.compile_expr(target)?;
        let mut struct_name = self.struct_name_from_expr(target).ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!(
                    "Avenys cannot resolve struct field path '{}'",
                    fields.join(".")
                ),
            })
        })?;
        let mut current_ptr = target_val.repr;

        for (index, member) in fields.iter().enumerate() {
            let struct_info = self
                .user_structs
                .get(&struct_name)
                .cloned()
                .ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: format!("Unknown struct '{}'", struct_name),
                    })
                })?;
            let field_index = struct_info
                .field_indices
                .get(*member)
                .copied()
                .ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: format!("Struct '{}' has no field '{}'", struct_name, member),
                    })
                })?;
            let struct_ty = self.render_struct_ty(&struct_info.fields);
            let field_ptr = self.tmp();
            self.body.push(format!(
                "  {field_ptr} = getelementptr inbounds {}, ptr {}, i32 0, i32 {}",
                struct_ty, current_ptr, field_index
            ));

            let field_ty = struct_info
                .fields
                .get(field_index)
                .cloned()
                .unwrap_or(LlType::I64);
            let field_data_type = struct_info
                .field_data_types
                .get(field_index)
                .cloned()
                .unwrap_or(DataType::Unknown);

            if index + 1 == fields.len() {
                return Ok((field_ptr, field_ty, field_data_type));
            }

            let next_struct_name = field_data_type
                .struct_name()
                .map(ToOwned::to_owned)
                .ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        message: format!(
                            "Field '{}.{}' is not a nested struct",
                            struct_name, member
                        ),
                    })
                })?;
            let loaded = self.tmp();
            self.body
                .push(format!("  {loaded} = load ptr, ptr {field_ptr}"));
            current_ptr = loaded;
            struct_name = next_struct_name;
        }

        Err(MireError::new(ErrorKind::Runtime {
            message: format!("Invalid field assignment target '{}'", fields.join(".")),
        }))
    }

    fn compile_list_get(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.get expects 2 arguments".to_string(),
            }));
        }
        let list = self.compile_expr(&args[0])?;
        let index = self.compile_expr(&args[1])?;
        let list_type = self.expression_data_type(&args[0]);
        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            _ => DataType::I64,
        };
        self.compile_index(list, index, &list_type, &elem_type)
    }

    fn compile_member_access(&mut self, target: &Expression, member: &str) -> Result<LlValue> {
        let target_val = self.compile_expr(target)?;
        let struct_name = self.struct_name_from_expr(target).ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!(
                    "Avenys cannot resolve struct member '{}' without concrete struct metadata",
                    member
                ),
            })
        })?;
        let struct_info = self
            .user_structs
            .get(&struct_name)
            .cloned()
            .ok_or_else(|| {
                MireError::new(ErrorKind::Runtime {
                    message: format!("Unknown struct '{}'", struct_name),
                })
            })?;
        let field_index = struct_info
            .field_indices
            .get(member)
            .copied()
            .ok_or_else(|| {
                MireError::new(ErrorKind::Runtime {
                    message: format!("Struct '{}' has no field '{}'", struct_name, member),
                })
            })?;
        let struct_ty = self.render_struct_ty(&struct_info.fields);
        let field_ptr = self.tmp();
        self.body.push(format!(
            "  {field_ptr} = getelementptr inbounds {}, ptr {}, i32 0, i32 {}",
            struct_ty, target_val.repr, field_index
        ));
        let field_ty = struct_info
            .fields
            .get(field_index)
            .cloned()
            .unwrap_or(LlType::I64);

        match field_ty {
            LlType::I64 => {
                let value = self.tmp();
                self.body
                    .push(format!("  {value} = load i64, ptr {field_ptr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: value,
                    owned: false,
                })
            }
            LlType::I1 => {
                let value = self.tmp();
                self.body
                    .push(format!("  {value} = load i1, ptr {field_ptr}"));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: value,
                    owned: false,
                })
            }
            LlType::F64 => {
                let value = self.tmp();
                self.body
                    .push(format!("  {value} = load double, ptr {field_ptr}"));
                Ok(LlValue {
                    ty: LlType::F64,
                    repr: value,
                    owned: false,
                })
            }
            LlType::Ptr => {
                let value = self.tmp();
                self.body
                    .push(format!("  {value} = load ptr, ptr {field_ptr}"));
                Ok(LlValue {
                    ty: LlType::Ptr,
                    repr: value,
                    owned: false,
                })
            }
        }
    }

    fn compile_enum_variant_path(
        &mut self,
        enum_name: &str,
        variant_name: &str,
    ) -> Result<LlValue> {
        let (enum_ty, tag) = {
            let (enum_info, variant) = self.lookup_enum_variant(enum_name, variant_name)?;
            (enum_info.llvm_type.clone(), variant.tag)
        };
        let ptr = self.tmp();
        self.body.push(format!("  {ptr} = alloca {enum_ty}"));
        let tag_ptr = self.tmp();
        self.body.push(format!(
            "  {tag_ptr} = getelementptr inbounds {}, ptr {ptr}, i32 0, i32 0",
            enum_ty
        ));
        self.body
            .push(format!("  store i32 {}, ptr {tag_ptr}", tag));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: ptr,
            owned: false,
        })
    }

    fn compile_enum_variant(
        &mut self,
        enum_name: &str,
        variant_name: &str,
        payloads: &[Expression],
    ) -> Result<LlValue> {
        let (enum_ty, tag) = {
            let (enum_info, variant) = self.lookup_enum_variant(enum_name, variant_name)?;
            (enum_info.llvm_type.clone(), variant.tag)
        };
        let ptr = self.tmp();
        self.body.push(format!("  {ptr} = alloca {enum_ty}"));
        let tag_ptr = self.tmp();
        self.body.push(format!(
            "  {tag_ptr} = getelementptr inbounds {}, ptr {ptr}, i32 0, i32 0",
            enum_ty
        ));
        self.body
            .push(format!("  store i32 {}, ptr {tag_ptr}", tag));
        for (index, payload_expr) in payloads.iter().enumerate() {
            let payload_val = self.compile_expr(payload_expr)?;
            let payload_i64 = self.cast_to_i64(payload_val)?;
            let payload_ptr = self.tmp();
            self.body.push(format!(
                "  {payload_ptr} = getelementptr inbounds {}, ptr {ptr}, i32 0, i32 1, i32 {}",
                enum_ty, index
            ));
            self.body.push(format!(
                "  store i64 {}, ptr {payload_ptr}",
                payload_i64.repr
            ));
        }
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: ptr,
            owned: false,
        })
    }

    fn compile_index(
        &mut self,
        target: LlValue,
        index: LlValue,
        target_data_type: &DataType,
        result_data_type: &DataType,
    ) -> Result<LlValue> {
        if target.ty != LlType::Ptr {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cannot index non-pointer type".to_string(),
            }));
        }

        match target_data_type {
            DataType::List | DataType::Vector { .. } | DataType::Slice { .. } | DataType::Tuple => {
                let index = self.cast_to_i64(index)?;
                let len = self.compile_list_len_value(target.clone())?;
                self.emit_bounds_check(index.clone(), len, "index out of bounds");
                let elem_size = self.element_size(result_data_type);
                let base = self.tmp();
                self.body.push(format!(
                    "  {base} = getelementptr inbounds i8, ptr {}, i64 8",
                    target.repr
                ));
                let offset = self.tmp();
                self.body.push(format!(
                    "  {offset} = mul i64 {}, {}",
                    index.repr, elem_size
                ));
                let elem_ptr = self.tmp();
                self.body.push(format!(
                    "  {elem_ptr} = getelementptr inbounds i8, ptr {base}, i64 {offset}"
                ));
                let elem_ty = self.map_type(result_data_type)?;
                if elem_ty == LlType::Ptr {
                    let val = self.tmp();
                    self.body
                        .push(format!("  {val} = load ptr, ptr {elem_ptr}"));
                    Ok(LlValue {
                        ty: LlType::Ptr,
                        repr: val,
                        owned: false,
                    })
                } else if elem_ty == LlType::I1 {
                    let raw = self.tmp();
                    let val = self.tmp();
                    self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
                    self.body.push(format!("  {val} = icmp ne i8 {raw}, 0"));
                    Ok(LlValue {
                        ty: LlType::I1,
                        repr: val,
                        owned: false,
                    })
                } else {
                    let raw_ty = self.scalar_storage_ir_type(result_data_type);
                    let raw = self.tmp();
                    self.body
                        .push(format!("  {raw} = load {raw_ty}, ptr {elem_ptr}"));
                    let val = match raw_ty {
                        "i8" => {
                            let widened = self.tmp();
                            let ext = if matches!(result_data_type, DataType::U8) {
                                "zext"
                            } else {
                                "sext"
                            };
                            self.body
                                .push(format!("  {widened} = {ext} i8 {raw} to i64"));
                            widened
                        }
                        "i16" => {
                            let widened = self.tmp();
                            let ext = if matches!(result_data_type, DataType::U16) {
                                "zext"
                            } else {
                                "sext"
                            };
                            self.body
                                .push(format!("  {widened} = {ext} i16 {raw} to i64"));
                            widened
                        }
                        "i32" => {
                            let widened = self.tmp();
                            let ext = if matches!(result_data_type, DataType::U32) {
                                "zext"
                            } else {
                                "sext"
                            };
                            self.body
                                .push(format!("  {widened} = {ext} i32 {raw} to i64"));
                            widened
                        }
                        _ => raw,
                    };
                    Ok(LlValue {
                        ty: LlType::I64,
                        repr: val,
                        owned: false,
                    })
                }
            }
            DataType::Array { element_type, size } => {
                let index = self.cast_to_i64(index)?;
                let elem_size = self.element_size(element_type);
                let size_val = LlValue {
                    ty: LlType::I64,
                    repr: size.to_string(),
                    owned: false,
                };
                self.emit_bounds_check(index.clone(), size_val, "index out of bounds");
                let base = self.tmp();
                self.body.push(format!(
                    "  {base} = getelementptr inbounds i8, ptr {}, i64 8",
                    target.repr
                ));
                let offset_val = self.tmp();
                self.body.push(format!(
                    "  {offset_val} = mul i64 {}, {}",
                    index.repr, elem_size
                ));
                let elem_ptr = self.tmp();
                self.body.push(format!(
                    "  {elem_ptr} = getelementptr inbounds i8, ptr {base}, i64 {offset_val}"
                ));
                let elem_ty = self.map_type(element_type)?;
                if elem_ty == LlType::Ptr {
                    let val = self.tmp();
                    self.body
                        .push(format!("  {val} = load ptr, ptr {elem_ptr}"));
                    Ok(LlValue {
                        ty: LlType::Ptr,
                        repr: val,
                        owned: false,
                    })
                } else if elem_ty == LlType::I1 {
                    let raw = self.tmp();
                    let val = self.tmp();
                    self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
                    self.body.push(format!("  {val} = icmp ne i8 {raw}, 0"));
                    Ok(LlValue {
                        ty: LlType::I1,
                        repr: val,
                        owned: false,
                    })
                } else {
                    let raw_ty = self.scalar_storage_ir_type(element_type);
                    let raw = self.tmp();
                    self.body
                        .push(format!("  {raw} = load {raw_ty}, ptr {elem_ptr}"));
                    let val = match raw_ty {
                        "i8" => {
                            let widened = self.tmp();
                            self.body
                                .push(format!("  {widened} = zext i8 {raw} to i64"));
                            widened
                        }
                        "i16" => {
                            let widened = self.tmp();
                            self.body
                                .push(format!("  {widened} = zext i16 {raw} to i64"));
                            widened
                        }
                        "i32" => {
                            let widened = self.tmp();
                            self.body
                                .push(format!("  {widened} = zext i32 {raw} to i64"));
                            widened
                        }
                        _ => raw,
                    };
                    Ok(LlValue {
                        ty: LlType::I64,
                        repr: val,
                        owned: false,
                    })
                }
            }
            DataType::Str => {
                let index = self.cast_to_i64(index)?;
                let len = self.tmp();
                self.body
                    .push(format!("  {len} = call i64 @strlen(ptr {})", target.repr));
                self.emit_bounds_check(
                    index.clone(),
                    LlValue {
                        ty: LlType::I64,
                        repr: len,
                        owned: false,
                    },
                    "index out of bounds",
                );
                let elem_ptr = self.tmp();
                self.body.push(format!(
                    "  {elem_ptr} = getelementptr inbounds i8, ptr {}, i64 {}",
                    target.repr, index.repr
                ));
                let byte = self.tmp();
                self.body
                    .push(format!("  {byte} = load i8, ptr {elem_ptr}"));
                let widened = self.tmp();
                self.body
                    .push(format!("  {widened} = zext i8 {byte} to i64"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: widened,
                    owned: false,
                })
            }
            _ => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Avenys cannot index type {:?}", target_data_type),
            })),
        }
    }

    fn compile_list_pop(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys list.pop(...) expects 1 argument".to_string(),
            }));
        }
        Err(MireError::new(ErrorKind::Backend {
            message: "Avenys does not yet lower list.pop(...) safely".to_string(),
        }))
    }

    fn compile_dict_get(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 && args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys dict.get(...) expects 2 or 3 arguments".to_string(),
            }));
        }

        let (dict_key_type, dict_value_type) = match self.expression_data_type(&args[0]) {
            DataType::Map {
                key_type,
                value_type,
            } => (*key_type, *value_type),
            _ => (DataType::Unknown, DataType::I64),
        };
        let dict = self.compile_expr(&args[0])?;
        let key = self.compile_expr(&args[1])?;
        let key_kind = self.runtime_kind_code(&dict_key_type);
        let key_i64 = if key.ty == LlType::Ptr {
            LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            }
        } else {
            self.cast_to_i64(key.clone())?
        };
        let key_ptr = if key.ty == LlType::Ptr {
            key
        } else {
            LlValue {
                ty: LlType::Ptr,
                repr: "null".to_string(),
                owned: false,
            }
        };

        if matches!(
            dict_value_type,
            DataType::Map { .. }
                | DataType::Vector { .. }
                | DataType::Array { .. }
                | DataType::Slice { .. }
                | DataType::Str
        ) {
            let default_value = if args.len() == 3 {
                let value = self.compile_expr(&args[2])?;
                self.cast_to_type(value, LlType::Ptr)?
            } else {
                LlValue {
                    ty: LlType::Ptr,
                    repr: "null".to_string(),
                    owned: false,
                }
            };
            let result = self.tmp();
            self.body.push(format!(
                "  {result} = call ptr @mire_dict_get_ptr(ptr {}, i64 {}, i64 {}, ptr {}, ptr {})",
                dict.repr, key_kind, key_i64.repr, key_ptr.repr, default_value.repr
            ));
            return Ok(LlValue {
                ty: LlType::Ptr,
                repr: result,
                owned: false,
            });
        }

        let default_value = if args.len() == 3 {
            let value = self.compile_expr(&args[2])?;
            self.cast_to_i64(value)?
        } else {
            LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            }
        };
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call i64 @mire_dict_get_i64(ptr {}, i64 {}, i64 {}, ptr {}, i64 {})",
            dict.repr, key_kind, key_i64.repr, key_ptr.repr, default_value.repr
        ));
        Ok(LlValue {
            ty: LlType::I64,
            repr: result,
            owned: false,
        })
    }

    fn compile_dict_set(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys dict.set(...) expects 3 arguments".to_string(),
            }));
        }
        let dict_type = self.expression_data_type(&args[0]);
        let (key_data_type, value_data_type) = match dict_type {
            DataType::Map {
                key_type,
                value_type,
            } => (*key_type, *value_type),
            _ => (
                self.expression_data_type(&args[1]),
                self.expression_data_type(&args[2]),
            ),
        };
        let dict = self.compile_expr(&args[0])?;
        let key = self.compile_expr(&args[1])?;
        let value_expr = self.compile_expr(&args[2])?;
        let key_kind = self.runtime_kind_code(&key_data_type);
        let value_kind = self.runtime_kind_code(&value_data_type);
        let key_i64 = if key.ty == LlType::Ptr {
            LlValue {
                ty: LlType::I64,
                repr: "0".to_string(),
                owned: false,
            }
        } else {
            self.cast_to_i64(key.clone())?
        };
        let key_ptr = if key.ty == LlType::Ptr {
            key
        } else {
            LlValue {
                ty: LlType::Ptr,
                repr: "null".to_string(),
                owned: false,
            }
        };
        let result = self.tmp();

        if value_expr.ty == LlType::Ptr {
            let value = self.cast_to_type(value_expr, LlType::Ptr)?;
            self.body.push(format!(
                "  {result} = call ptr @mire_dict_set_ptr(ptr {}, i64 {}, i64 {}, i64 {}, ptr {}, ptr {})",
                dict.repr, key_kind, value_kind, key_i64.repr, key_ptr.repr, value.repr
            ));
        } else {
            let value = self.cast_to_i64(value_expr)?;
            self.body.push(format!(
                "  {result} = call ptr @mire_dict_set_i64(ptr {}, i64 {}, i64 {}, i64 {}, ptr {}, i64 {})",
                dict.repr, key_kind, value_kind, key_i64.repr, key_ptr.repr, value.repr
            ));
        }
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_contains(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys contains(...) expects 2 arguments".to_string(),
            }));
        }
        Err(MireError::new(ErrorKind::Backend {
            message: "Avenys does not yet lower contains(...) safely".to_string(),
        }))
    }

    fn compile_dict_keys(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "dicts.keys(...) expects 1 argument".to_string(),
            }));
        }
        let dict = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_dict_keys(ptr {})",
            dict.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_dict_values(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "dicts.values(...) expects 1 argument".to_string(),
            }));
        }
        let dict = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_dict_values(ptr {})",
            dict.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_float(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys float(...) expects 1 argument".to_string(),
            }));
        }
        let value = self.compile_expr(&args[0])?;
        self.cast_to_i64(value)
    }

    fn compile_int(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys int(...) expects 1 argument".to_string(),
            }));
        }
        let value = self.compile_expr(&args[0])?;
        self.cast_to_i64(value)
    }

    fn compile_bool(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys bool(...) expects 1 argument".to_string(),
            }));
        }
        let value = self.compile_expr(&args[0])?;
        self.cast_to_i1(value)
    }

    fn compile_concat(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() < 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys concat(...) expects at least 2 arguments".to_string(),
            }));
        }

        let mut iter = args.iter().filter(
            |arg| !matches!(arg, Expression::Literal(Literal::Str(value)) if value.is_empty()),
        );

        let Some(first) = iter.next() else {
            return Ok(self.string_value(""));
        };

        let mut acc = self.compile_expr(first)?;
        for arg in iter {
            let value = self.compile_expr(arg)?;
            acc = self.concat_values(acc, value);
        }
        Ok(acc)
    }

    fn compile_replace(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys replace(...) expects 3 arguments".to_string(),
            }));
        }

        if let (
            Expression::Literal(Literal::Str(input)),
            Expression::Literal(Literal::Str(from)),
            Expression::Literal(Literal::Str(to)),
        ) = (&args[0], &args[1], &args[2])
        {
            return Ok(self.string_value(&input.replace(from, to)));
        }

        if let (_, Expression::Literal(Literal::Str(from)), Expression::Literal(Literal::Str(to))) =
            (&args[0], &args[1], &args[2])
            && (from.is_empty() || from == to)
        {
            return self.compile_expr(&args[0]);
        }

        let input = self.compile_expr(&args[0])?;
        let from = self.compile_expr(&args[1])?;
        let to = self.compile_expr(&args[2])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_strings_replace(ptr {}, ptr {}, ptr {})",
            input.repr, from.repr, to.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_split(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "strings.split(...) expects 2 arguments".to_string(),
            }));
        }
        let input = self.compile_expr(&args[0])?;
        let delimiter = self.compile_expr(&args[1])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_strings_split_list(ptr {}, ptr {})",
            input.repr, delimiter.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_join(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "strings.join(...) expects 2 arguments".to_string(),
            }));
        }
        let input = self.compile_expr(&args[0])?;
        let delimiter = self.compile_expr(&args[1])?;
        let count = self.compile_list_len_value(input.clone())?;
        let data_ptr = self.tmp();
        self.body.push(format!(
            "  {data_ptr} = getelementptr inbounds i8, ptr {}, i64 8",
            input.repr
        ));
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_strings_join(ptr {data_ptr}, i64 {}, ptr {})",
            count.repr, delimiter.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_trim(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "strings.trim(...) expects 1 argument".to_string(),
            }));
        }
        if let Expression::Literal(Literal::Str(input)) = &args[0] {
            return Ok(self.string_value(input.trim()));
        }
        let input = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_strings_trim(ptr {})",
            input.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_to_upper(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys to_upper(...) expects 1 argument".to_string(),
            }));
        }
        if let Expression::Literal(Literal::Str(input)) = &args[0] {
            return Ok(self.string_value(&input.to_ascii_uppercase()));
        }
        let input = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_string_to_upper(ptr {})",
            input.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_to_lower(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys to_lower(...) expects 1 argument".to_string(),
            }));
        }
        if let Expression::Literal(Literal::Str(input)) = &args[0] {
            return Ok(self.string_value(&input.to_ascii_lowercase()));
        }
        let input = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_string_to_lower(ptr {})",
            input.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_to_string(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "strings.to_string(...) expects 1 argument".to_string(),
            }));
        }
        let input = self.compile_expr(&args[0])?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_dict_to_string(ptr {})",
            input.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_abs(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys abs(...) expects 1 argument".to_string(),
            }));
        }
        let value = self.compile_expr(&args[0])?;
        let tmp = self.tmp();
        self.body
            .push(format!("  {tmp} = call i64 @abs(i64 {})", value.repr));
        Ok(LlValue {
            ty: LlType::I64,
            repr: tmp,
            owned: false,
        })
    }

    fn compile_sqrt(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys sqrt(...) expects 1 argument".to_string(),
            }));
        }
        Err(MireError::new(ErrorKind::Backend {
            message: "Avenys does not yet lower sqrt(...) safely".to_string(),
        }))
    }

    fn compile_pow(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys pow(...) expects 2 arguments".to_string(),
            }));
        }
        let base = self.compile_expr(&args[0])?;
        let exp = self.compile_expr(&args[1])?;
        let tmp = self.tmp();
        self.body.push(format!(
            "  {tmp} = call i64 @pow(i64 {}, i64 {})",
            base.repr, exp.repr
        ));
        Ok(LlValue {
            ty: LlType::I64,
            repr: tmp,
            owned: false,
        })
    }

    fn compile_floor(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys floor(...) expects 1 argument".to_string(),
            }));
        }
        self.compile_expr(&args[0])
    }

    fn compile_ceil(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys ceil(...) expects 1 argument".to_string(),
            }));
        }
        self.compile_expr(&args[0])
    }

    fn compile_round(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys round(...) expects 1 argument".to_string(),
            }));
        }
        self.compile_expr(&args[0])
    }

    fn compile_min(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys min(...) expects 2 arguments".to_string(),
            }));
        }
        let lhs = self.compile_expr(&args[0])?;
        let rhs = self.compile_expr(&args[1])?;
        let tmp = self.tmp();
        self.body.push(format!(
            "  {tmp} = call i64 @llvm.smin.i64(i64 {}, i64 {})",
            lhs.repr, rhs.repr
        ));
        Ok(LlValue {
            ty: LlType::I64,
            repr: tmp,
            owned: false,
        })
    }

    fn compile_max(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys max(...) expects 2 arguments".to_string(),
            }));
        }
        let lhs = self.compile_expr(&args[0])?;
        let rhs = self.compile_expr(&args[1])?;
        let tmp = self.tmp();
        self.body.push(format!(
            "  {tmp} = call i64 @llvm.smax.i64(i64 {}, i64 {})",
            lhs.repr, rhs.repr
        ));
        Ok(LlValue {
            ty: LlType::I64,
            repr: tmp,
            owned: false,
        })
    }

    fn compile_range(&mut self, _args: &[Expression]) -> Result<LlValue> {
        Err(MireError::new(ErrorKind::Backend {
            message: "Avenys does not yet lower range(...) as a first-class value safely"
                .to_string(),
        }))
    }

    fn compile_sleep(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys sleep(...) expects 1 argument".to_string(),
            }));
        }
        let ms = self.compile_expr(&args[0])?;
        self.body
            .push(format!("  call void @usleep(i64 {})", ms.repr));
        Ok(LlValue {
            ty: LlType::I64,
            repr: "0".to_string(),
            owned: false,
        })
    }

    fn compile_exit(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys exit(...) expects 1 argument".to_string(),
            }));
        }
        let code = self.compile_expr(&args[0])?;
        self.body.push(format!("  ret i32 {}", code.repr));
        Ok(LlValue {
            ty: LlType::I64,
            repr: code.repr,
            owned: false,
        })
    }

    fn compile_time_mark(&mut self, _args: &[Expression]) -> Result<LlValue> {
        let tmp = self.tmp();
        self.body
            .push(format!("  {tmp} = call i64 @mire_wall_mark_ns()"));
        Ok(LlValue {
            ty: LlType::I64,
            repr: tmp,
            owned: false,
        })
    }

    fn compile_time_elapsed_ms(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys time.elapsed_ms expects 1 argument".to_string(),
            }));
        }
        let start = self.compile_expr(&args[0])?;
        let diff = self.tmp();
        self.body.push(format!(
            "  {diff} = call ptr @mire_wall_elapsed_ms_str(i64 {})",
            start.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: diff,
            owned: true,
        })
    }

    fn compile_cpu_mark(&mut self, _args: &[Expression]) -> Result<LlValue> {
        let result = self.tmp();
        self.body
            .push(format!("  {result} = call i64 @mire_cpu_mark_ns()"));
        Ok(LlValue {
            ty: LlType::I64,
            repr: result,
            owned: false,
        })
    }

    fn compile_cpu_elapsed_ms(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cpu.elapsed_ms expects 1 argument".to_string(),
            }));
        }
        let start = self.compile_expr(&args[0])?;
        let diff = self.tmp();
        self.body.push(format!(
            "  {diff} = call ptr @mire_cpu_elapsed_ms_str(i64 {})",
            start.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: diff,
            owned: true,
        })
    }

    fn compile_cpu_cycles_est(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cpu.cycles_est expects 1 argument".to_string(),
            }));
        }
        let start = self.compile_expr(&args[0])?;
        let diff = self.tmp();
        self.body.push(format!(
            "  {diff} = call i64 @mire_cpu_cycles_est(i64 {})",
            start.repr
        ));
        Ok(LlValue {
            ty: LlType::I64,
            repr: diff,
            owned: false,
        })
    }

    fn compile_gpu_snapshot(&mut self, _args: &[Expression]) -> Result<LlValue> {
        let result = self.tmp();
        self.body
            .push(format!("  {result} = call ptr @mire_gpu_snapshot()"));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_mem_format(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys mem.format expects 1 argument".to_string(),
            }));
        }
        let value_expr = self.compile_expr(&args[0])?;
        let value = self.cast_to_i64(value_expr)?;
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_mem_format(i64 {})",
            value.repr
        ));
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_mem_process(&mut self, _args: &[Expression]) -> Result<LlValue> {
        let result = self.tmp();
        self.body
            .push(format!("  {result} = call i64 @mire_mem_process_bytes()"));
        Ok(LlValue {
            ty: LlType::I64,
            repr: result,
            owned: false,
        })
    }

    fn compile_lists_push(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.push expects 2 arguments".to_string(),
            }));
        }

        let list = self.compile_expr(&args[0])?;
        let value = self.compile_expr(&args[1])?;
        let list_type = self.expression_data_type(&args[0]);
        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            _ => DataType::I64,
        };
        let result = self.tmp();
        if value.ty == LlType::Ptr {
            self.body.push(format!(
                "  {result} = call ptr @mire_list_push_ptr(ptr {}, ptr {})",
                list.repr, value.repr
            ));
        } else {
            let value = self.cast_to_i64(value)?;
            let elem_size = self.element_size(&elem_type);
            if elem_size == 8 {
                self.body.push(format!(
                    "  {result} = call ptr @mire_list_push_i64(ptr {}, i64 {})",
                    list.repr, value.repr
                ));
            } else {
                self.body.push(format!(
                    "  {result} = call ptr @mire_list_push_scalar(ptr {}, i64 {}, i64 {})",
                    list.repr, value.repr, elem_size
                ));
            }
        }

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: false,
        })
    }

    fn compile_lists_fold(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.fold expects 3 arguments (initial, fn, list)".to_string(),
            }));
        }

        let initial = self.compile_expr(&args[0])?;
        let list = self.compile_expr(&args[2])?;
        let acc_type = self.expression_data_type(&args[0]);
        let list_type = self.expression_data_type(&args[2]);

        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            other => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Avenys lists.fold expects vec/arr/slice input, got {:?}",
                        other
                    ),
                }));
            }
        };
        let Expression::Closure {
            params,
            body,
            return_type,
            ..
        } = &args[1]
        else {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.fold expects a closure as second argument".to_string(),
            }));
        };
        if params.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.fold closure must have exactly 2 parameters".to_string(),
            }));
        }

        let acc_ty = self.map_type(&acc_type)?;
        let result_ptr = self.tmp();
        let index_ptr = self.tmp();
        self.entry_allocas.push(format!(
            "  {result_ptr} = alloca {}",
            self.ty(acc_ty.clone())
        ));
        self.entry_allocas
            .push(format!("  {index_ptr} = alloca i64"));
        self.store_casted(&result_ptr, acc_ty, initial)?;
        self.body.push(format!("  store i64 0, ptr {index_ptr}"));

        let is_null = self.tmp();
        let null_label = self.label("fold_null");
        let loop_cond_label = self.label("fold_cond");
        let loop_body_label = self.label("fold_body");
        let end_label = self.label("fold_end");
        self.body
            .push(format!("  {is_null} = icmp eq ptr {}, null", list.repr));
        self.body.push(format!(
            "  br i1 {is_null}, label %{null_label}, label %{loop_cond_label}"
        ));

        self.body.push(format!("{null_label}:"));
        self.body.push(format!("  br label %{end_label}"));

        let len = self.tmp();
        let index = self.tmp();
        let has_more = self.tmp();
        self.body.push(format!("{loop_cond_label}:"));
        self.body
            .push(format!("  {len} = load i64, ptr {}", list.repr));
        self.body
            .push(format!("  {index} = load i64, ptr {index_ptr}"));
        self.body
            .push(format!("  {has_more} = icmp slt i64 {index}, {len}"));
        self.body.push(format!(
            "  br i1 {has_more}, label %{loop_body_label}, label %{end_label}"
        ));

        self.body.push(format!("{loop_body_label}:"));
        let next_index = self.tmp();
        let elem = self.load_list_element_unchecked(&list.repr, &index, &elem_type)?;
        let current_acc = self.load_slot_value(&result_ptr, &acc_type)?;
        let next_acc =
            self.compile_bound_closure(params, &[current_acc, elem], body, return_type)?;
        self.store_casted(&result_ptr, self.map_type(&acc_type)?, next_acc)?;
        self.body
            .push(format!("  {next_index} = add i64 {index}, 1"));
        self.body
            .push(format!("  store i64 {next_index}, ptr {index_ptr}"));
        self.body.push(format!("  br label %{loop_cond_label}"));

        self.body.push(format!("{end_label}:"));
        self.load_slot_value(&result_ptr, &acc_type)
    }

    fn compile_lists_map(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.map expects 2 arguments (fn, list)".to_string(),
            }));
        }

        let list = self.compile_expr(&args[1])?;
        let list_type = self.expression_data_type(&args[1]);

        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            other => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Avenys lists.map expects vec/arr/slice input, got {:?}",
                        other
                    ),
                }));
            }
        };
        let Expression::Closure {
            params,
            body,
            return_type,
            ..
        } = &args[0]
        else {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.map expects a closure as first argument".to_string(),
            }));
        };
        if params.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.map closure must have exactly 1 parameter".to_string(),
            }));
        }
        let mapped_type = if *return_type == DataType::Unknown {
            params[0].1.clone()
        } else {
            return_type.clone()
        };

        let result_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {result_ptr} = alloca ptr"));
        let initial_result = self.tmp();
        self.body.push(format!(
            "  {initial_result} = call ptr @mire_list_create(i64 4, i64 {})",
            self.element_size(&mapped_type)
        ));
        self.body
            .push(format!("  store ptr {initial_result}, ptr {result_ptr}"));

        let len = self.tmp();
        let index_ptr = self.tmp();
        let is_null = self.tmp();
        self.entry_allocas
            .push(format!("  {index_ptr} = alloca i64"));
        self.body.push(format!("  store i64 0, ptr {index_ptr}"));

        self.body
            .push(format!("  {is_null} = icmp eq ptr {}, null", list.repr));
        let null_label = self.label("map_null");
        let loop_cond_label = self.label("map_cond");
        let loop_body_label = self.label("map_body");
        let end_label = self.label("map_end");
        self.body.push(format!(
            "  br i1 {is_null}, label %{null_label}, label %{loop_cond_label}"
        ));

        self.body.push(format!("{null_label}:"));
        self.body.push(format!("  br label %{end_label}"));

        let index = self.tmp();
        let has_more = self.tmp();
        self.body.push(format!("{loop_cond_label}:"));
        self.body
            .push(format!("  {len} = load i64, ptr {}", list.repr));
        self.body
            .push(format!("  {index} = load i64, ptr {index_ptr}"));
        self.body
            .push(format!("  {has_more} = icmp slt i64 {index}, {len}"));
        self.body.push(format!(
            "  br i1 {has_more}, label %{loop_body_label}, label %{end_label}"
        ));

        self.body.push(format!("{loop_body_label}:"));
        let next_index = self.tmp();
        let elem = self.load_list_element_unchecked(&list.repr, &index, &elem_type)?;
        let mapped = self.compile_bound_closure(params, &[elem], body, return_type)?;
        let current_result = self.tmp();
        self.body
            .push(format!("  {current_result} = load ptr, ptr {result_ptr}"));
        let updated = self.push_list_value(
            LlValue {
                ty: LlType::Ptr,
                repr: current_result,
                owned: true,
            },
            mapped,
            &mapped_type,
        )?;
        self.body
            .push(format!("  store ptr {}, ptr {result_ptr}", updated.repr));

        self.body
            .push(format!("  {next_index} = add i64 {index}, 1"));
        self.body
            .push(format!("  store i64 {next_index}, ptr {index_ptr}"));
        self.body.push(format!("  br label %{loop_cond_label}"));

        self.body.push(format!("{end_label}:"));
        let final_result = self.tmp();
        self.body
            .push(format!("  {final_result} = load ptr, ptr {result_ptr}"));

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: final_result,
            owned: true,
        })
    }

    fn compile_lists_filter(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.filter expects 2 arguments (fn, list)".to_string(),
            }));
        }

        let list = self.compile_expr(&args[1])?;
        let list_type = self.expression_data_type(&args[1]);

        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            other => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Avenys lists.filter expects vec/arr/slice input, got {:?}",
                        other
                    ),
                }));
            }
        };
        let Expression::Closure {
            params,
            body,
            return_type,
            ..
        } = &args[0]
        else {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.filter expects a closure as first argument".to_string(),
            }));
        };
        if params.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.filter closure must have exactly 1 parameter".to_string(),
            }));
        }

        let result_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {result_ptr} = alloca ptr"));
        let initial_result = self.tmp();
        self.body.push(format!(
            "  {initial_result} = call ptr @mire_list_create(i64 4, i64 {})",
            self.element_size(&elem_type)
        ));
        self.body
            .push(format!("  store ptr {initial_result}, ptr {result_ptr}"));

        let len = self.tmp();
        let index_ptr = self.tmp();
        let is_null = self.tmp();
        self.entry_allocas
            .push(format!("  {index_ptr} = alloca i64"));
        self.body.push(format!("  store i64 0, ptr {index_ptr}"));

        self.body
            .push(format!("  {is_null} = icmp eq ptr {}, null", list.repr));
        let null_label = self.label("filter_null");
        let loop_cond_label = self.label("filter_cond");
        let loop_body_label = self.label("filter_body");
        let end_label = self.label("filter_end");
        self.body.push(format!(
            "  br i1 {is_null}, label %{null_label}, label %{loop_cond_label}"
        ));

        self.body.push(format!("{null_label}:"));
        self.body.push(format!("  br label %{end_label}"));

        let index = self.tmp();
        let has_more = self.tmp();
        self.body.push(format!("{loop_cond_label}:"));
        self.body
            .push(format!("  {len} = load i64, ptr {}", list.repr));
        self.body
            .push(format!("  {index} = load i64, ptr {index_ptr}"));
        self.body
            .push(format!("  {has_more} = icmp slt i64 {index}, {len}"));
        self.body.push(format!(
            "  br i1 {has_more}, label %{loop_body_label}, label %{end_label}"
        ));

        self.body.push(format!("{loop_body_label}:"));
        let next_index = self.tmp();
        let elem = self.load_list_element_unchecked(&list.repr, &index, &elem_type)?;
        let keep =
            self.compile_bound_closure(params, std::slice::from_ref(&elem), body, return_type)?;
        let keep = self.cast_to_i1(keep)?;

        let new_list = self.tmp();
        let cond_filter = self.label("filter_conditional");
        let after_filter = self.label("filter_after");
        self.body.push(format!(
            "  br i1 {}, label %{cond_filter}, label %{after_filter}",
            keep.repr
        ));

        self.body.push(format!("{cond_filter}:"));
        let current_result = self.tmp();
        self.body
            .push(format!("  {current_result} = load ptr, ptr {result_ptr}"));
        let updated = self.push_list_value(
            LlValue {
                ty: LlType::Ptr,
                repr: current_result,
                owned: true,
            },
            elem,
            &elem_type,
        )?;
        self.body
            .push(format!("  store ptr {}, ptr {result_ptr}", updated.repr));
        self.body.push(format!(
            "  {new_list} = ptrtoint ptr {} to i64",
            updated.repr
        ));
        self.body.push(format!("  br label %{after_filter}"));

        self.body.push(format!("{after_filter}:"));
        self.body
            .push(format!("  {next_index} = add i64 {index}, 1"));
        self.body
            .push(format!("  store i64 {next_index}, ptr {index_ptr}"));
        self.body.push(format!("  br label %{loop_cond_label}"));

        self.body.push(format!("{end_label}:"));
        let final_result = self.tmp();
        self.body
            .push(format!("  {final_result} = load ptr, ptr {result_ptr}"));

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: final_result,
            owned: true,
        })
    }

    fn compile_lists_slice(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys lists.slice expects 3 arguments".to_string(),
            }));
        }

        let list = self.compile_expr(&args[0])?;
        let start = self.compile_expr(&args[1])?;
        let end = self.compile_expr(&args[2])?;

        let start_i64 = self.cast_to_i64(start)?;
        let end_i64 = self.cast_to_i64(end)?;

        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_list_slice(ptr {}, i64 {}, i64 {})",
            list.repr, start_i64.repr, end_i64.repr
        ));

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        })
    }

    fn compile_struct_constructor(
        &mut self,
        type_name: &str,
        args: &[Expression],
    ) -> Result<LlValue> {
        let struct_info = self.user_structs.get(type_name).cloned().ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Unknown struct '{}'", type_name),
            })
        })?;

        let ptr = self.tmp();
        self.body.push(format!(
            "  {ptr} = call ptr @malloc(i64 {})",
            struct_info.fields.len() * 8
        ));

        let struct_ty = self.render_struct_ty(&struct_info.fields);

        for arg in args {
            if let Expression::NamedArg { name, value, .. } = arg
                && let Some(field_index) = struct_info.field_indices.get(name)
            {
                let field_value = self.compile_expr(value)?;
                let field_ptr = self.tmp();
                self.body.push(format!(
                    "  {field_ptr} = getelementptr inbounds {}, ptr {ptr}, i32 0, i32 {}",
                    struct_ty, field_index
                ));

                let field_type = struct_info
                    .fields
                    .get(*field_index)
                    .cloned()
                    .unwrap_or(LlType::I64);
                match field_type {
                    LlType::I64 => {
                        let casted = self.cast_to_i64(field_value)?;
                        self.body
                            .push(format!("  store i64 {}, ptr {field_ptr}", casted.repr));
                    }
                    LlType::I1 => {
                        let casted = self.cast_to_i1(field_value)?;
                        self.body
                            .push(format!("  store i1 {}, ptr {field_ptr}", casted.repr));
                    }
                    LlType::F64 => {
                        self.body.push(format!(
                            "  store double {}, ptr {field_ptr}",
                            field_value.repr
                        ));
                    }
                    LlType::Ptr => {
                        self.body
                            .push(format!("  store ptr {}, ptr {field_ptr}", field_value.repr));
                    }
                }
            }
        }

        Ok(LlValue {
            ty: LlType::Ptr,
            repr: ptr,
            owned: true,
        })
    }

    fn compile_len(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys len(...) expects exactly 1 argument".to_string(),
            }));
        }
        let value = self.compile_expr(&args[0])?;
        let data_type = match &args[0] {
            Expression::Identifier(identifier) => &identifier.data_type,
            Expression::BinaryOp { data_type, .. }
            | Expression::UnaryOp { data_type, .. }
            | Expression::NamedArg { data_type, .. }
            | Expression::Call { data_type, .. }
            | Expression::List { data_type, .. }
            | Expression::Dict { data_type, .. }
            | Expression::Tuple { data_type, .. }
            | Expression::Index { data_type, .. }
            | Expression::MemberAccess { data_type, .. }
            | Expression::Reference { data_type, .. }
            | Expression::Dereference { data_type, .. }
            | Expression::Box { data_type, .. }
            | Expression::Pipeline { data_type, .. }
            | Expression::Match { data_type, .. }
            | Expression::EnumVariantPath { data_type, .. }
            | Expression::EnumVariant { data_type, .. } => data_type,
            Expression::Literal(Literal::Str(_)) => &DataType::Str,
            Expression::Literal(Literal::List(_)) => &DataType::List,
            Expression::Literal(_) => &DataType::Unknown,
            Expression::Closure { return_type, .. } => return_type,
        };

        match data_type {
            DataType::Str => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = call i64 @strlen(ptr {})", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: tmp,
                    owned: false,
                })
            }
            DataType::List | DataType::Vector { .. } => self.compile_list_len(args),
            _ => match value.ty {
                LlType::Ptr => self.compile_list_len(args),
                LlType::I64 | LlType::I1 | LlType::F64 => Ok(LlValue {
                    ty: LlType::I64,
                    repr: "0".to_string(),
                    owned: false,
                }),
            },
        }
    }

    fn compile_math_sum(&mut self, args: &[Expression]) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys math.sum expects 1 argument".to_string(),
            }));
        }

        let list = self.compile_expr(&args[0])?;
        let list_type = self.expression_data_type(&args[0]);
        let elem_type = match &list_type {
            DataType::Vector { element_type, .. } => *element_type.clone(),
            DataType::Array { element_type, .. } => *element_type.clone(),
            DataType::Slice { element_type } => *element_type.clone(),
            _ => DataType::I64,
        };
        let elem_size = self.element_size(&elem_type);
        let result_ptr = self.tmp();
        let index_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {result_ptr} = alloca i64"));
        self.entry_allocas
            .push(format!("  {index_ptr} = alloca i64"));
        self.body.push(format!("  store i64 0, ptr {result_ptr}"));
        self.body.push(format!("  store i64 0, ptr {index_ptr}"));

        let is_null = self.tmp();
        let null_label = self.label("math_sum_null");
        let loop_cond_label = self.label("math_sum_cond");
        let loop_body_label = self.label("math_sum_body");
        let end_label = self.label("math_sum_end");
        self.body
            .push(format!("  {is_null} = icmp eq ptr {}, null", list.repr));
        self.body.push(format!(
            "  br i1 {is_null}, label %{null_label}, label %{loop_cond_label}"
        ));

        self.body.push(format!("{null_label}:"));
        self.body.push(format!("  br label %{end_label}"));

        let len = self.tmp();
        let index = self.tmp();
        let has_more = self.tmp();
        self.body.push(format!("{loop_cond_label}:"));
        self.body
            .push(format!("  {len} = load i64, ptr {}", list.repr));
        self.body
            .push(format!("  {index} = load i64, ptr {index_ptr}"));
        self.body
            .push(format!("  {has_more} = icmp slt i64 {index}, {len}"));
        self.body.push(format!(
            "  br i1 {has_more}, label %{loop_body_label}, label %{end_label}"
        ));

        self.body.push(format!("{loop_body_label}:"));
        let data_ptr = self.tmp();
        let offset = self.tmp();
        let elem_ptr = self.tmp();
        let elem = self.tmp();
        let current_sum = self.tmp();
        let next_sum = self.tmp();
        let next_index = self.tmp();
        self.body.push(format!(
            "  {data_ptr} = getelementptr i8, ptr {}, i64 8",
            list.repr
        ));
        self.body
            .push(format!("  {offset} = mul i64 {index}, {}", elem_size));
        self.body.push(format!(
            "  {elem_ptr} = getelementptr i8, ptr {data_ptr}, i64 {offset}"
        ));
        match self.scalar_storage_ir_type(&elem_type) {
            "i8" => {
                let raw = self.tmp();
                let ext = if matches!(elem_type, DataType::U8) {
                    "zext"
                } else {
                    "sext"
                };
                self.body.push(format!("  {raw} = load i8, ptr {elem_ptr}"));
                self.body.push(format!("  {elem} = {ext} i8 {raw} to i64"));
            }
            "i16" => {
                let raw = self.tmp();
                let ext = if matches!(elem_type, DataType::U16) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {raw} = load i16, ptr {elem_ptr}"));
                self.body.push(format!("  {elem} = {ext} i16 {raw} to i64"));
            }
            "i32" => {
                let raw = self.tmp();
                let ext = if matches!(elem_type, DataType::U32) {
                    "zext"
                } else {
                    "sext"
                };
                self.body
                    .push(format!("  {raw} = load i32, ptr {elem_ptr}"));
                self.body.push(format!("  {elem} = {ext} i32 {raw} to i64"));
            }
            _ => {
                self.body
                    .push(format!("  {elem} = load i64, ptr {elem_ptr}"));
            }
        }
        self.body
            .push(format!("  {current_sum} = load i64, ptr {result_ptr}"));
        self.body
            .push(format!("  {next_sum} = add i64 {current_sum}, {elem}"));
        self.body
            .push(format!("  store i64 {next_sum}, ptr {result_ptr}"));
        self.body
            .push(format!("  {next_index} = add i64 {index}, 1"));
        self.body
            .push(format!("  store i64 {next_index}, ptr {index_ptr}"));
        self.body.push(format!("  br label %{loop_cond_label}"));

        self.body.push(format!("{end_label}:"));
        let result = self.tmp();
        self.body
            .push(format!("  {result} = load i64, ptr {result_ptr}"));
        Ok(LlValue {
            ty: LlType::I64,
            repr: result,
            owned: false,
        })
    }

    fn compile_if_expr(&mut self, args: &[Expression], data_type: &DataType) -> Result<LlValue> {
        if args.len() != 3 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys __if_expr expects 3 arguments".to_string(),
            }));
        }
        let then_expr = self.closure_return_expr(&args[1], "__if_expr then")?;
        let else_expr = self.closure_return_expr(&args[2], "__if_expr else")?;
        let result_ty = self.map_type(data_type)?;
        let result_ptr = self.tmp();
        let result_ty_clone = result_ty.clone();
        self.entry_allocas.push(format!(
            "  {result_ptr} = alloca {}",
            self.ty(result_ty_clone)
        ));

        let then_label = self.label("ifexpr_then");
        let else_label = self.label("ifexpr_else");
        let end_label = self.label("ifexpr_end");
        let cond_val = self.compile_expr(&args[0])?;
        let cond = self.cast_to_i1(cond_val)?;
        self.body.push(format!(
            "  br i1 {}, label %{then_label}, label %{else_label}",
            cond.repr
        ));

        self.body.push(format!("{then_label}:"));
        let then_value = self.compile_expr(then_expr)?;
        self.store_casted(&result_ptr, result_ty.clone(), then_value)?;
        self.body.push(format!("  br label %{end_label}"));

        self.body.push(format!("{else_label}:"));
        let else_value = self.compile_expr(else_expr)?;
        self.store_casted(&result_ptr, result_ty.clone(), else_value)?;
        self.body.push(format!("  br label %{end_label}"));

        self.body.push(format!("{end_label}:"));
        let loaded = self.tmp();
        self.body.push(format!(
            "  {loaded} = load {}, ptr {}",
            self.ty(result_ty.clone()),
            result_ptr
        ));
        Ok(LlValue {
            ty: result_ty,
            repr: loaded,
            owned: false,
        })
    }

    fn compile_match_statement(
        &mut self,
        value: &Expression,
        cases: &[(Expression, Vec<Statement>)],
        default: &[Statement],
    ) -> Result<()> {
        let match_value = self.compile_expr(value)?;
        let end_label = self.label("match_end");
        let default_label = self.label("match_default");
        let mut next_label = None;

        for (index, (pattern, body)) in cases.iter().enumerate() {
            let check_label = next_label
                .take()
                .unwrap_or_else(|| self.label("match_check"));
            let body_label = self.label(&format!("match_body_{index}"));
            let fallthrough_label = if index + 1 == cases.len() {
                default_label.clone()
            } else {
                self.label(&format!("match_next_{index}"))
            };

            if index > 0 {
                self.body.push(format!("{check_label}:"));
            }

            let cond = self.compile_match_case_condition(&match_value, pattern)?;
            self.body.push(format!(
                "  br i1 {}, label %{body_label}, label %{fallthrough_label}",
                cond.repr
            ));

            self.body.push(format!("{body_label}:"));
            let previous_binding = self.bind_match_pattern_payloads(&match_value, pattern)?;
            for stmt in body {
                self.compile_statement(stmt)?;
            }
            self.restore_match_pattern_payloads(previous_binding);
            self.body.push(format!("  br label %{end_label}"));
            next_label = Some(fallthrough_label);
        }

        let default_entry = next_label.unwrap_or(default_label.clone());
        self.body.push(format!("{default_entry}:"));
        for stmt in default {
            self.compile_statement(stmt)?;
        }
        self.body.push(format!("  br label %{end_label}"));
        self.body.push(format!("{end_label}:"));
        Ok(())
    }

    fn compile_match_expr(
        &mut self,
        value: &Expression,
        cases: &[(Expression, Expression)],
        default: &Expression,
        data_type: &DataType,
    ) -> Result<LlValue> {
        let match_value = self.compile_expr(value)?;
        let result_ty = self.map_type(data_type)?;
        let result_ptr = self.tmp();
        self.entry_allocas.push(format!(
            "  {result_ptr} = alloca {}",
            self.ty(result_ty.clone())
        ));

        let end_label = self.label("match_expr_end");
        let default_label = self.label("match_expr_default");
        let mut next_label = None;

        for (index, (pattern, result_expr)) in cases.iter().enumerate() {
            let check_label = next_label
                .take()
                .unwrap_or_else(|| self.label("match_expr_check"));
            let body_label = self.label(&format!("match_expr_body_{index}"));
            let fallthrough_label = if index + 1 == cases.len() {
                default_label.clone()
            } else {
                self.label(&format!("match_expr_next_{index}"))
            };

            if index > 0 {
                self.body.push(format!("{check_label}:"));
            }

            let cond = self.compile_match_case_condition(&match_value, pattern)?;
            self.body.push(format!(
                "  br i1 {}, label %{body_label}, label %{fallthrough_label}",
                cond.repr
            ));

            self.body.push(format!("{body_label}:"));
            let previous_binding = self.bind_match_pattern_payloads(&match_value, pattern)?;
            let body_value = self.compile_expr(result_expr)?;
            self.restore_match_pattern_payloads(previous_binding);
            self.store_casted(&result_ptr, result_ty.clone(), body_value)?;
            self.body.push(format!("  br label %{end_label}"));
            next_label = Some(fallthrough_label);
        }

        let default_entry = next_label.unwrap_or(default_label.clone());
        self.body.push(format!("{default_entry}:"));

        // Handle default case - if it's a wildcard _, use a default value
        // Also handle implicit None placeholder (when no default arm is provided)
        let is_implicit_none = matches!(default, Expression::Literal(Literal::None));
        if is_implicit_none {
            // No explicit default - use type's default value
            let default_val = self.default_value(result_ty.clone());
            self.store_casted(&result_ptr, result_ty.clone(), default_val)?;
        } else if let Expression::Identifier(ident) = default {
            if ident.name == "_" {
                // Default case - just set result to 0 or default for the type
                let default_val = self.default_value(result_ty.clone());
                self.store_casted(&result_ptr, result_ty.clone(), default_val)?;
            } else {
                let default_value = self.compile_expr(default)?;
                self.store_casted(&result_ptr, result_ty.clone(), default_value)?;
            }
        } else {
            let default_value = self.compile_expr(default)?;
            self.store_casted(&result_ptr, result_ty.clone(), default_value)?;
        }
        self.body.push(format!("  br label %{end_label}"));

        self.body.push(format!("{end_label}:"));
        let loaded = self.tmp();
        self.body.push(format!(
            "  {loaded} = load {}, ptr {}",
            self.ty(result_ty.clone()),
            result_ptr
        ));
        Ok(LlValue {
            ty: result_ty,
            repr: loaded,
            owned: false,
        })
    }

    fn compile_match_case_condition(
        &mut self,
        value: &LlValue,
        pattern: &Expression,
    ) -> Result<LlValue> {
        // Handle wildcard pattern - always matches (true)
        if let Expression::Identifier(ident) = pattern
            && ident.name == "_"
        {
            let result = self.tmp();
            self.body.push(format!("  {result} = add i1 0, 1"));
            return Ok(LlValue {
                ty: LlType::I1,
                repr: result,
                owned: false,
            });
        }

        // Handle enum variant patterns (Status.Ok or Result.Ok(value))
        if let Expression::EnumVariantPath {
            enum_name,
            variant_name,
            ..
        } = pattern
            && value.ty == LlType::Ptr
        {
            let (enum_ty, tag) = {
                let (enum_info, variant) = self.lookup_enum_variant(enum_name, variant_name)?;
                (enum_info.llvm_type.clone(), variant.tag)
            };
            let tag_ptr = self.tmp();
            self.body.push(format!(
                "  {tag_ptr} = getelementptr inbounds {}, ptr {}, i32 0, i32 0",
                enum_ty, value.repr
            ));
            let loaded_tag = self.tmp();
            self.body
                .push(format!("  {loaded_tag} = load i32, ptr {tag_ptr}"));
            let result = self.tmp();
            self.body
                .push(format!("  {result} = icmp eq i32 {loaded_tag}, {}", tag));
            return Ok(LlValue {
                ty: LlType::I1,
                repr: result,
                owned: false,
            });
        }

        // Handle enum variant with payloads: Ok(value) / Pair(a b) in match pattern
        if let Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads: _,
            ..
        } = pattern
            && value.ty == LlType::Ptr
        {
            let (enum_ty, tag) = {
                let (enum_info, variant) = self.lookup_enum_variant(enum_name, variant_name)?;
                (enum_info.llvm_type.clone(), variant.tag)
            };
            let tag_ptr = self.tmp();
            self.body.push(format!(
                "  {tag_ptr} = getelementptr inbounds {}, ptr {}, i32 0, i32 0",
                enum_ty, value.repr
            ));
            let loaded_tag = self.tmp();
            self.body
                .push(format!("  {loaded_tag} = load i32, ptr {tag_ptr}"));
            let result = self.tmp();
            self.body
                .push(format!("  {result} = icmp eq i32 {loaded_tag}, {}", tag));

            return Ok(LlValue {
                ty: LlType::I1,
                repr: result,
                owned: false,
            });
        }

        let pattern_value = self.compile_expr(pattern)?;
        let result = self.tmp();

        match (&value.ty, &pattern_value.ty) {
            (LlType::Ptr, LlType::Ptr) => {
                let cmp_value = self.tmp();
                self.body.push(format!(
                    "  {cmp_value} = call i32 @strcmp(ptr {}, ptr {})",
                    value.repr, pattern_value.repr
                ));
                self.body
                    .push(format!("  {result} = icmp eq i32 {cmp_value}, 0"));
            }
            (LlType::I1, LlType::I1) => {
                self.body.push(format!(
                    "  {result} = icmp eq i1 {}, {}",
                    value.repr, pattern_value.repr
                ));
            }
            (LlType::I64, LlType::I64) => {
                self.body.push(format!(
                    "  {result} = icmp eq i64 {}, {}",
                    value.repr, pattern_value.repr
                ));
            }
            (LlType::I1, LlType::I64)
            | (LlType::I64, LlType::I1)
            | (LlType::I64, LlType::Ptr)
            | (LlType::Ptr, LlType::I64) => {
                let lhs = self.cast_to_i64(value.clone())?;
                let rhs = self.cast_to_i64(pattern_value)?;
                self.body.push(format!(
                    "  {result} = icmp eq i64 {}, {}",
                    lhs.repr, rhs.repr
                ));
            }
            _ => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Avenys does not yet compare match values of type {:?} against {:?}",
                        value.ty, pattern_value.ty
                    ),
                }));
            }
        }

        Ok(LlValue {
            ty: LlType::I1,
            repr: result,
            owned: false,
        })
    }

    fn bind_match_pattern_payloads(
        &mut self,
        value: &LlValue,
        pattern: &Expression,
    ) -> Result<Vec<(String, Option<VarInfo>)>> {
        let Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads,
            ..
        } = pattern
        else {
            return Ok(Vec::new());
        };

        if value.ty != LlType::Ptr {
            return Ok(Vec::new());
        }

        let (enum_ty, variant_payload_types) = {
            let (enum_info, variant) = self.lookup_enum_variant(enum_name, variant_name)?;
            (enum_info.llvm_type.clone(), variant.payload_types.clone())
        };

        if variant_payload_types.is_empty() {
            return Ok(Vec::new());
        }

        let mut previous = Vec::new();
        for (index, payload) in payloads.iter().enumerate() {
            let Expression::Identifier(id) = payload else {
                continue;
            };

            let payload_ty = variant_payload_types
                .get(index)
                .cloned()
                .unwrap_or(LlType::I64);
            let payload_data_type = self.expression_data_type(payload);
            let payload_ptr = self.tmp();
            self.entry_allocas.push(format!(
                "  {payload_ptr} = alloca {}",
                self.ty(payload_ty.clone())
            ));
            let payload_gep = self.tmp();
            self.body.push(format!(
                "  {payload_gep} = getelementptr inbounds {}, ptr {}, i32 0, i32 1, i32 {}",
                enum_ty, value.repr, index
            ));
            let payload_raw = self.tmp();
            self.body
                .push(format!("  {payload_raw} = load i64, ptr {payload_gep}"));
            let payload_value = self.cast_enum_payload_value(payload_raw, payload_ty.clone())?;
            self.store_casted(&payload_ptr, payload_ty.clone(), payload_value)?;

            previous.push((
                id.name.clone(),
                self.vars.insert(
                    id.name.clone(),
                    VarInfo {
                        ptr: payload_ptr,
                        ty: payload_ty,
                        data_type: payload_data_type,
                        owns_heap_string: false,
                        struct_name: None,
                    },
                ),
            ));
        }

        Ok(previous)
    }

    fn restore_match_pattern_payloads(&mut self, previous: Vec<(String, Option<VarInfo>)>) {
        for (name, prior) in previous {
            if let Some(prior) = prior {
                self.vars.insert(name, prior);
            } else {
                self.vars.remove(&name);
            }
        }
    }

    fn lookup_enum_variant<'a>(
        &'a self,
        enum_name: &str,
        variant_name: &str,
    ) -> Result<(&'a EnumInfo, &'a VariantInfo)> {
        let enum_info = self.user_enums.get(enum_name).ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Unknown enum '{}'", enum_name),
            })
        })?;
        let variant = enum_info.variants.get(variant_name).ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Enum '{}' has no variant '{}'", enum_name, variant_name),
            })
        })?;
        Ok((enum_info, variant))
    }

    fn cast_enum_payload_value(&mut self, raw_value: String, target_ty: LlType) -> Result<LlValue> {
        match target_ty {
            LlType::I64 => Ok(LlValue {
                ty: LlType::I64,
                repr: raw_value,
                owned: false,
            }),
            LlType::I1 => {
                let bool_value = self.tmp();
                self.body
                    .push(format!("  {bool_value} = icmp ne i64 {raw_value}, 0"));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: bool_value,
                    owned: false,
                })
            }
            LlType::F64 => Ok(LlValue {
                ty: LlType::F64,
                repr: raw_value,
                owned: false,
            }),
            LlType::Ptr => {
                let ptr_value = self.tmp();
                self.body
                    .push(format!("  {ptr_value} = inttoptr i64 {raw_value} to ptr"));
                Ok(LlValue {
                    ty: LlType::Ptr,
                    repr: ptr_value,
                    owned: false,
                })
            }
        }
    }

    fn emit_nonzero_check(&mut self, value_repr: &str, message: &str) {
        let cond = self.tmp();
        self.body
            .push(format!("  {cond} = icmp ne i64 {value_repr}, 0"));
        self.emit_runtime_guard(cond, message);
    }

    fn emit_bounds_check(&mut self, index: LlValue, len: LlValue, message: &str) {
        let non_negative = self.tmp();
        self.body
            .push(format!("  {non_negative} = icmp sge i64 {}, 0", index.repr));
        let within_len = self.tmp();
        self.body.push(format!(
            "  {within_len} = icmp slt i64 {}, {}",
            index.repr, len.repr
        ));
        let in_bounds = self.tmp();
        self.body.push(format!(
            "  {in_bounds} = and i1 {non_negative}, {within_len}"
        ));
        self.emit_runtime_guard(in_bounds, message);
    }

    fn emit_runtime_guard(&mut self, condition_repr: String, message: &str) {
        let ok_label = self.label("rt_ok");
        let fail_label = self.label("rt_fail");
        self.body.push(format!(
            "  br i1 {condition_repr}, label %{ok_label}, label %{fail_label}"
        ));
        self.body.push(format!("{fail_label}:"));
        let message_value = self.string_value(message);
        self.body.push(format!(
            "  call void @mire_runtime_panic(ptr {})",
            message_value.repr
        ));
        self.body.push("  unreachable".to_string());
        self.body.push(format!("{ok_label}:"));
    }

    fn compile_do_while(&mut self, args: &[Expression]) -> Result<()> {
        if args.len() != 2 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys __do_while expects 2 closures".to_string(),
            }));
        }
        let body = self.closure_statements(&args[0], "__do_while body")?;
        let condition = self.closure_return_expr(&args[1], "__do_while condition")?;

        let body_label = self.label("dowhile_body");
        let cond_label = self.label("dowhile_cond");
        let end_label = self.label("dowhile_end");

        self.body.push(format!("  br label %{body_label}"));
        self.body.push(format!("{body_label}:"));
        self.loop_stack.push(LoopLabels {
            break_label: end_label.clone(),
            continue_label: cond_label.clone(),
        });
        for stmt in body {
            self.compile_statement(stmt)?;
        }
        self.loop_stack.pop();
        self.body.push(format!("  br label %{cond_label}"));

        self.body.push(format!("{cond_label}:"));
        let cond_val = self.compile_expr(condition)?;
        let cond = self.cast_to_i1(cond_val)?;
        self.body.push(format!(
            "  br i1 {}, label %{body_label}, label %{end_label}",
            cond.repr
        ));
        self.body.push(format!("{end_label}:"));
        Ok(())
    }

    fn compile_for_range(
        &mut self,
        variable: &str,
        iterable: &Expression,
        body: &[Statement],
    ) -> Result<()> {
        let (start_expr, end_expr, step_expr) = match iterable {
            Expression::Call { name, args, .. } if name == "range" => match args.len() {
                1 => (
                    Expression::Literal(Literal::Int(0)),
                    args[0].clone(),
                    Expression::Literal(Literal::Int(1)),
                ),
                2 => (
                    args[0].clone(),
                    args[1].clone(),
                    Expression::Literal(Literal::Int(1)),
                ),
                3 => (args[0].clone(), args[1].clone(), args[2].clone()),
                _ => {
                    return Err(MireError::new(ErrorKind::Runtime {
                        message: "Avenys range(...) supports 1 to 3 arguments".to_string(),
                    }));
                }
            },
            other => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Avenys for-loop currently supports range(...) only, found {:?}",
                        other
                    ),
                }));
            }
        };

        let start_value = self.compile_expr(&start_expr)?;
        let start = self.cast_to_i64(start_value)?;
        let end_value = self.compile_expr(&end_expr)?;
        let end = self.cast_to_i64(end_value)?;
        let step_value = self.compile_expr(&step_expr)?;
        let step = self.cast_to_i64(step_value)?;
        let iter_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {iter_ptr} = alloca i64"));
        self.body
            .push(format!("  store i64 {}, ptr {}", start.repr, iter_ptr));

        let saved = self.vars.insert(
            variable.to_string(),
            VarInfo {
                ptr: iter_ptr.clone(),
                ty: LlType::I64,
                data_type: DataType::I64,
                owns_heap_string: false,
                struct_name: None,
            },
        );

        let cond_label = self.label("for_cond");
        let body_label = self.label("for_body");
        let continue_label = self.label("for_continue");
        let positive_label = self.label("for_positive");
        let negative_label = self.label("for_negative");
        let cond_merge_label = self.label("for_cond_merge");
        let end_label = self.label("for_end");
        let step_positive = self.tmp();
        let current_val = self.tmp();
        let pos_cmp = self.tmp();
        let neg_cmp = self.tmp();
        let cmp_ptr = self.tmp();
        self.entry_allocas.push(format!("  {cmp_ptr} = alloca i1"));

        self.body.push(format!("  br label %{cond_label}"));
        self.body.push(format!("{cond_label}:"));
        self.body
            .push(format!("  {step_positive} = icmp sgt i64 {}, 0", step.repr));
        self.body
            .push(format!("  {current_val} = load i64, ptr {}", iter_ptr));
        self.body.push(format!(
            "  br i1 {}, label %{positive_label}, label %{negative_label}",
            step_positive
        ));
        self.body.push(format!("{positive_label}:"));
        self.body.push(format!(
            "  {pos_cmp} = icmp slt i64 {}, {}",
            current_val, end.repr
        ));
        self.body
            .push(format!("  store i1 {}, ptr {}", pos_cmp, cmp_ptr));
        self.body.push(format!("  br label %{cond_merge_label}"));
        self.body.push(format!("{negative_label}:"));
        self.body.push(format!(
            "  {neg_cmp} = icmp sgt i64 {}, {}",
            current_val, end.repr
        ));
        self.body
            .push(format!("  store i1 {}, ptr {}", neg_cmp, cmp_ptr));
        self.body.push(format!("  br label %{cond_merge_label}"));
        self.body.push(format!("{cond_merge_label}:"));
        let cmp_tmp = self.tmp();
        self.body
            .push(format!("  {cmp_tmp} = load i1, ptr {}", cmp_ptr));
        self.body.push(format!(
            "  br i1 {}, label %{body_label}, label %{end_label}",
            cmp_tmp
        ));

        self.body.push(format!("{body_label}:"));
        self.loop_stack.push(LoopLabels {
            break_label: end_label.clone(),
            continue_label: continue_label.clone(),
        });
        for stmt in body {
            self.compile_statement(stmt)?;
        }
        self.loop_stack.pop();
        self.body.push(format!("  br label %{continue_label}"));

        self.body.push(format!("{continue_label}:"));
        let iter_value = self.tmp();
        let next_value = self.tmp();
        self.body
            .push(format!("  {iter_value} = load i64, ptr {}", iter_ptr));
        self.body.push(format!(
            "  {next_value} = add i64 {}, {}",
            iter_value, step.repr
        ));
        self.body
            .push(format!("  store i64 {}, ptr {}", next_value, iter_ptr));
        self.body.push(format!("  br label %{cond_label}"));
        self.body.push(format!("{end_label}:"));

        if let Some(saved) = saved {
            self.vars.insert(variable.to_string(), saved);
        } else {
            self.vars.remove(variable);
        }

        Ok(())
    }

    fn closure_statements<'a>(&self, expr: &'a Expression, ctx: &str) -> Result<&'a [Statement]> {
        match expr {
            Expression::Closure { params, body, .. } if params.is_empty() => Ok(body),
            _ => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Avenys expects a zero-arg closure for {}", ctx),
            })),
        }
    }

    fn closure_return_expr<'a>(&self, expr: &'a Expression, ctx: &str) -> Result<&'a Expression> {
        match expr {
            Expression::Closure { params, body, .. } if params.is_empty() => {
                if let [Statement::Return(Some(value))] = body.as_slice() {
                    Ok(value)
                } else {
                    Err(MireError::new(ErrorKind::Runtime {
                        message: format!(
                            "Avenys expects {} closure to be a single return expression",
                            ctx
                        ),
                    }))
                }
            }
            _ => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Avenys expects a zero-arg closure for {}", ctx),
            })),
        }
    }

    fn emit_print(&mut self, value: &LlValue) -> Result<()> {
        match value.ty {
            LlType::I64 => {
                self.body.push(format!(
                    "  call i32 (ptr, ...) @printf(ptr @.fmt_i64, i64 {})",
                    value.repr
                ));
                Ok(())
            }
            LlType::Ptr => {
                self.body.push(format!(
                    "  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr {})",
                    value.repr
                ));
                Ok(())
            }
            LlType::I1 => {
                let true_ptr = self.string_value("true");
                let false_ptr = self.string_value("false");
                let select = self.tmp();
                self.body.push(format!(
                    "  {select} = select i1 {}, ptr {}, ptr {}",
                    value.repr, true_ptr.repr, false_ptr.repr
                ));
                self.body.push(format!(
                    "  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr {select})"
                ));
                Ok(())
            }
            LlType::F64 => {
                self.body.push(format!(
                    "  call i32 (ptr, ...) @printf(ptr @.fmt_f64, double {})",
                    value.repr
                ));
                Ok(())
            }
        }
    }

    fn emit_dasu_expr(&mut self, expr: &Expression) -> Result<()> {
        let value = self.compile_expr(expr)?;
        self.emit_print(&value)?;
        Ok(())
    }

    fn struct_name_from_expr(&self, expr: &Expression) -> Option<String> {
        match expr {
            Expression::Call {
                name, data_type, ..
            } if data_type.is_struct_like() => {
                data_type.struct_name().map(ToOwned::to_owned).or_else(|| {
                    if self.user_structs.contains_key(name) {
                        Some(name.clone())
                    } else if let Some((owner, _method)) = name.split_once('.') {
                        self.vars
                            .get(owner)
                            .and_then(|info| info.struct_name.clone())
                            .or_else(|| {
                                self.user_structs
                                    .contains_key(owner)
                                    .then(|| owner.to_string())
                            })
                    } else {
                        None
                    }
                })
            }
            Expression::Identifier(Identifier { name, .. }) => self
                .vars
                .get(name)
                .and_then(|info| info.struct_name.clone()),
            _ => None,
        }
    }

    fn compile_input_expr(&mut self, args: &[Expression], data_type: &DataType) -> Result<LlValue> {
        if args.len() != 1 {
            return Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys ireru expects 1 argument".to_string(),
            }));
        }

        let prompt = self.compile_expr(&args[0])?;
        self.body.push(format!(
            "  call i32 (ptr, ...) @printf(ptr @.fmt_prompt, ptr {})",
            prompt.repr
        ));

        match data_type {
            DataType::I64 | DataType::I32 | DataType::I16 | DataType::I8 => {
                let temp_buf = self.tmp();
                let result = self.tmp();
                self.body.push(format!("  {temp_buf} = alloca i64"));
                self.body.push(format!(
                    "  call i32 (ptr, ...) @scanf(ptr @.scanf_i64, ptr {temp_buf})"
                ));
                self.body
                    .push(format!("  {result} = load i64, ptr {temp_buf}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            _ => {
                let input_buf = self.tmp();
                self.body
                    .push(format!("  {input_buf} = call ptr @malloc(i64 256)"));
                self.body.push(format!(
                    "  call i32 (ptr, ...) @scanf(ptr @.scanf_str, ptr {input_buf})"
                ));
                Ok(LlValue {
                    ty: LlType::Ptr,
                    repr: input_buf,
                    owned: true,
                })
            }
        }
    }

    fn expression_data_type(&self, expr: &Expression) -> DataType {
        match expr {
            Expression::Literal(Literal::Str(_)) => DataType::Str,
            Expression::Literal(Literal::Bool(_)) => DataType::Bool,
            Expression::Literal(Literal::Int(_)) => DataType::I64,
            Expression::Literal(Literal::List(_)) => DataType::Vector {
                element_type: Box::new(DataType::Unknown),
                dynamic: false,
            },
            Expression::Literal(Literal::Dict(_)) => DataType::Map {
                key_type: Box::new(DataType::Unknown),
                value_type: Box::new(DataType::Unknown),
            },
            Expression::Literal(_) => DataType::Unknown,
            Expression::Identifier(identifier) => {
                if identifier.data_type != DataType::Unknown {
                    identifier.data_type.clone()
                } else {
                    self.vars
                        .get(&identifier.name)
                        .map(|var| var.data_type.clone())
                        .unwrap_or(DataType::Unknown)
                }
            }
            Expression::BinaryOp { data_type, .. }
            | Expression::UnaryOp { data_type, .. }
            | Expression::NamedArg { data_type, .. }
            | Expression::Call { data_type, .. }
            | Expression::List { data_type, .. }
            | Expression::Dict { data_type, .. }
            | Expression::Tuple { data_type, .. }
            | Expression::Reference { data_type, .. }
            | Expression::Dereference { data_type, .. }
            | Expression::Box { data_type, .. }
            | Expression::Pipeline { data_type, .. }
            | Expression::Match { data_type, .. }
            | Expression::EnumVariantPath { data_type, .. }
            | Expression::EnumVariant { data_type, .. } => data_type.clone(),
            Expression::MemberAccess {
                target,
                member,
                data_type,
            } => {
                if *data_type != DataType::Unknown {
                    return data_type.clone();
                }
                let target_type = self.expression_data_type(target);
                let Some(struct_name) = target_type
                    .struct_name()
                    .map(ToOwned::to_owned)
                    .or_else(|| self.struct_name_from_expr(target))
                else {
                    return DataType::Unknown;
                };
                self.user_structs
                    .get(&struct_name)
                    .and_then(|info| {
                        info.field_indices
                            .get(member)
                            .and_then(|index| info.field_data_types.get(*index))
                            .cloned()
                    })
                    .unwrap_or(DataType::Unknown)
            }
            Expression::Index {
                target, data_type, ..
            } => {
                if *data_type != DataType::Unknown {
                    return data_type.clone();
                }
                match self.expression_data_type(target) {
                    DataType::Array { element_type, .. }
                    | DataType::Slice { element_type }
                    | DataType::Vector { element_type, .. } => *element_type,
                    DataType::Map { value_type, .. } => *value_type,
                    _ => DataType::Unknown,
                }
            }
            Expression::Closure { return_type, .. } => return_type.clone(),
        }
    }

    fn map_type(&self, data_type: &DataType) -> Result<LlType> {
        match data_type {
            DataType::I64 | DataType::Unknown | DataType::Anything => Ok(LlType::I64),
            DataType::I32 => Ok(LlType::I64),
            DataType::I8 | DataType::I16 => Ok(LlType::I64),
            DataType::U8 | DataType::U16 | DataType::U32 | DataType::U64 => Ok(LlType::I64),
            DataType::F32 | DataType::F64 => Ok(LlType::F64),
            DataType::Bool => Ok(LlType::I1),
            DataType::Str => Ok(LlType::Ptr),
            DataType::List
            | DataType::Vector { .. }
            | DataType::Dict
            | DataType::Map { .. }
            | DataType::Set
            | DataType::Tuple
            | DataType::Array { .. }
            | DataType::Slice { .. }
            | DataType::Struct
            | DataType::StructNamed(_)
            | DataType::Enum
            | DataType::EnumNamed(_)
            | DataType::Ref { .. }
            | DataType::RefMut { .. } => Ok(LlType::Ptr),
            DataType::None => Ok(LlType::I64),
            other => Err(MireError::new(ErrorKind::Backend {
                message: format!("Avenys does not yet lower type {:?}", other),
            })),
        }
    }

    fn runtime_kind_code(&self, data_type: &DataType) -> i64 {
        match data_type {
            DataType::Bool => 2,
            DataType::Str => 3,
            DataType::Dict | DataType::Map { .. } => 4,
            DataType::List
            | DataType::Vector { .. }
            | DataType::Set
            | DataType::Tuple
            | DataType::Array { .. }
            | DataType::Slice { .. } => 5,
            _ => 1,
        }
    }

    fn element_size(&self, data_type: &DataType) -> i64 {
        match data_type {
            DataType::Bool | DataType::I8 | DataType::U8 => 1,
            DataType::I16 | DataType::U16 => 2,
            DataType::I32 | DataType::U32 => 4,
            DataType::Str
            | DataType::List
            | DataType::Vector { .. }
            | DataType::Dict
            | DataType::Map { .. }
            | DataType::Set
            | DataType::Tuple
            | DataType::Array { .. }
            | DataType::Slice { .. }
            | DataType::F32
            | DataType::F64 => 8,
            _ => 8,
        }
    }

    fn scalar_storage_ir_type(&self, data_type: &DataType) -> &'static str {
        match data_type {
            DataType::Bool | DataType::I8 | DataType::U8 => "i8",
            DataType::I16 | DataType::U16 => "i16",
            DataType::I32 | DataType::U32 => "i32",
            _ => "i64",
        }
    }

    fn cast_scalar_for_store(
        &mut self,
        value: LlValue,
        data_type: &DataType,
    ) -> Result<(String, String)> {
        match data_type {
            DataType::Bool => {
                let bool_value = self.cast_to_i1(value)?;
                let widened = self.tmp();
                self.body
                    .push(format!("  {widened} = zext i1 {} to i8", bool_value.repr));
                Ok(("i8".to_string(), widened))
            }
            DataType::I8 | DataType::U8 => {
                let scalar = self.cast_to_i64(value)?;
                let narrowed = self.tmp();
                self.body
                    .push(format!("  {narrowed} = trunc i64 {} to i8", scalar.repr));
                Ok(("i8".to_string(), narrowed))
            }
            DataType::I16 | DataType::U16 => {
                let scalar = self.cast_to_i64(value)?;
                let narrowed = self.tmp();
                self.body
                    .push(format!("  {narrowed} = trunc i64 {} to i16", scalar.repr));
                Ok(("i16".to_string(), narrowed))
            }
            DataType::I32 | DataType::U32 => {
                let scalar = self.cast_to_i64(value)?;
                let narrowed = self.tmp();
                self.body
                    .push(format!("  {narrowed} = trunc i64 {} to i32", scalar.repr));
                Ok(("i32".to_string(), narrowed))
            }
            _ => {
                let scalar = self.cast_to_i64(value)?;
                Ok(("i64".to_string(), scalar.repr))
            }
        }
    }

    fn default_value(&mut self, ty: LlType) -> LlValue {
        match ty {
            LlType::I64 => LlValue {
                ty,
                repr: "0".to_string(),
                owned: false,
            },
            LlType::I1 => LlValue {
                ty,
                repr: "0".to_string(),
                owned: false,
            },
            LlType::F64 => LlValue {
                ty,
                repr: "0.0".to_string(),
                owned: false,
            },
            LlType::Ptr => self.string_value(""),
        }
    }

    fn string_value(&mut self, value: &str) -> LlValue {
        let label = format!("@.str{}", self.strings.len());
        let escaped = escape_llvm_string(value);
        let len = string_byte_len(value) + 1;
        self.strings.push(format!(
            "{label} = private unnamed_addr constant [{len} x i8] c\"{escaped}\\00\""
        ));
        let tmp = self.tmp();
        self.body.push(format!(
            "  {tmp} = getelementptr inbounds [{len} x i8], ptr {label}, i64 0, i64 0"
        ));
        LlValue {
            ty: LlType::Ptr,
            repr: tmp,
            owned: false,
        }
    }

    fn cast_to_i64(&mut self, value: LlValue) -> Result<LlValue> {
        match value.ty {
            LlType::I64 => Ok(value),
            LlType::I1 => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = zext i1 {} to i64", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: tmp,
                    owned: false,
                })
            }
            LlType::F64 => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = fptosi double {} to i64", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: tmp,
                    owned: false,
                })
            }
            LlType::Ptr => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = ptrtoint ptr {} to i64", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: tmp,
                    owned: false,
                })
            }
        }
    }

    fn cast_to_i1(&mut self, value: LlValue) -> Result<LlValue> {
        match value.ty {
            LlType::I1 => Ok(value),
            LlType::I64 => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = icmp ne i64 {}, 0", value.repr));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: tmp,
                    owned: false,
                })
            }
            LlType::F64 => {
                let tmp = self.tmp();
                self.body
                    .push(format!("  {tmp} = fcmp one double {}, 0.0", value.repr));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: tmp,
                    owned: false,
                })
            }
            LlType::Ptr => Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cannot cast pointer/struct to bool".to_string(),
            })),
        }
    }

    fn compile_binary(
        &mut self,
        op: &str,
        lhs: LlValue,
        rhs: LlValue,
        _data_type: &DataType,
    ) -> Result<LlValue> {
        let left_repr = lhs.repr.clone();
        let right_repr = rhs.repr.clone();
        let left_is_ptr = lhs.ty == LlType::Ptr;
        let right_is_ptr = rhs.ty == LlType::Ptr;
        let result = self.tmp();

        if left_is_ptr && right_is_ptr && op == "+" {
            self.body.push(format!(
                "  {result} = call ptr @mire_string_concat(ptr {left_repr}, ptr {right_repr})"
            ));
            return Ok(LlValue {
                ty: LlType::Ptr,
                repr: result,
                owned: true,
            });
        }

        if left_is_ptr && right_is_ptr && matches!(op, "==" | "!=" | "<" | ">" | "<=" | ">=") {
            let cmp_value = self.tmp();
            self.body.push(format!(
                "  {cmp_value} = call i32 @strcmp(ptr {left_repr}, ptr {right_repr})"
            ));
            let pred = match op {
                "==" => "eq",
                "!=" => "ne",
                "<" => "slt",
                ">" => "sgt",
                "<=" => "sle",
                ">=" => "sge",
                _ => unreachable!(),
            };
            self.body
                .push(format!("  {result} = icmp {pred} i32 {cmp_value}, 0"));
            return Ok(LlValue {
                ty: LlType::I1,
                repr: result,
                owned: false,
            });
        }

        match op {
            "+" => {
                self.body
                    .push(format!("  {result} = add i64 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "-" => {
                self.body
                    .push(format!("  {result} = sub i64 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "*" => {
                self.body
                    .push(format!("  {result} = mul i64 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "/" => {
                self.emit_nonzero_check(&right_repr, "division by zero");
                self.body
                    .push(format!("  {result} = sdiv i64 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "%" => {
                self.emit_nonzero_check(&right_repr, "division by zero");
                self.body
                    .push(format!("  {result} = srem i64 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "==" | "!=" | "<" | ">" | "<=" | ">=" => {
                let cmp = match op {
                    "==" => "eq",
                    "!=" => "ne",
                    "<" => "slt",
                    ">" => "sgt",
                    "<=" => "sle",
                    ">=" => "sge",
                    _ => "eq",
                };
                self.body.push(format!(
                    "  {result} = icmp {cmp} i64 {left_repr}, {right_repr}"
                ));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: result,
                    owned: false,
                })
            }
            "&&" => {
                self.body
                    .push(format!("  {result} = and i1 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: result,
                    owned: false,
                })
            }
            "||" => {
                self.body
                    .push(format!("  {result} = or i1 {left_repr}, {right_repr}"));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: result,
                    owned: false,
                })
            }
            "^" => {
                if lhs.ty == LlType::I1 && rhs.ty == LlType::I1 {
                    self.body
                        .push(format!("  {result} = xor i1 {left_repr}, {right_repr}"));
                    Ok(LlValue {
                        ty: LlType::I1,
                        repr: result,
                        owned: false,
                    })
                } else {
                    let left_i64 = self.cast_to_i64(lhs)?;
                    let right_i64 = self.cast_to_i64(rhs)?;
                    self.body.push(format!(
                        "  {result} = xor i64 {}, {}",
                        left_i64.repr, right_i64.repr
                    ));
                    Ok(LlValue {
                        ty: LlType::I64,
                        repr: result,
                        owned: false,
                    })
                }
            }
            "&" => {
                let left_i64 = self.cast_to_i64(lhs)?;
                let right_i64 = self.cast_to_i64(rhs)?;
                self.body.push(format!(
                    "  {result} = and i64 {}, {}",
                    left_i64.repr, right_i64.repr
                ));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "|" => {
                let left_i64 = self.cast_to_i64(lhs)?;
                let right_i64 = self.cast_to_i64(rhs)?;
                self.body.push(format!(
                    "  {result} = or i64 {}, {}",
                    left_i64.repr, right_i64.repr
                ));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "<<" => {
                let left_i64 = self.cast_to_i64(lhs)?;
                let right_i64 = self.cast_to_i64(rhs)?;
                self.body.push(format!(
                    "  {result} = shl i64 {}, {}",
                    left_i64.repr, right_i64.repr
                ));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            ">>" => {
                let left_i64 = self.cast_to_i64(lhs)?;
                let right_i64 = self.cast_to_i64(rhs)?;
                self.body.push(format!(
                    "  {result} = lshr i64 {}, {}",
                    left_i64.repr, right_i64.repr
                ));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            _ => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Unknown operator: {}", op),
            })),
        }
    }

    fn compile_logical_short_circuit(
        &mut self,
        op: &str,
        left: &Expression,
        right: &Expression,
        _data_type: &DataType,
    ) -> Result<LlValue> {
        let end_label = self.label("logical_end");
        let result_ptr = self.tmp();
        self.entry_allocas
            .push(format!("  {result_ptr} = alloca i1"));

        let left_val = self.compile_expr(left)?;
        let left_cond = self.cast_to_i1(left_val)?;

        if op == "&&" {
            let skip_label = self.label("and_skip_rhs");
            let rhs_label = self.label("and_rhs");
            self.body.push(format!(
                "  br i1 {}, label %{rhs_label}, label %{skip_label}",
                left_cond.repr
            ));
            self.body.push(format!("{skip_label}:"));
            self.body.push(format!("  store i1 0, ptr {result_ptr}"));
            self.body.push(format!("  br label %{end_label}"));
            self.body.push(format!("{rhs_label}:"));
            let right_val = self.compile_expr(right)?;
            let right_cond = self.cast_to_i1(right_val)?;
            self.body
                .push(format!("  store i1 {}, ptr {result_ptr}", right_cond.repr));
            self.body.push(format!("  br label %{end_label}"));
        } else {
            let skip_label = self.label("or_skip_rhs");
            let rhs_label = self.label("or_rhs");
            self.body.push(format!(
                "  br i1 {}, label %{skip_label}, label %{rhs_label}",
                left_cond.repr
            ));
            self.body.push(format!("{skip_label}:"));
            self.body.push(format!("  store i1 1, ptr {result_ptr}"));
            self.body.push(format!("  br label %{end_label}"));
            self.body.push(format!("{rhs_label}:"));
            let right_val = self.compile_expr(right)?;
            let right_cond = self.cast_to_i1(right_val)?;
            self.body
                .push(format!("  store i1 {}, ptr {result_ptr}", right_cond.repr));
            self.body.push(format!("  br label %{end_label}"));
        }

        self.body.push(format!("{end_label}:"));
        let loaded = self.tmp();
        self.body
            .push(format!("  {loaded} = load i1, ptr {result_ptr}"));
        Ok(LlValue {
            ty: LlType::I1,
            repr: loaded,
            owned: false,
        })
    }

    fn compile_unary(&mut self, op: &str, value: LlValue) -> Result<LlValue> {
        let result = self.tmp();
        match op {
            "-" => {
                self.body
                    .push(format!("  {result} = sub i64 0, {}", value.repr));
                Ok(LlValue {
                    ty: LlType::I64,
                    repr: result,
                    owned: false,
                })
            }
            "!" => {
                let bool_val = self.cast_to_i1(value)?;
                self.body
                    .push(format!("  {result} = xor i1 {}, 1", bool_val.repr));
                Ok(LlValue {
                    ty: LlType::I1,
                    repr: result,
                    owned: false,
                })
            }
            _ => Err(MireError::new(ErrorKind::Runtime {
                message: format!("Unknown unary operator: {}", op),
            })),
        }
    }

    fn compile_list_literal(
        &mut self,
        elements: &[Expression],
        element_type: &DataType,
    ) -> Result<LlValue> {
        let size = elements.len() as i64;
        if size == 0 {
            let ptr = self.tmp();
            self.body.push(format!("  {ptr} = inttoptr i64 0 to ptr"));
            return Ok(LlValue {
                ty: LlType::Ptr,
                repr: ptr,
                owned: false,
            });
        }
        let malloc = self.tmp();
        let list_ptr = self.tmp();
        let elem_size = self.element_size(element_type);
        self.body.push(format!(
            "  {malloc} = call ptr @malloc(i64 {})",
            16 + size * elem_size
        ));
        self.body
            .push(format!("  store i64 {}, ptr {malloc}", size));
        self.body.push(format!(
            "  {list_ptr} = getelementptr i8, ptr {malloc}, i64 8"
        ));
        self.body
            .push(format!("  store i64 {}, ptr {list_ptr}", size));
        let elem_ll_ty = self.map_type(element_type).unwrap_or(LlType::I64);
        for (i, elem) in elements.iter().enumerate() {
            let val = self.compile_expr(elem)?;
            let elem_ptr = self.tmp();
            self.body.push(format!(
                "  {elem_ptr} = getelementptr i8, ptr {}, i64 {}",
                list_ptr,
                8 + i as i64 * elem_size
            ));
            if elem_ll_ty == LlType::Ptr {
                let stored = self.cast_to_type(val, LlType::Ptr)?;
                self.body
                    .push(format!("  store ptr {}, ptr {}", stored.repr, elem_ptr));
            } else {
                let (store_ty, store_repr) = self.cast_scalar_for_store(val, element_type)?;
                self.body.push(format!(
                    "  store {} {}, ptr {}",
                    store_ty, store_repr, elem_ptr
                ));
            }
        }
        Ok(LlValue {
            ty: LlType::Ptr,
            repr: list_ptr,
            owned: false,
        })
    }

    fn concat_values(&mut self, lhs: LlValue, rhs: LlValue) -> LlValue {
        let result = self.tmp();
        self.body.push(format!(
            "  {result} = call ptr @mire_string_concat(ptr {}, ptr {})",
            lhs.repr, rhs.repr
        ));
        LlValue {
            ty: LlType::Ptr,
            repr: result,
            owned: true,
        }
    }

    fn compile_dict_literal(&mut self, entries: &[(Expression, Expression)]) -> Result<LlValue> {
        let mut current = LlValue {
            ty: LlType::Ptr,
            repr: "null".to_string(),
            owned: false,
        };

        for (key_expr, value_expr) in entries {
            let key_data_type = self.expression_data_type(key_expr);
            let value_data_type = self.expression_data_type(value_expr);
            let key = self.compile_expr(key_expr)?;
            let value = self.compile_expr(value_expr)?;
            let key_kind = self.runtime_kind_code(&key_data_type);
            let value_kind = self.runtime_kind_code(&value_data_type);
            let key_i64 = if key.ty == LlType::Ptr {
                LlValue {
                    ty: LlType::I64,
                    repr: "0".to_string(),
                    owned: false,
                }
            } else {
                self.cast_to_i64(key.clone())?
            };
            let key_ptr = if key.ty == LlType::Ptr {
                key
            } else {
                LlValue {
                    ty: LlType::Ptr,
                    repr: "null".to_string(),
                    owned: false,
                }
            };
            let result = self.tmp();

            if value.ty == LlType::Ptr {
                let casted = self.cast_to_type(value, LlType::Ptr)?;
                self.body.push(format!(
                    "  {result} = call ptr @mire_dict_set_ptr(ptr {}, i64 {}, i64 {}, i64 {}, ptr {}, ptr {})",
                    current.repr, key_kind, value_kind, key_i64.repr, key_ptr.repr, casted.repr
                ));
            } else {
                let casted = self.cast_to_i64(value)?;
                self.body.push(format!(
                    "  {result} = call ptr @mire_dict_set_i64(ptr {}, i64 {}, i64 {}, i64 {}, ptr {}, i64 {})",
                    current.repr, key_kind, value_kind, key_i64.repr, key_ptr.repr, casted.repr
                ));
            }

            current = LlValue {
                ty: LlType::Ptr,
                repr: result,
                owned: true,
            };
        }

        Ok(current)
    }

    fn cast_to_type(&mut self, value: LlValue, ty: LlType) -> Result<LlValue> {
        match ty {
            LlType::I64 => self.cast_to_i64(value),
            LlType::I1 => self.cast_to_i1(value),
            LlType::F64 => Ok(value),
            LlType::Ptr if value.ty == LlType::Ptr => Ok(value),
            LlType::Ptr => Err(MireError::new(ErrorKind::Runtime {
                message: "Avenys cannot cast non-pointer value to string".to_string(),
            })),
        }
    }

    fn store_casted(&mut self, ptr: &str, ty: LlType, value: LlValue) -> Result<()> {
        let value = match ty {
            LlType::I64 => self.cast_to_i64(value)?,
            LlType::I1 => self.cast_to_i1(value)?,
            LlType::F64 => value,
            LlType::Ptr if value.ty == LlType::Ptr => value,
            LlType::Ptr => {
                return Err(MireError::new(ErrorKind::Runtime {
                    message: "Avenys cannot store non-pointer into string slot".to_string(),
                }));
            }
        };
        self.body.push(format!(
            "  store {} {}, ptr {}",
            self.ty(ty),
            value.repr,
            ptr
        ));
        Ok(())
    }

    fn store_variable(
        &mut self,
        name: &str,
        ptr: &str,
        ty: LlType,
        data_type: DataType,
        value: LlValue,
    ) -> Result<()> {
        if data_type == DataType::Str && ty == LlType::Ptr {
            let old_owned = self
                .vars
                .get(name)
                .map(|var| var.owns_heap_string)
                .unwrap_or(false);

            if old_owned {
                let old_ptr = self.tmp();
                self.body.push(format!("  {old_ptr} = load ptr, ptr {ptr}"));
                self.body
                    .push(format!("  call void @mire_string_free(ptr {old_ptr})"));
            }

            let owned_value = if value.owned {
                value
            } else {
                let copied = self.tmp();
                self.body.push(format!(
                    "  {copied} = call ptr @mire_string_copy(ptr {})",
                    value.repr
                ));
                LlValue {
                    ty: LlType::Ptr,
                    repr: copied,
                    owned: true,
                }
            };

            self.store_casted(ptr, ty.clone(), owned_value)?;
            if let Some(var) = self.vars.get_mut(name) {
                var.data_type = data_type;
                var.owns_heap_string = true;
            }
            return Ok(());
        }

        self.store_casted(ptr, ty.clone(), value)?;
        if let Some(var) = self.vars.get_mut(name) {
            var.data_type = data_type;
            var.owns_heap_string = false;
        }
        Ok(())
    }

    fn try_compile_in_place_string_append(
        &mut self,
        target: &str,
        var: &VarInfo,
        value: &Expression,
    ) -> Result<bool> {
        if var.data_type != DataType::Str || var.ty != LlType::Ptr || !var.owns_heap_string {
            return Ok(false);
        }

        let Expression::BinaryOp {
            operator,
            left,
            right,
            ..
        } = value
        else {
            return Ok(false);
        };

        if operator != "+" {
            return Ok(false);
        }

        let Expression::Identifier(identifier) = left.as_ref() else {
            return Ok(false);
        };

        if identifier.name != target {
            return Ok(false);
        }

        let rhs = self.compile_expr(right)?;
        let current = self.tmp();
        let appended = self.tmp();
        self.body
            .push(format!("  {current} = load ptr, ptr {}", var.ptr));
        self.body.push(format!(
            "  {appended} = call ptr @mire_string_append_owned(ptr {current}, ptr {})",
            rhs.repr
        ));
        self.body
            .push(format!("  store ptr {appended}, ptr {}", var.ptr));
        if let Some(var) = self.vars.get_mut(target) {
            var.owns_heap_string = true;
        }
        Ok(true)
    }

    fn ty(&self, ty: LlType) -> &'static str {
        match ty {
            LlType::I64 => "i64",
            LlType::I1 => "i1",
            LlType::F64 => "double",
            LlType::Ptr => "ptr",
        }
    }

    fn render_struct_ty(&self, fields: &[LlType]) -> String {
        let rendered = fields
            .iter()
            .map(|field| self.ty(field.clone()).to_string())
            .collect::<Vec<_>>()
            .join(", ");
        format!("{{ {} }}", rendered)
    }

    fn tmp(&mut self) -> String {
        let out = format!("%t{}", self.next_tmp);
        self.next_tmp += 1;
        out
    }

    fn label(&mut self, prefix: &str) -> String {
        let out = format!("{prefix}_{}", self.next_label);
        self.next_label += 1;
        out
    }

    fn compile_function_ir(
        &mut self,
        name: &str,
        params: &[(String, DataType)],
        body: &[Statement],
        ret: LlType,
    ) -> Result<String> {
        let saved_allocas = std::mem::take(&mut self.entry_allocas);
        let saved_body = std::mem::take(&mut self.body);
        let saved_vars = std::mem::take(&mut self.vars);
        let saved_loop_stack = std::mem::take(&mut self.loop_stack);
        let saved_return = self.current_return.clone();
        self.current_return = ret.clone();

        let fn_info = self.user_functions.get(name).cloned().ok_or_else(|| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Avenys missing function metadata for '{}'", name),
            })
        })?;
        let method_owner = name.split_once('.').map(|(owner, _)| owner.to_string());

        for ((param_name, param_data_type), param_ty) in params.iter().zip(fn_info.params.iter()) {
            let ptr = self.tmp();
            let arg_name = format!("%arg_{}", sanitize_symbol(param_name));
            let param_ty = param_ty.clone();
            self.entry_allocas
                .push(format!("  {ptr} = alloca {}", self.ty(param_ty.clone())));
            self.body.push(format!(
                "  store {} {}, ptr {}",
                self.ty(param_ty.clone()),
                arg_name,
                ptr
            ));

            let param_struct_name = match param_data_type {
                DataType::StructNamed(name) => Some(name.clone()),
                _ => {
                    let ty_str = self.ty(param_ty.clone());
                    self.user_structs
                        .iter()
                        .find(|(_, info)| self.render_struct_ty(&info.fields) == ty_str)
                        .map(|(name, _)| name.clone())
                }
            };

            let final_data_type = if param_name == "self" {
                method_owner
                    .clone()
                    .map(DataType::StructNamed)
                    .unwrap_or(DataType::Struct)
            } else {
                param_data_type.clone()
            };

            let final_struct_name = if param_name == "self" {
                method_owner.clone()
            } else {
                param_struct_name
            };

            self.vars.insert(
                param_name.clone(),
                VarInfo {
                    ptr,
                    ty: param_ty.clone(),
                    data_type: final_data_type,
                    owns_heap_string: false,
                    struct_name: final_struct_name,
                },
            );
        }

        for stmt in body {
            self.compile_statement(stmt)?;
        }

        let ret_clone = ret.clone();
        if body
            .iter()
            .all(|stmt| !matches!(stmt, Statement::Return(_)))
        {
            if fn_info.returns_value {
                if let Some(Statement::Expression(expr)) = body.last() {
                    let value = self.compile_expr(expr)?;
                    let ret = self.cast_to_type(value, ret_clone.clone())?;
                    let result_ptr = self.tmp();
                    self.body.push(format!(
                        "  {result_ptr} = alloca {}",
                        self.ty(ret_clone.clone())
                    ));
                    self.body.push(format!(
                        "  store {} {}, ptr {}",
                        self.ty(ret_clone.clone()),
                        ret.repr,
                        result_ptr
                    ));
                    self.body.push(format!(
                        "  %ret_val = load {}, ptr {}",
                        self.ty(ret_clone.clone()),
                        result_ptr
                    ));
                    self.body
                        .push(format!("  ret {} %ret_val", self.ty(ret_clone.clone())));
                } else {
                    let default = self.default_value(ret_clone.clone());
                    self.body.push(format!(
                        "  ret {} {}",
                        self.ty(ret_clone.clone()),
                        default.repr
                    ));
                }
            } else {
                let default = self.default_value(ret_clone.clone());
                self.body.push(format!(
                    "  ret {} {}",
                    self.ty(ret_clone.clone()),
                    default.repr
                ));
            }
        }

        let args = params
            .iter()
            .zip(fn_info.params.iter())
            .map(|((name, _), ty)| {
                format!("{} %arg_{}", self.ty(ty.clone()), sanitize_symbol(name))
            })
            .collect::<Vec<_>>()
            .join(", ");

        let mut lines = Vec::new();
        lines.push(format!(
            "define {} {}({}) {{",
            self.ty(ret_clone.clone()),
            fn_info.llvm_name,
            args
        ));
        lines.push("entry:".to_string());
        lines.extend(self.entry_allocas.clone());
        lines.extend(self.body.clone());
        lines.push("}".to_string());

        self.entry_allocas = saved_allocas;
        self.body = saved_body;
        self.vars = saved_vars;
        self.loop_stack = saved_loop_stack;
        self.current_return = saved_return;

        Ok(lines.join("\n"))
    }
}

fn string_byte_len(value: &str) -> usize {
    value.len()
}

fn escape_llvm_string(value: &str) -> String {
    let mut out = String::new();
    for byte in value.bytes() {
        match byte {
            b'\\' => out.push_str("\\5C"),
            b'"' => out.push_str("\\22"),
            b'\n' => out.push_str("\\0A"),
            b'\r' => out.push_str("\\0D"),
            b'\t' => out.push_str("\\09"),
            32..=126 => out.push(byte as char),
            _ => out.push_str(&format!("\\{:02X}", byte)),
        }
    }
    out
}

fn sanitize_symbol(value: &str) -> String {
    value
        .chars()
        .map(|ch| {
            if ch.is_ascii_alphanumeric() || ch == '_' {
                ch
            } else {
                '_'
            }
        })
        .collect()
}
