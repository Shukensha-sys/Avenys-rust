use crate::error::Result;
use crate::parser::ast::{AssignmentTarget, DataType, Expression, Identifier, Literal};

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    pub(super) fn check_let_statement(
        &mut self,
        name: &str,
        data_type: &mut DataType,
        value: &mut Option<Expression>,
        is_mutable: bool,
    ) -> Result<()> {
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
        self.insert_var(name.to_string(), final_type, is_mutable);
        self.refresh_binding_metadata(name, data_type, value.as_ref());
        Ok(())
    }

    pub(super) fn check_assignment_statement(
        &mut self,
        target: &mut AssignmentTarget,
        value: &mut Expression,
    ) -> Result<()> {
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
            AssignmentTarget::Field(path) => self.check_field_assignment(path, value, &value_type)?,
            AssignmentTarget::Index { .. } => {}
            AssignmentTarget::Variable(name) => {
                Self::validate_explicit_nested_literal(&target_type, value)?;
                target_type = Self::unify_types(&target_type, &value_type)?;
                self.insert_var(name.clone(), target_type, is_target_mutable);
                self.refresh_binding_metadata(name, &value_type, Some(value));
            }
        }

        Ok(())
    }

    fn check_field_assignment(
        &mut self,
        path: &str,
        value: &Expression,
        value_type: &DataType,
    ) -> Result<()> {
        let Some((owner, field_name)) = path.split_once('.') else {
            return Ok(());
        };

        let (owner_type, owner_mutable) = self.lookup_var(owner).ok_or_else(|| {
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

            if !self.is_assignable(&field.data_type, value_type) {
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
                type_args: Vec::new(),
                data_type: owner_type.clone(),
            };

            self.insert_var(owner.to_string(), owner_type.clone(), owner_mutable);
            self.refresh_binding_metadata(owner, &owner_type, Some(&struct_constructor));
        }

        Ok(())
    }
}
