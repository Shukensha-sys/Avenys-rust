use crate::error::Result;
use crate::parser::ast::{DataType, Expression, QueryBinding, QueryOp, Statement};

use crate::compiler::typeck::{type_error, TypeChecker};
use crate::compiler::typeck::typeck_builtins;

impl TypeChecker {
    pub(super) fn check_scoped_body(&mut self, body: &mut [Statement]) -> Result<()> {
        self.push_scope();
        self.check_statements(body)?;
        self.pop_scope();
        Ok(())
    }

    pub(super) fn check_asm_statement(
        &mut self,
        instructions: &mut [(String, Expression)],
    ) -> Result<()> {
        for (_, expr) in instructions.iter_mut() {
            self.check_expression(expr)?;
        }
        Ok(())
    }

    pub(super) fn check_drop_statement(&mut self, value: &mut Expression) -> Result<()> {
        self.check_expression(value)?;
        Ok(())
    }

    pub(super) fn check_new_statement(
        &mut self,
        value: &mut Option<Expression>,
        declared_type: &DataType,
    ) -> Result<()> {
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
        Ok(())
    }

    pub(super) fn check_own_statement(
        &mut self,
        value: &mut Option<Expression>,
        inner_type: &DataType,
    ) -> Result<()> {
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
        Ok(())
    }

    pub(super) fn check_move_statement(
        &mut self,
        target: &str,
        value: &mut Expression,
    ) -> Result<()> {
        let moved_type = self.check_expression(value)?;
        self.insert_var(target.to_string(), moved_type.clone(), true);
        self.refresh_binding_metadata(target, &moved_type, Some(value));
        Ok(())
    }

    pub(super) fn check_query_statement(
        &mut self,
        ops: &mut [QueryOp],
        bindings: &[QueryBinding],
    ) -> Result<()> {
        for bind in bindings {
            self.insert_var(bind.target.clone(), DataType::Anything, true);
            self.insert_var(bind.alias.clone(), DataType::Anything, true);
        }

        for op in ops.iter_mut() {
            self.check_query_op(op)?;
        }

        Ok(())
    }

    pub(super) fn check_use_statement(&mut self, path: &str) {
        if path == "__std_all__" {
            for module in ["math", "term", "strings", "lists", "dicts", "time"] {
                typeck_builtins::import_std_members(self, module);
            }
        } else if let Some(rest) = path.strip_prefix("stdall:") {
            typeck_builtins::import_std_members(self, rest);
        } else if let Some(rest) = path.strip_prefix("stdselect:")
            && let Some((_, items)) = rest.split_once(':')
        {
            for item in items.split(',').filter(|item| !item.is_empty()) {
                self.insert_var(item.to_string(), DataType::Anything, true);
            }
        } else if let Some(rest) = path.strip_prefix("stdalias:")
            && let Some((alias, _)) = rest.split_once(':')
        {
            self.insert_var(alias.to_string(), DataType::Anything, true);
        } else if let Some(rest) = path.strip_prefix("stdaliasselect:") {
            let mut parts = rest.splitn(3, ':');
            if let Some(alias) = parts.next() {
                self.insert_var(alias.to_string(), DataType::Anything, true);
            }
        }
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
}
