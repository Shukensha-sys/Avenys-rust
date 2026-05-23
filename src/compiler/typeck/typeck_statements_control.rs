use crate::error::Result;
use crate::parser::ast::{DataType, Expression, Statement};

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    pub(super) fn check_if_statement(
        &mut self,
        condition: &mut Expression,
        then_branch: &mut [Statement],
        else_branch: &mut Option<Vec<Statement>>,
    ) -> Result<()> {
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

        Ok(())
    }

    pub(super) fn check_while_statement(
        &mut self,
        condition: &mut Expression,
        body: &mut [Statement],
    ) -> Result<()> {
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
        Ok(())
    }

    pub(super) fn check_for_statement(
        &mut self,
        variable: &str,
        index: &Option<String>,
        iterable: &mut Expression,
        body: &mut [Statement],
    ) -> Result<()> {
        let iter_type = self.check_expression(iterable)?;
        self.push_scope();

        let item_type = Self::loop_item_type(iterable, iter_type);
        self.insert_var(variable.to_string(), item_type, true);
        if let Some(index_name) = index {
            self.insert_var(index_name.clone(), DataType::I64, true);
        }

        self.check_statements(body)?;
        self.pop_scope();
        Ok(())
    }

    pub(super) fn check_find_statement(
        &mut self,
        variable: &str,
        iterable: &mut Expression,
        body: &mut [Statement],
    ) -> Result<()> {
        let iter_type = self.check_expression(iterable)?;
        self.push_scope();

        let item_type = Self::loop_item_type(iterable, iter_type);
        self.insert_var(variable.to_string(), item_type, true);

        self.check_statements(body)?;
        self.pop_scope();
        Ok(())
    }

    pub(super) fn check_match_statement(
        &mut self,
        value: &mut Expression,
        cases: &mut [(Expression, Vec<Statement>)],
        default: &mut [Statement],
    ) -> Result<()> {
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
        Ok(())
    }

    fn loop_item_type(iterable: &Expression, iter_type: DataType) -> DataType {
        match iterable {
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
        }
    }
}
