use crate::error::Result;
use crate::parser::ast::{DataType, Expression, Statement};

use crate::compiler::typeck::{
    type_error, FunctionSig, TypeChecker,
};
use crate::compiler::typeck::typeck_returns::{
    implicit_return_expression_mut, statements_contain_explicit_return,
};

impl TypeChecker {
    pub(super) fn check_function_statement(
        &mut self,
        name: &str,
        type_params: &[String],
        type_param_bounds: &[(String, Vec<String>)],
        params: &[(String, DataType)],
        body: &mut [Statement],
        return_type: &mut DataType,
    ) -> Result<()> {
        self.functions.insert(
            name.to_string(),
            FunctionSig {
                type_params: type_params.to_vec(),
                type_param_bounds: type_param_bounds.to_vec(),
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

        Ok(())
    }

    pub(super) fn check_return_statement(
        &mut self,
        expr: &mut Option<Expression>,
    ) -> Result<()> {
        let return_type = if let Some(expression) = expr {
            self.check_expression(expression)?
        } else {
            DataType::None
        };

        if let Some(current) = self.return_type_stack.last_mut() {
            let unified = Self::unify_types(current, &return_type)?;
            *current = unified;
        }

        Ok(())
    }
}
