use crate::error::Result;
use crate::parser::ast::{DataType, Expression, Literal, Statement};

use crate::compiler::typeck::{type_error, TypeChecker};

impl TypeChecker {
    fn variant_name_from_match_pattern<'a>(
        &'a self,
        pattern: &'a Expression,
        expected_enum: &str,
    ) -> Result<Option<&'a str>> {
        match pattern {
            Expression::EnumVariantPath {
                enum_name,
                variant_name,
                ..
            }
            | Expression::EnumVariant {
                enum_name,
                variant_name,
                ..
            } => {
                if enum_name != expected_enum {
                    return Err(type_error(format!(
                        "Match pattern enum mismatch: expected '{}', got '{}'",
                        expected_enum, enum_name
                    )));
                }
                Ok(Some(variant_name.as_str()))
            }
            _ => Ok(None),
        }
    }

    fn enum_variant_names_for(&self, enum_name: &str) -> Vec<String> {
        let prefix = format!("{enum_name}.");
        self.enum_variants
            .keys()
            .filter_map(|full| full.strip_prefix(&prefix).map(ToOwned::to_owned))
            .collect()
    }

    pub(super) fn validate_match_coverage(
        &self,
        value_type: &DataType,
        cases: &[(Expression, Vec<Statement>)],
        has_default: bool,
    ) -> Result<()> {
        let DataType::EnumNamed(enum_name) = value_type else {
            return Ok(());
        };

        let mut covered = std::collections::HashSet::new();
        for (pattern, _) in cases {
            if let Some(variant_name) = self.variant_name_from_match_pattern(pattern, enum_name)?
                && !covered.insert(variant_name.to_string())
            {
                return Err(type_error(format!(
                    "Duplicate match arm for enum variant '{}.{}'",
                    enum_name, variant_name
                )));
            }
        }

        if has_default {
            return Ok(());
        }

        let all = self.enum_variant_names_for(enum_name);
        let missing: Vec<String> = all.into_iter().filter(|name| !covered.contains(name)).collect();
        if missing.is_empty() {
            return Ok(());
        }

        Err(type_error(format!(
            "Non-exhaustive match for enum '{}'; missing variants: {}",
            enum_name,
            missing.join(", ")
        )))
    }

    pub(super) fn validate_match_expr_coverage(
        &self,
        value_type: &DataType,
        cases: &[(Expression, Expression)],
        default: &Expression,
    ) -> Result<()> {
        let DataType::EnumNamed(enum_name) = value_type else {
            return Ok(());
        };

        let mut covered = std::collections::HashSet::new();
        for (pattern, _) in cases {
            if let Some(variant_name) = self.variant_name_from_match_pattern(pattern, enum_name)?
                && !covered.insert(variant_name.to_string())
            {
                return Err(type_error(format!(
                    "Duplicate match arm for enum variant '{}.{}'",
                    enum_name, variant_name
                )));
            }
        }

        let has_default = !matches!(default, Expression::Literal(Literal::None));
        if has_default {
            return Ok(());
        }

        let all = self.enum_variant_names_for(enum_name);
        let missing: Vec<String> = all.into_iter().filter(|name| !covered.contains(name)).collect();
        if missing.is_empty() {
            return Ok(());
        }

        Err(type_error(format!(
            "Non-exhaustive match expression for enum '{}'; missing variants: {}",
            enum_name,
            missing.join(", ")
        )))
    }
}
