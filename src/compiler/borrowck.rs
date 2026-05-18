use std::collections::HashMap;
use std::path::PathBuf;

use crate::compiler::AnalysisSelection;
use crate::compiler::semantic::{BindingInfo, BindingKind, FunctionInfo, SemanticModel};
use crate::error::mss::MssError;
use crate::error::{ErrorKind, MireError, Result};
use crate::incremental::analysis_unit_key;
use crate::parser::ast::{AssignmentTarget, DataType, Expression, Program, QueryOp, Statement};

pub fn check_program(program: &Program, semantic_model: &SemanticModel) -> Result<()> {
    let mut checker = BorrowChecker::new(semantic_model);
    checker.check_top_level_statements(&program.statements)
}

pub fn check_program_with_origins(
    program: &Program,
    semantic_model: &SemanticModel,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
) -> Result<()> {
    check_program_partial_with_origins(
        program,
        semantic_model,
        statement_origins,
        sources,
        &AnalysisSelection::full(program),
    )
}

pub fn check_program_partial_with_origins(
    program: &Program,
    semantic_model: &SemanticModel,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
    selection: &AnalysisSelection,
) -> Result<()> {
    let mut checker = BorrowChecker::new(semantic_model);
    checker.statement_origins = statement_origins
        .iter()
        .map(|path| path.display().to_string())
        .collect();
    checker.sources_by_filename = sources
        .iter()
        .map(|(path, source)| (path.display().to_string(), source.clone()))
        .collect();
    checker.nested_statement_masks = selection.nested_statement_masks.clone();
    checker.check_selected_top_level_statements(&program.statements, &selection.statement_mask)
}

#[derive(Debug, Clone, Default)]
struct BindingState {
    is_moved: bool,
    immutable_borrows: usize,
    mutable_borrow: bool,
    ref_target: Option<ReferenceBinding>,
}

#[derive(Debug, Clone)]
struct ReferenceBinding {
    target: String,
    is_mutable: bool,
}

struct BorrowChecker<'a> {
    semantic_model: &'a SemanticModel,
    scopes: Vec<HashMap<String, BindingState>>,
    unsafe_depth: usize,
    function_stack: Vec<FunctionContext>,
    impl_owner_stack: Vec<String>,
    statement_origins: Vec<String>,
    sources_by_filename: HashMap<String, String>,
    current_filename: Option<String>,
    current_line: usize,
    current_column: usize,
    current_top_level_index: Option<usize>,
    current_top_level_key: Option<String>,
    nested_statement_masks: HashMap<String, Vec<bool>>,
}

#[derive(Debug, Clone)]
struct FunctionContext {
    scope_id: usize,
}

impl<'a> BorrowChecker<'a> {
    fn new(semantic_model: &'a SemanticModel) -> Self {
        Self {
            semantic_model,
            scopes: vec![HashMap::new()],
            unsafe_depth: 0,
            function_stack: Vec::new(),
            impl_owner_stack: Vec::new(),
            statement_origins: Vec::new(),
            sources_by_filename: HashMap::new(),
            current_filename: None,
            current_line: 1,
            current_column: 1,
            current_top_level_index: None,
            current_top_level_key: None,
            nested_statement_masks: HashMap::new(),
        }
    }

    fn check_top_level_statements(&mut self, statements: &[Statement]) -> Result<()> {
        for (index, statement) in statements.iter().enumerate() {
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
        statements: &[Statement],
        statement_mask: &[bool],
    ) -> Result<()> {
        if statement_mask.len() != statements.len() {
            return Err(MireError::new(ErrorKind::Runtime {
                message: format!(
                    "Borrow check mask length mismatch: expected {}, got {}",
                    statements.len(),
                    statement_mask.len()
                ),
            }));
        }

        for (index, (statement, should_check)) in statements
            .iter()
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

    fn attach_current_context(&self, err: MireError) -> MireError {
        let err = if err.filename().is_none() {
            if let Some(filename) = &self.current_filename {
                err.with_filename(filename.clone())
            } else {
                err
            }
        } else {
            err
        };

        if err.source().is_none()
            && let Some(filename) = err.filename()
            && let Some(source) = self.sources_by_filename.get(filename)
        {
            return err.with_source(source.clone());
        }

        err
    }

    fn check_statements(&mut self, statements: &[Statement]) -> Result<()> {
        for statement in statements {
            self.check_statement(statement)?;
        }
        Ok(())
    }

    fn check_statement(&mut self, statement: &Statement) -> Result<()> {
        let (line, column) = Self::statement_location(statement);
        self.current_line = line;
        self.current_column = column;
        match statement {
            Statement::Let { name, value, .. } => {
                if let Some(value) = value {
                    self.check_expression(value)?;
                }
                let mut state = BindingState::default();
                if let Some((target, is_mutable)) = Self::reference_target(value.as_ref()) {
                    self.register_borrow(&target, is_mutable)?;
                    state.ref_target = Some(ReferenceBinding { target, is_mutable });
                }
                self.insert_binding(name.clone(), state);
            }
            Statement::Assignment { target, value, .. } => {
                let binding_target = assignment_binding_target(target);
                self.ensure_binding_available(&binding_target)?;
                self.ensure_can_write(&binding_target)?;
                if let AssignmentTarget::Index { target, index } = target {
                    self.check_expression(target)?;
                    self.check_expression(index)?;
                }
                self.check_expression(value)?;
                if matches!(target, AssignmentTarget::Variable(name) if name == &binding_target) {
                    self.rebind_reference_target(
                        &binding_target,
                        Self::reference_target(Some(value)),
                    )?;
                }
                if let Some(state) = self.lookup_binding_mut(&binding_target) {
                    state.is_moved = false;
                }
            }
            Statement::Function {
                name, params, body, ..
            } => {
                let scope_id = self
                    .current_function_scope_id(name)
                    .unwrap_or_else(|| self.current_scope_depth() + 1);
                self.push_scope();
                self.function_stack.push(FunctionContext { scope_id });
                for (name, _) in params {
                    self.insert_binding(name.clone(), BindingState::default());
                }
                let result = self.check_statements(body);
                if result.is_ok()
                    && !statements_contain_explicit_return(body)
                    && let Some(expr) = implicit_return_expression(body)
                {
                    self.ensure_return_is_safe(expr)?;
                }
                self.function_stack.pop();
                self.pop_scope();
                result?;
            }
            Statement::Return(expr) => {
                if let Some(expr) = expr {
                    self.check_expression(expr)?;
                    self.ensure_return_is_safe(expr)?;
                }
            }
            Statement::If {
                condition,
                then_branch,
                else_branch,
            } => {
                self.check_expression(condition)?;
                self.push_scope();
                self.check_statements(then_branch)?;
                self.pop_scope();
                if let Some(else_branch) = else_branch {
                    self.push_scope();
                    self.check_statements(else_branch)?;
                    self.pop_scope();
                }
            }
            Statement::While { condition, body } => {
                self.check_expression(condition)?;
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
                self.check_expression(iterable)?;
                self.push_scope();
                self.insert_binding(variable.clone(), BindingState::default());
                if let Some(index_name) = index {
                    self.insert_binding(index_name.clone(), BindingState::default());
                }
                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::Find {
                variable,
                iterable,
                body,
            } => {
                self.check_expression(iterable)?;
                self.push_scope();
                self.insert_binding(variable.clone(), BindingState::default());
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
                self.check_expression(value)?;
                for (case_expr, case_body) in cases {
                    // Skip pattern checking - they're just comparison values
                    self.push_scope();
                    self.insert_match_pattern_bindings(case_expr);
                    self.check_statements(case_body)?;
                    self.pop_scope();
                }
                self.push_scope();
                self.check_statements(default)?;
                self.pop_scope();
            }
            Statement::Impl {
                type_name, methods, ..
            } => {
                self.impl_owner_stack.push(type_name.clone());
                let method_mask = self
                    .current_nested_statement_mask()
                    .map(|mask| mask.to_vec());
                for (method_index, method) in methods.iter().enumerate() {
                    if method_mask
                        .as_ref()
                        .and_then(|mask| mask.get(method_index))
                        .is_some_and(|should_check| !should_check)
                    {
                        continue;
                    }
                    self.check_statement(method)?;
                }
                self.impl_owner_stack.pop();
            }
            Statement::Class { methods, .. } | Statement::Code { methods, .. } => {
                self.check_statements(methods)?;
            }
            Statement::Type { fields, .. } => {
                self.check_statements(fields)?;
            }
            Statement::Skill { .. } => {}
            Statement::Unsafe { body } => {
                self.unsafe_depth += 1;
                self.push_scope();
                let result = self.check_statements(body);
                self.pop_scope();
                self.unsafe_depth = self.unsafe_depth.saturating_sub(1);
                result?;
            }
            Statement::Asm { instructions } => {
                for (_, expr) in instructions {
                    self.check_expression(expr)?;
                }
            }
            Statement::Module { body, .. }
            | Statement::DmireTable { body, .. }
            | Statement::DmireColumn { body, .. } => {
                self.push_scope();
                self.check_statements(body)?;
                self.pop_scope();
            }
            Statement::Drop { value } => {
                self.check_expression(value)?;
                if let Some(name) = Self::identifier_name(value) {
                    self.ensure_can_drop(&name)?;
                    if let Some(state) = self.lookup_binding_mut(&name) {
                        state.is_moved = true;
                    }
                }
            }
            Statement::New { value, .. } | Statement::Own { value, .. } => {
                if let Some(value) = value {
                    self.check_expression(value)?;
                }
            }
            Statement::Move { target, value } => {
                self.check_expression(value)?;
                if let Some(source) = Self::identifier_name(value) {
                    self.ensure_can_move(&source)?;
                    if let Some(state) = self.lookup_binding_mut(&source) {
                        state.is_moved = true;
                    }
                }
                self.insert_binding(target.clone(), BindingState::default());
            }
            Statement::Query { bindings, ops, .. } => {
                self.push_scope();
                for binding in bindings {
                    self.insert_binding(binding.target.clone(), BindingState::default());
                    self.insert_binding(binding.alias.clone(), BindingState::default());
                }
                for op in ops {
                    self.check_query_op(op)?;
                }
                self.pop_scope();
            }
            Statement::DmireDlist { data, .. } => {
                for expr in data {
                    self.check_expression(expr)?;
                }
            }
            Statement::Break
            | Statement::Continue
            | Statement::Trait { .. }
            | Statement::ExternLib { .. }
            | Statement::ExternFunction { .. }
            | Statement::AddLib { .. }
            | Statement::Use { .. }
            | Statement::Enum { .. } => {}
        }

        Ok(())
    }

    fn check_query_op(&mut self, op: &QueryOp) -> Result<()> {
        match op {
            QueryOp::Insert { assigns } => {
                for (_, expr) in assigns {
                    self.check_expression(expr)?;
                }
            }
            QueryOp::Update { condition, assigns } => {
                self.check_expression(condition)?;
                for (_, expr) in assigns {
                    self.check_expression(expr)?;
                }
            }
            QueryOp::Delete { condition } => {
                self.check_expression(condition)?;
            }
            QueryOp::Get(get) => {
                self.check_expression(&get.condition)?;
                self.push_scope();
                self.insert_binding(get.target.clone(), BindingState::default());
                self.check_statements(&get.body)?;
                self.pop_scope();
            }
            QueryOp::Export { .. } | QueryOp::Import { .. } => {}
        }
        Ok(())
    }

    fn check_expression(&mut self, expression: &Expression) -> Result<()> {
        let (line, column) = Self::expression_location(expression);
        self.current_line = line;
        self.current_column = column;
        match expression {
            Expression::Literal(_) => {}
            Expression::Identifier(ident) => {
                self.ensure_binding_available(&ident.name)?;
            }
            Expression::BinaryOp { left, right, .. } => {
                self.check_expression(left)?;
                self.check_expression(right)?;
            }
            Expression::UnaryOp { operand, .. } => {
                self.check_expression(operand)?;
            }
            Expression::NamedArg { value, .. } => {
                self.check_expression(value)?;
            }
            Expression::Call { name, args, .. } => {
                for (index, arg) in args.iter().enumerate() {
                    self.check_expression(arg)?;
                    self.check_call_argument(name, index, arg)?;
                }
            }
            Expression::List { elements: args, .. } | Expression::Tuple { elements: args, .. } => {
                for arg in args {
                    self.check_expression(arg)?;
                }
            }
            Expression::Dict { entries, .. } => {
                for (key, value) in entries {
                    self.check_expression(key)?;
                    self.check_expression(value)?;
                }
            }
            Expression::Index { target, index, .. } => {
                self.check_expression(target)?;
                self.check_expression(index)?;
            }
            Expression::MemberAccess { target, .. } => {
                self.check_expression(target)?;
            }
            Expression::Closure { body, .. } => {
                self.push_scope();
                if let Expression::Closure {
                    params, capture, ..
                } = expression
                {
                    for (name, _) in capture {
                        self.insert_binding(name.clone(), BindingState::default());
                    }
                    for (name, _) in params {
                        self.insert_binding(name.clone(), BindingState::default());
                    }
                }
                self.check_statements(body)?;
                self.pop_scope();
            }
            Expression::Reference {
                expr, is_mutable, ..
            } => {
                self.check_expression(expr)?;
                if let Some(name) = Self::identifier_name(expr) {
                    self.ensure_borrow_allowed(&name, *is_mutable)?;
                }
            }
            Expression::Dereference { expr, .. } | Expression::Box { value: expr, .. } => {
                self.check_expression(expr)?;
            }
            Expression::Pipeline { input, stage, .. } => {
                self.check_expression(input)?;
                self.check_expression(stage)?;
            }
            Expression::Match {
                value,
                cases,
                default,
                ..
            } => {
                self.check_expression(value)?;
                for (pattern, result) in cases {
                    // Skip pattern checking - they're just comparison values
                    self.push_scope();
                    self.insert_match_pattern_bindings(pattern);
                    self.check_expression(result)?;
                    self.pop_scope();
                }
                self.check_expression(default)?;
            }
            Expression::EnumVariantPath { .. } => {}
            Expression::EnumVariant { payloads, .. } => {
                for payload in payloads {
                    self.check_expression(payload)?;
                }
            }
        }
        Ok(())
    }

    fn ensure_binding_available(&self, name: &str) -> Result<()> {
        if let Some(state) = self.lookup_binding(name)
            && state.is_moved
        {
            return Err(self.ownership_error(MssError::UseAfterMove));
        }
        Ok(())
    }

    fn ensure_can_write(&self, name: &str) -> Result<()> {
        if self.unsafe_depth > 0 {
            return Ok(());
        }
        let state = self
            .lookup_binding(name)
            .ok_or_else(|| self.ownership_error(MssError::UseAfterMove))?;
        if state.mutable_borrow || state.immutable_borrows > 0 {
            return Err(self.ownership_error(MssError::MutationWhileShared));
        }
        Ok(())
    }

    fn ensure_can_move(&self, name: &str) -> Result<()> {
        let state = self
            .lookup_binding(name)
            .ok_or_else(|| self.ownership_error(MssError::UseAfterMove))?;
        if state.is_moved {
            return Err(self.ownership_error(MssError::UseAfterMove));
        }
        if self.unsafe_depth == 0 && (state.mutable_borrow || state.immutable_borrows > 0) {
            return Err(self.ownership_error(MssError::MoveWhileBorrowed));
        }
        Ok(())
    }

    fn ensure_can_drop(&self, name: &str) -> Result<()> {
        let state = self
            .lookup_binding(name)
            .ok_or_else(|| self.ownership_error(MssError::UseAfterMove))?;
        if state.is_moved {
            return Err(self.ownership_error(MssError::UseAfterMove));
        }
        if self.unsafe_depth == 0 && (state.mutable_borrow || state.immutable_borrows > 0) {
            return Err(self.ownership_error(MssError::DropWhileBorrowed));
        }
        Ok(())
    }

    fn ensure_borrow_allowed(&self, name: &str, is_mutable: bool) -> Result<()> {
        if self.unsafe_depth > 0 {
            return Ok(());
        }
        let state = self
            .lookup_binding(name)
            .ok_or_else(|| self.ownership_error(MssError::UseAfterMove))?;
        if state.is_moved {
            return Err(self.ownership_error(MssError::UseAfterMove));
        }
        if is_mutable {
            if state.mutable_borrow {
                return Err(self.ownership_error(MssError::MultipleMutableRefs));
            }
            if state.immutable_borrows > 0 {
                return Err(self.ownership_error(MssError::MutationWhileShared));
            }
        } else if state.mutable_borrow {
            return Err(self.ownership_error(MssError::MutationWhileShared));
        }
        Ok(())
    }

    fn register_borrow(&mut self, name: &str, is_mutable: bool) -> Result<()> {
        self.ensure_borrow_allowed(name, is_mutable)?;
        let state = match self.lookup_binding_mut(name) {
            Some(state) => state,
            None => return Err(self.ownership_error(MssError::UseAfterMove)),
        };
        if is_mutable {
            state.mutable_borrow = true;
        } else {
            state.immutable_borrows += 1;
        }
        Ok(())
    }

    fn release_borrow(&mut self, name: &str, is_mutable: bool) {
        if let Some(state) = self.lookup_binding_mut(name) {
            if is_mutable {
                state.mutable_borrow = false;
            } else if state.immutable_borrows > 0 {
                state.immutable_borrows -= 1;
            }
        }
    }

    fn push_scope(&mut self) {
        self.scopes.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        if self.scopes.len() <= 1 {
            return;
        }

        if let Some(scope) = self.scopes.pop() {
            for (_, binding) in scope {
                if let Some(reference) = binding.ref_target {
                    self.release_borrow(&reference.target, reference.is_mutable);
                }
            }
        }
    }

    fn insert_binding(&mut self, name: String, state: BindingState) {
        let previous = self
            .scopes
            .last_mut()
            .and_then(|scope| scope.insert(name, state));
        if let Some(previous) = previous.and_then(|binding| binding.ref_target) {
            self.release_borrow(&previous.target, previous.is_mutable);
        }
    }

    fn insert_match_pattern_bindings(&mut self, pattern: &Expression) {
        if let Expression::EnumVariant { payloads, .. } = pattern {
            for payload in payloads {
                if let Expression::Identifier(ident) = payload {
                    self.insert_binding(ident.name.clone(), BindingState::default());
                }
            }
        }
    }

    fn rebind_reference_target(
        &mut self,
        name: &str,
        new_reference: Option<(String, bool)>,
    ) -> Result<()> {
        let old_reference = self
            .lookup_binding(name)
            .and_then(|state| state.ref_target.clone());
        if let Some(old_reference) = old_reference {
            self.release_borrow(&old_reference.target, old_reference.is_mutable);
        }

        if let Some((target, is_mutable)) = new_reference {
            self.register_borrow(&target, is_mutable)?;
            if let Some(state) = self.lookup_binding_mut(name) {
                state.ref_target = Some(ReferenceBinding { target, is_mutable });
            }
        } else if let Some(state) = self.lookup_binding_mut(name) {
            state.ref_target = None;
        }

        Ok(())
    }

    fn lookup_binding(&self, name: &str) -> Option<&BindingState> {
        for scope in self.scopes.iter().rev() {
            if let Some(binding) = scope.get(name) {
                return Some(binding);
            }
        }
        None
    }

    fn lookup_binding_mut(&mut self, name: &str) -> Option<&mut BindingState> {
        for scope in self.scopes.iter_mut().rev() {
            if let Some(binding) = scope.get_mut(name) {
                return Some(binding);
            }
        }
        None
    }

    fn current_scope_depth(&self) -> usize {
        self.scopes.len().saturating_sub(1)
    }

    fn current_function_scope_id(&self, name: &str) -> Option<usize> {
        self.semantic_model
            .functions
            .get(name)
            .or_else(|| {
                self.impl_owner_stack.last().and_then(|owner| {
                    self.semantic_model
                        .functions
                        .get(&format!("{owner}.{name}"))
                })
            })
            .map(|info| info.scope_id)
    }

    fn ensure_return_is_safe(&self, expression: &Expression) -> Result<()> {
        let Some(function_context) = self.function_stack.last() else {
            return Ok(());
        };

        if let Some((target, is_mutable)) = Self::reference_target(Some(expression)) {
            let binding = self
                .semantic_binding(&target)
                .ok_or_else(|| self.ownership_error(MssError::BorrowOutOfScope))?;

            let is_reference_binding = matches!(
                binding.kind,
                BindingKind::SharedRef | BindingKind::MutableRef
            );
            let same_function_scope = binding.scope_id >= function_context.scope_id;

            if same_function_scope && !is_reference_binding {
                return Err(self.ownership_error(if is_mutable {
                    MssError::UnsafeViolation
                } else {
                    MssError::BorrowOutOfScope
                }));
            }
        }

        Ok(())
    }

    fn check_call_argument(&mut self, callee: &str, index: usize, arg: &Expression) -> Result<()> {
        let Some(function) = self.resolve_semantic_function(callee) else {
            return Ok(());
        };
        let Some(expected) = function.params.get(index) else {
            return Ok(());
        };

        match expected {
            DataType::Ref { .. } => {
                if let Some((target, is_mutable)) = Self::reference_target(Some(arg)) {
                    if is_mutable {
                        return Err(self.ownership_error(MssError::MultipleMutableRefs));
                    }
                    self.ensure_borrow_allowed(&target, false)?;
                } else if let Some(binding) =
                    Self::identifier_name(arg).and_then(|name| self.semantic_binding(&name))
                    && !matches!(
                        binding.kind,
                        BindingKind::SharedRef | BindingKind::MutableRef
                    )
                {
                    return Err(MireError::type_error(format!(
                        "Function '{}' argument {} requires a shared reference",
                        callee,
                        index + 1
                    )));
                }
            }
            DataType::RefMut { .. } => {
                if let Some((target, is_mutable)) = Self::reference_target(Some(arg)) {
                    if !is_mutable {
                        return Err(MireError::type_error(format!(
                            "Function '{}' argument {} requires a mutable reference",
                            callee,
                            index + 1
                        )));
                    }
                    self.ensure_borrow_allowed(&target, true)?;
                } else if let Some(binding) =
                    Self::identifier_name(arg).and_then(|name| self.semantic_binding(&name))
                    && !matches!(binding.kind, BindingKind::MutableRef)
                {
                    return Err(MireError::type_error(format!(
                        "Function '{}' argument {} requires a mutable reference",
                        callee,
                        index + 1
                    )));
                }
            }
            _ => {
                if let Some(name) = Self::identifier_name(arg) {
                    // Calls are non-consuming by default. Explicit ownership transfer
                    // should use `move::(...)` so call sites stay readable and Owl/CLI
                    // orchestration code can pass strings/paths safely.
                    let _ = name;
                }
            }
        }

        Ok(())
    }

    fn ownership_error(&self, kind: MssError) -> MireError {
        MireError::ownership_error(self.current_line.max(1), self.current_column.max(1), kind)
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

    fn semantic_binding(&self, name: &str) -> Option<&BindingInfo> {
        let indexes = self.semantic_model.bindings_by_name.get(name)?;
        let binding_depth = self.binding_scope_depth(name)?;
        indexes
            .iter()
            .rev()
            .filter_map(|index| self.semantic_model.bindings.get(*index))
            .find(|binding| binding.scope_depth == binding_depth)
    }

    fn reference_target(expression: Option<&Expression>) -> Option<(String, bool)> {
        match expression? {
            Expression::Reference {
                expr, is_mutable, ..
            } => Self::identifier_name(expr).map(|name| (name, *is_mutable)),
            _ => None,
        }
    }

    fn identifier_name(expression: &Expression) -> Option<String> {
        match expression {
            Expression::Identifier(ident) => Some(ident.name.clone()),
            _ => None,
        }
    }

    fn resolve_semantic_function(&self, callee: &str) -> Option<&FunctionInfo> {
        if let Some(function) = self.semantic_model.functions.get(callee) {
            return Some(function);
        }

        let (receiver_name, method_name) = callee.split_once('.')?;
        let binding = self.semantic_binding(receiver_name)?;
        let struct_name = binding.data_type.struct_name()?;
        self.semantic_model
            .functions
            .get(&format!("{struct_name}.{method_name}"))
    }

    fn binding_scope_depth(&self, name: &str) -> Option<usize> {
        let depth = self.scopes.len().checked_sub(1)?;
        self.scopes
            .iter()
            .rev()
            .enumerate()
            .find_map(|(rev_index, scope)| scope.contains_key(name).then_some(depth - rev_index))
    }
}

fn assignment_binding_target(target: &AssignmentTarget) -> String {
    target
        .binding_name()
        .map(ToString::to_string)
        .unwrap_or_else(|| target.to_string())
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

fn implicit_return_expression(statements: &[Statement]) -> Option<&Expression> {
    match statements.last()? {
        Statement::Expression(expr) => Some(expr),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::{check_program, check_program_partial_with_origins};
    use crate::compiler::AnalysisSelection;
    use crate::compiler::semantic;
    use crate::parser::ast::{
        AssignmentTarget, DataType, Expression, Identifier, Literal, Program, Statement, Visibility,
    };
    use std::collections::HashMap;
    use std::path::PathBuf;

    fn let_stmt(name: &str, value: Option<Expression>) -> Statement {
        Statement::Let {
            name: name.to_string(),
            data_type: DataType::Unknown,
            value,
            is_constant: false,
            is_mutable: false,
            is_static: false,
            visibility: Visibility::Public,
        }
    }

    fn ident(name: &str) -> Expression {
        Expression::Identifier(Identifier {
            name: name.to_string(),
            data_type: DataType::Unknown,
            line: 0,
            column: 0,
        })
    }

    fn ident_at(name: &str, line: usize, column: usize) -> Expression {
        Expression::Identifier(Identifier {
            name: name.to_string(),
            data_type: DataType::Unknown,
            line,
            column,
        })
    }

    #[test]
    fn rejects_assignment_while_shared_borrow_exists() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                let_stmt(
                    "r",
                    Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }),
                ),
                Statement::Assignment {
                    target: AssignmentTarget::Variable("x".to_string()),
                    value: Expression::Literal(Literal::Int(2)),
                    is_mutable: true,
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Cannot mutate"));
    }

    #[test]
    fn rejects_mutable_borrow_while_shared_borrow_exists() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                let_stmt(
                    "r",
                    Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }),
                ),
                let_stmt(
                    "m",
                    Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: true,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }),
                ),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Cannot mutate"));
    }

    #[test]
    fn rejects_use_after_move() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                Statement::Move {
                    target: "y".to_string(),
                    value: ident_at("x", 10, 4),
                },
                Statement::Expression(ident_at("x", 12, 8)),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Use after move"));
        assert_eq!(err.line, 12);
        assert_eq!(err.column, 8);
    }

    #[test]
    fn releases_borrow_on_scope_exit() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                Statement::If {
                    condition: Expression::Literal(Literal::Bool(true)),
                    then_branch: vec![let_stmt(
                        "r",
                        Some(Expression::Reference {
                            expr: Box::new(ident("x")),
                            is_mutable: false,
                            data_type: DataType::Unknown,
                            referenced_type: DataType::Unknown,
                        }),
                    )],
                    else_branch: None,
                },
                Statement::Assignment {
                    target: AssignmentTarget::Variable("x".to_string()),
                    value: Expression::Literal(Literal::Int(2)),
                    is_mutable: true,
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        check_program(&program, &semantic_model)
            .expect("borrow should be released when scope ends");
    }

    #[test]
    fn unsafe_allows_write_while_borrowed() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                let_stmt(
                    "r",
                    Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }),
                ),
                Statement::Unsafe {
                    body: vec![Statement::Assignment {
                        target: AssignmentTarget::Variable("x".to_string()),
                        value: Expression::Literal(Literal::Int(2)),
                        is_mutable: true,
                    }],
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        check_program(&program, &semantic_model)
            .expect("unsafe block should bypass borrow conflict checks");
    }

    #[test]
    fn rejects_returning_reference_to_local_binding() {
        let program = Program {
            statements: vec![Statement::Function {
                name: "bad".to_string(),
                params: vec![],
                body: vec![
                    let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                    Statement::Return(Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    })),
                ],
                return_type: DataType::shared_ref(DataType::Unknown),
                visibility: Visibility::Public,
                is_method: false,
            }],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Borrow outlives owner scope"));
    }

    #[test]
    fn rejects_returning_reference_to_local_from_impl_method() {
        let program = Program {
            statements: vec![
                Statement::Type {
                    name: "Point".to_string(),
                    parent: None,
                    fields: vec![],
                },
                Statement::Impl {
                    trait_name: None,
                    type_name: "Point".to_string(),
                    methods: vec![Statement::Function {
                        name: "leak".to_string(),
                        params: vec![(
                            "self".to_string(),
                            DataType::StructNamed("Point".to_string()),
                        )],
                        body: vec![
                            let_stmt("tmp", Some(Expression::Literal(Literal::Int(1)))),
                            Statement::Return(Some(Expression::Reference {
                                expr: Box::new(ident("tmp")),
                                is_mutable: false,
                                data_type: DataType::Unknown,
                                referenced_type: DataType::Unknown,
                            })),
                        ],
                        return_type: DataType::shared_ref(DataType::Unknown),
                        visibility: Visibility::Public,
                        is_method: true,
                    }],
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Borrow outlives owner scope"));
    }

    #[test]
    fn rejects_call_that_requires_mut_ref_but_receives_shared_ref() {
        let program = Program {
            statements: vec![
                Statement::Function {
                    name: "mutate".to_string(),
                    params: vec![(
                        "value".to_string(),
                        DataType::mutable_ref(DataType::Unknown),
                    )],
                    body: vec![],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                Statement::Expression(Expression::Call {
                    name: "mutate".to_string(),
                    args: vec![Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }],
                    data_type: DataType::Unknown,
                }),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("mutable reference"));
    }

    #[test]
    fn passing_moved_type_by_value_consumes_binding() {
        let program = Program {
            statements: vec![
                Statement::Function {
                    name: "consume".to_string(),
                    params: vec![("name".to_string(), DataType::Str)],
                    body: vec![],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
                Statement::Let {
                    name: "name".to_string(),
                    data_type: DataType::Str,
                    value: Some(Expression::Literal(Literal::Str("mire".to_string()))),
                    is_constant: false,
                    is_mutable: false,
                    is_static: false,
                    visibility: Visibility::Public,
                },
                Statement::Expression(Expression::Call {
                    name: "consume".to_string(),
                    args: vec![ident("name")],
                    data_type: DataType::Unknown,
                }),
                Statement::Expression(ident("name")),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{}", err).contains("Use after move"));
    }

    #[test]
    fn passing_copy_type_by_value_does_not_consume_binding() {
        let program = Program {
            statements: vec![
                Statement::Function {
                    name: "show".to_string(),
                    params: vec![("value".to_string(), DataType::I64)],
                    body: vec![],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                Statement::Expression(Expression::Call {
                    name: "show".to_string(),
                    args: vec![ident("x")],
                    data_type: DataType::Unknown,
                }),
                Statement::Expression(ident("x")),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        check_program(&program, &semantic_model).expect("copy-like values should remain usable");
    }

    #[test]
    fn partial_borrowck_skips_unselected_top_level_statements() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                let_stmt(
                    "r",
                    Some(Expression::Reference {
                        expr: Box::new(ident("x")),
                        is_mutable: false,
                        data_type: DataType::Unknown,
                        referenced_type: DataType::Unknown,
                    }),
                ),
                Statement::Assignment {
                    target: AssignmentTarget::Variable("x".to_string()),
                    value: Expression::Literal(Literal::Int(2)),
                    is_mutable: true,
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        check_program_partial_with_origins(
            &program,
            &semantic_model,
            &[
                PathBuf::from("test.mire"),
                PathBuf::from("test.mire"),
                PathBuf::from("test.mire"),
            ],
            &HashMap::new(),
            &AnalysisSelection {
                statement_mask: vec![true, true, false],
                ..AnalysisSelection::default()
            },
        )
        .expect("masked borrow check should skip unselected top-level statements");
    }

    #[test]
    fn partial_borrowck_can_skip_unchanged_impl_methods() {
        let program = Program {
            statements: vec![
                let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                Statement::Impl {
                    trait_name: None,
                    type_name: "Point".to_string(),
                    methods: vec![
                        Statement::Function {
                            name: "good".to_string(),
                            params: vec![],
                            body: vec![Statement::Expression(Expression::Literal(Literal::Int(1)))],
                            return_type: DataType::None,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                        Statement::Function {
                            name: "bad".to_string(),
                            params: vec![],
                            body: vec![
                                let_stmt(
                                    "r",
                                    Some(Expression::Reference {
                                        expr: Box::new(ident("x")),
                                        is_mutable: false,
                                        data_type: DataType::Unknown,
                                        referenced_type: DataType::Unknown,
                                    }),
                                ),
                                Statement::Assignment {
                                    target: AssignmentTarget::Variable("x".to_string()),
                                    value: Expression::Literal(Literal::Int(2)),
                                    is_mutable: true,
                                },
                            ],
                            return_type: DataType::None,
                            visibility: Visibility::Public,
                            is_method: true,
                        },
                    ],
                },
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        check_program_partial_with_origins(
            &program,
            &semantic_model,
            &[PathBuf::from("test.mire"), PathBuf::from("test.mire")],
            &HashMap::new(),
            &AnalysisSelection {
                statement_mask: vec![true, true],
                nested_statement_masks: HashMap::from([(
                    "impl::Point".to_string(),
                    vec![true, false],
                )]),
            },
        )
        .expect("partial borrow check should skip unchanged impl method");
    }

    #[test]
    fn later_global_binding_does_not_hide_local_ref_escape() {
        let program = Program {
            statements: vec![
                Statement::Function {
                    name: "leak".to_string(),
                    params: vec![],
                    body: vec![
                        let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                        Statement::Return(Some(Expression::Reference {
                            expr: Box::new(ident("x")),
                            is_mutable: false,
                            data_type: DataType::Unknown,
                            referenced_type: DataType::Unknown,
                        })),
                    ],
                    return_type: DataType::shared_ref(DataType::Unknown),
                    visibility: Visibility::Public,
                    is_method: false,
                },
                let_stmt("x", Some(Expression::Literal(Literal::Int(2)))),
            ],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{err}").contains("Borrow"), "{err}");
    }

    #[test]
    fn impl_method_returning_local_ref_is_rejected() {
        let program = Program {
            statements: vec![Statement::Impl {
                trait_name: None,
                type_name: "Point".to_string(),
                methods: vec![Statement::Function {
                    name: "leak".to_string(),
                    params: vec![(
                        "self".to_string(),
                        DataType::StructNamed("Point".to_string()),
                    )],
                    body: vec![
                        let_stmt("x", Some(Expression::Literal(Literal::Int(1)))),
                        Statement::Return(Some(Expression::Reference {
                            expr: Box::new(ident("x")),
                            is_mutable: false,
                            data_type: DataType::Unknown,
                            referenced_type: DataType::Unknown,
                        })),
                    ],
                    return_type: DataType::shared_ref(DataType::Unknown),
                    visibility: Visibility::Public,
                    is_method: true,
                }],
            }],
        };

        let semantic_model = semantic::analyze_program(&program);
        let err = check_program(&program, &semantic_model).unwrap_err();
        assert!(format!("{err}").contains("Borrow"), "{err}");
    }
}
