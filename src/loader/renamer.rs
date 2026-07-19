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
use crate::parser::ast::{AssignmentTarget, DataType, EnumVariantDef, Expression, Identifier, Literal, Statement};
use crate::parser::{Program, parse};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
pub(crate) struct ModuleRenamer<'a> {
    pub(crate) prefix: &'a str,
    pub(crate) module_symbols: &'a HashSet<String>,
}

impl<'a> ModuleRenamer<'a> {
    pub(crate) fn rename_statement(&self, statement: Statement, top_level: bool) -> Statement {
        let mut scope_stack = vec![HashSet::new()];
        self.rename_statement_with_scope(statement, &mut scope_stack, top_level)
    }

    #[allow(clippy::ptr_arg)]
    fn rename_statement_with_scope(
        &self,
        statement: Statement,
        scope_stack: &mut Vec<HashSet<String>>,
        top_level: bool,
    ) -> Statement {
        match statement {
            Statement::Let {
                name,
                data_type,
                value,
                is_constant,
                is_mutable,
                is_static,
                visibility,
                name_line,
                name_column,
            } => {
                let name = self.rename_decl_name(name, scope_stack, top_level);
                let data_type = self.rename_data_type(data_type, scope_stack);
                let value = value.map(|expr| self.rename_expression(expr, scope_stack));
                Statement::Let {
                    name,
                    data_type,
                    value,
                    is_constant,
                    is_mutable,
                    is_static,
                    visibility,
                    name_line,
                    name_column,
                }
            }
            Statement::Assignment {
                target,
                value,
                is_mutable,
            } => Statement::Assignment {
                target: self.rename_assignment_target(target, scope_stack),
                value: self.rename_expression(value, scope_stack),
                is_mutable,
            },
            Statement::Function {
                name,
                type_params,
                type_param_bounds,
                params,
                body,
                return_type,
                visibility,
                is_method,
                attributes,
            } => {
                let name = self.rename_decl_name(name, scope_stack, top_level);
                let mut body_scope = scope_stack.clone();
                if let Some(scope) = body_scope.last_mut() {
                    scope.extend(type_params.iter().cloned());
                    scope.extend(params.iter().map(|(name, _)| name.clone()));
                }
                let params = params
                    .into_iter()
                    .map(|(param_name, param_type)| {
                        (param_name, self.rename_data_type(param_type, scope_stack))
                    })
                    .collect();
                let type_param_bounds = type_param_bounds
                    .into_iter()
                    .map(|(bound, traits)| {
                        (
                            bound,
                            traits
                                .into_iter()
                                .map(|trait_name| self.rename_type_name(trait_name, scope_stack))
                                .collect(),
                        )
                    })
                    .collect();
                let return_type = self.rename_data_type(return_type, scope_stack);
                let body = self.rename_statement_block(body, &mut body_scope);
                Statement::Function {
                    attributes,
                    name,
                    type_params,
                    type_param_bounds,
                    params,
                    body,
                    return_type,
                    visibility,
                    is_method,
                }
            }
            Statement::Return(expr) => {
                Statement::Return(expr.map(|expr| self.rename_expression(expr, scope_stack)))
            }
            Statement::If {
                condition,
                then_branch,
                else_branch,
            } => Statement::If {
                condition: self.rename_expression(condition, scope_stack),
                then_branch: self.rename_statement_block(then_branch, &mut scope_stack.clone()),
                else_branch: else_branch
                    .map(|branch| self.rename_statement_block(branch, &mut scope_stack.clone())),
            },
            Statement::While { condition, body } => Statement::While {
                condition: self.rename_expression(condition, scope_stack),
                body: self.rename_statement_block(body, &mut scope_stack.clone()),
            },
            Statement::For {
                variable,
                index,
                iterable,
                body,
            } => {
                let mut body_scope = scope_stack.clone();
                if let Some(scope) = body_scope.last_mut() {
                    scope.insert(variable.clone());
                    if let Some(index) = &index {
                        scope.insert(index.clone());
                    }
                }
                Statement::For {
                    variable,
                    index,
                    iterable: self.rename_expression(iterable, scope_stack),
                    body: self.rename_statement_block(body, &mut body_scope),
                }
            }
            Statement::Expression(expr) => {
                Statement::Expression(self.rename_expression(expr, scope_stack))
            }
            Statement::Break => Statement::Break,
            Statement::Continue => Statement::Continue,
            Statement::Find {
                variable,
                iterable,
                body,
            } => {
                let mut body_scope = scope_stack.clone();
                if let Some(scope) = body_scope.last_mut() {
                    scope.insert(variable.clone());
                }
                Statement::Find {
                    variable,
                    iterable: self.rename_expression(iterable, scope_stack),
                    body: self.rename_statement_block(body, &mut body_scope),
                }
            }
            Statement::Match {
                value,
                cases,
                default,
            } => {
                let value = self.rename_expression(value, scope_stack);
                let cases = cases
                    .into_iter()
                    .map(|(pattern, body)| {
                        let pattern = self.rename_match_pattern(pattern, scope_stack);
                        let mut case_scope = scope_stack.clone();
                        if let Some(scope) = case_scope.last_mut() {
                            scope.extend(match_pattern_bindings(&pattern));
                        }
                        (pattern, self.rename_statement_block(body, &mut case_scope))
                    })
                    .collect();
                let default = self.rename_statement_block(default, &mut scope_stack.clone());
                Statement::Match {
                    value,
                    cases,
                    default,
                }
            }
            Statement::Type {
                visibility,
                name,
                type_params,
                type_param_bounds,
                parent,
                fields,
            } => {
                let name = self.rename_decl_name(name, scope_stack, top_level);
                let mut fields_scope = scope_stack.clone();
                if let Some(scope) = fields_scope.last_mut() {
                    scope.extend(type_params.iter().cloned());
                }
                let type_param_bounds = type_param_bounds
                    .into_iter()
                    .map(|(bound, traits)| {
                        (
                            bound,
                            traits
                                .into_iter()
                                .map(|trait_name| self.rename_type_name(trait_name, scope_stack))
                                .collect(),
                        )
                    })
                    .collect();
                let parent = parent.map(|parent| self.rename_type_name(parent, scope_stack));
                let fields = self.rename_statement_block(fields, &mut fields_scope);
                Statement::Type {
                    visibility,
                    name,
                    type_params,
                    type_param_bounds,
                    parent,
                    fields,
                }
            }
            Statement::Skill { name, visibility, methods } => Statement::Skill {
                name: self.rename_decl_name(name, scope_stack, top_level),
                visibility,
                methods: methods
                    .into_iter()
                    .map(|mut method| {
                        method.params = method
                            .params
                            .into_iter()
                            .map(|(param_name, param_type)| {
                                (param_name, self.rename_data_type(param_type, scope_stack))
                            })
                            .collect();
                        method.return_type = self.rename_data_type(method.return_type, scope_stack);
                        method
                    })
                    .collect(),
            },
            Statement::Impl {
                trait_name,
                type_name,
                type_params,
                type_param_bounds,
                methods,
            } => {
                let mut body_scope = scope_stack.clone();
                if let Some(scope) = body_scope.last_mut() {
                    scope.extend(type_params.iter().cloned());
                }
                let trait_name = trait_name.map(|name| self.rename_type_name(name, scope_stack));
                let type_name = self.rename_type_name(type_name, scope_stack);
                let type_param_bounds = type_param_bounds
                    .into_iter()
                    .map(|(bound, traits)| {
                        (
                            bound,
                            traits
                                .into_iter()
                                .map(|trait_name| self.rename_type_name(trait_name, scope_stack))
                                .collect(),
                        )
                    })
                    .collect();
                let methods = self.rename_statement_block(methods, &mut body_scope);
                Statement::Impl {
                    trait_name,
                    type_name,
                    type_params,
                    type_param_bounds,
                    methods,
                }
            }
            Statement::ExternLib { name, path } => Statement::ExternLib {
                name: self.rename_decl_name(name, scope_stack, top_level),
                path,
            },
            Statement::ExternFunction {
                name,
                lib_name,
                params,
                return_type,
                visibility,
            } => Statement::ExternFunction {
                name: self.rename_extern_name(name, scope_stack, top_level, &lib_name),
                lib_name,
                params: params
                    .into_iter()
                    .map(|(param_name, param_type)| {
                        (param_name, self.rename_data_type(param_type, scope_stack))
                    })
                    .collect(),
                return_type: self.rename_data_type(return_type, scope_stack),
                visibility,
            },
            Statement::Unsafe {
                line, column, body, ..
            } => Statement::Unsafe {
                line,
                column,
                body: self.rename_statement_block(body, &mut scope_stack.clone()),
            },
            Statement::Asm { instructions } => Statement::Asm {
                instructions: instructions
                    .into_iter()
                    .map(|(name, expr)| (name, self.rename_expression(expr, scope_stack)))
                    .collect(),
            },
            Statement::Load { path, alias, items } => Statement::Load { path, alias, items },
            Statement::LoadLocal {
                rel_path,
                absolute,
            } => Statement::LoadLocal {
                rel_path,
                absolute,
            },
            Statement::Module { name } => Statement::Module {
                name: self.rename_decl_name(name, scope_stack, top_level),
            },
            Statement::Drop { value } => Statement::Drop {
                value: self.rename_expression(value, scope_stack),
            },
            Statement::New {
                value,
                declared_type,
            } => Statement::New {
                value: value.map(|expr| self.rename_expression(expr, scope_stack)),
                declared_type: self.rename_data_type(declared_type, scope_stack),
            },
            Statement::Own { value, inner_type } => Statement::Own {
                value: value.map(|expr| self.rename_expression(expr, scope_stack)),
                inner_type: self.rename_data_type(inner_type, scope_stack),
            },
            Statement::Move { target, value } => Statement::Move {
                target: self.rename_decl_name(target, scope_stack, top_level),
                value: self.rename_expression(value, scope_stack),
            },
            Statement::Enum {
                visibility,
                name,
                type_params,
                type_param_bounds,
                variants,
            } => {
                let name = self.rename_decl_name(name, scope_stack, top_level);
                let type_param_bounds = type_param_bounds
                    .into_iter()
                    .map(|(bound, traits)| {
                        (
                            bound,
                            traits
                                .into_iter()
                                .map(|trait_name| self.rename_type_name(trait_name, scope_stack))
                                .collect(),
                        )
                    })
                    .collect();
                let variants = variants
                    .into_iter()
                    .map(|variant| self.rename_enum_variant(variant, &name, scope_stack))
                    .collect();
                Statement::Enum {
                    visibility,
                    name,
                    type_params,
                    type_param_bounds,
                    variants,
                }
            }
            Statement::Query {
                table,
                bindings,
                ops,
                joins,
                group_by,
            } => Statement::Query {
                table,
                bindings,
                ops: ops
                    .into_iter()
                    .map(|op| self.rename_query_op(op, scope_stack))
                    .collect(),
                joins,
                group_by,
            },
        }
    }

    fn rename_statement_block(
        &self,
        statements: Vec<Statement>,
        scope_stack: &mut Vec<HashSet<String>>,
    ) -> Vec<Statement> {
        let mut renamed = Vec::with_capacity(statements.len());
        for statement in statements {
            let renamed_statement = self.rename_statement_with_scope(statement, scope_stack, false);
            let bindings = statement_bindings(&renamed_statement);
            if let Some(scope) = scope_stack.last_mut() {
                scope.extend(bindings);
            }
            renamed.push(renamed_statement);
        }
        renamed
    }

    fn rename_decl_name(
        &self,
        name: String,
        scope_stack: &[HashSet<String>],
        top_level: bool,
    ) -> String {
        if top_level && self.should_prefix(&name, scope_stack) {
            format!("{}.{}", self.prefix, name)
        } else {
            name
        }
    }

    fn rename_extern_name(
        &self,
        name: String,
        scope_stack: &[HashSet<String>],
        top_level: bool,
        lib_name: &str,
    ) -> String {
        if lib_name == "c" {
            name
        } else if top_level && self.should_prefix(&name, scope_stack) {
            format!("{}.{}", self.prefix, name)
        } else {
            name
        }
    }

    fn rename_type_name(&self, name: String, scope_stack: &[HashSet<String>]) -> String {
        if self.should_prefix(&name, scope_stack) {
            format!("{}.{}", self.prefix, name)
        } else {
            name
        }
    }

    fn should_prefix(&self, name: &str, scope_stack: &[HashSet<String>]) -> bool {
        // Skip names that already contain a prefix (introduced by a prior pass).
        // Function names in mire are plain identifiers without dots natively,
        // so a dot means the name was already prefixed by a nested load.
        self.module_symbols.contains(name) && !is_shadowed(scope_stack, name) && !name.contains('.')
    }

    fn rename_data_type(&self, data_type: DataType, scope_stack: &[HashSet<String>]) -> DataType {
        match data_type {
            DataType::StructNamed(name) => {
                DataType::StructNamed(self.rename_type_name(name, scope_stack))
            }
            DataType::EnumNamed(name) => {
                DataType::EnumNamed(self.rename_type_name(name, scope_stack))
            }
            DataType::DynTrait { trait_name } => DataType::DynTrait {
                trait_name: self.rename_type_name(trait_name, scope_stack),
            },
            DataType::Vector {
                element_type,
                dynamic,
            } => DataType::Vector {
                element_type: Box::new(self.rename_data_type(*element_type, scope_stack)),
                dynamic,
            },
            DataType::Slice { element_type } => DataType::Slice {
                element_type: Box::new(self.rename_data_type(*element_type, scope_stack)),
            },
            DataType::Result { ok, err } => DataType::Result {
                ok: Box::new(self.rename_data_type(*ok, scope_stack)),
                err: Box::new(self.rename_data_type(*err, scope_stack)),
            },
            DataType::Map {
                key_type,
                value_type,
            } => DataType::Map {
                key_type: Box::new(self.rename_data_type(*key_type, scope_stack)),
                value_type: Box::new(self.rename_data_type(*value_type, scope_stack)),
            },
            DataType::Array { element_type, size } => DataType::Array {
                element_type: Box::new(self.rename_data_type(*element_type, scope_stack)),
                size,
            },
            DataType::Ref { inner } => DataType::Ref {
                inner: Box::new(self.rename_data_type(*inner, scope_stack)),
            },
            DataType::RefMut { inner } => DataType::RefMut {
                inner: Box::new(self.rename_data_type(*inner, scope_stack)),
            },
            other => other,
        }
    }

    fn rename_assignment_target(
        &self,
        target: AssignmentTarget,
        scope_stack: &[HashSet<String>],
    ) -> AssignmentTarget {
        match target {
            AssignmentTarget::Variable(name) => {
                AssignmentTarget::Variable(self.rename_type_name(name, scope_stack))
            }
            AssignmentTarget::Field(path) => {
                let mut parts = path.split('.').map(ToString::to_string).collect::<Vec<_>>();
                if let Some(root) = parts.first_mut() {
                    *root = self.rename_type_name(root.clone(), scope_stack);
                }
                AssignmentTarget::Field(parts.join("."))
            }
            AssignmentTarget::Index { target, index } => AssignmentTarget::Index {
                target: Box::new(self.rename_expression(*target, scope_stack)),
                index: Box::new(self.rename_expression(*index, scope_stack)),
            },
        }
    }

    fn rename_match_pattern(
        &self,
        pattern: Expression,
        scope_stack: &[HashSet<String>],
    ) -> Expression {
        match pattern {
            Expression::EnumVariant {
                enum_name,
                variant_name,
                payloads,
                data_type,
            } => Expression::EnumVariant {
                enum_name: self.rename_type_name(enum_name, scope_stack),
                variant_name,
                payloads: payloads
                    .into_iter()
                    .map(|payload| match payload {
                        Expression::Identifier(_) => payload,
                        other => self.rename_expression(other, scope_stack),
                    })
                    .collect(),
                data_type,
            },
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                data_type,
            } => Expression::EnumVariantPath {
                enum_name: self.rename_type_name(enum_name, scope_stack),
                variant_name,
                data_type,
            },
            Expression::Call {
                name,
                args,
                type_args,
                name_line,
                name_column,
                data_type,
            } if name == "__match_guard" || name == "__match_or" => Expression::Call {
                name,
                args: args
                    .into_iter()
                    .map(|arg| self.rename_match_pattern(arg, scope_stack))
                    .collect(),
                type_args: type_args
                    .into_iter()
                    .map(|data_type| self.rename_data_type(data_type, scope_stack))
                    .collect(),
                name_line,
                name_column,
                data_type,
            },
            other => self.rename_expression(other, scope_stack),
        }
    }

    fn rename_expression(
        &self,
        expression: Expression,
        scope_stack: &[HashSet<String>],
    ) -> Expression {
        match expression {
            Expression::Ascription {
                expr,
                target,
                data_type,
            } => Expression::Ascription {
                expr: Box::new(self.rename_expression(*expr, scope_stack)),
                target: self.rename_data_type(target, scope_stack),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Identifier(Identifier {
                name,
                data_type,
                line,
                column,
            }) => Expression::Identifier(Identifier {
                name: self.rename_type_name(name, scope_stack),
                data_type: self.rename_data_type(data_type, scope_stack),
                line,
                column,
            }),
            Expression::BinaryOp {
                operator,
                left,
                right,
                data_type,
            } => Expression::BinaryOp {
                operator,
                left: Box::new(self.rename_expression(*left, scope_stack)),
                right: Box::new(self.rename_expression(*right, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::UnaryOp {
                operator,
                operand,
                data_type,
            } => Expression::UnaryOp {
                operator,
                operand: Box::new(self.rename_expression(*operand, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::NamedArg {
                name,
                value,
                data_type,
            } => Expression::NamedArg {
                name,
                value: Box::new(self.rename_expression(*value, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Call {
                name,
                args,
                type_args,
                name_line,
                name_column,
                data_type,
            } => {
                let name = self.rename_type_name(name, scope_stack);
                Expression::Call {
                    name,
                    args: args
                        .into_iter()
                        .map(|arg| self.rename_expression(arg, scope_stack))
                        .collect(),
                    type_args: type_args
                        .into_iter()
                        .map(|data_type| self.rename_data_type(data_type, scope_stack))
                        .collect(),
                    name_line,
                    name_column,
                    data_type: self.rename_data_type(data_type, scope_stack),
                }
            }
            Expression::List {
                elements,
                element_type,
                data_type,
            } => Expression::List {
                elements: elements
                    .into_iter()
                    .map(|element| self.rename_expression(element, scope_stack))
                    .collect(),
                element_type: self.rename_data_type(element_type, scope_stack),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Dict {
                entries,
                key_type,
                value_type,
                data_type,
            } => Expression::Dict {
                entries: entries
                    .into_iter()
                    .map(|(key, value)| {
                        (
                            self.rename_expression(key, scope_stack),
                            self.rename_expression(value, scope_stack),
                        )
                    })
                    .collect(),
                key_type: self.rename_data_type(key_type, scope_stack),
                value_type: self.rename_data_type(value_type, scope_stack),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Tuple {
                elements,
                data_type,
            } => Expression::Tuple {
                elements: elements
                    .into_iter()
                    .map(|element| self.rename_expression(element, scope_stack))
                    .collect(),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Index {
                target,
                index,
                data_type,
            } => Expression::Index {
                target: Box::new(self.rename_expression(*target, scope_stack)),
                index: Box::new(self.rename_expression(*index, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::MemberAccess {
                target,
                member,
                data_type,
            } => Expression::MemberAccess {
                target: Box::new(self.rename_expression(*target, scope_stack)),
                member,
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Closure {
                params,
                body,
                return_type,
                capture,
            } => {
                let mut body_scope = scope_stack.to_vec();
                if let Some(scope) = body_scope.last_mut() {
                    scope.extend(params.iter().map(|(name, _)| name.clone()));
                }
                Expression::Closure {
                    params: params
                        .into_iter()
                        .map(|(name, data_type)| {
                            (name, self.rename_data_type(data_type, scope_stack))
                        })
                        .collect(),
                    body: self.rename_statement_block(body, &mut body_scope),
                    return_type: self.rename_data_type(return_type, scope_stack),
                    capture,
                }
            }
            Expression::Reference {
                expr,
                is_mutable,
                data_type,
                referenced_type,
            } => Expression::Reference {
                expr: Box::new(self.rename_expression(*expr, scope_stack)),
                is_mutable,
                data_type: self.rename_data_type(data_type, scope_stack),
                referenced_type: self.rename_data_type(referenced_type, scope_stack),
            },
            Expression::Dereference { expr, data_type } => Expression::Dereference {
                expr: Box::new(self.rename_expression(*expr, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Box { value, data_type } => Expression::Box {
                value: Box::new(self.rename_expression(*value, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Pipeline {
                input,
                stage,
                safe,
                data_type,
            } => Expression::Pipeline {
                input: Box::new(self.rename_expression(*input, scope_stack)),
                stage: Box::new(self.rename_expression(*stage, scope_stack)),
                safe,
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Try { expr, data_type } => Expression::Try {
                expr: Box::new(self.rename_expression(*expr, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Ok { value, data_type } => Expression::Ok {
                value: Box::new(self.rename_expression(*value, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Err { value, data_type } => Expression::Err {
                value: Box::new(self.rename_expression(*value, scope_stack)),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::Match {
                value,
                cases,
                default,
                data_type,
            } => {
                let value = self.rename_expression(*value, scope_stack);
                let cases = cases
                    .into_iter()
                    .map(|(pattern, body)| {
                        let pattern = self.rename_match_pattern(pattern, scope_stack);
                        let mut case_scope = scope_stack.to_vec();
                        if let Some(scope) = case_scope.last_mut() {
                            scope.extend(match_pattern_bindings(&pattern));
                        }
                        (pattern, self.rename_expression(body, &case_scope))
                    })
                    .collect();
                let default = Box::new(self.rename_expression(*default, scope_stack));
                Expression::Match {
                    value: Box::new(value),
                    cases,
                    default,
                    data_type: self.rename_data_type(data_type, scope_stack),
                }
            }
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                data_type,
            } => Expression::EnumVariantPath {
                enum_name: self.rename_type_name(enum_name, scope_stack),
                variant_name,
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::EnumVariant {
                enum_name,
                variant_name,
                payloads,
                data_type,
            } => Expression::EnumVariant {
                enum_name: self.rename_type_name(enum_name, scope_stack),
                variant_name,
                payloads: payloads
                    .into_iter()
                    .map(|payload| self.rename_expression(payload, scope_stack))
                    .collect(),
                data_type: self.rename_data_type(data_type, scope_stack),
            },
            Expression::UseMacro { inner } => Expression::UseMacro {
                inner: Box::new(self.rename_expression(*inner, scope_stack)),
            },
            Expression::Literal(literal) => Expression::Literal(match literal {
                Literal::List(elements) => Literal::List(
                    elements
                        .into_iter()
                        .map(|element| self.rename_expression(element, scope_stack))
                        .collect(),
                ),
                Literal::Dict(entries) => Literal::Dict(
                    entries
                        .into_iter()
                        .map(|((key, value), data_type)| {
                            (
                                (
                                    self.rename_expression(key, scope_stack),
                                    self.rename_expression(value, scope_stack),
                                ),
                                self.rename_data_type(data_type, scope_stack),
                            )
                        })
                        .collect(),
                ),
                Literal::Tuple(elements) => Literal::Tuple(
                    elements
                        .into_iter()
                        .map(|element| self.rename_expression(element, scope_stack))
                        .collect(),
                ),
                other => other,
            }),
        }
    }

    fn rename_query_op(
        &self,
        op: crate::parser::ast::QueryOp,
        scope_stack: &[HashSet<String>],
    ) -> crate::parser::ast::QueryOp {
        match op {
            crate::parser::ast::QueryOp::Insert { assigns } => {
                crate::parser::ast::QueryOp::Insert {
                    assigns: assigns
                        .into_iter()
                        .map(|(name, expr)| (name, self.rename_expression(expr, scope_stack)))
                        .collect(),
                }
            }
            crate::parser::ast::QueryOp::Update { condition, assigns } => {
                crate::parser::ast::QueryOp::Update {
                    condition: self.rename_expression(condition, scope_stack),
                    assigns: assigns
                        .into_iter()
                        .map(|(name, expr)| (name, self.rename_expression(expr, scope_stack)))
                        .collect(),
                }
            }
            crate::parser::ast::QueryOp::Delete { condition } => {
                crate::parser::ast::QueryOp::Delete {
                    condition: self.rename_expression(condition, scope_stack),
                }
            }
            crate::parser::ast::QueryOp::Get(mut get) => {
                get.condition = self.rename_expression(get.condition, scope_stack);
                get.body = self.rename_statement_block(get.body, &mut scope_stack.to_vec());
                crate::parser::ast::QueryOp::Get(get)
            }
            other => other,
        }
    }

    fn rename_enum_variant(
        &self,
        mut variant: EnumVariantDef,
        enum_name: &str,
        scope_stack: &[HashSet<String>],
    ) -> EnumVariantDef {
        variant.enum_name = enum_name.to_string();
        variant.data_types = variant
            .data_types
            .into_iter()
            .map(|data_type| self.rename_data_type(data_type, scope_stack))
            .collect();
        variant
    }
}

fn is_shadowed(scope_stack: &[HashSet<String>], name: &str) -> bool {
    scope_stack.iter().rev().any(|scope| scope.contains(name))
}

fn match_pattern_bindings(pattern: &Expression) -> Vec<String> {
    let mut bindings = Vec::new();
    match pattern {
        Expression::EnumVariant { payloads, .. } => {
            for payload in payloads {
                if let Expression::Identifier(Identifier { name, .. }) = payload {
                    bindings.push(name.clone());
                }
            }
        }
        Expression::Call { name, args, .. } if name == "__match_guard" || name == "__match_or" => {
            if let Some(inner) = args.first() {
                bindings.extend(match_pattern_bindings(inner));
            }
        }
        _ => {}
    }
    bindings
}

fn statement_bindings(statement: &Statement) -> Vec<String> {
    let mut bindings = Vec::new();
    match statement {
        Statement::Let { name, .. }
        | Statement::Function { name, .. }
        | Statement::Type { name, .. }
        | Statement::Skill { name, .. }
        | Statement::Module { name, .. }
        | Statement::Enum { name, .. }
        | Statement::ExternLib { name, .. }
        | Statement::ExternFunction { name, .. } => bindings.push(name.clone()),
        Statement::For {
            variable, index, ..
        } => {
            bindings.push(variable.clone());
            if let Some(index) = index {
                bindings.push(index.clone());
            }
        }
        Statement::Find { variable, .. }
        | Statement::Move {
            target: variable, ..
        } => bindings.push(variable.clone()),
        _ => {}
    }
    bindings
}

pub(crate) fn select_imported_statements(
    statements: &[ExpandedStatement],
    items: Option<&[String]>,
    import_path: &Path,
) -> Result<Vec<ExpandedStatement>> {
    if let Some(items) = items {
        let mut selected_indices = Vec::new();
        let mut selected = HashSet::new();
        for item in items {
            let statement_idx = statements
                .iter()
                .enumerate()
                .find(|statement| {
                    statement_export_name(&statement.1.statement) == Some(item.as_str())
                })
                .map(|(idx, _)| idx)
                .ok_or_else(|| {
                    MireError::new(ErrorKind::Runtime {
                        line: 0,
                        column: 0,
                        message: format!(
                            "Local load '{}' does not export '{}'",
                            import_path.display(),
                            item
                        ),
                    })
                })?;
            if selected.insert(statement_idx) {
                selected_indices.push(statement_idx);
            }
        }

        let mut cursor = 0usize;
        while cursor < selected_indices.len() {
            let idx = selected_indices[cursor];
            cursor += 1;

            let mut deps = Vec::new();
            collect_statement_dependencies(&statements[idx].statement, &mut deps);
            for dependency in deps {
                for candidate in [
                    Some(dependency.as_str()),
                    dependency.rsplit_once('.').map(|(_, tail)| tail),
                ] {
                    let Some(candidate_name) = candidate else {
                        continue;
                    };
                    for (dep_idx, statement) in statements.iter().enumerate() {
                        let export_name = statement_export_name(&statement.statement);
                        let internal_name = match &statement.statement {
                            Statement::ExternFunction { name, .. }
                            | Statement::ExternLib { name, .. } => Some(name.as_str()),
                            // Module-level bindings (`set`/`let`) and private
                            // functions are shared module state. They must be
                            // includable as transitive dependencies of an
                            // imported function (e.g. a private helper called
                            // by a pub function, or a module binding consumed
                            // by one of its own functions), even when they are
                            // not `pub`. Without this, importing a module drops
                            // its internal helpers and downstream functions fail
                            // to resolve them.
                            Statement::Function { name, .. } => Some(name.as_str()),
                            Statement::Let { name, .. } => Some(name.as_str()),
                            Statement::Assignment {
                                target: AssignmentTarget::Variable(name),
                                ..
                            } => Some(name.as_str()),
                            _ => None,
                        };
                        if (export_name == Some(candidate_name)
                            || internal_name == Some(candidate_name))
                            && selected.insert(dep_idx)
                        {
                            selected_indices.push(dep_idx);
                        }
                    }
                }
            }
        }

        // Second pass: include impl blocks for selected types, then process their deps
        let mut selected_types: HashSet<String> = HashSet::new();
        for idx in &selected_indices {
            if let Statement::Type { name, .. } | Statement::Enum { name, .. } =
                &statements[*idx].statement
            {
                selected_types.insert(name.clone());
            }
        }
        for (idx, statement) in statements.iter().enumerate() {
            if !selected.contains(&idx)
                && let Statement::Impl { type_name, .. } = &statement.statement
            {
                let base = type_name.rsplit('.').next().unwrap_or(type_name);
                if selected_types.contains(type_name) || selected_types.contains(base) {
                    selected.insert(idx);
                    selected_indices.push(idx);
                }
            }
        }
        // Process dependencies of newly added impl blocks (they reference trait names)
        while cursor < selected_indices.len() {
            let idx = selected_indices[cursor];
            cursor += 1;
            let mut deps = Vec::new();
            collect_statement_dependencies(&statements[idx].statement, &mut deps);
            for dependency in deps {
                for candidate in [
                    Some(dependency.as_str()),
                    dependency.rsplit_once('.').map(|(_, tail)| tail),
                ] {
                    let Some(candidate_name) = candidate else {
                        continue;
                    };
                    for (dep_idx, statement) in statements.iter().enumerate() {
                        let export_name = statement_export_name(&statement.statement);
                        let internal_name = match &statement.statement {
                            Statement::ExternFunction { name, .. }
                            | Statement::ExternLib { name, .. } => Some(name.as_str()),
                            // Module-level bindings (`set`/`let`) and private
                            // functions are shared module state. They must be
                            // includable as transitive dependencies of an
                            // imported function (e.g. a private helper called
                            // by a pub function, or a module binding consumed
                            // by one of its own functions), even when they are
                            // not `pub`. Without this, importing a module drops
                            // its internal helpers and downstream functions fail
                            // to resolve them.
                            Statement::Function { name, .. } => Some(name.as_str()),
                            Statement::Let { name, .. } => Some(name.as_str()),
                            Statement::Assignment {
                                target: AssignmentTarget::Variable(name),
                                ..
                            } => Some(name.as_str()),
                            _ => None,
                        };
                        if (export_name == Some(candidate_name)
                            || internal_name == Some(candidate_name))
                            && selected.insert(dep_idx)
                        {
                            selected_indices.push(dep_idx);
                        }
                    }
                }
            }
        }

        let mut reachable = Vec::new();
        for (idx, statement) in statements.iter().enumerate() {
            if selected.contains(&idx) {
                reachable.push(statement.clone());
            }
        }
        return Ok(reachable);
    }

    // Wildcard load (items=None): start with all pub items and impl blocks,
    // then resolve transitive dependencies so private helpers called by pub
    // functions are included.
    let mut selected: HashSet<usize> = HashSet::new();
    let mut selected_indices: Vec<usize> = Vec::new();
    for (idx, statement) in statements.iter().enumerate() {
        if statement_export_name(&statement.statement).is_some()
            || matches!(&statement.statement, Statement::Impl { .. })
        {
            if selected.insert(idx) {
                selected_indices.push(idx);
            }
        }
    }

    let mut cursor = 0usize;
    while cursor < selected_indices.len() {
        let idx = selected_indices[cursor];
        cursor += 1;

        let mut deps = Vec::new();
        collect_statement_dependencies(&statements[idx].statement, &mut deps);
        for dependency in deps {
            for candidate in [
                Some(dependency.as_str()),
                dependency.rsplit_once('.').map(|(_, tail)| tail),
            ] {
                let Some(candidate_name) = candidate else {
                    continue;
                };
                for (dep_idx, statement) in statements.iter().enumerate() {
                    let export_name = statement_export_name(&statement.statement);
                    let internal_name = match &statement.statement {
                        Statement::ExternFunction { name, .. }
                        | Statement::ExternLib { name, .. } => Some(name.as_str()),
                        Statement::Function { name, .. } => Some(name.as_str()),
                        Statement::Let { name, .. } => Some(name.as_str()),
                        Statement::Assignment {
                            target: AssignmentTarget::Variable(name),
                            ..
                        } => Some(name.as_str()),
                        _ => None,
                    };
                    if (export_name == Some(candidate_name)
                        || internal_name == Some(candidate_name))
                        && selected.insert(dep_idx)
                    {
                        selected_indices.push(dep_idx);
                    }
                }
            }
        }
    }

    let mut result: Vec<ExpandedStatement> = Vec::new();
    for (idx, statement) in statements.iter().enumerate() {
        if selected.contains(&idx) {
            result.push(statement.clone());
        }
    }
    Ok(result)
}

