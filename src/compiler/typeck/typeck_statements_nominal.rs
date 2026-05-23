use crate::error::Result;
use crate::parser::ast::{DataType, Statement};

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    pub(super) fn check_impl_statement(
        &mut self,
        trait_name: &Option<String>,
        type_name: &str,
        methods: &mut [Statement],
    ) -> Result<()> {
        self.validate_impl_method_declarations(type_name, methods)?;
        if let Some(trait_name) = trait_name {
            self.validate_trait_impl(trait_name, type_name, methods)?;
        }

        let old_self = self.impl_self_type.take();
        let old_self_name = self.impl_self_name.take();
        let method_mask = self.current_nested_statement_mask().map(|mask| mask.to_vec());

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
            self.impl_self_type = has_self.then(|| DataType::StructNamed(type_name.to_string()));
            self.impl_self_name = has_self.then(|| type_name.to_string());
            self.check_statement(method)?;
        }

        self.impl_self_type = old_self;
        self.impl_self_name = old_self_name;
        Ok(())
    }

    pub(super) fn check_type_statement(&mut self, fields: &mut [Statement]) -> Result<()> {
        self.check_container_statements(fields)
    }

    pub(super) fn check_skill_statement(
        &mut self,
        name: &str,
        methods: &[crate::parser::ast::TraitMethodSig],
    ) -> Result<()> {
        if methods.is_empty() {
            return Err(type_error(format!(
                "Skill '{}' must declare at least one method",
                name
            )));
        }
        self.validate_trait_method_declarations(name, methods, "Skill")?;
        Ok(())
    }
}
