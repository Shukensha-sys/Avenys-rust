use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::PathBuf;

use crate::compiler::AnalysisSelection;
use crate::error::{MireError, Result};
use crate::incremental::analysis_unit_key;
use crate::lexer::tokenize;
use crate::parser::Parser;
use crate::parser::ast::{
    AssignmentTarget, DataType, Expression, Identifier, Literal, MireValue, Program, QueryOp,
    Statement, TraitMethodSig,
};

#[derive(Debug, Clone)]
struct FunctionSig {
    params: Vec<DataType>,
    return_type: DataType,
}

#[derive(Debug, Clone)]
struct ClassFieldSig {
    name: String,
    data_type: DataType,
    has_default: bool,
}

#[derive(Debug, Clone)]
struct ClassSig {
    fields: Vec<ClassFieldSig>,
}

#[derive(Debug, Clone)]
struct EnumVariantSig {
    payload_names: Vec<String>,
    payload_types: Vec<DataType>,
}

#[derive(Debug, Clone)]
struct TraitSig {
    methods: Vec<TraitMethodSig>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum MethodKind {
    Instance,
    Associated,
}

pub fn check_program_types(program: &mut Program, source: &str) -> Result<()> {
    let mut checker = TypeChecker::new(source);
    checker
        .collect_function_signatures(&program.statements)
        .map_err(|err| checker.attach_current_context(err))?;
    checker.check_top_level_statements(&mut program.statements)
}

pub fn check_program_types_with_origins(
    program: &mut Program,
    source: &str,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
) -> Result<()> {
    check_program_types_partial_with_origins(
        program,
        source,
        statement_origins,
        sources,
        &AnalysisSelection::full(program),
    )
}

pub fn check_program_types_partial_with_origins(
    program: &mut Program,
    source: &str,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
    selection: &AnalysisSelection,
) -> Result<()> {
    let mut checker = TypeChecker::new(source);
    checker.statement_origins = statement_origins
        .iter()
        .map(|path| path.display().to_string())
        .collect();
    checker.sources_by_filename = sources
        .iter()
        .map(|(path, source)| (path.display().to_string(), source.clone()))
        .collect();
    checker.nested_statement_masks = selection.nested_statement_masks.clone();
    checker
        .collect_function_signatures(&program.statements)
        .map_err(|err| checker.attach_current_context(err))?;
    checker.check_selected_top_level_statements(&mut program.statements, &selection.statement_mask)
}

struct TypeChecker {
    scopes: Vec<HashMap<String, (DataType, bool)>>,
    struct_scopes: Vec<HashMap<String, String>>,
    ref_scopes: Vec<HashMap<String, DataType>>,
    functions: HashMap<String, FunctionSig>,
    classes: HashMap<String, ClassSig>,
    enum_variants: HashMap<String, EnumVariantSig>,
    traits: HashMap<String, TraitSig>,
    builtin_returns: HashMap<String, DataType>,
    return_type_stack: Vec<DataType>,
    visited_libs: HashSet<String>,
    impl_self_type: Option<DataType>,
    impl_self_name: Option<String>,
    statement_origins: Vec<String>,
    sources_by_filename: HashMap<String, String>,
    base_source: Option<String>,
    current_filename: Option<String>,
    current_line: usize,
    current_column: usize,
    current_top_level_index: Option<usize>,
    current_top_level_key: Option<String>,
    nested_statement_masks: HashMap<String, Vec<bool>>,
}

impl TypeChecker {
    fn new(source: &str) -> Self {
        Self {
            scopes: vec![HashMap::new()],
            struct_scopes: vec![HashMap::new()],
            ref_scopes: vec![HashMap::new()],
            functions: HashMap::new(),
            classes: HashMap::new(),
            enum_variants: HashMap::new(),
            traits: HashMap::new(),
            builtin_returns: Self::default_builtin_returns(),
            return_type_stack: Vec::new(),
            visited_libs: HashSet::new(),
            impl_self_type: None,
            impl_self_name: None,
            statement_origins: Vec::new(),
            sources_by_filename: HashMap::new(),
            base_source: (!source.is_empty()).then(|| source.to_string()),
            current_filename: None,
            current_line: 1,
            current_column: 1,
            current_top_level_index: None,
            current_top_level_key: None,
            nested_statement_masks: HashMap::new(),
        }
    }

    fn check_top_level_statements(&mut self, statements: &mut [Statement]) -> Result<()> {
        for (index, statement) in statements.iter_mut().enumerate() {
            self.current_filename = self.statement_origins.get(index).cloned();
            self.current_top_level_index = Some(index);
            self.current_top_level_key = Some(analysis_unit_key(statement));
            self.check_statement(statement)
                .map_err(|err| self.attach_current_context(err))?;
        }
        self.current_top_level_index = None;
        self.current_top_level_key = None;
        Ok(())
    }

    fn check_selected_top_level_statements(
        &mut self,
        statements: &mut [Statement],
        statement_mask: &[bool],
    ) -> Result<()> {
        if statement_mask.len() != statements.len() {
            return Err(type_error(format!(
                "Typecheck mask length mismatch: expected {}, got {}",
                statements.len(),
                statement_mask.len()
            )));
        }

        for (index, (statement, should_check)) in statements
            .iter_mut()
            .zip(statement_mask.iter().copied())
            .enumerate()
        {
            if !should_check {
                continue;
            }

            self.current_filename = self.statement_origins.get(index).cloned();
            self.current_top_level_index = Some(index);
            self.current_top_level_key = Some(analysis_unit_key(statement));
            self.check_statement(statement)
                .map_err(|err| self.attach_current_context(err))?;
        }
        self.current_top_level_index = None;
        self.current_top_level_key = None;
        Ok(())
    }

    fn current_nested_statement_mask(&self) -> Option<&[bool]> {
        self.current_top_level_key
            .as_ref()
            .and_then(|key| self.nested_statement_masks.get(key).map(Vec::as_slice))
    }

    fn check_selected_statements(
        &mut self,
        statements: &mut [Statement],
        statement_mask: &[bool],
    ) -> Result<()> {
        if statement_mask.len() != statements.len() {
            return Err(type_error(format!(
                "Nested typecheck mask length mismatch: expected {}, got {}",
                statements.len(),
                statement_mask.len()
            )));
        }

        for (statement, should_check) in statements.iter_mut().zip(statement_mask.iter().copied()) {
            if !should_check {
                continue;
            }
            self.check_statement(statement)?;
        }

        Ok(())
    }

    fn check_container_statements(&mut self, statements: &mut [Statement]) -> Result<()> {
        if let Some(mask) = self.current_nested_statement_mask() {
            let mask = mask.to_vec();
            self.check_selected_statements(statements, &mask)
        } else {
            self.check_statements(statements)
        }
    }

    fn attach_current_context(&self, err: MireError) -> MireError {
        let err = if err.line == 1 && err.column == 1 {
            err.with_position(self.current_line, self.current_column)
        } else {
            err
        };

        let err = if err.filename().is_none() {
            if let Some(filename) = &self.current_filename {
                err.with_filename(filename.clone())
            } else {
                err
            }
        } else {
            err
        };

        if err.source().is_none() {
            if let Some(filename) = err.filename()
                && let Some(source) = self.sources_by_filename.get(filename)
            {
                return err.with_source(source.clone());
            }
            if let Some(source) = &self.base_source {
                return err.with_source(source.clone());
            }
        }

        err
    }

    fn default_builtin_returns() -> HashMap<String, DataType> {
        let mut builtins = HashMap::new();

        // ── Builtins that return None (side-effect only) ──────────────────────
        for name in [
            // Core terminal output
            "dasu",
            // Collections (mutate in-place semantics)
            "push",
            "append",
            "remove",
            // Time
            "time_sleep_ms",
            "time_sleep_ns",
            // Fs – write-side operations
            "fs_write",
            "fs_append",
            "fs_copy",
            "fs_move",
            "fs_drop",
            "fs_mkdir",
            "fs_rmdir",
            // Env – setter operations
            "env_set",
            "env_chdir",
            // Proc – side effects on process table
            "proc_kill",
            "proc_write",
            "proc_on",
            "proc_exit",
        ] {
            builtins.insert(name.to_string(), DataType::None);
        }

        // ── Builtins that return i64 ──────────────────────────────────────────
        for name in [
            "len",
            "time_now_ms",
            "time_now_ns",
            "time_since_ms",
            "time_since_ns",
            "time_mark",
            "time_elapsed_ms",
            "time_elapsed_ns",
            "time.mark",
            "time.elapsed_ns",
            "mem_used",
            "mem_total",
            "mem_free",
            "mem_available",
            "mem_process",
            "mem.process",
            "cpu_time_ns",
            "cpu_time_ms",
            "cpu_mark",
            "cpu_elapsed_ns",
            "cpu_count",
            "cpu_cycles_est",
            "cpu.cycles_est",
            "cpu.mark",
            "sum",
            "min",
            "max",
            "abs",
            "round",
            "floor",
            "ceil",
            "clamp",
            "fs_size",
            "proc_wait",
            "math.sum",
            "lists.len",
            "lists.get",
            "strings.len",
        ] {
            builtins.insert(name.to_string(), DataType::I64);
        }

        // Builtins that return list
        for name in ["lists.push", "lists.set", "lists.slice"] {
            builtins.insert(
                name.to_string(),
                DataType::Vector {
                    element_type: Box::new(DataType::Anything),
                    dynamic: true,
                },
            );
        }

        // Builtins: fold, map, filter - use Unknown for flexible handling
        for name in ["lists.fold", "lists.map", "lists.filter"] {
            builtins.insert(name.to_string(), DataType::Unknown);
        }

        // Builtins that return str
        for name in [
            "strings.replace",
            "strings.join",
            "strings.to_upper",
            "strings.to_lower",
            "strings.trim",
            "strings.concat",
            "strings.to_string",
            "strings.replace_first",
            "mem.format",
            "gpu.snapshot",
            "time.elapsed_ms",
            "cpu.elapsed_ms",
            "cpu_elapsed_ms",
        ] {
            builtins.insert(name.to_string(), DataType::Str);
        }

        // Builtins that return Vector<str>
        builtins.insert(
            "strings.split".to_string(),
            DataType::Vector {
                element_type: Box::new(DataType::Str),
                dynamic: true,
            },
        );

        // ── Builtins that return str ──────────────────────────────────────────
        for name in [
            "ireru",
            "__mire_fmt",
            "mem_format_bytes",
            // Fs content + path helpers
            "fs_read",
            "fs_join",
            "fs_dir",
            "fs_name",
            "fs_ext",
            // Env context
            "env_get",
            "env_cwd",
            // Proc output helpers
            "proc_run",
            "proc_exec",
            "proc_shell",
            "proc_exec_pipe",
            "proc_pipe",
            "proc_read",
            // String builtins
            "strings.to_upper",
            "strings.to_lower",
            "strings.trim",
            "strings.concat",
        ] {
            builtins.insert(name.to_string(), DataType::Str);
        }

        // ── Builtins that return bool ─────────────────────────────────────────
        for name in ["fs_exists", "fs_is_dir", "proc_exists", "gpu_available", "strings.starts_with", "strings.ends_with"] {
            builtins.insert(name.to_string(), DataType::Bool);
        }

        // ── Builtins that return list ─────────────────────────────────────────
        for name in ["lists.keys", "lists.values", "lists.slice", "range"] {
            builtins.insert(
                name.to_string(),
                DataType::Vector {
                    element_type: Box::new(DataType::Anything),
                    dynamic: true,
                },
            );
        }

        // fs_list returns Vector<str>
        builtins.insert(
            "fs_list".to_string(),
            DataType::Vector {
                element_type: Box::new(DataType::Str),
                dynamic: true,
            },
        );

        // env_args returns list of strings
        builtins.insert(
            "env_args".to_string(),
            DataType::Vector {
                element_type: Box::new(DataType::Str),
                dynamic: true,
            },
        );

        // ── Builtins that return dict ─────────────────────────────────────────
        for name in [
            "env_all",
            "mem_snapshot",
            "mem.snapshot",
            "cpu_loadavg",
            "cpu_snapshot",
            "cpu.snapshot",
            "gpu_snapshot",
            "dicts.set",
            "dicts.keys",
            "dicts.values",
            "dicts.to_string",
        ] {
            builtins.insert(
                name.to_string(),
                DataType::Map {
                    key_type: Box::new(DataType::Anything),
                    value_type: Box::new(DataType::Anything),
                },
            );
        }
        builtins.insert("dicts.get".to_string(), DataType::Anything);

        // ── Polymorphic / Anything builtins ───────────────────────────────────
        for name in [
            "int",
            "float",
            "bool",
            "type",
            "sort",
            "reverse",
            "unique",
            "trim",
            "ltrim",
            "rtrim",
            "substr",
            "pad_left",
            "pad_right",
            "first",
            "last",
            "slice",
            "concat",
            "flatten",
            "is_int",
            "is_float",
            "is_bool",
            "is_str",
            "is_list",
            "is_dict",
            "is_none",
            "contains",
            "index_of",
            "ram_usage",
            "mem_percent",
            "cpu_freq_mhz",
            "proc_spawn",
            "proc_exec_bg",
        ] {
            builtins.insert(name.to_string(), DataType::Anything);
        }

        builtins.insert("str".to_string(), DataType::Str);
        builtins.insert("range".to_string(), DataType::List);
        builtins.insert("call".to_string(), DataType::Unknown);
        builtins.insert("__if_expr".to_string(), DataType::Unknown);
        builtins.insert("__do_while".to_string(), DataType::None);
        builtins.insert("__type_matches".to_string(), DataType::Bool);
        builtins.insert("__is".to_string(), DataType::Bool);
        builtins.insert("new::".to_string(), DataType::Unknown);
        builtins.insert("own::".to_string(), DataType::Box);
        builtins.insert("move::".to_string(), DataType::Unknown);
        builtins.insert("drop::".to_string(), DataType::None);

        builtins
    }

    fn import_std_members(&mut self, module: &str) {
        let members: &[&str] = match module {
            "math" => &[
                "abs", "min", "max", "sum", "range", "round", "floor", "ceil", "clamp",
            ],
            "strings" => &[
                "upper",
                "lower",
                "strip",
                "split",
                "replace",
                "contains",
                "startswith",
                "endswith",
                "len",
                "trim",
                "ltrim",
                "rtrim",
                "substr",
                "pad_left",
                "pad_right",
                "repeat",
                "is_empty",
            ],
            "lists" => &[
                "len", "push", "pop", "remove", "delete", "append", "clear", "join", "contains",
                "index_of", "first", "last", "slice", "concat", "flatten", "reverse", "sort",
                "unique", "is_empty",
            ],
            "dicts" => &[
                "len", "keys", "values", "has", "get", "set", "remove", "delete", "entries",
                "merge", "is_empty",
            ],
            "time" => &[
                "unix_ms",
                "unix_ns",
                "since_ms",
                "since_ns",
                "mark",
                "elapsed_ms",
                "elapsed_ns",
                "sleep_ms",
                "sleep_ns",
            ],
            "term" => &["style", "hr", "clear"],
            "mem" => &[
                "used",
                "total",
                "free",
                "available",
                "percent",
                "process",
                "snapshot",
                "format",
            ],
            "cpu" => &[
                "time_ns",
                "time_ms",
                "mark",
                "elapsed_ns",
                "elapsed_ms",
                "count",
                "freq_mhz",
                "cycles_est",
                "loadavg",
                "snapshot",
            ],
            "gpu" => &["available", "snapshot"],
            "fs" => &[
                "read", "write", "append", "exists", "size", "copy", "move", "drop", "list",
                "mkdir", "rmdir", "join", "dir", "name", "ext",
            ],
            "env" => &["get", "set", "all", "args", "cwd", "chdir"],
            "proc" => &[
                "run", "spawn", "pipe", "shell", "read", "write", "on", "exit", "err", "exec",
                "exec_bg", "kill", "wait", "exists",
            ],
            _ => &[],
        };

        for member in members {
            self.insert_var((*member).to_string(), DataType::Anything, true);
        }
    }

    fn collect_function_signatures(&mut self, statements: &[Statement]) -> Result<()> {
        for statement in statements {
            match statement {
                Statement::Function {
                    name,
                    params,
                    return_type,
                    ..
                } => {
                    self.functions.insert(
                        name.clone(),
                        FunctionSig {
                            params: params.iter().map(|(_, t)| t.clone()).collect(),
                            return_type: return_type.clone(),
                        },
                    );
                }
                Statement::ExternFunction {
                    name,
                    params,
                    return_type,
                    ..
                } => {
                    self.functions.insert(
                        name.clone(),
                        FunctionSig {
                            params: params.iter().map(|(_, t)| t.clone()).collect(),
                            return_type: return_type.clone(),
                        },
                    );
                }
                Statement::Impl {
                    type_name, methods, ..
                } => {
                    for method in methods {
                        if let Statement::Function {
                            name,
                            params,
                            return_type,
                            ..
                        } = method
                        {
                            let mut full_params = params.clone();
                            if let Some((_, self_ty)) =
                                full_params.iter_mut().find(|(param, _)| param == "self")
                            {
                                *self_ty = DataType::StructNamed(type_name.clone());
                            }
                            self.functions.insert(
                                format!("{}.{}", type_name, name),
                                FunctionSig {
                                    params: full_params.iter().map(|(_, t)| t.clone()).collect(),
                                    return_type: return_type.clone(),
                                },
                            );
                        }
                    }
                    self.collect_function_signatures(methods)?;
                }
                Statement::Module { body, .. } => self.collect_function_signatures(body)?,
                Statement::Skill { name, methods, .. } => {
                    self.traits.insert(
                        name.clone(),
                        TraitSig {
                            methods: methods.clone(),
                        },
                    );
                }
                Statement::Trait { name, methods } => {
                    self.traits.insert(
                        name.clone(),
                        TraitSig {
                            methods: methods.clone(),
                        },
                    );
                }
                Statement::Class { name, methods, .. } => {
                    let fields = methods
                        .iter()
                        .filter_map(|statement| match statement {
                            Statement::Let {
                                name,
                                data_type,
                                value,
                                ..
                            } => Some(ClassFieldSig {
                                name: name.clone(),
                                data_type: data_type.clone(),
                                has_default: value.is_some(),
                            }),
                            _ => None,
                        })
                        .collect();
                    self.classes.insert(name.clone(), ClassSig { fields });
                    self.collect_function_signatures(methods)?
                }
                Statement::Type { name, fields, .. } => {
                    let type_fields = fields
                        .iter()
                        .filter_map(|statement| match statement {
                            Statement::Let {
                                name,
                                data_type,
                                value,
                                ..
                            } => Some(ClassFieldSig {
                                name: name.clone(),
                                data_type: data_type.clone(),
                                has_default: value.is_some(),
                            }),
                            _ => None,
                        })
                        .collect();
                    self.classes.insert(
                        name.clone(),
                        ClassSig {
                            fields: type_fields,
                        },
                    );
                    self.collect_function_signatures(fields)?
                }
                Statement::Code { .. } => {
                    // Code no longer supported
                }
                Statement::AddLib { path } => self.collect_library_signatures(path)?,
                Statement::Enum { name, variants, .. } => {
                    for variant in variants {
                        let full_name = format!("{}.{}", name, variant.name);
                        self.enum_variants.insert(
                            full_name,
                            EnumVariantSig {
                                payload_names: variant.payload_names.clone(),
                                payload_types: variant.data_types.clone(),
                            },
                        );
                    }
                    self.insert_var(name.clone(), DataType::EnumNamed(name.clone()), true);
                }
                _ => {}
            }
        }
        Ok(())
    }

    fn collect_library_signatures(&mut self, path: &str) -> Result<()> {
        if !self.visited_libs.insert(path.to_string()) {
            return Ok(());
        }

        let source = fs::read_to_string(path)
            .map_err(|err| type_error(format!("Failed to read library '{}': {}", path, err)))?;
        let tokens = tokenize(&source).map_err(|err| {
            err.with_source(source.clone())
                .with_filename(path.to_string())
        })?;
        let mut parser = Parser::new(tokens);
        let imported = parser
            .parse()
            .map_err(|err| err.with_source(source).with_filename(path.to_string()))?;
        self.collect_function_signatures(&imported.statements)
    }

    fn check_statements(&mut self, statements: &mut [Statement]) -> Result<()> {
        for statement in statements {
            self.check_statement(statement)?;
        }
        Ok(())
    }

    fn check_statement(&mut self, statement: &mut Statement) -> Result<()> {
        let (line, column) = Self::statement_location(statement);
        self.current_line = line;
        self.current_column = column;
        match statement {
            Statement::Let {
                name,
                data_type,
                value,
                is_constant: _,
                is_mutable,
                is_static: _,
                visibility: _,
            } => {
                if let Some(expr) = value
                    && let Expression::Literal(Literal::Int(int_val)) = expr
                {
                    Self::validate_int_literal_range(data_type, *int_val)?;
                }
                let inferred = if let Some(expr) = value {
                    self.check_expression(expr)?
                } else {
                    DataType::Unknown
                };

                let final_type = if *data_type == DataType::Unknown {
                    inferred
                } else {
                    if inferred != DataType::Unknown && !self.is_assignable(data_type, &inferred) {
                        return Err(type_error(format!(
                            "Type mismatch in let '{}': expected {:?}, got {:?}",
                            name, data_type, inferred
                        )));
                    }
                    if let Some(expr) = value.as_ref() {
                        Self::validate_explicit_nested_literal(data_type, expr)?;
                    }
                    data_type.clone()
                };

                *data_type = final_type.clone();
                let mutable = *is_mutable;
                self.insert_var(name.clone(), final_type, mutable);
                self.refresh_binding_metadata(name, data_type, value.as_ref());
            }
            Statement::Assignment { target, value, .. } => {
                let value_type = self.check_expression(value)?;
                let (mut target_type, is_target_mutable) = self
                    .resolve_assignment_target(target)?
                    .ok_or_else(|| type_error("Assignment to undefined variable".to_string()))?;

                if !self.is_assignable(&target_type, &value_type) {
                    return Err(type_error(format!(
                        "Type mismatch in assignment to '{}': expected {:?}, got {:?}",
                        target, target_type, value_type
                    )));
                }

                if !is_target_mutable {
                    return Err(type_error(format!(
                        "Cannot reassign immutable variable '{}'",
                        target
                    )));
                }

                match target {
                    AssignmentTarget::Field(path) => {
                        if let Some((owner, field_name)) = path.split_once('.') {
                            let (owner_type, owner_mutable) =
                                self.lookup_var(owner).ok_or_else(|| {
                                    type_error(format!(
                                        "Cannot find variable '{}' for field assignment",
                                        owner
                                    ))
                                })?;

                            if let DataType::StructNamed(ref struct_name) = owner_type
                                && let Some(class_sig) = self.classes.get(struct_name)
                            {
                                let field = class_sig
                                    .fields
                                    .iter()
                                    .find(|f| f.name == field_name)
                                    .ok_or_else(|| {
                                        type_error(format!(
                                            "Struct '{}' has no field '{}'",
                                            struct_name, field_name
                                        ))
                                    })?;

                                if !self.is_assignable(&field.data_type, &value_type) {
                                    return Err(type_error(format!(
                                        "Type mismatch for field '{}': expected {:?}, got {:?}",
                                        field_name, field.data_type, value_type
                                    )));
                                }

                                let mut new_fields: Vec<Expression> = Vec::new();
                                for f in &class_sig.fields {
                                    if f.name == field_name {
                                        new_fields.push(value.clone());
                                    } else {
                                        let field_access = Expression::MemberAccess {
                                            target: Box::new(Expression::Identifier(Identifier {
                                                name: owner.to_string(),
                                                data_type: owner_type.clone(),
                                                line: 0,
                                                column: 0,
                                            })),
                                            member: f.name.clone(),
                                            data_type: f.data_type.clone(),
                                        };
                                        new_fields.push(field_access);
                                    }
                                }

                                let struct_constructor = Expression::Call {
                                    name: struct_name.clone(),
                                    args: new_fields,
                                    data_type: owner_type.clone(),
                                };

                                self.insert_var(
                                    owner.to_string(),
                                    owner_type.clone(),
                                    owner_mutable,
                                );
                                self.refresh_binding_metadata(
                                    owner,
                                    &owner_type,
                                    Some(&struct_constructor),
                                );
                            }
                        }
                    }
                    AssignmentTarget::Index { .. } => {}
                    AssignmentTarget::Variable(name) => {
                        Self::validate_explicit_nested_literal(&target_type, value)?;

                        target_type = Self::unify_types(&target_type, &value_type)?;
                        self.insert_var(name.clone(), target_type, is_target_mutable);
                        self.refresh_binding_metadata(name, &value_type, Some(value));
                    }
                }
            }
            Statement::Function {
                name,
                params,
                body,
                return_type,
                ..
            } => {
                self.functions.insert(
                    name.clone(),
                    FunctionSig {
                        params: params.iter().map(|(_, t)| t.clone()).collect(),
                        return_type: return_type.clone(),
                    },
                );

                self.push_scope();
                for (param_name, param_type) in params.iter() {
                    self.insert_var(param_name.clone(), param_type.clone(), true);
                    self.refresh_binding_metadata(param_name, param_type, None);
                }

                self.return_type_stack.push(return_type.clone());
                self.check_statements(body)?;
                if !statements_contain_explicit_return(body)
                    && let Some(expr) = implicit_return_expression_mut(body)
                {
                    let tail_type = self.check_expression(expr)?;
                    if let Some(current) = self.return_type_stack.last_mut() {
                        let unified = Self::unify_types(current, &tail_type)?;
                        *current = unified;
                    }
                }
                let inferred_return = self.return_type_stack.pop().unwrap_or(DataType::Unknown);

                if *return_type == DataType::Unknown {
                    *return_type = inferred_return.clone();
                } else if inferred_return != DataType::Unknown
                    && !self.is_assignable(return_type, &inferred_return)
                {
                    return Err(type_error(format!(
                        "Function '{}' return type mismatch: declared {:?}, inferred {:?}",
                        name, return_type, inferred_return
                    )));
                }

                self.pop_scope();

                if let Some(sig) = self.functions.get_mut(name) {
                    sig.return_type = return_type.clone();
                }
            }
            Statement::Return(expr) => {
                let return_type = if let Some(expression) = expr {
                    self.check_expression(expression)?
                } else {
                    DataType::None
                };

                if let Some(current) = self.return_type_stack.last_mut() {
                    let unified = Self::unify_types(current, &return_type)?;
                    *current = unified;
                }
            }
            Statement::If {
                condition,
                then_branch,
                else_branch,
            } => {
                let cond_type = self.check_expression(condition)?;
                if !Self::is_bool_like(&cond_type) {
                    return Err(type_error(format!(
                        "If condition must be bool, got {:?}",
                        cond_type
                    )));
                }

                self.push_scope();
                self.check_statements(then_branch)?;
                self.pop_scope();

                if let Some(branch) = else_branch {
                    self.push_scope();
                    self.check_statements(branch)?;
                    self.pop_scope();
                }
            }
            Statement::While { condition, body } => {
                let cond_type = self.check_expression(condition)?;
                if !Self::is_bool_like(&cond_type) {
                    return Err(type_error(format!(
                        "While condition must be bool, got {:?}",
                        cond_type
                    )));
                }

                self.push_scope();
                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::For {
                variable,
                index,
                iterable,
                body,
            } => {
                let iter_type = self.check_expression(iterable)?;
                self.push_scope();

                let item_type = match iterable {
                    Expression::Call { name, .. } if name == "range" => DataType::I64,
                    _ => match iter_type {
                        DataType::Array { element_type, .. } | DataType::Slice { element_type } => {
                            *element_type
                        }
                        DataType::Tuple => DataType::Anything,
                        DataType::List => DataType::Anything,
                        DataType::Vector { element_type, .. } => *element_type,
                        DataType::Str => DataType::Str,
                        _ => DataType::Anything,
                    },
                };
                self.insert_var(variable.clone(), item_type, true);
                if let Some(index_name) = index {
                    self.insert_var(index_name.clone(), DataType::I64, true);
                }

                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::Find {
                variable,
                iterable,
                body,
            } => {
                let iter_type = self.check_expression(iterable)?;
                self.push_scope();

                let item_type = match iterable {
                    Expression::Call { name, .. } if name == "range" => DataType::I64,
                    _ => match iter_type {
                        DataType::Array { element_type, .. } | DataType::Slice { element_type } => {
                            *element_type
                        }
                        DataType::Tuple => DataType::Anything,
                        DataType::List => DataType::Anything,
                        DataType::Vector { element_type, .. } => *element_type,
                        DataType::Str => DataType::Str,
                        _ => DataType::Anything,
                    },
                };
                self.insert_var(variable.clone(), item_type, true);

                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::Expression(expr) => {
                self.check_expression(expr)?;
            }
            Statement::Match {
                value,
                cases,
                default,
            } => {
                let value_type = self.check_expression(value)?;
                self.validate_match_coverage(&value_type, cases, !default.is_empty())?;
                for (case_expr, case_body) in cases.iter_mut() {
                    if !Self::is_match_identifier_pattern(case_expr) {
                        let case_type = self.check_match_pattern(case_expr)?;
                        if value_type != DataType::Unknown
                            && case_type != DataType::Unknown
                            && !self.is_assignable(&value_type, &case_type)
                        {
                            return Err(type_error(format!(
                                "Match case type mismatch: value is {:?}, case is {:?}",
                                value_type, case_type
                            )));
                        }
                    }

                    self.push_scope();

                    self.insert_match_pattern_bindings(case_expr);

                    self.check_statements(case_body)?;
                    self.pop_scope();
                }

                self.push_scope();
                self.check_statements(default)?;
                self.pop_scope();
            }
            Statement::Unsafe { body }
            | Statement::Module { body, .. }
            | Statement::DmireTable { body, .. }
            | Statement::DmireColumn { body, .. } => {
                self.push_scope();
                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::Asm { instructions } => {
                for (_, expr) in instructions.iter_mut() {
                    self.check_expression(expr)?;
                }
            }
            Statement::Drop { value } => {
                self.check_expression(value)?;
            }
            Statement::New {
                value,
                declared_type,
            } => {
                self.validate_new_target_type(declared_type)?;
                if let Some(initial) = value {
                    let initial_ty = self.check_expression(initial)?;
                    if !self.is_assignable(declared_type, &initial_ty) {
                        return Err(type_error(format!(
                            "new:: value type mismatch: declared {:?}, got {:?}",
                            declared_type, initial_ty
                        )));
                    }
                }
            }
            Statement::Own { value, inner_type } => {
                self.validate_own_target_type(inner_type)?;
                if let Some(initial) = value {
                    let initial_ty = self.check_expression(initial)?;
                    if !self.is_assignable(inner_type, &initial_ty) {
                        return Err(type_error(format!(
                            "own:: value type mismatch: declared {:?}, got {:?}",
                            inner_type, initial_ty
                        )));
                    }
                }
            }
            Statement::Move { target, value } => {
                let moved_type = self.check_expression(value)?;
                self.insert_var(target.clone(), moved_type.clone(), true);
                self.refresh_binding_metadata(target, &moved_type, Some(value));
            }
            Statement::Query {
                ops,
                bindings,
                group_by: _,
                joins: _,
                table: _,
            } => {
                for bind in bindings.iter() {
                    self.insert_var(bind.target.clone(), DataType::Anything, true);
                    self.insert_var(bind.alias.clone(), DataType::Anything, true);
                }

                for op in ops.iter_mut() {
                    self.check_query_op(op)?;
                }
            }
            Statement::DmireDlist { data, .. } => {
                for expr in data.iter_mut() {
                    self.check_expression(expr)?;
                }
            }
            Statement::Class { methods, .. } => self.check_container_statements(methods)?,
            Statement::Impl {
                trait_name,
                type_name,
                methods,
            } => {
                self.validate_impl_method_declarations(type_name, methods)?;
                if let Some(trait_name) = trait_name {
                    self.validate_trait_impl(trait_name, type_name, methods)?;
                }
                let old_self = self.impl_self_type.take();
                let old_self_name = self.impl_self_name.take();
                let method_mask = self
                    .current_nested_statement_mask()
                    .map(|mask| mask.to_vec());

                for (method_index, method) in methods.iter_mut().enumerate() {
                    if method_mask
                        .as_ref()
                        .and_then(|mask| mask.get(method_index))
                        .is_some_and(|should_check| !should_check)
                    {
                        continue;
                    }
                    let has_self = matches!(
                        method,
                        Statement::Function { params, .. }
                            if params.iter().any(|(param_name, _)| param_name == "self")
                    );
                    self.impl_self_type =
                        has_self.then(|| DataType::StructNamed(type_name.clone()));
                    self.impl_self_name = has_self.then(|| type_name.clone());
                    self.check_statement(method)?;
                }

                self.impl_self_type = old_self;
                self.impl_self_name = old_self_name;
            }
            Statement::Type { fields, .. } => self.check_container_statements(fields)?,
            Statement::Code { methods, .. } => self.check_container_statements(methods)?,
            Statement::Skill { name, methods } => {
                if methods.is_empty() {
                    return Err(type_error(format!(
                        "Skill '{}' must declare at least one method",
                        name
                    )));
                }
                self.validate_trait_method_declarations(name, methods, "Skill")?;
            }
            Statement::Trait { name, methods } => {
                self.validate_trait_method_declarations(name, methods, "Trait")?;
            }
            Statement::Break
            | Statement::Continue
            | Statement::ExternLib { .. }
            | Statement::ExternFunction { .. }
            | Statement::Enum { .. } => {}
            Statement::AddLib { .. } => {}
            Statement::Use { path, .. } => {
                if path == "__std_all__" {
                    for module in ["math", "term", "strings", "lists", "dicts", "time"] {
                        self.import_std_members(module);
                    }
                } else if let Some(rest) = path.strip_prefix("stdall:") {
                    self.import_std_members(rest);
                } else if let Some(rest) = path.strip_prefix("stdselect:") {
                    if let Some((_, items)) = rest.split_once(':') {
                        for item in items.split(',').filter(|item| !item.is_empty()) {
                            self.insert_var(item.to_string(), DataType::Anything, true);
                        }
                    }
                } else if let Some(rest) = path.strip_prefix("stdalias:") {
                    if let Some((alias, _)) = rest.split_once(':') {
                        self.insert_var(alias.to_string(), DataType::Anything, true);
                    }
                } else if let Some(rest) = path.strip_prefix("stdaliasselect:") {
                    let mut parts = rest.splitn(3, ':');
                    if let Some(alias) = parts.next() {
                        self.insert_var(alias.to_string(), DataType::Anything, true);
                    }
                }
            }
        }

        Ok(())
    }

    fn check_query_op(&mut self, op: &mut QueryOp) -> Result<()> {
        match op {
            QueryOp::Insert { assigns } => {
                for (_, expr) in assigns.iter_mut() {
                    self.check_expression(expr)?;
                }
            }
            QueryOp::Update { condition, assigns } => {
                let cond_type = self.check_expression(condition)?;
                if !Self::is_bool_like(&cond_type) {
                    return Err(type_error(format!(
                        "Query update condition must be bool, got {:?}",
                        cond_type
                    )));
                }
                for (_, expr) in assigns.iter_mut() {
                    self.check_expression(expr)?;
                }
            }
            QueryOp::Delete { condition } => {
                let cond_type = self.check_expression(condition)?;
                if !Self::is_bool_like(&cond_type) {
                    return Err(type_error(format!(
                        "Query delete condition must be bool, got {:?}",
                        cond_type
                    )));
                }
            }
            QueryOp::Get(get) => {
                let cond_type = self.check_expression(&mut get.condition)?;
                if !Self::is_bool_like(&cond_type) {
                    return Err(type_error(format!(
                        "Query get condition must be bool, got {:?}",
                        cond_type
                    )));
                }

                self.push_scope();
                self.insert_var(get.target.clone(), DataType::Anything, true);
                self.check_statements(&mut get.body)?;
                self.pop_scope();
            }
            QueryOp::Export { .. } | QueryOp::Import { .. } => {}
        }

        Ok(())
    }

    fn check_expression(&mut self, expression: &mut Expression) -> Result<DataType> {
        let (line, column) = Self::expression_location(expression);
        self.current_line = line;
        self.current_column = column;
        match expression {
            Expression::Literal(lit) => Ok(Self::literal_type(lit)),
            Expression::Identifier(ident) => {
                let (resolved, _) = self.lookup_var(&ident.name).ok_or_else(|| {
                    type_error_at(
                        ident.line,
                        ident.column,
                        format!("Unknown identifier '{}'", ident.name),
                    )
                })?;
                ident.data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::BinaryOp {
                operator,
                left,
                right,
                data_type,
            } => {
                let left_type = if Self::is_logical_operator(operator) {
                    self.check_expression_allow_unknown_identifier(left)?
                } else {
                    self.check_expression(left)?
                };
                let right_type = if Self::is_logical_operator(operator) {
                    self.check_expression_allow_unknown_identifier(right)?
                } else {
                    self.check_expression(right)?
                };
                let resolved = self.resolve_binary_type(operator, &left_type, &right_type)?;
                *data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::UnaryOp {
                operator,
                operand,
                data_type,
            } => {
                let operand_type = self.check_expression(operand)?;
                let resolved = match operator.as_str() {
                    "-" if Self::is_numeric(&operand_type) => operand_type,
                    "!" if Self::is_bool_like(&operand_type) => DataType::Bool,
                    "-" => {
                        return Err(type_error(format!(
                            "Unary '-' requires numeric operand, got {:?}",
                            operand_type
                        )));
                    }
                    _ => DataType::Unknown,
                };
                *data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::NamedArg {
                value, data_type, ..
            } => {
                let resolved = self.check_expression(value)?;
                *data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::Call {
                name,
                args,
                data_type,
            } => {
                // `ireru(...) :Type` propagates the explicit type annotation to the call node.
                if name == "ireru" && *data_type != DataType::Unknown {
                    *data_type = data_type.clone();
                    return Ok(data_type.clone());
                }

                // Handle lists.fold/map/filter specially - check args in custom order
                if name == "lists.fold" || name == "lists.map" || name == "lists.filter" {
                    return self.check_list_hof(name, args, data_type);
                }

                let arg_types: Vec<DataType> = args
                    .iter_mut()
                    .map(|arg| self.check_expression(arg))
                    .collect::<Result<_>>()?;

                if name == "__if_expr" {
                    if args.len() != 3 {
                        return Err(type_error(
                            "__if_expr expects condition, then branch, and else branch".to_string(),
                        ));
                    }

                    let cond_type = arg_types.first().cloned().unwrap_or(DataType::Unknown);
                    if !Self::is_bool_like(&cond_type) {
                        return Err(type_error(format!(
                            "If expression condition must be bool, got {:?}",
                            cond_type
                        )));
                    }

                    let then_type = Self::closure_return_type(&args[1], "__if_expr then")?;
                    let else_type = Self::closure_return_type(&args[2], "__if_expr else")?;
                    let resolved = Self::unify_types(&then_type, &else_type)?;
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "new::" {
                    if args.is_empty() {
                        if *data_type == DataType::Unknown {
                            return Err(type_error(
                                "new::() requires a type annotation (:T)".to_string(),
                            ));
                        }
                        return Ok(data_type.clone());
                    }
                    if args.len() == 1 {
                        *data_type = arg_types[0].clone();
                        return Ok(arg_types[0].clone());
                    }
                }

                if name == "own::" {
                    if args.is_empty() {
                        if *data_type == DataType::Unknown {
                            return Err(type_error(
                                "own::() requires a type annotation (:T)".to_string(),
                            ));
                        }
                        *data_type = DataType::Box;
                        return Ok(DataType::Box);
                    }
                    if args.len() == 1 {
                        *data_type = DataType::Box;
                        return Ok(DataType::Box);
                    }
                }

                if name == "move::" {
                    if let Some(first) = arg_types.first() {
                        *data_type = first.clone();
                        return Ok(first.clone());
                    }
                }

                if name == "drop::" {
                    *data_type = DataType::None;
                    return Ok(DataType::None);
                }

                if let Some(resolved) = self.resolve_instance_method_call(name, &arg_types)? {
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "dicts.get" {
                    let resolved = match arg_types.first().cloned().unwrap_or(DataType::Unknown) {
                        DataType::Map { value_type, .. } => *value_type,
                        DataType::Dict => arg_types.get(2).cloned().unwrap_or(DataType::Anything),
                        _ => arg_types.get(2).cloned().unwrap_or(DataType::Anything),
                    };
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "dicts.set" {
                    let key_type = arg_types.get(1).cloned().unwrap_or(DataType::Anything);
                    let value_type = arg_types.get(2).cloned().unwrap_or(DataType::Anything);
                    let resolved = match arg_types.first().cloned().unwrap_or(DataType::Unknown) {
                        DataType::Map {
                            key_type,
                            value_type: existing_value,
                        } => DataType::Map {
                            key_type,
                            value_type: Box::new(Self::unify_types(&existing_value, &value_type)?),
                        },
                        _ => DataType::Map {
                            key_type: Box::new(key_type),
                            value_type: Box::new(value_type),
                        },
                    };
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "lists.get" {
                    let arg_type = arg_types.first().cloned().unwrap_or(DataType::Unknown);
                    let resolved = match arg_type {
                        DataType::Vector { element_type, .. } => *element_type,
                        DataType::List => DataType::Anything,
                        DataType::Unknown => DataType::Anything,
                        DataType::Anything => DataType::Anything,
                        other => {
                            return Err(type_error(format!(
                                "lists.get expects vec/vec! input, got {:?}",
                                other
                            )));
                        }
                    };
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "lists.push" {
                    let list_type = arg_types.first().cloned().unwrap_or(DataType::Unknown);
                    let value_type = arg_types.get(1).cloned().unwrap_or(DataType::Unknown);
                    let resolved = match list_type {
                        DataType::Vector {
                            element_type,
                            dynamic: true,
                        } => DataType::Vector {
                            element_type: Box::new(Self::unify_types(&element_type, &value_type)?),
                            dynamic: true,
                        },
                        DataType::Vector {
                            dynamic: false,
                            element_type,
                        } => DataType::Vector {
                            element_type: Box::new(Self::unify_types(&element_type, &value_type)?),
                            dynamic: true,
                        },
                        DataType::List => DataType::Vector {
                            element_type: Box::new(value_type),
                            dynamic: true,
                        },
                        DataType::Unknown => DataType::Vector {
                            element_type: Box::new(value_type),
                            dynamic: true,
                        },
                        other => {
                            return Err(type_error(format!(
                                "lists.push expects vec![T], got {:?}",
                                other
                            )));
                        }
                    };
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if name == "lists.slice" {
                    let list_type = arg_types.first().cloned().unwrap_or(DataType::Unknown);
                    let resolved = match list_type {
                        DataType::Vector { element_type, .. } => DataType::Vector {
                            element_type: element_type.clone(),
                            dynamic: true,
                        },
                        DataType::List => DataType::Vector {
                            element_type: Box::new(DataType::Unknown),
                            dynamic: true,
                        },
                        other => {
                            return Err(type_error(format!(
                                "lists.slice expects vector input, got {:?}",
                                other
                            )));
                        }
                    };
                    *data_type = resolved.clone();
                    return Ok(resolved);
                }

                if let Some(sig) = self.functions.get(name).cloned() {
                    if sig.params.len() != arg_types.len() {
                        return Err(type_error(format!(
                            "Function '{}' expects {} arguments, got {}",
                            name,
                            sig.params.len(),
                            arg_types.len()
                        )));
                    }

                    for (idx, (expected, actual)) in
                        sig.params.iter().zip(arg_types.iter()).enumerate()
                    {
                        if !self.is_assignable(expected, actual) {
                            return Err(type_error(format!(
                                "Function '{}' argument {} expects {:?}, got {:?}",
                                name,
                                idx + 1,
                                expected,
                                actual
                            )));
                        }
                    }

                    *data_type = sig.return_type.clone();
                    return Ok(sig.return_type);
                }

                if let Some(ret) = self.builtin_returns.get(name).cloned() {
                    *data_type = ret.clone();
                    return Ok(ret);
                }

                if let Some(rest) = name.strip_prefix("std.")
                    && let Some(ret) = self.builtin_returns.get(rest).cloned()
                {
                    *data_type = ret.clone();
                    return Ok(ret);
                }

                // Check class constructors BEFORE enum variants.
                // Associated methods use `Type::method(...)`, while direct constructors
                // still use `(Type field: value, ...)`.
                if let Some(class_sig) = self.classes.get(name).cloned() {
                    self.check_class_constructor_call(name, &class_sig, args, &arg_types)?;
                    *data_type = DataType::StructNamed(name.clone());
                    return Ok(DataType::StructNamed(name.clone()));
                }

                if let Some(variant_sig) = self.enum_variants.get(name).cloned() {
                    self.check_enum_variant_call(name, &variant_sig, &arg_types)?;
                    let enum_name = name
                        .split_once('.')
                        .map(|(enum_name, _)| enum_name.to_string())
                        .unwrap_or_else(|| name.clone());
                    *data_type = DataType::EnumNamed(enum_name.clone());
                    return Ok(DataType::EnumNamed(enum_name));
                }

                Err(type_error(format!("Unknown function '{}'", name)))
            }
            Expression::List {
                elements,
                element_type,
                data_type,
            } => {
                if let DataType::Vector { dynamic: true, .. } = data_type.clone() {
                    return Ok(data_type.clone());
                }
                if let DataType::Array { .. } = data_type.clone() {
                    return Ok(data_type.clone());
                }
                let mut current = DataType::Unknown;
                for element in elements.iter_mut() {
                    let elem_type = self.check_expression(element)?;
                    current = Self::unify_types(&current, &elem_type)?;
                }
                *element_type = current.clone();
                *data_type = DataType::Vector {
                    element_type: Box::new(current.clone()),
                    dynamic: false,
                };
                Ok(data_type.clone())
            }
            Expression::Dict {
                entries,
                key_type,
                value_type,
                data_type,
            } => {
                if let DataType::Map { .. } = data_type.clone() {
                    return Ok(data_type.clone());
                }
                let mut kt = DataType::Unknown;
                let mut vt = DataType::Unknown;
                for (key, value) in entries.iter_mut() {
                    let next_key = self.check_expression(key)?;
                    let next_value = self.check_expression(value)?;
                    kt = Self::unify_types(&kt, &next_key)?;
                    vt = Self::unify_types(&vt, &next_value)?;
                }
                *key_type = kt.clone();
                *value_type = vt.clone();
                *data_type = DataType::Map {
                    key_type: Box::new(kt),
                    value_type: Box::new(vt),
                };
                Ok(data_type.clone())
            }
            Expression::Tuple {
                elements,
                data_type,
            } => {
                for element in elements.iter_mut() {
                    self.check_expression(element)?;
                }
                *data_type = DataType::Tuple;
                Ok(DataType::Tuple)
            }
            Expression::Index {
                target,
                index,
                data_type,
            } => {
                let target_type = self.check_expression(target)?;
                let index_type = self.check_expression(index)?;

                if !Self::is_numeric(&index_type)
                    && !matches!(target_type, DataType::Dict)
                    && index_type != DataType::Unknown
                {
                    return Err(type_error(format!(
                        "Index must be numeric for {:?}, got {:?}",
                        target_type, index_type
                    )));
                }

                let resolved = match target_type {
                    DataType::Array { element_type, .. } | DataType::Slice { element_type } => {
                        *element_type
                    }
                    DataType::Str => DataType::Str,
                    DataType::Vector { element_type, .. } => *element_type,
                    DataType::List | DataType::Tuple | DataType::Dict => DataType::Anything,
                    DataType::Map { value_type, .. } => *value_type,
                    DataType::Unknown => DataType::Unknown,
                    other => {
                        return Err(type_error(format!("Type {:?} is not indexable", other)));
                    }
                };

                *data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::MemberAccess {
                target,
                member,
                data_type,
            } => {
                let target_type = self.check_expression(target)?;
                if target_type.is_struct_like() {
                    if let Some(struct_name) = self
                        .struct_name_for_expr(target)
                        .or_else(|| target_type.struct_name().map(ToOwned::to_owned))
                    {
                        if let Some(class_sig) = self.classes.get(&struct_name)
                            && let Some(field) = class_sig.fields.iter().find(|f| f.name == *member)
                        {
                            *data_type = field.data_type.clone();
                            return Ok(field.data_type.clone());
                        }
                        if let Some(fn_sig) =
                            self.functions.get(&format!("{}.{}", struct_name, member))
                        {
                            *data_type = fn_sig.return_type.clone();
                            return Ok(fn_sig.return_type.clone());
                        }
                        return Err(type_error(format!(
                            "Struct '{}' has no field or method '{}'",
                            struct_name, member
                        )));
                    }
                    return Err(type_error(format!(
                        "Cannot resolve concrete struct type for member access '.{}'",
                        member
                    )));
                }
                if matches!(target_type, DataType::Anything) {
                    *data_type = DataType::Anything;
                    return Ok(DataType::Anything);
                }
                if matches!(target_type, DataType::Unknown) {
                    return Err(type_error(format!(
                        "Cannot access member '{}' on unknown type - type not determined",
                        member
                    )));
                }
                Err(type_error(format!(
                    "Type {:?} has no member '{}'",
                    target_type, member
                )))
            }
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                data_type,
            } => {
                let full_name = format!("{}.{}", enum_name, variant_name);
                if !self.enum_variants.contains_key(&full_name) {
                    return Err(type_error(format!("Unknown enum variant '{}'", full_name)));
                }
                *data_type = DataType::EnumNamed(enum_name.clone());
                Ok(DataType::EnumNamed(enum_name.clone()))
            }
            Expression::EnumVariant {
                enum_name,
                variant_name,
                payloads,
                data_type,
            } => {
                let full_name = format!("{}.{}", enum_name, variant_name);
                let variant_sig =
                    self.enum_variants.get(&full_name).cloned().ok_or_else(|| {
                        type_error(format!("Unknown enum variant '{}'", full_name))
                    })?;
                self.normalize_enum_variant_payloads(&full_name, &variant_sig, payloads)?;
                *data_type = DataType::EnumNamed(enum_name.clone());
                Ok(DataType::EnumNamed(enum_name.clone()))
            }
            Expression::Closure {
                params,
                body,
                return_type,
                capture,
            } => {
                self.push_scope();

                for (name, value) in capture.iter() {
                    self.insert_var(name.clone(), Self::mire_value_type(value), true);
                }

                for (name, ptype) in params.iter() {
                    self.insert_var(name.clone(), ptype.clone(), true);
                }

                self.return_type_stack.push(return_type.clone());
                self.check_statements(body)?;
                let inferred_return = self.return_type_stack.pop().unwrap_or(DataType::Unknown);

                if *return_type == DataType::Unknown {
                    *return_type = inferred_return;
                }

                self.pop_scope();
                Ok(DataType::Function)
            }
            Expression::Reference {
                expr,
                is_mutable,
                data_type,
                referenced_type,
            } => {
                let target_type = self.check_expression(expr)?;
                let target_is_mutable = self.reference_target_is_mutable(expr);
                if *is_mutable && !target_is_mutable {
                    return Err(type_error(
                        "Cannot take mutable reference from immutable target".to_string(),
                    ));
                }
                *is_mutable = target_is_mutable;
                *referenced_type = target_type.clone();
                *data_type = if target_is_mutable {
                    DataType::RefMut {
                        inner: Box::new(target_type.clone()),
                    }
                } else {
                    DataType::Ref {
                        inner: Box::new(target_type.clone()),
                    }
                };
                Ok(data_type.clone())
            }
            Expression::Dereference { expr, data_type } => {
                let inner = self.check_expression(expr)?;
                let resolved = match inner {
                    DataType::Ref { .. } | DataType::RefMut { .. } => self
                        .referenced_type_for_expr(expr)
                        .unwrap_or(DataType::Unknown),
                    DataType::Unknown => DataType::Unknown,
                    other => {
                        return Err(type_error(format!(
                            "Cannot dereference non-reference type {:?}",
                            other
                        )));
                    }
                };
                *data_type = resolved.clone();
                Ok(resolved)
            }
            Expression::Box { value, data_type } => {
                self.check_expression(value)?;
                *data_type = DataType::Box;
                Ok(DataType::Box)
            }
            Expression::Pipeline {
                input,
                stage,
                safe,
                data_type,
            } => {
                let input_type = self.check_expression(input)?;
                let resolved = if let Expression::Closure {
                    params,
                    body,
                    return_type,
                    capture,
                } = stage.as_mut()
                {
                    let elem_type = self.pipeline_input_element_type(&input_type);
                    self.push_scope();
                    for (name, value) in capture.iter() {
                        self.insert_var(name.clone(), Self::mire_value_type(value), true);
                    }
                    if let Some((_, ptype)) = params.first_mut()
                        && *ptype == DataType::Unknown
                    {
                        *ptype = elem_type.clone();
                    }
                    for (name, ptype) in params.iter() {
                        self.insert_var(name.clone(), ptype.clone(), true);
                    }
                    self.return_type_stack.push(return_type.clone());
                    self.check_statements(body)?;
                    if !statements_contain_explicit_return(body)
                        && let Some(expr) = implicit_return_expression_mut(body)
                    {
                        let tail_type = self.check_expression(expr)?;
                        if let Some(current) = self.return_type_stack.last_mut() {
                            *current = Self::unify_types(current, &tail_type)?;
                        }
                    }
                    let inferred_return = self.return_type_stack.pop().unwrap_or(DataType::Unknown);
                    if *return_type == DataType::Unknown {
                        if inferred_return == DataType::Unknown {
                            return Err(type_error(
                                "Pipeline stage return type cannot be inferred - closure must return a value".to_string(),
                            ));
                        }
                        *return_type = inferred_return.clone();
                    }
                    self.pop_scope();
                    DataType::Vector {
                        element_type: Box::new(if *return_type == DataType::Unknown {
                            return Err(type_error(
                                    "Cannot determine pipeline output element type - specify return type in closure".to_string(),
                                ));
                        } else {
                            return_type.clone()
                        }),
                        dynamic: true,
                    }
                } else if let Some(stage_type) =
                    self.resolve_pipeline_stage_type(stage.as_mut(), &input_type)?
                {
                    stage_type
                } else {
                    let stage_check = self.check_expression(stage)?;
                    if stage_check == DataType::Unknown {
                        return Err(type_error(
                            "Pipeline stage has unknown type - cannot infer output type"
                                .to_string(),
                        ));
                    }
                    stage_check
                };
                let _ = safe;
                if *data_type == DataType::Unknown {
                    *data_type = resolved.clone();
                } else if resolved != DataType::Unknown && !self.is_assignable(data_type, &resolved)
                {
                    return Err(type_error(format!(
                        "Pipeline type mismatch: expected {:?}, got {:?}",
                        data_type, resolved
                    )));
                }
                Ok(data_type.clone())
            }
            Expression::Match {
                value,
                cases,
                default,
                data_type,
            } => {
                let value_type = self.check_expression(value)?;
                self.validate_match_expr_coverage(&value_type, cases, default)?;
                let mut resolved_type = DataType::Unknown;
                for (case_expr, case_body) in cases.iter_mut() {
                    if !Self::is_match_identifier_pattern(case_expr) {
                        let _ = self.check_match_pattern(case_expr)?;
                    }

                    self.push_scope();

                    self.insert_match_pattern_bindings(case_expr);

                    let case_type = self.check_expression(case_body)?;
                    self.pop_scope();
                    resolved_type = Self::unify_types(&resolved_type, &case_type)?;
                }

                // Only unify with default if it's not the implicit None placeholder
                let is_implicit_default =
                    matches!(default.as_ref(), Expression::Literal(Literal::None));
                if !is_implicit_default {
                    let default_type = self.check_expression(default)?;
                    resolved_type = Self::unify_types(&resolved_type, &default_type)?;
                }

                if *data_type == DataType::Unknown {
                    *data_type = resolved_type.clone();
                } else if resolved_type != DataType::Unknown
                    && !self.is_assignable(data_type, &resolved_type)
                {
                    return Err(type_error(format!(
                        "Match expression type mismatch: expected {:?}, got {:?}",
                        data_type, resolved_type
                    )));
                }
                Ok(data_type.clone())
            }
        }
    }

    fn validate_new_target_type(&self, declared_type: &DataType) -> Result<()> {
        if matches!(
            declared_type,
            DataType::Array { .. } | DataType::Vector { .. } | DataType::Map { .. }
        ) {
            return Ok(());
        }

        Err(type_error(format!(
            "new:: only supports arr/vec/map targets, got {:?}",
            declared_type
        )))
    }

    fn validate_own_target_type(&self, inner_type: &DataType) -> Result<()> {
        if matches!(
            inner_type,
            DataType::I8
                | DataType::I16
                | DataType::I32
                | DataType::I64
                | DataType::U8
                | DataType::U16
                | DataType::U32
                | DataType::U64
                | DataType::F32
                | DataType::F64
                | DataType::Bool
                | DataType::Char
                | DataType::Str
                | DataType::Struct
                | DataType::StructNamed(_)
                | DataType::Enum
                | DataType::EnumNamed(_)
                | DataType::Array { .. }
                | DataType::Vector { .. }
                | DataType::Map { .. }
        ) {
            return Ok(());
        }

        Err(type_error(format!(
            "own:: target type {:?} is not heap-allocatable",
            inner_type
        )))
    }

    fn variant_name_from_match_pattern<'a>(
        &'a self,
        pattern: &'a Expression,
        expected_enum: &str,
    ) -> Result<Option<&'a str>> {
        match pattern {
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                ..
            }
            | Expression::EnumVariant {
                enum_name,
                variant_name,
                ..
            } => {
                if enum_name != expected_enum {
                    return Err(type_error(format!(
                        "Match pattern enum mismatch: expected '{}', got '{}'",
                        expected_enum, enum_name
                    )));
                }
                Ok(Some(variant_name.as_str()))
            }
            _ => Ok(None),
        }
    }

    fn enum_variant_names_for(&self, enum_name: &str) -> Vec<String> {
        let prefix = format!("{enum_name}.");
        self.enum_variants
            .keys()
            .filter_map(|full| full.strip_prefix(&prefix).map(ToOwned::to_owned))
            .collect()
    }

    fn validate_match_coverage(
        &self,
        value_type: &DataType,
        cases: &[(Expression, Vec<Statement>)],
        has_default: bool,
    ) -> Result<()> {
        let DataType::EnumNamed(enum_name) = value_type else {
            return Ok(());
        };

        let mut covered = std::collections::HashSet::new();
        for (pattern, _) in cases {
            if let Some(variant_name) = self.variant_name_from_match_pattern(pattern, enum_name)? {
                if !covered.insert(variant_name.to_string()) {
                    return Err(type_error(format!(
                        "Duplicate match arm for enum variant '{}.{}'",
                        enum_name, variant_name
                    )));
                }
            }
        }

        if has_default {
            return Ok(());
        }

        let all = self.enum_variant_names_for(enum_name);
        let missing: Vec<String> = all.into_iter().filter(|name| !covered.contains(name)).collect();
        if missing.is_empty() {
            return Ok(());
        }

        Err(type_error(format!(
            "Non-exhaustive match for enum '{}'; missing variants: {}",
            enum_name,
            missing.join(", ")
        )))
    }

    fn validate_match_expr_coverage(
        &self,
        value_type: &DataType,
        cases: &[(Expression, Expression)],
        default: &Expression,
    ) -> Result<()> {
        let DataType::EnumNamed(enum_name) = value_type else {
            return Ok(());
        };

        let mut covered = std::collections::HashSet::new();
        for (pattern, _) in cases {
            if let Some(variant_name) = self.variant_name_from_match_pattern(pattern, enum_name)? {
                if !covered.insert(variant_name.to_string()) {
                    return Err(type_error(format!(
                        "Duplicate match arm for enum variant '{}.{}'",
                        enum_name, variant_name
                    )));
                }
            }
        }

        let has_default = !matches!(default, Expression::Literal(Literal::None));
        if has_default {
            return Ok(());
        }

        let all = self.enum_variant_names_for(enum_name);
        let missing: Vec<String> = all.into_iter().filter(|name| !covered.contains(name)).collect();
        if missing.is_empty() {
            return Ok(());
        }

        Err(type_error(format!(
            "Non-exhaustive match expression for enum '{}'; missing variants: {}",
            enum_name,
            missing.join(", ")
        )))
    }

    fn resolve_binary_type(
        &self,
        operator: &str,
        left: &DataType,
        right: &DataType,
    ) -> Result<DataType> {
        match operator {
            "+" | "-" | "*" | "/" | "%" => {
                if operator == "+" && left == &DataType::Str && right == &DataType::Str {
                    return Ok(DataType::Str);
                }

                if operator == "+" {
                    match (left, right) {
                        (
                            DataType::Vector {
                                element_type: l_elem,
                                dynamic: l_dyn,
                            },
                            DataType::Vector {
                                element_type: r_elem,
                                dynamic: r_dyn,
                            },
                        ) => {
                            let unified_elem = Self::unify_types(l_elem, r_elem)?;
                            return Ok(DataType::Vector {
                                element_type: Box::new(unified_elem),
                                dynamic: *l_dyn || *r_dyn,
                            });
                        }
                        (DataType::Vector { .. }, DataType::List)
                        | (DataType::List, DataType::Vector { .. })
                        | (DataType::List, DataType::List) => {
                            return Ok(DataType::Vector {
                                element_type: Box::new(DataType::Unknown),
                                dynamic: true,
                            });
                        }
                        _ => {}
                    }
                }

                if Self::is_numeric(left) && Self::is_numeric(right) {
                    return Ok(Self::promote_numeric(left, right));
                }

                Err(type_error(format!(
                    "Operator '{}' not supported for {:?} and {:?}",
                    operator, left, right
                )))
            }
            "==" | "!=" | "<" | "<=" | ">" | ">=" => Ok(DataType::Bool),
            "&&" | "||" => {
                if left == &DataType::Unknown || right == &DataType::Unknown {
                    return Ok(DataType::Bool);
                }
                if Self::is_bool_like(left) && Self::is_bool_like(right) {
                    Ok(DataType::Bool)
                } else {
                    Err(type_error(format!(
                        "Logical operator '{}' requires bool operands, got {:?} and {:?}",
                        operator, left, right
                    )))
                }
            }
            "^" => {
                if left == &DataType::Unknown || right == &DataType::Unknown {
                    return Ok(DataType::Unknown);
                }
                if Self::is_bool_like(left) && Self::is_bool_like(right) {
                    Ok(DataType::Bool)
                } else if Self::is_integer_type(left) && Self::is_integer_type(right) {
                    Ok(left.clone())
                } else {
                    Err(type_error(format!(
                        "XOR operator '^' requires either bool or integer operands, got {:?} and {:?}",
                        left, right
                    )))
                }
            }
            "&" | "|" | "<<" | ">>" => {
                if left == &DataType::Unknown || right == &DataType::Unknown {
                    return Ok(DataType::Unknown);
                }
                if Self::is_integer_type(left) && Self::is_integer_type(right) {
                    Ok(left.clone())
                } else {
                    Err(type_error(format!(
                        "Bitwise operator '{}' requires integer operands, got {:?} and {:?}",
                        operator, left, right
                    )))
                }
            }
            _ => Ok(DataType::Unknown),
        }
    }

    fn is_integer_type(ty: &DataType) -> bool {
        matches!(
            ty,
            DataType::I64
                | DataType::I32
                | DataType::I16
                | DataType::I8
                | DataType::U64
                | DataType::U32
                | DataType::U16
                | DataType::U8
        )
    }

    fn check_expression_allow_unknown_identifier(
        &mut self,
        expression: &mut Expression,
    ) -> Result<DataType> {
        match expression {
            Expression::Identifier(ident) => {
                if let Some((resolved, _)) = self.lookup_var(&ident.name) {
                    ident.data_type = resolved.clone();
                    Ok(resolved)
                } else {
                    ident.data_type = DataType::Unknown;
                    Ok(DataType::Unknown)
                }
            }
            Expression::BinaryOp {
                operator,
                left,
                right,
                data_type,
            } if Self::is_logical_operator(operator) => {
                let left_type = self.check_expression_allow_unknown_identifier(left)?;
                let right_type = self.check_expression_allow_unknown_identifier(right)?;
                let resolved = self.resolve_binary_type(operator, &left_type, &right_type)?;
                *data_type = resolved.clone();
                Ok(resolved)
            }
            _ => self.check_expression(expression),
        }
    }

    fn is_logical_operator(operator: &str) -> bool {
        matches!(operator, "&&" | "||")
    }

    fn is_match_identifier_pattern(expression: &Expression) -> bool {
        matches!(expression, Expression::Identifier(_))
    }

    fn literal_type(lit: &Literal) -> DataType {
        match lit {
            Literal::Int(_) => DataType::I64,
            Literal::Float(_) => DataType::F64,
            Literal::Char(_) => DataType::Char,
            Literal::Str(_) => DataType::Str,
            Literal::Bool(_) => DataType::Bool,
            Literal::None => DataType::None,
            Literal::List(_) => DataType::Vector {
                element_type: Box::new(DataType::Unknown),
                dynamic: false,
            },
            Literal::Dict(_) => DataType::Map {
                key_type: Box::new(DataType::Unknown),
                value_type: Box::new(DataType::Unknown),
            },
            Literal::Tuple(_) => DataType::Tuple,
        }
    }

    fn validate_int_literal_range(data_type: &DataType, value: i64) -> Result<()> {
        match data_type {
            DataType::I8 if (!(-128..=127).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds i8 range (-128 to 127)",
                    value
                )));
            }
            DataType::I16 if (!(-32768..=32767).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds i16 range (-32768 to 32767)",
                    value
                )));
            }
            DataType::I32 if (!(-2147483648..=2147483647).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds i32 range (-2147483648 to 2147483647)",
                    value
                )));
            }
            DataType::U8 if (!(0..=255).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds u8 range (0 to 255)",
                    value
                )));
            }
            DataType::U16 if (!(0..=65535).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds u16 range (0 to 65535)",
                    value
                )));
            }
            DataType::U32 if (!(0..=4294967295).contains(&value)) => {
                return Err(type_error(format!(
                    "Integer literal {} exceeds u32 range (0 to 4294967295)",
                    value
                )));
            }
            _ => {}
        }
        Ok(())
    }

    fn mire_value_type(value: &MireValue) -> DataType {
        match value {
            MireValue::I8(_) => DataType::I8,
            MireValue::I16(_) => DataType::I16,
            MireValue::I32(_) => DataType::I32,
            MireValue::I64(_) => DataType::I64,
            MireValue::U8(_) => DataType::U8,
            MireValue::U16(_) => DataType::U16,
            MireValue::U32(_) => DataType::U32,
            MireValue::U64(_) => DataType::U64,
            MireValue::Float(_) => DataType::F64,
            MireValue::F64(_) => DataType::F64,
            MireValue::F32(_) => DataType::F32,
            MireValue::Str(_) => DataType::Str,
            MireValue::Bool(_) => DataType::Bool,
            MireValue::None => DataType::None,
            MireValue::List(values) => {
                let element_type = values
                    .first()
                    .map(Self::mire_value_type)
                    .unwrap_or(DataType::Anything);
                DataType::Vector {
                    element_type: Box::new(element_type),
                    dynamic: false,
                }
            }
            MireValue::Dict(entries) => {
                let key_type = entries
                    .first()
                    .map(|((key, _), _)| Self::mire_value_type(key))
                    .unwrap_or(DataType::Anything);
                let value_type = entries
                    .first()
                    .map(|((_, value), _)| Self::mire_value_type(value))
                    .unwrap_or(DataType::Anything);
                DataType::Map {
                    key_type: Box::new(key_type),
                    value_type: Box::new(value_type),
                }
            }
            MireValue::Tuple(_) => DataType::Tuple,
            MireValue::Function(_) | MireValue::Builtinfn(_) => DataType::Function,
            MireValue::Object { .. } | MireValue::Instance { .. } => DataType::Anything,
            MireValue::Trait { .. } => DataType::DynTrait {
                trait_name: "trait".to_string(),
            },
            MireValue::Ref { is_mutable, .. } => {
                if *is_mutable {
                    DataType::RefMut {
                        inner: Box::new(DataType::Anything),
                    }
                } else {
                    DataType::Ref {
                        inner: Box::new(DataType::Anything),
                    }
                }
            }
            MireValue::Box { .. } => DataType::Box,
            MireValue::Array { elements, size } => {
                let element_type = elements
                    .first()
                    .map(Self::mire_value_type)
                    .unwrap_or(DataType::Anything);
                DataType::Array {
                    element_type: Box::new(element_type),
                    size: *size,
                }
            }
            MireValue::Slice { elements } => {
                let element_type = elements
                    .first()
                    .map(Self::mire_value_type)
                    .unwrap_or(DataType::Anything);
                DataType::Slice {
                    element_type: Box::new(element_type),
                }
            }
            MireValue::EnumVariant { enum_name, .. } => DataType::EnumNamed(enum_name.clone()),
        }
    }

    fn unify_types(left: &DataType, right: &DataType) -> Result<DataType> {
        if left == right {
            return Ok(left.clone());
        }

        if left.is_struct_like() && right.is_struct_like() {
            return match (left.struct_name(), right.struct_name()) {
                (Some(left_name), Some(right_name)) if left_name != right_name => {
                    Err(type_error(format!(
                        "Cannot unify incompatible struct types {:?} and {:?}",
                        left, right
                    )))
                }
                (Some(_), _) => Ok(left.clone()),
                (_, Some(_)) => Ok(right.clone()),
                _ => Ok(DataType::Struct),
            };
        }

        if left.is_enum_like() && right.is_enum_like() {
            return match (left.enum_name(), right.enum_name()) {
                (Some(left_name), Some(right_name)) if left_name != right_name => {
                    Err(type_error(format!(
                        "Cannot unify incompatible enum types {:?} and {:?}",
                        left, right
                    )))
                }
                (Some(_), _) => Ok(left.clone()),
                (_, Some(_)) => Ok(right.clone()),
                _ => Ok(DataType::Enum),
            };
        }

        if left == &DataType::Unknown {
            return Ok(right.clone());
        }
        if right == &DataType::Unknown {
            return Ok(left.clone());
        }

        if Self::is_numeric(left) && Self::is_numeric(right) {
            return Ok(Self::promote_numeric(left, right));
        }

        match (left, right) {
            (
                DataType::Vector {
                    element_type: left_elem,
                    dynamic: left_dynamic,
                },
                DataType::Vector {
                    element_type: right_elem,
                    dynamic: right_dynamic,
                },
            ) => {
                let element_type = Self::unify_types(left_elem, right_elem)?;
                return Ok(DataType::Vector {
                    element_type: Box::new(element_type),
                    dynamic: *left_dynamic || *right_dynamic,
                });
            }
            (
                DataType::Map {
                    key_type: left_key,
                    value_type: left_value,
                },
                DataType::Map {
                    key_type: right_key,
                    value_type: right_value,
                },
            ) => {
                let key_type = Self::unify_types(left_key, right_key)?;
                let value_type = Self::unify_types(left_value, right_value)?;
                return Ok(DataType::Map {
                    key_type: Box::new(key_type),
                    value_type: Box::new(value_type),
                });
            }
            _ => {}
        }

        match (left, right) {
            (
                DataType::Ref { inner: left_inner } | DataType::RefMut { inner: left_inner },
                DataType::Ref { inner: right_inner } | DataType::RefMut { inner: right_inner },
            ) => {
                let inner = Self::unify_types(left_inner, right_inner)?;
                let same_kind = std::mem::discriminant(left) == std::mem::discriminant(right);
                return Ok(if same_kind {
                    if matches!(left, DataType::Ref { .. }) {
                        DataType::Ref {
                            inner: Box::new(inner),
                        }
                    } else {
                        DataType::RefMut {
                            inner: Box::new(inner),
                        }
                    }
                } else {
                    DataType::Ref {
                        inner: Box::new(inner),
                    }
                });
            }
            (DataType::Ref { inner } | DataType::RefMut { inner }, other)
            | (other, DataType::Ref { inner } | DataType::RefMut { inner }) => {
                return Self::unify_types(inner, other);
            }
            _ => {}
        }

        Err(type_error(format!(
            "Cannot unify incompatible types {:?} and {:?}",
            left, right
        )))
    }

    fn promote_numeric(left: &DataType, right: &DataType) -> DataType {
        if matches!(left, DataType::F64 | DataType::F32)
            || matches!(right, DataType::F64 | DataType::F32)
        {
            DataType::F64
        } else if left == &DataType::I64 || right == &DataType::I64 {
            DataType::I64
        } else {
            left.clone()
        }
    }

    fn is_numeric(dtype: &DataType) -> bool {
        matches!(
            dtype,
            DataType::I8
                | DataType::I16
                | DataType::I32
                | DataType::I64
                | DataType::U8
                | DataType::U16
                | DataType::U32
                | DataType::U64
                | DataType::F32
                | DataType::F64
        )
    }

    fn is_bool_like(dtype: &DataType) -> bool {
        matches!(
            dtype,
            DataType::Bool | DataType::Anything | DataType::Unknown
        )
    }

    fn is_assignable(&self, expected: &DataType, actual: &DataType) -> bool {
        if expected == actual {
            return true;
        }

        if expected.is_struct_like() && actual.is_struct_like() {
            return match (expected.struct_name(), actual.struct_name()) {
                (Some(expected_name), Some(actual_name)) => expected_name == actual_name,
                _ => true,
            };
        }

        if expected.is_enum_like() && actual.is_enum_like() {
            return match (expected.enum_name(), actual.enum_name()) {
                (Some(expected_name), Some(actual_name)) => expected_name == actual_name,
                _ => true,
            };
        }

        match (expected, actual) {
            (
                DataType::Ref {
                    inner: expected_inner,
                },
                DataType::Ref {
                    inner: actual_inner,
                }
                | DataType::RefMut {
                    inner: actual_inner,
                },
            ) => {
                return self.is_assignable(expected_inner, actual_inner);
            }
            (
                DataType::RefMut {
                    inner: expected_inner,
                },
                DataType::RefMut {
                    inner: actual_inner,
                },
            ) => {
                return self.is_assignable(expected_inner, actual_inner);
            }
            (DataType::RefMut { .. }, DataType::Ref { .. }) => return false,
            (DataType::Ref { inner, .. } | DataType::RefMut { inner, .. }, _) => {
                return self.is_assignable(inner, actual);
            }
            _ => {}
        }

        if expected == &DataType::Anything || actual == &DataType::Unknown {
            return true;
        }

        if expected == &DataType::Unknown {
            return true;
        }

        if expected == &DataType::Dict && actual == &DataType::List {
            return true;
        }

        if matches!(expected, DataType::Map { .. }) && actual == &DataType::Dict {
            return true;
        }

        match (expected, actual) {
            (
                DataType::Array {
                    element_type: expected_elem,
                    ..
                }
                | DataType::Slice {
                    element_type: expected_elem,
                },
                DataType::Vector {
                    element_type: actual_elem,
                    ..
                },
            ) => {
                return self.is_assignable(expected_elem, actual_elem);
            }
            (DataType::Array { .. } | DataType::Slice { .. }, DataType::List) => return true,
            (
                DataType::Vector {
                    element_type: expected_elem,
                    ..
                },
                DataType::Vector {
                    element_type: actual_elem,
                    ..
                },
            ) => {
                return self.is_assignable(expected_elem, actual_elem);
            }
            (DataType::Vector { .. }, DataType::List) => return true,
            _ => {}
        }

        Self::is_numeric(expected) && Self::is_numeric(actual)
    }

    fn validate_explicit_nested_literal(expected: &DataType, expr: &Expression) -> Result<()> {
        match (expected, expr) {
            (
                DataType::Vector { element_type, .. } | DataType::Array { element_type, .. },
                Expression::List { elements, .. },
            ) => {
                if Self::requires_explicit_nested_element(element_type) {
                    for element in elements {
                        if !matches!(
                            element,
                            Expression::List { .. }
                                | Expression::Dict { .. }
                                | Expression::Identifier(_)
                        ) {
                            return Err(type_error(format!(
                                "Nested literal for {:?} must use explicit inner brackets",
                                expected
                            )));
                        }
                    }
                }
                for element in elements {
                    Self::validate_explicit_nested_literal(element_type, element)?;
                }
                Ok(())
            }
            (DataType::Map { value_type, .. }, Expression::Dict { entries, .. }) => {
                if Self::requires_explicit_nested_element(value_type) {
                    for (_, value) in entries {
                        if !matches!(value, Expression::List { .. } | Expression::Dict { .. }) {
                            return Err(type_error(format!(
                                "Nested literal for {:?} must use explicit inner brackets",
                                expected
                            )));
                        }
                    }
                }
                for (_, value) in entries {
                    Self::validate_explicit_nested_literal(value_type, value)?;
                }
                Ok(())
            }
            _ => Ok(()),
        }
    }

    fn closure_return_type(expr: &Expression, context: &str) -> Result<DataType> {
        if let Expression::Closure { return_type, .. } = expr {
            Ok(return_type.clone())
        } else {
            Err(type_error(format!(
                "{} must be represented as a closure in the AST",
                context
            )))
        }
    }

    fn infer_list_element_type(list_type: DataType) -> Result<DataType> {
        match list_type {
            DataType::Vector { element_type, .. } => Ok(*element_type),
            DataType::Array { element_type, .. } => Ok(*element_type),
            DataType::Slice { element_type } => Ok(*element_type),
            DataType::List => Ok(DataType::Anything),
            other => Err(type_error(format!(
                "High-order list function expects vec/arr/slice input, got {:?}",
                other
            ))),
        }
    }

    fn check_closure_with_expected_params(
        &mut self,
        expr: &mut Expression,
        expected_params: &[DataType],
        context: &str,
    ) -> Result<DataType> {
        let Expression::Closure {
            params,
            body,
            return_type,
            capture,
        } = expr
        else {
            return Err(type_error(format!(
                "{} expects a closure argument",
                context
            )));
        };

        if params.len() != expected_params.len() {
            return Err(type_error(format!(
                "{} expects a closure with {} parameter(s), got {}",
                context,
                expected_params.len(),
                params.len()
            )));
        }

        self.push_scope();

        for (name, value) in capture.iter() {
            self.insert_var(name.clone(), Self::mire_value_type(value), true);
        }

        for ((name, param_type), expected_type) in params.iter_mut().zip(expected_params.iter()) {
            let resolved = Self::unify_types(param_type, expected_type)?;
            *param_type = resolved.clone();
            self.insert_var(name.clone(), resolved, true);
        }

        self.return_type_stack.push(return_type.clone());
        self.check_statements(body)?;
        if !statements_contain_explicit_return(body)
            && let Some(expr) = implicit_return_expression_mut(body)
        {
            let tail_type = self.check_expression(expr)?;
            if let Some(current) = self.return_type_stack.last_mut() {
                let unified = Self::unify_types(current, &tail_type)?;
                *current = unified;
            }
        }
        let inferred_return = self.return_type_stack.pop().unwrap_or(DataType::Unknown);

        if *return_type == DataType::Unknown {
            *return_type = inferred_return.clone();
        } else if inferred_return != DataType::Unknown
            && !self.is_assignable(return_type, &inferred_return)
        {
            return Err(type_error(format!(
                "{} return type mismatch: declared {:?}, inferred {:?}",
                context, return_type, inferred_return
            )));
        }

        self.pop_scope();
        Ok(return_type.clone())
    }

    fn requires_explicit_nested_element(dtype: &DataType) -> bool {
        matches!(
            dtype,
            DataType::Vector { .. } | DataType::Array { .. } | DataType::Map { .. }
        )
    }

    fn check_enum_variant_call(
        &self,
        variant_name: &str,
        variant_sig: &EnumVariantSig,
        arg_types: &[DataType],
    ) -> Result<()> {
        if variant_sig.payload_types.len() != arg_types.len() {
            return Err(type_error(format!(
                "Enum variant '{}' expects {} values, got {}",
                variant_name,
                variant_sig.payload_types.len(),
                arg_types.len()
            )));
        }

        for (index, (expected, actual)) in variant_sig
            .payload_types
            .iter()
            .zip(arg_types.iter())
            .enumerate()
        {
            if !self.is_assignable(expected, actual) {
                return Err(type_error(format!(
                    "Enum variant '{}' value {} expects {:?}, got {:?}",
                    variant_name,
                    index + 1,
                    expected,
                    actual
                )));
            }
        }

        Ok(())
    }

    fn normalize_enum_variant_payloads(
        &mut self,
        variant_name: &str,
        variant_sig: &EnumVariantSig,
        payloads: &mut Vec<Expression>,
    ) -> Result<Vec<DataType>> {
        let has_named = payloads
            .iter()
            .any(|arg| matches!(arg, Expression::NamedArg { .. }));
        let has_positional = payloads
            .iter()
            .any(|arg| !matches!(arg, Expression::NamedArg { .. }));

        if has_named && has_positional {
            return Err(type_error(format!(
                "Enum variant '{}' cannot mix named and positional arguments",
                variant_name
            )));
        }

        if !has_named {
            let mut arg_types = Vec::with_capacity(payloads.len());
            for payload in payloads.iter_mut() {
                arg_types.push(self.check_expression(payload)?);
            }
            self.check_enum_variant_call(variant_name, variant_sig, &arg_types)?;
            return Ok(arg_types);
        }

        let mut seen = HashSet::new();
        let mut named_values: HashMap<String, Expression> = HashMap::new();

        for payload in std::mem::take(payloads) {
            let Expression::NamedArg { name, value, .. } = payload else {
                unreachable!("named enum payload validation should reject mixed arguments");
            };

            if !seen.insert(name.clone()) {
                return Err(type_error(format!(
                    "Enum variant '{}' received duplicate field '{}'",
                    variant_name, name
                )));
            }

            if !variant_sig.payload_names.iter().any(|field| field == &name) {
                return Err(type_error(format!(
                    "Enum variant '{}' has no field '{}'",
                    variant_name, name
                )));
            }

            named_values.insert(name, *value);
        }

        for field in &variant_sig.payload_names {
            if !named_values.contains_key(field) {
                return Err(type_error(format!(
                    "Enum variant '{}' is missing required field '{}'",
                    variant_name, field
                )));
            }
        }

        let mut reordered_payloads = Vec::with_capacity(variant_sig.payload_names.len());
        let mut arg_types = Vec::with_capacity(variant_sig.payload_names.len());
        for field in &variant_sig.payload_names {
            let mut value = named_values
                .remove(field)
                .expect("enum payload field validated before reorder");
            let value_type = self.check_expression(&mut value)?;
            reordered_payloads.push(value);
            arg_types.push(value_type);
        }

        self.check_enum_variant_call(variant_name, variant_sig, &arg_types)?;
        *payloads = reordered_payloads;
        Ok(arg_types)
    }

    fn check_match_pattern(&mut self, pattern: &mut Expression) -> Result<DataType> {
        match pattern {
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                data_type,
            } => {
                let full_name = format!("{}.{}", enum_name, variant_name);
                if !self.enum_variants.contains_key(&full_name) {
                    return Err(type_error(format!("Unknown enum variant '{}'", full_name)));
                }
                *data_type = DataType::EnumNamed(enum_name.clone());
                Ok(DataType::EnumNamed(enum_name.clone()))
            }
            Expression::EnumVariant {
                enum_name,
                variant_name,
                payloads,
                data_type,
            } => {
                let full_name = format!("{}.{}", enum_name, variant_name);
                let variant_sig =
                    self.enum_variants.get(&full_name).cloned().ok_or_else(|| {
                        type_error(format!("Unknown enum variant '{}'", full_name))
                    })?;
                let mut arg_types = Vec::with_capacity(payloads.len());
                for (index, payload) in payloads.iter_mut().enumerate() {
                    if matches!(payload, Expression::Identifier(_)) {
                        arg_types.push(
                            variant_sig
                                .payload_types
                                .get(index)
                                .cloned()
                                .unwrap_or(DataType::Unknown),
                        );
                    } else {
                        arg_types.push(self.check_expression(payload)?);
                    }
                }
                self.check_enum_variant_call(&full_name, &variant_sig, &arg_types)?;
                *data_type = DataType::EnumNamed(enum_name.clone());
                Ok(DataType::EnumNamed(enum_name.clone()))
            }
            _ => self.check_expression(pattern),
        }
    }

    fn insert_match_pattern_bindings(&mut self, case_expr: &Expression) {
        if let Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads,
            ..
        } = case_expr
        {
            let full_name = format!("{}.{}", enum_name, variant_name);
            if let Some(variant_sig) = self.enum_variants.get(&full_name).cloned() {
                for (payload_expr, payload_type) in
                    payloads.iter().zip(variant_sig.payload_types.iter())
                {
                    if let Expression::Identifier(id) = payload_expr {
                        self.insert_var(id.name.clone(), payload_type.clone(), true);
                    }
                }
            }
        }
    }

    fn validate_trait_impl(
        &self,
        trait_name: &str,
        type_name: &str,
        methods: &[Statement],
    ) -> Result<()> {
        let trait_sig = self
            .traits
            .get(trait_name)
            .ok_or_else(|| type_error(format!("Unknown skill/trait '{}'", trait_name)))?;

        for required_method in &trait_sig.methods {
            let implemented = methods.iter().find_map(|statement| match statement {
                Statement::Function {
                    name,
                    params,
                    return_type,
                    ..
                } if name == &required_method.name => Some((params.clone(), return_type.clone())),
                _ => None,
            });

            let Some((implemented_params, implemented_return)) = implemented else {
                return Err(type_error(format!(
                    "Type '{}' does not implement required method '{}.{}'",
                    type_name, trait_name, required_method.name
                )));
            };

            let required_kind = Self::method_kind_for_params(&required_method.params);
            let implemented_kind = Self::method_kind_for_params(&implemented_params);
            if required_kind != implemented_kind {
                return Err(type_error(format!(
                    "Method '{}.{}' must be implemented as {}, got {}",
                    trait_name,
                    required_method.name,
                    Self::describe_method_kind(required_kind),
                    Self::describe_method_kind(implemented_kind),
                )));
            }

            let required_params =
                Self::normalize_trait_impl_params(type_name, &required_method.params);
            let implemented_params =
                Self::normalize_trait_impl_params(type_name, &implemented_params);

            if implemented_params != required_params
                || implemented_return != required_method.return_type
            {
                return Err(type_error(format!(
                    "Method '{}.{}' implementation signature does not match declaration: expected {:?} -> {:?}, got {:?} -> {:?}",
                    trait_name,
                    required_method.name,
                    required_params,
                    required_method.return_type,
                    implemented_params,
                    implemented_return,
                )));
            }
        }

        Ok(())
    }

    fn validate_trait_method_declarations(
        &self,
        container_name: &str,
        methods: &[TraitMethodSig],
        container_kind: &str,
    ) -> Result<()> {
        for method in methods {
            Self::validate_self_param_position(
                &method.params,
                format!("{} '{}.{}'", container_kind, container_name, method.name),
            )?;
        }
        Ok(())
    }

    fn validate_impl_method_declarations(
        &self,
        type_name: &str,
        methods: &[Statement],
    ) -> Result<()> {
        for method in methods {
            if let Statement::Function { name, params, .. } = method {
                Self::validate_self_param_position(
                    params,
                    format!("Method '{}.{}'", type_name, name),
                )?;
            }
        }
        Ok(())
    }

    fn normalize_trait_impl_params(
        owner_type_name: &str,
        params: &[(String, DataType)],
    ) -> Vec<DataType> {
        params
            .iter()
            .map(|(name, data_type)| {
                if name == "self" && matches!(data_type, DataType::Unknown | DataType::Struct) {
                    DataType::StructNamed(owner_type_name.to_string())
                } else {
                    data_type.clone()
                }
            })
            .collect()
    }

    fn validate_self_param_position(params: &[(String, DataType)], context: String) -> Result<()> {
        if params.iter().skip(1).any(|(name, _)| name == "self") {
            return Err(type_error(format!(
                "{} must declare 'self' as the first parameter",
                context
            )));
        }
        Ok(())
    }

    fn method_kind_for_params(params: &[(String, DataType)]) -> MethodKind {
        if params.first().is_some_and(|(name, _)| name == "self") {
            MethodKind::Instance
        } else {
            MethodKind::Associated
        }
    }

    fn describe_method_kind(kind: MethodKind) -> &'static str {
        match kind {
            MethodKind::Instance => "an instance method",
            MethodKind::Associated => "an associated method",
        }
    }

    fn check_class_constructor_call(
        &self,
        class_name: &str,
        class_sig: &ClassSig,
        args: &[Expression],
        arg_types: &[DataType],
    ) -> Result<()> {
        let has_named = args
            .iter()
            .any(|arg| matches!(arg, Expression::NamedArg { .. }));
        let has_positional = args
            .iter()
            .any(|arg| !matches!(arg, Expression::NamedArg { .. }));

        if has_named && has_positional {
            return Err(type_error(format!(
                "Constructor '{}' cannot mix named and positional arguments",
                class_name
            )));
        }

        if has_named {
            let mut seen = HashSet::new();
            for (index, arg) in args.iter().enumerate() {
                let Expression::NamedArg { name, .. } = arg else {
                    continue;
                };

                if !seen.insert(name.clone()) {
                    return Err(type_error(format!(
                        "Constructor '{}' received duplicate field '{}'",
                        class_name, name
                    )));
                }

                let field = class_sig
                    .fields
                    .iter()
                    .find(|field| field.name == *name)
                    .ok_or_else(|| {
                        type_error(format!(
                            "Constructor '{}' has no field '{}'",
                            class_name, name
                        ))
                    })?;

                let actual = arg_types.get(index).cloned().unwrap_or(DataType::Unknown);
                if !self.is_assignable(&field.data_type, &actual) {
                    return Err(type_error(format!(
                        "Constructor '{}.{}' expects {:?}, got {:?}",
                        class_name, name, field.data_type, actual
                    )));
                }
            }

            for field in &class_sig.fields {
                if !field.has_default && !seen.contains(&field.name) {
                    return Err(type_error(format!(
                        "Constructor '{}' is missing required field '{}'",
                        class_name, field.name
                    )));
                }
            }
        } else {
            if arg_types.len() > class_sig.fields.len() {
                return Err(type_error(format!(
                    "Constructor '{}' expects at most {} values, got {}",
                    class_name,
                    class_sig.fields.len(),
                    arg_types.len()
                )));
            }

            for (index, actual) in arg_types.iter().enumerate() {
                let Some(field) = class_sig.fields.get(index) else {
                    break;
                };
                if !self.is_assignable(&field.data_type, actual) {
                    return Err(type_error(format!(
                        "Constructor '{}.{}' expects {:?}, got {:?}",
                        class_name, field.name, field.data_type, actual
                    )));
                }
            }

            for field in class_sig.fields.iter().skip(arg_types.len()) {
                if !field.has_default {
                    return Err(type_error(format!(
                        "Constructor '{}' is missing required field '{}'",
                        class_name, field.name
                    )));
                }
            }
        }

        Ok(())
    }

    fn push_scope(&mut self) {
        self.scopes.push(HashMap::new());
        self.struct_scopes.push(HashMap::new());
        self.ref_scopes.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        if self.scopes.len() > 1 {
            self.scopes.pop();
        }
        if self.struct_scopes.len() > 1 {
            self.struct_scopes.pop();
        }
        if self.ref_scopes.len() > 1 {
            self.ref_scopes.pop();
        }
    }

    fn insert_var(&mut self, name: String, data_type: DataType, is_mutable: bool) {
        if let Some(scope) = self.scopes.last_mut() {
            scope.insert(name, (data_type, is_mutable));
        }
    }

    fn refresh_binding_metadata(
        &mut self,
        name: &str,
        data_type: &DataType,
        value: Option<&Expression>,
    ) {
        self.bind_struct_name(name, data_type, value);
        self.bind_reference_type(name, value);
    }

    fn bind_struct_name(&mut self, name: &str, data_type: &DataType, value: Option<&Expression>) {
        let struct_name = data_type
            .struct_name()
            .map(ToOwned::to_owned)
            .or_else(|| value.and_then(|expr| self.struct_name_for_expr(expr)));
        if let Some(scope) = self.struct_scopes.last_mut() {
            if let Some(struct_name) = struct_name {
                scope.insert(name.to_string(), struct_name);
            } else {
                scope.remove(name);
            }
        }
    }

    fn bind_reference_type(&mut self, name: &str, value: Option<&Expression>) {
        let referenced_type = value.and_then(|expr| self.referenced_type_from_value(expr));
        if let Some(scope) = self.ref_scopes.last_mut() {
            if let Some(referenced_type) = referenced_type {
                scope.insert(name.to_string(), referenced_type);
            } else {
                scope.remove(name);
            }
        }
    }

    fn resolve_assignment_target(
        &mut self,
        target: &AssignmentTarget,
    ) -> Result<Option<(DataType, bool)>> {
        match target {
            AssignmentTarget::Variable(name) => Ok(self.lookup_var(name)),
            AssignmentTarget::Field(path) => {
                let Some((owner, field_path)) = path.split_once('.') else {
                    return Ok(self.lookup_var(path));
                };

                let (mut current_type, is_mutable) = self.lookup_var(owner).ok_or_else(|| {
                    type_error(format!("Assignment to undefined variable '{}'", owner))
                })?;

                for field_name in field_path.split('.') {
                    let struct_name = match &current_type {
                        DataType::StructNamed(name) => name.clone(),
                        other => {
                            return Err(type_error(format!(
                                "Cannot assign field '{}' on non-struct target '{}': {:?}",
                                field_name, owner, other
                            )));
                        }
                    };

                    let class_sig = self.classes.get(&struct_name).ok_or_else(|| {
                        type_error(format!(
                            "Struct '{}' has no field metadata for assignment '{}'",
                            struct_name, path
                        ))
                    })?;
                    let field = class_sig
                        .fields
                        .iter()
                        .find(|field| field.name == field_name)
                        .ok_or_else(|| {
                            type_error(format!(
                                "Struct '{}' has no field '{}'",
                                struct_name, field_name
                            ))
                        })?;
                    current_type = field.data_type.clone();
                }

                Ok(Some((current_type, is_mutable)))
            }
            AssignmentTarget::Index {
                target: index_target,
                index,
            } => {
                let owner_name = target.binding_name().ok_or_else(|| {
                    type_error(
                        "Indexed assignment requires an identifier-backed target".to_string(),
                    )
                })?;
                let (_, is_mutable) = self.lookup_var(owner_name).ok_or_else(|| {
                    type_error(format!("Assignment to undefined variable '{}'", owner_name))
                })?;
                let mut target_expr = index_target.clone();
                let mut index_expr = index.clone();
                let target_type = self.check_expression(&mut target_expr)?;
                let index_type = self.check_expression(&mut index_expr)?;
                if !Self::is_numeric(&index_type) && index_type != DataType::Unknown {
                    return Err(type_error(format!(
                        "Index must be numeric for indexed assignment, got {:?}",
                        index_type
                    )));
                }

                let element_type = match target_type {
                    DataType::Array { element_type, .. }
                    | DataType::Slice { element_type }
                    | DataType::Vector { element_type, .. } => *element_type,
                    DataType::Map { value_type, .. } => *value_type,
                    DataType::List | DataType::Tuple | DataType::Dict => DataType::Anything,
                    DataType::Unknown => DataType::Unknown,
                    other => {
                        return Err(type_error(format!(
                            "Type {:?} does not support indexed assignment",
                            other
                        )));
                    }
                };

                Ok(Some((element_type, is_mutable)))
            }
        }
    }

    fn lookup_var(&self, name: &str) -> Option<(DataType, bool)> {
        if name == "self"
            && let Some(ref self_type) = self.impl_self_type
        {
            return Some((self_type.clone(), true));
        }
        for scope in self.scopes.iter().rev() {
            if let Some(data_type) = scope.get(name) {
                return Some(data_type.clone());
            }
        }
        None
    }

    fn lookup_struct_name(&self, name: &str) -> Option<String> {
        if name == "self" {
            return self.impl_self_name.clone();
        }
        for scope in self.struct_scopes.iter().rev() {
            if let Some(struct_name) = scope.get(name) {
                return Some(struct_name.clone());
            }
        }
        self.lookup_var(name)
            .and_then(|(data_type, _)| data_type.struct_name().map(ToOwned::to_owned))
    }

    fn lookup_ref_type(&self, name: &str) -> Option<DataType> {
        for scope in self.ref_scopes.iter().rev() {
            if let Some(data_type) = scope.get(name) {
                return Some(data_type.clone());
            }
        }
        None
    }

    fn struct_name_for_expr(&self, expr: &Expression) -> Option<String> {
        match expr {
            Expression::Call {
                name, data_type, ..
            } if data_type.is_struct_like() => {
                data_type.struct_name().map(ToOwned::to_owned).or_else(|| {
                    if self.classes.contains_key(name) {
                        Some(name.clone())
                    } else if let Some((owner, _method)) = name.split_once('.') {
                        self.lookup_struct_name(owner)
                            .or_else(|| self.classes.contains_key(owner).then(|| owner.to_string()))
                    } else {
                        None
                    }
                })
            }
            Expression::Identifier(Identifier { name, .. }) => self.lookup_struct_name(name),
            Expression::Reference { expr, .. } | Expression::Dereference { expr, .. } => {
                self.struct_name_for_expr(expr)
            }
            _ => None,
        }
    }

    fn referenced_type_from_value(&self, expr: &Expression) -> Option<DataType> {
        match expr {
            Expression::Reference { expr, .. } => self.referenced_type_for_expr(expr),
            _ => None,
        }
    }

    fn reference_target_is_mutable(&self, expr: &Expression) -> bool {
        match expr {
            Expression::Identifier(Identifier { name, .. }) => self
                .lookup_var(name)
                .map(|(_, is_mutable)| is_mutable)
                .unwrap_or(false),
            Expression::MemberAccess { target, .. } | Expression::Index { target, .. } => {
                self.reference_target_is_mutable(target)
            }
            Expression::Reference { expr, .. } | Expression::Dereference { expr, .. } => {
                self.reference_target_is_mutable(expr)
            }
            _ => false,
        }
    }

    fn referenced_type_for_expr(&self, expr: &Expression) -> Option<DataType> {
        match expr {
            Expression::Identifier(Identifier { name, .. }) => self
                .lookup_ref_type(name)
                .or_else(|| self.lookup_var(name).map(|(data_type, _)| data_type)),
            Expression::Reference { expr, .. } => self.referenced_type_for_expr(expr),
            Expression::Dereference { expr, .. } => self.referenced_type_for_expr(expr),
            _ => Some(self.expression_type_hint(expr)),
        }
    }

    fn expression_type_hint(&self, expr: &Expression) -> DataType {
        match expr {
            Expression::Identifier(identifier) => identifier.data_type.clone(),
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
            | Expression::EnumVariant { data_type, .. } => data_type.clone(),
            Expression::Literal(Literal::Int(_)) => DataType::I64,
            Expression::Literal(Literal::Float(_)) => DataType::F64,
            Expression::Literal(Literal::Char(_)) => DataType::Char,
            Expression::Literal(Literal::Str(_)) => DataType::Str,
            Expression::Literal(Literal::Bool(_)) => DataType::Bool,
            Expression::Literal(Literal::None) => DataType::None,
            Expression::Literal(Literal::List(_)) => DataType::List,
            Expression::Literal(Literal::Dict(_)) => DataType::Dict,
            Expression::Literal(Literal::Tuple(_)) => DataType::Tuple,
            Expression::Closure { return_type, .. } => return_type.clone(),
        }
    }

    fn pipeline_input_element_type(&self, input_type: &DataType) -> DataType {
        match input_type {
            DataType::Vector { element_type, .. }
            | DataType::Array { element_type, .. }
            | DataType::Slice { element_type } => *element_type.clone(),
            DataType::Str => DataType::Str,
            other => other.clone(),
        }
    }

    fn resolve_pipeline_stage_type(
        &mut self,
        stage: &mut Expression,
        input_type: &DataType,
    ) -> Result<Option<DataType>> {
        match stage {
            Expression::Call {
                name,
                args,
                data_type,
            } => {
                let arg_types: Vec<DataType> = std::iter::once(Ok(input_type.clone()))
                    .chain(args.iter_mut().map(|arg| self.check_expression(arg)))
                    .collect::<Result<_>>()?;
                if name == "len" {
                    *data_type = DataType::I64;
                    return Ok(Some(DataType::I64));
                }
                if let Some(resolved) = self.resolve_instance_method_call(name, &arg_types[1..])? {
                    *data_type = resolved.clone();
                    return Ok(Some(resolved));
                }
                if let Some(sig) = self.functions.get(name).cloned()
                    && sig.params.len() == arg_types.len()
                    && sig
                        .params
                        .iter()
                        .zip(arg_types.iter())
                        .all(|(expected, actual)| self.is_assignable(expected, actual))
                {
                    *data_type = sig.return_type.clone();
                    return Ok(Some(sig.return_type));
                }
                if let Some(ret) = self.builtin_returns.get(name).cloned() {
                    *data_type = ret.clone();
                    return Ok(Some(ret));
                }
                Ok(None)
            }
            Expression::Identifier(Identifier {
                name, data_type, ..
            }) => {
                if name == "len" {
                    *data_type = DataType::Function;
                    return Ok(Some(DataType::I64));
                }
                if let Some(sig) = self.functions.get(name).cloned()
                    && sig.params.len() == 1
                    && self.is_assignable(&sig.params[0], input_type)
                {
                    *data_type = sig.return_type.clone();
                    return Ok(Some(sig.return_type));
                }
                if let Some(ret) = self.builtin_returns.get(name).cloned() {
                    *data_type = ret.clone();
                    return Ok(Some(ret));
                }
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn resolve_instance_method_call(
        &self,
        name: &str,
        arg_types: &[DataType],
    ) -> Result<Option<DataType>> {
        let Some((receiver_name, method_name)) = name.split_once('.') else {
            return Ok(None);
        };
        let Some(struct_name) = self.lookup_struct_name(receiver_name) else {
            return Ok(None);
        };
        let full_name = format!("{}.{}", struct_name, method_name);
        let Some(sig) = self.functions.get(&full_name) else {
            return Err(type_error(format!(
                "Struct '{}' has no method '{}'",
                struct_name, method_name
            )));
        };

        if !sig.params.first().is_some_and(DataType::is_struct_like) {
            return Ok(None);
        }

        let expected_args = sig.params.get(1..).unwrap_or(&[]);

        if expected_args.len() != arg_types.len() {
            return Err(type_error(format!(
                "Method '{}.{}' expects {} arguments, got {}",
                struct_name,
                method_name,
                expected_args.len(),
                arg_types.len()
            )));
        }

        for (idx, (expected, actual)) in expected_args.iter().zip(arg_types.iter()).enumerate() {
            if !self.is_assignable(expected, actual) {
                return Err(type_error(format!(
                    "Method '{}.{}' argument {} expects {:?}, got {:?}",
                    struct_name,
                    method_name,
                    idx + 1,
                    expected,
                    actual
                )));
            }
        }

        Ok(Some(sig.return_type.clone()))
    }

    fn check_list_hof(
        &mut self,
        name: &str,
        args: &mut [Expression],
        data_type: &mut DataType,
    ) -> Result<DataType> {
        match name {
            "lists.fold" => {
                if args.len() != 3 {
                    return Err(type_error("lists.fold expects 3 arguments".to_string()));
                }
                // Mire currently defines the order as `(acc, closure, list)`.
                let acc_type = self.check_expression(&mut args[0])?;
                let list_type = self.check_expression(&mut args[2])?;
                let elem_type = Self::infer_list_element_type(list_type)?;
                let closure_return = self.check_closure_with_expected_params(
                    &mut args[1],
                    &[acc_type.clone(), elem_type],
                    "lists.fold",
                )?;
                if closure_return != DataType::Unknown
                    && !self.is_assignable(&acc_type, &closure_return)
                {
                    return Err(type_error(format!(
                        "lists.fold closure must return {:?}, got {:?}",
                        acc_type, closure_return
                    )));
                }
                *data_type = acc_type.clone();
                Ok(acc_type)
            }
            "lists.map" => {
                if args.len() != 2 {
                    return Err(type_error("lists.map expects 2 arguments".to_string()));
                }
                let list_type = self.check_expression(&mut args[1])?;
                let elem_type = Self::infer_list_element_type(list_type)?;
                let mapped_type = self.check_closure_with_expected_params(
                    &mut args[0],
                    &[elem_type],
                    "lists.map",
                )?;
                if mapped_type == DataType::Unknown {
                    return Err(type_error(
                        "lists.map closure must return a value".to_string(),
                    ));
                }
                let result = DataType::Vector {
                    element_type: Box::new(mapped_type),
                    dynamic: true,
                };
                *data_type = result.clone();
                Ok(result)
            }
            "lists.filter" => {
                if args.len() != 2 {
                    return Err(type_error("lists.filter expects 2 arguments".to_string()));
                }
                let list_type = self.check_expression(&mut args[1])?;
                let elem_type = Self::infer_list_element_type(list_type)?;
                let predicate_type = self.check_closure_with_expected_params(
                    &mut args[0],
                    std::slice::from_ref(&elem_type),
                    "lists.filter",
                )?;
                if !Self::is_bool_like(&predicate_type) {
                    return Err(type_error(format!(
                        "lists.filter closure must return bool, got {:?}",
                        predicate_type
                    )));
                }
                let result = DataType::Vector {
                    element_type: Box::new(elem_type),
                    dynamic: true,
                };
                *data_type = result.clone();
                Ok(result)
            }
            _ => unreachable!(),
        }
    }

    fn statement_location(statement: &Statement) -> (usize, usize) {
        match statement {
        Statement::Let {
            value: Some(value), ..
        }
        | Statement::Assignment { value, .. }
        | Statement::Expression(value)
        | Statement::Drop { value }
        | Statement::New {
            value: Some(value), ..
        }
        | Statement::Own {
            value: Some(value), ..
        }
        | Statement::Move { value, .. } => Self::expression_location(value),
            Statement::Return(Some(value)) => Self::expression_location(value),
            Statement::If { condition, .. } | Statement::While { condition, .. } => {
                Self::expression_location(condition)
            }
            Statement::For { iterable, .. } | Statement::Find { iterable, .. } => {
                Self::expression_location(iterable)
            }
            Statement::Match { value, .. } => Self::expression_location(value),
            _ => (1, 1),
        }
    }

    fn expression_location(expression: &Expression) -> (usize, usize) {
        match expression {
            Expression::Identifier(ident) => (ident.line.max(1), ident.column.max(1)),
            Expression::BinaryOp { left, .. }
            | Expression::NamedArg { value: left, .. }
            | Expression::Reference { expr: left, .. }
            | Expression::Dereference { expr: left, .. }
            | Expression::Box { value: left, .. }
            | Expression::Pipeline { input: left, .. } => Self::expression_location(left),
            Expression::UnaryOp { operand, .. } => Self::expression_location(operand),
            Expression::Call { args, .. }
            | Expression::List { elements: args, .. }
            | Expression::Tuple { elements: args, .. } => args
                .first()
                .map(Self::expression_location)
                .unwrap_or((1, 1)),
            Expression::Dict { entries, .. } => entries
                .first()
                .map(|(key, _)| Self::expression_location(key))
                .unwrap_or((1, 1)),
            Expression::Index { target, .. } | Expression::MemberAccess { target, .. } => {
                Self::expression_location(target)
            }
            Expression::Closure { body, .. } => body
                .first()
                .map(Self::statement_location)
                .unwrap_or((1, 1)),
            Expression::Match { value, .. } => Self::expression_location(value),
            Expression::EnumVariant { payloads, .. } => payloads
                .first()
                .map(Self::expression_location)
                .unwrap_or((1, 1)),
            Expression::Literal(_) | Expression::EnumVariantPath { .. } => (1, 1),
        }
    }
}

fn type_error(message: String) -> MireError {
    type_error_at(0, 0, message)
}

fn type_error_at(line: usize, column: usize, message: String) -> MireError {
    let (err_line, err_col) = if line == 0 { (1, 1) } else { (line, column) };
    MireError::type_error_at(err_line, err_col, message)
}

fn statements_contain_explicit_return(statements: &[Statement]) -> bool {
    statements.iter().any(statement_contains_explicit_return)
}

fn statement_contains_explicit_return(statement: &Statement) -> bool {
    match statement {
        Statement::Return(_) => true,
        Statement::If {
            then_branch,
            else_branch,
            ..
        } => {
            statements_contain_explicit_return(then_branch)
                || else_branch
                    .as_ref()
                    .is_some_and(|branch| statements_contain_explicit_return(branch))
        }
        Statement::While { body, .. }
        | Statement::For { body, .. }
        | Statement::Find { body, .. }
        | Statement::Unsafe { body }
        | Statement::Module { body, .. }
        | Statement::DmireTable { body, .. }
        | Statement::DmireColumn { body, .. } => statements_contain_explicit_return(body),
        Statement::Match { cases, default, .. } => {
            cases
                .iter()
                .any(|(_, body)| statements_contain_explicit_return(body))
                || statements_contain_explicit_return(default)
        }
        Statement::Function { body, .. }
        | Statement::Type { fields: body, .. }
        | Statement::Class { methods: body, .. }
        | Statement::Code { methods: body, .. }
        | Statement::Impl { methods: body, .. } => statements_contain_explicit_return(body),
        _ => false,
    }
}

fn implicit_return_expression_mut(statements: &mut [Statement]) -> Option<&mut Expression> {
    match statements.last_mut()? {
        Statement::Expression(expr) => Some(expr),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::{
        check_program_types, check_program_types_partial_with_origins,
        check_program_types_with_origins,
    };
    use crate::compiler::AnalysisSelection;
    use crate::parse;
    use crate::parser::ast::{
        AssignmentTarget, DataType, Expression, Identifier, Literal, Program, Statement, Visibility,
    };
    use std::collections::HashMap;
    use std::path::PathBuf;

    #[test]
    fn infers_unknown_let_from_literal() {
        let mut program = Program {
            statements: vec![Statement::Let {
                name: "x".to_string(),
                data_type: DataType::Unknown,
                value: Some(Expression::Literal(Literal::Int(42))),
                is_constant: false,
                is_mutable: false,
                is_static: false,
                visibility: Visibility::Public,
            }],
        };

        check_program_types(&mut program, "").expect("type check must pass");

        match &program.statements[0] {
            Statement::Let { data_type, .. } => assert_eq!(*data_type, DataType::I64),
            _ => panic!("expected let"),
        }
    }

    #[test]
    fn resolves_identifier_type() {
        let mut program = Program {
            statements: vec![
                Statement::Let {
                    name: "x".to_string(),
                    data_type: DataType::I64,
                    value: Some(Expression::Literal(Literal::Int(1))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Expression(Expression::Identifier(Identifier {
                    name: "x".to_string(),
                    data_type: DataType::Unknown,
                    line: 0,
                    column: 0,
                })),
            ],
        };

        check_program_types(&mut program, "").expect("type check must pass");

        match &program.statements[1] {
            Statement::Expression(Expression::Identifier(ident)) => {
                assert_eq!(ident.data_type, DataType::I64)
            }
            _ => panic!("expected expression identifier"),
        }
    }

    #[test]
    fn infers_function_call_return_type() {
        let mut program = Program {
            statements: vec![
                Statement::Function {
                    name: "sum".to_string(),
                    params: vec![
                        ("a".to_string(), DataType::I64),
                        ("b".to_string(), DataType::I64),
                    ],
                    body: vec![Statement::Return(Some(Expression::BinaryOp {
                        operator: "+".to_string(),
                        left: Box::new(Expression::Identifier(Identifier {
                            name: "a".to_string(),
                            data_type: DataType::Unknown,
                            line: 0,
                            column: 0,
                        })),
                        right: Box::new(Expression::Identifier(Identifier {
                            name: "b".to_string(),
                            data_type: DataType::Unknown,
                            line: 0,
                            column: 0,
                        })),
                        data_type: DataType::Unknown,
                    }))],
                    return_type: DataType::Unknown,
                    visibility: Visibility::Public,
                    is_method: false,
                },
                Statement::Expression(Expression::Call {
                    name: "sum".to_string(),
                    args: vec![
                        Expression::Literal(Literal::Int(1)),
                        Expression::Literal(Literal::Int(2)),
                    ],
                    data_type: DataType::Unknown,
                }),
            ],
        };

        check_program_types(&mut program, "").expect("type check must pass");

        match &program.statements[1] {
            Statement::Expression(Expression::Call { data_type, .. }) => {
                assert_eq!(*data_type, DataType::I64)
            }
            _ => panic!("expected call expression"),
        }
    }

    #[test]
    fn fails_on_undefined_identifier() {
        let mut program = Program {
            statements: vec![Statement::Expression(Expression::Identifier(Identifier {
                name: "missing".to_string(),
                data_type: DataType::Unknown,
                line: 0,
                column: 0,
            }))],
        };

        let err = check_program_types(&mut program, "").expect_err("must fail");
        assert!(err.to_string().contains("Unknown identifier 'missing'"));
    }

    #[test]
    fn fails_on_assignment_type_mismatch() {
        let mut program = Program {
            statements: vec![
                Statement::Let {
                    name: "x".to_string(),
                    data_type: DataType::I64,
                    value: Some(Expression::Literal(Literal::Int(1))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Assignment {
                    target: AssignmentTarget::Variable("x".to_string()),
                    value: Expression::Literal(Literal::Str("bad".to_string())),
                    is_mutable: true,
                },
            ],
        };

        let err = check_program_types(&mut program, "").expect_err("must fail");
        assert!(
            err.to_string()
                .contains("Type mismatch in assignment to 'x'")
        );
    }

    #[test]
    fn accepts_builtin_calls() {
        let mut program = Program {
            statements: vec![
                Statement::Expression(Expression::Call {
                    name: "dasu".to_string(),
                    args: vec![Expression::Literal(Literal::Str("hello".to_string()))],
                    data_type: DataType::Unknown,
                }),
                Statement::Expression(Expression::Call {
                    name: "len".to_string(),
                    args: vec![Expression::Literal(Literal::List(vec![
                        Expression::Literal(Literal::Int(1)),
                        Expression::Literal(Literal::Int(2)),
                    ]))],
                    data_type: DataType::Unknown,
                }),
            ],
        };

        check_program_types(&mut program, "").expect("type check must pass");

        match &program.statements[0] {
            Statement::Expression(Expression::Call { data_type, .. }) => {
                assert_eq!(*data_type, DataType::None)
            }
            _ => panic!("expected call expression"),
        }
        match &program.statements[1] {
            Statement::Expression(Expression::Call { data_type, .. }) => {
                assert_eq!(*data_type, DataType::I64)
            }
            _ => panic!("expected call expression"),
        }
    }

    #[test]
    fn allows_unknown_in_logical_binary_ops() {
        let mut program = Program {
            statements: vec![
                Statement::Let {
                    name: "x".to_string(),
                    data_type: DataType::I64,
                    value: Some(Expression::Literal(Literal::Int(1))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Let {
                    name: "b".to_string(),
                    data_type: DataType::Unknown,
                    value: None,
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Expression(Expression::BinaryOp {
                    operator: "&&".to_string(),
                    left: Box::new(Expression::Identifier(Identifier {
                        name: "a".to_string(),
                        data_type: DataType::Unknown,
                        line: 0,
                        column: 0,
                    })),
                    right: Box::new(Expression::Identifier(Identifier {
                        name: "b".to_string(),
                        data_type: DataType::Unknown,
                        line: 0,
                        column: 0,
                    })),
                    data_type: DataType::Unknown,
                }),
            ],
        };

        check_program_types(&mut program, "").expect("type check must pass");
    }

    #[test]
    fn partial_typecheck_rechecks_only_selected_top_level_statements() {
        let mut previous = Program {
            statements: vec![
                Statement::Let {
                    name: "x".to_string(),
                    data_type: DataType::Unknown,
                    value: Some(Expression::Literal(Literal::Int(1))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Let {
                    name: "y".to_string(),
                    data_type: DataType::Unknown,
                    value: Some(Expression::Identifier(Identifier {
                        name: "x".to_string(),
                        data_type: DataType::Unknown,
                        line: 0,
                        column: 0,
                    })),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
            ],
        };
        check_program_types(&mut previous, "").expect("baseline type check must pass");

        let mut current = Program {
            statements: vec![
                Statement::Let {
                    name: "x".to_string(),
                    data_type: DataType::Unknown,
                    value: Some(Expression::Literal(Literal::Int(2))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                previous.statements[1].clone(),
            ],
        };

        let origins = vec![PathBuf::from("test.mire"), PathBuf::from("test.mire")];
        check_program_types_partial_with_origins(
            &mut current,
            "",
            &origins,
            &HashMap::new(),
            &AnalysisSelection {
                statement_mask: vec![true, false],
                ..AnalysisSelection::default()
            },
        )
        .expect("partial type check must pass");

        match &current.statements[0] {
            Statement::Let { data_type, .. } => assert_eq!(*data_type, DataType::I64),
            _ => panic!("expected let"),
        }

        match &current.statements[1] {
            Statement::Let {
                data_type,
                value: Some(Expression::Identifier(ident)),
                ..
            } => {
                assert_eq!(*data_type, DataType::I64);
                assert_eq!(ident.data_type, DataType::I64);
            }
            _ => panic!("expected reused typed let"),
        }
    }

    #[test]
    fn partial_typecheck_can_skip_unchanged_impl_methods() {
        let mut program = Program {
            statements: vec![Statement::Impl {
                trait_name: None,
                type_name: "Point".to_string(),
                methods: vec![
                    Statement::Function {
                        name: "good".to_string(),
                        params: vec![],
                        body: vec![Statement::Return(Some(Expression::Literal(Literal::Int(
                            1,
                        ))))],
                        return_type: DataType::I64,
                        visibility: Visibility::Public,
                        is_method: true,
                    },
                    Statement::Function {
                        name: "bad".to_string(),
                        params: vec![],
                        body: vec![Statement::Return(Some(Expression::Identifier(
                            Identifier {
                                name: "missing".to_string(),
                                data_type: DataType::Unknown,
                                line: 0,
                                column: 0,
                            },
                        )))],
                        return_type: DataType::I64,
                        visibility: Visibility::Public,
                        is_method: true,
                    },
                ],
            }],
        };

        check_program_types_partial_with_origins(
            &mut program,
            "",
            &[PathBuf::from("test.mire")],
            &HashMap::new(),
            &AnalysisSelection {
                statement_mask: vec![true],
                nested_statement_masks: HashMap::from([(
                    "impl::Point".to_string(),
                    vec![true, false],
                )]),
            },
        )
        .expect("partial type check should skip unchanged impl method");
    }

    #[test]
    fn partial_typecheck_can_skip_nested_members_in_type_class_and_code() {
        let mut program = Program {
            statements: vec![
                Statement::Type {
                    name: "PointType".to_string(),
                    parent: None,
                    fields: vec![
                        Statement::Let {
                            name: "x".to_string(),
                            data_type: DataType::Unknown,
                            value: Some(Expression::Literal(Literal::Int(1))),
                            is_constant: false,
                            is_mutable: false,
                            is_static: false,
                            visibility: Visibility::Public,
                        },
                        Statement::Let {
                            name: "broken".to_string(),
                            data_type: DataType::Unknown,
                            value: Some(Expression::Identifier(Identifier {
                                name: "missing".to_string(),
                                data_type: DataType::Unknown,
                                line: 0,
                                column: 0,
                            })),
                            is_constant: false,
                            is_mutable: false,
                            is_static: false,
                            visibility: Visibility::Public,
                        },
                    ],
                },
                Statement::Class {
                    name: "PointClass".to_string(),
                    parent: None,
                    methods: vec![
                        Statement::Function {
                            name: "good".to_string(),
                            params: vec![],
                            body: vec![Statement::Return(Some(Expression::Literal(Literal::Int(
                                1,
                            ))))],
                            return_type: DataType::I64,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                        Statement::Function {
                            name: "bad".to_string(),
                            params: vec![],
                            body: vec![Statement::Return(Some(Expression::Identifier(
                                Identifier {
                                    name: "missing".to_string(),
                                    data_type: DataType::Unknown,
                                    line: 0,
                                    column: 0,
                                },
                            )))],
                            return_type: DataType::I64,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                    ],
                },
                Statement::Code {
                    trait_name: "Drawable".to_string(),
                    type_name: "PointCode".to_string(),
                    methods: vec![
                        Statement::Function {
                            name: "draw".to_string(),
                            params: vec![],
                            body: vec![Statement::Return(Some(Expression::Literal(Literal::Int(
                                1,
                            ))))],
                            return_type: DataType::I64,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                        Statement::Function {
                            name: "broken".to_string(),
                            params: vec![],
                            body: vec![Statement::Return(Some(Expression::Identifier(
                                Identifier {
                                    name: "missing".to_string(),
                                    data_type: DataType::Unknown,
                                    line: 0,
                                    column: 0,
                                },
                            )))],
                            return_type: DataType::I64,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                    ],
                },
            ],
        };

        check_program_types_partial_with_origins(
            &mut program,
            "",
            &[
                PathBuf::from("test.mire"),
                PathBuf::from("test.mire"),
                PathBuf::from("test.mire"),
            ],
            &HashMap::new(),
            &AnalysisSelection {
                statement_mask: vec![true, true, true],
                nested_statement_masks: HashMap::from([
                    ("PointType".to_string(), vec![true, false]),
                    ("PointClass".to_string(), vec![true, false]),
                    ("code::Drawable::PointCode".to_string(), vec![true, false]),
                ]),
            },
        )
        .expect("partial type check should skip unchanged nested members");

        let Statement::Type { fields, .. } = &program.statements[0] else {
            panic!("expected type");
        };
        let Statement::Let { data_type, .. } = &fields[0] else {
            panic!("expected typed field");
        };
        assert_eq!(*data_type, DataType::I64);
    }

    #[test]
    fn dereference_of_reference_binding_recovers_pointed_type() {
        let source = "pub fn main: () {\n    set x = 1 :i64\n    set r = &x\n    set y = *r\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source).expect("type check must pass");

        let Statement::Function { body, .. } = &program.statements[0] else {
            panic!("expected function");
        };
        let Statement::Let {
            data_type,
            value:
                Some(Expression::Dereference {
                    data_type: deref_type,
                    ..
                }),
            ..
        } = &body[2]
        else {
            panic!("expected dereference binding");
        };
        assert_eq!(*deref_type, DataType::I64);
        assert_eq!(*data_type, DataType::I64);
    }

    #[test]
    fn pipeline_closure_infers_vector_of_return_type() {
        let source = "pub fn main: () {\n    set nums = [1 2 3] :vec![i64]\n    set doubled = nums => (x => x * 2)\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source).expect("pipeline should type check");

        let Statement::Function { body, .. } = &program.statements[0] else {
            panic!("expected function");
        };
        let Statement::Let { data_type, .. } = &body[1] else {
            panic!("expected pipeline let");
        };
        assert_eq!(
            *data_type,
            DataType::Vector {
                element_type: Box::new(DataType::I64),
                dynamic: true,
            }
        );
    }

    #[test]
    fn integer_literal_range_validation_does_not_scan_unrelated_scope_bindings() {
        let source = "pub fn main: () {\n    set tiny = 1 :i8\n    set big = 300 :i64\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source)
            .expect("unrelated i8 binding must not reject i64 literal");
    }

    #[test]
    fn map_assignment_rejects_vector_values() {
        let mut program = Program {
            statements: vec![
                Statement::Let {
                    name: "values".to_string(),
                    data_type: DataType::Vector {
                        element_type: Box::new(DataType::I64),
                        dynamic: true,
                    },
                    value: Some(Expression::List {
                        elements: vec![
                            Expression::Literal(Literal::Int(1)),
                            Expression::Literal(Literal::Int(2)),
                            Expression::Literal(Literal::Int(3)),
                        ],
                        element_type: DataType::I64,
                        data_type: DataType::Vector {
                            element_type: Box::new(DataType::I64),
                            dynamic: true,
                        },
                    }),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Let {
                    name: "m".to_string(),
                    data_type: DataType::Map {
                        key_type: Box::new(DataType::Str),
                        value_type: Box::new(DataType::I64),
                    },
                    value: Some(Expression::Identifier(Identifier {
                        name: "values".to_string(),
                        data_type: DataType::Unknown,
                        line: 0,
                        column: 0,
                    })),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
            ],
        };

        let err = check_program_types(&mut program, "").expect_err("must reject vec -> map");
        assert!(err.to_string().contains("Type mismatch in let 'm'"));
    }

    #[test]
    fn typed_struct_parameters_can_dispatch_instance_methods() {
        let source = "struct Counter {\n    value :i64\n}\n\nimpl Counter {\n    fn get: (self) :i64 {\n        return self.value\n    }\n}\n\nfn read_counter: (counter :Counter) :i64 {\n    return counter.get()\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source)
            .expect("typed struct parameter should preserve concrete method dispatch");
    }

    #[test]
    fn unify_types_is_order_independent_for_reference_and_value_pairs() {
        assert_eq!(
            super::TypeChecker::unify_types(
                &DataType::Ref {
                    inner: Box::new(DataType::I64),
                },
                &DataType::I64,
            )
            .expect("ref + value should unify"),
            DataType::I64
        );
        assert_eq!(
            super::TypeChecker::unify_types(
                &DataType::I64,
                &DataType::Ref {
                    inner: Box::new(DataType::I64),
                },
            )
            .expect("value + ref should unify"),
            DataType::I64
        );
    }

    #[test]
    fn mutable_reference_expectation_rejects_shared_reference_argument() {
        let mut program = Program {
            statements: vec![
                Statement::Function {
                    name: "bump".to_string(),
                    params: vec![(
                        "value".to_string(),
                        DataType::RefMut {
                            inner: Box::new(DataType::I64),
                        },
                    )],
                    body: vec![],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
                Statement::Function {
                    name: "main".to_string(),
                    params: vec![],
                    body: vec![
                        Statement::Let {
                            name: "x".to_string(),
                            data_type: DataType::I64,
                            value: Some(Expression::Literal(Literal::Int(1))),
                            is_constant: false,
                            is_mutable: false,
                            is_static: false,
                            visibility: Visibility::Public,
                        },
                        Statement::Let {
                            name: "shared".to_string(),
                            data_type: DataType::Unknown,
                            value: Some(Expression::Reference {
                                expr: Box::new(Expression::Identifier(Identifier {
                                    name: "x".to_string(),
                                    data_type: DataType::Unknown,
                                    line: 0,
                                    column: 0,
                                })),
                                is_mutable: false,
                                data_type: DataType::Unknown,
                                referenced_type: DataType::Unknown,
                            }),
                            is_constant: false,
                            is_mutable: false,
                            is_static: false,
                            visibility: Visibility::Public,
                        },
                        Statement::Expression(Expression::Call {
                            name: "bump".to_string(),
                            args: vec![Expression::Identifier(Identifier {
                                name: "shared".to_string(),
                                data_type: DataType::Unknown,
                                line: 0,
                                column: 0,
                            })],
                            data_type: DataType::Unknown,
                        }),
                    ],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
            ],
        };

        let err = check_program_types(&mut program, "")
            .expect_err("shared ref should not satisfy &mut parameter");
        assert!(
            err.to_string()
                .contains("Function 'bump' argument 1 expects")
        );
        assert!(err.to_string().contains("RefMut"));
    }

    #[test]
    fn mutable_binding_reference_is_inferred_as_refmut() {
        let source = "pub fn main: () {\n    set x = 1 :i64 mut\n    set r = &x\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source).expect("type check should pass");

        let Statement::Function { body, .. } = &program.statements[0] else {
            panic!("expected function");
        };
        let Statement::Let { data_type, .. } = &body[1] else {
            panic!("expected second let");
        };
        assert!(matches!(data_type, DataType::RefMut { .. }));
    }

    #[test]
    fn immutable_binding_reference_is_inferred_as_shared_ref() {
        let source = "pub fn main: () {\n    set x = 1 :i64\n    set r = &x\n}\n";
        let mut program = parse(source).expect("source should parse");

        check_program_types(&mut program, source).expect("type check should pass");

        let Statement::Function { body, .. } = &program.statements[0] else {
            panic!("expected function");
        };
        let Statement::Let { data_type, .. } = &body[1] else {
            panic!("expected second let");
        };
        assert!(matches!(data_type, DataType::Ref { .. }));
    }

    #[test]
    fn explicit_mut_reference_rejected_for_immutable_binding() {
        let source = "pub fn main: () {\n    set x = 1 :i64\n    set r = &mut x\n}\n";
        let mut program = parse(source).expect("source should parse");
        let err = check_program_types(&mut program, source)
            .expect_err("immutable binding cannot produce mutable reference");
        assert!(
            err.to_string()
                .contains("Cannot take mutable reference from immutable target")
        );
    }

    #[test]
    fn type_checker_source_context_does_not_leak_between_runs() {
        let source_a = "pub fn main: () {\n    use dasu(missing_a)\n}\n";
        let mut program_a = parse(source_a).expect("source A should parse");
        let err_a = check_program_types(&mut program_a, source_a).expect_err("A must fail");
        assert_eq!(err_a.source(), Some(&source_a.to_string()));

        let source_b = "pub fn main: () {\n    use dasu(missing_b)\n}\n";
        let mut program_b = parse(source_b).expect("source B should parse");
        let err_b = check_program_types(&mut program_b, source_b).expect_err("B must fail");
        assert_eq!(err_b.source(), Some(&source_b.to_string()));
        assert_ne!(err_a.source(), err_b.source());
    }

    #[test]
    fn type_checker_uses_file_source_from_origins_without_global_state() {
        let source = "pub fn main: () {\n    use dasu(missing_file)\n}\n";
        let mut program = parse(source).expect("source should parse");
        let file = PathBuf::from("prototype_typeck_context.mire");
        let origins = vec![file.clone()];
        let mut sources = HashMap::new();
        sources.insert(file.clone(), source.to_string());

        let err = check_program_types_with_origins(&mut program, "", &origins, &sources)
            .expect_err("must fail and attach origin source");
        assert_eq!(err.filename().map(String::as_str), Some("prototype_typeck_context.mire"));
        assert_eq!(err.source(), Some(&source.to_string()));
    }
}
