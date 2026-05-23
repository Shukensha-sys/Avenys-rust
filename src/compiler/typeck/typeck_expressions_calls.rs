use crate::error::Result;
use crate::parser::ast::DataType;

use crate::compiler::typeck::{type_error, FunctionSig, TypeChecker};

impl TypeChecker {
    pub(super) fn infer_function_or_builtin_call(
        &self,
        name: &str,
        arg_types: &[DataType],
        type_args: &mut Vec<DataType>,
        data_type: &mut DataType,
    ) -> Result<Option<DataType>> {
        if let Some(sig) = self.functions.get(name).cloned() {
            let resolved = self.resolve_function_call(name, &sig, arg_types, type_args)?;
            *data_type = resolved.clone();
            return Ok(Some(resolved));
        }

        if let Some(alias_name) = Self::strip_root_namespace(name)
            && let Some(sig) = self.functions.get(&alias_name).cloned()
        {
            let resolved = self.resolve_function_call(&alias_name, &sig, arg_types, type_args)?;
            *data_type = resolved.clone();
            return Ok(Some(resolved));
        }

        if let Some(ret) = self.builtin_returns.get(name).cloned() {
            *data_type = ret.clone();
            return Ok(Some(ret));
        }

        if let Some(rest) = name.strip_prefix("std.")
            && let Some(ret) = self.builtin_returns.get(rest).cloned()
        {
            *data_type = ret.clone();
            return Ok(Some(ret));
        }

        Ok(None)
    }

    fn resolve_function_call(
        &self,
        display_name: &str,
        sig: &FunctionSig,
        arg_types: &[DataType],
        type_args: &mut Vec<DataType>,
    ) -> Result<DataType> {
        if sig.params.len() != arg_types.len() {
            return Err(type_error(format!(
                "Function '{}' expects {} arguments, got {}",
                display_name,
                sig.params.len(),
                arg_types.len()
            )));
        }

        let resolved_type_args = if sig.type_params.is_empty() {
            if !type_args.is_empty() {
                return Err(type_error(format!(
                    "Function '{}' is not generic; remove explicit type arguments",
                    display_name
                )));
            }
            Vec::new()
        } else {
            self.resolve_generic_type_args(sig, type_args, arg_types)?
        };
        self.validate_generic_bounds(display_name, sig, &resolved_type_args)?;
        let generic_bindings = self.generic_bindings_from_args(sig, &resolved_type_args);

        for (idx, (expected, actual)) in sig
            .params
            .iter()
            .map(|param| self.substitute_generics(param, &generic_bindings))
            .zip(arg_types.iter())
            .enumerate()
        {
            if !self.is_assignable(&expected, actual) {
                return Err(type_error(format!(
                    "Function '{}' argument {} expects {:?}, got {:?}",
                    display_name,
                    idx + 1,
                    expected,
                    actual
                )));
            }
        }

        if !resolved_type_args.is_empty() {
            *type_args = resolved_type_args;
        }
        Ok(self.substitute_generics(&sig.return_type, &generic_bindings))
    }
}
