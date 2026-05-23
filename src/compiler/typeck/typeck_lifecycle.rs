use crate::error::Result;
use crate::parser::ast::{DataType, Expression};

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    pub(super) fn infer_lifecycle_call(
        &self,
        name: &str,
        args: &[Expression],
        arg_types: &[DataType],
        data_type: &mut DataType,
    ) -> Result<Option<DataType>> {
        if name == "new::" {
            if args.is_empty() {
                if *data_type == DataType::Unknown {
                    return Err(type_error("new::() requires a type annotation (:T)".to_string()));
                }
                return Ok(Some(data_type.clone()));
            }
            if args.len() == 1 {
                *data_type = arg_types[0].clone();
                return Ok(Some(arg_types[0].clone()));
            }
            return Ok(None);
        }

        if name == "own::" {
            if args.is_empty() {
                if *data_type == DataType::Unknown {
                    return Err(type_error("own::() requires a type annotation (:T)".to_string()));
                }
                *data_type = DataType::Box;
                return Ok(Some(DataType::Box));
            }
            if args.len() == 1 {
                *data_type = DataType::Box;
                return Ok(Some(DataType::Box));
            }
            return Ok(None);
        }

        if name == "move::"
            && let Some(first) = arg_types.first()
        {
            *data_type = first.clone();
            return Ok(Some(first.clone()));
        }

        if name == "drop::" {
            *data_type = DataType::None;
            return Ok(Some(DataType::None));
        }

        Ok(None)
    }

    pub(super) fn validate_new_target_type(&self, declared_type: &DataType) -> Result<()> {
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

    pub(super) fn validate_own_target_type(&self, inner_type: &DataType) -> Result<()> {
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
}
