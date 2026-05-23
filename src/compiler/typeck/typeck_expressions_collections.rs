use crate::error::Result;
use crate::parser::ast::DataType;

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    pub(super) fn infer_collection_call(
        &self,
        name: &str,
        arg_types: &[DataType],
        data_type: &mut DataType,
    ) -> Result<Option<DataType>> {
        if name == "dicts.get" {
            let resolved = match arg_types.first().cloned().unwrap_or(DataType::Unknown) {
                DataType::Map { value_type, .. } => *value_type,
                DataType::Dict => arg_types.get(2).cloned().unwrap_or(DataType::Anything),
                _ => arg_types.get(2).cloned().unwrap_or(DataType::Anything),
            };
            *data_type = resolved.clone();
            return Ok(Some(resolved));
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
            return Ok(Some(resolved));
        }

        if name == "lists.get" {
            let arg_type = arg_types.first().cloned().unwrap_or(DataType::Unknown);
            let resolved = match arg_type {
                DataType::Vector { element_type, .. } => *element_type,
                DataType::List | DataType::Unknown | DataType::Anything => DataType::Anything,
                other => {
                    return Err(type_error(format!(
                        "lists.get expects vec/vec! input, got {:?}",
                        other
                    )));
                }
            };
            *data_type = resolved.clone();
            return Ok(Some(resolved));
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
                DataType::List | DataType::Unknown => DataType::Vector {
                    element_type: Box::new(value_type),
                    dynamic: true,
                },
                other => {
                    return Err(type_error(format!(
                        "lists.push expects vec[T], got {:?}",
                        other
                    )));
                }
            };
            *data_type = resolved.clone();
            return Ok(Some(resolved));
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
            return Ok(Some(resolved));
        }

        Ok(None)
    }
}
