use super::*;

pub(super) fn contains_self_placeholder(expr: &Expression) -> bool {
    match expr {
        Expression::Identifier(Identifier { name, .. }) => name == "self",
        Expression::BinaryOp { left, right, .. } => {
            contains_self_placeholder(left) || contains_self_placeholder(right)
        }
        Expression::UnaryOp { operand, .. } => contains_self_placeholder(operand),
        Expression::NamedArg { value, .. } => contains_self_placeholder(value),
        Expression::Call { args, .. }
        | Expression::List { elements: args, .. }
        | Expression::Tuple { elements: args, .. } => args.iter().any(contains_self_placeholder),
        Expression::Dict { entries, .. } => entries
            .iter()
            .any(|(key, value)| contains_self_placeholder(key) || contains_self_placeholder(value)),
        Expression::Index { target, index, .. } => {
            contains_self_placeholder(target) || contains_self_placeholder(index)
        }
        Expression::MemberAccess { target, .. }
        | Expression::Dereference { expr: target, .. }
        | Expression::Reference { expr: target, .. }
        | Expression::Box { value: target, .. } => contains_self_placeholder(target),
        Expression::Closure { body, .. } => body.iter().any(statement_contains_self_placeholder),
        Expression::Literal(_) => false,
        Expression::Pipeline { input, stage, .. } => {
            contains_self_placeholder(input) || contains_self_placeholder(stage)
        }
        Expression::Match {
            value,
            cases,
            default,
            ..
        } => {
            contains_self_placeholder(value)
                || cases
                    .iter()
                    .any(|(p, r)| contains_self_placeholder(p) || contains_self_placeholder(r))
                || contains_self_placeholder(default)
        }
        Expression::EnumVariantPath { .. } => false,
        Expression::EnumVariant { payloads, .. } => payloads.iter().any(contains_self_placeholder),
    }
}

fn statement_contains_self_placeholder(statement: &Statement) -> bool {
    match statement {
        Statement::Let { value, .. } => value.as_ref().is_some_and(contains_self_placeholder),
        Statement::Assignment { target, value, .. } => {
            contains_self_placeholder(&target.as_expression()) || contains_self_placeholder(value)
        }
        Statement::Function { body, .. }
        | Statement::Unsafe { body }
        | Statement::Module { body, .. } => body.iter().any(statement_contains_self_placeholder),
        Statement::Return(expr) => expr.as_ref().is_some_and(contains_self_placeholder),
        Statement::If {
            condition,
            then_branch,
            else_branch,
        } => {
            contains_self_placeholder(condition)
                || then_branch.iter().any(statement_contains_self_placeholder)
                || else_branch
                    .as_ref()
                    .is_some_and(|body| body.iter().any(statement_contains_self_placeholder))
        }
        Statement::While { condition, body } => {
            contains_self_placeholder(condition)
                || body.iter().any(statement_contains_self_placeholder)
        }
        Statement::For { iterable, body, .. } | Statement::Find { iterable, body, .. } => {
            contains_self_placeholder(iterable)
                || body.iter().any(statement_contains_self_placeholder)
        }
        Statement::Expression(expr) => contains_self_placeholder(expr),
        Statement::Match {
            value,
            cases,
            default,
        } => {
            contains_self_placeholder(value)
                || cases.iter().any(|(expr, body)| {
                    contains_self_placeholder(expr)
                        || body.iter().any(statement_contains_self_placeholder)
                })
                || default.iter().any(statement_contains_self_placeholder)
        }
        Statement::Impl { methods, .. } => methods.iter().any(statement_contains_self_placeholder),
        Statement::Type { fields, .. } => fields.iter().any(statement_contains_self_placeholder),
        Statement::Skill { .. } => false,
        Statement::Asm { instructions } => instructions
            .iter()
            .any(|(_, expr)| contains_self_placeholder(expr)),
        Statement::Drop { value } => contains_self_placeholder(value),
        Statement::New { value, .. } | Statement::Own { value, .. } => {
            value.as_ref().is_some_and(contains_self_placeholder)
        }
        Statement::Move { value, .. } => contains_self_placeholder(value),
        Statement::Query { .. }
        | Statement::Break
        | Statement::Continue
        | Statement::ExternLib { .. }
        | Statement::ExternFunction { .. }
        | Statement::Use { .. }
        | Statement::Enum { .. } => false,
    }
}

pub(super) fn replace_self_placeholder(expr: Expression, replacement: &Expression) -> Expression {
    match expr {
        Expression::Identifier(Identifier { name, .. }) if name == "self" => replacement.clone(),
        Expression::BinaryOp {
            operator,
            left,
            right,
            data_type,
        } => Expression::BinaryOp {
            operator,
            left: Box::new(replace_self_placeholder(*left, replacement)),
            right: Box::new(replace_self_placeholder(*right, replacement)),
            data_type,
        },
        Expression::UnaryOp {
            operator,
            operand,
            data_type,
        } => Expression::UnaryOp {
            operator,
            operand: Box::new(replace_self_placeholder(*operand, replacement)),
            data_type,
        },
        Expression::NamedArg {
            name,
            value,
            data_type,
        } => Expression::NamedArg {
            name,
            value: Box::new(replace_self_placeholder(*value, replacement)),
            data_type,
        },
        Expression::Call {
            name,
            args,
            type_args,
            data_type,
        } => Expression::Call {
            name,
            args: args
                .into_iter()
                .map(|arg| replace_self_placeholder(arg, replacement))
                .collect(),
            type_args,
            data_type,
        },
        Expression::List {
            elements,
            element_type,
            data_type,
        } => Expression::List {
            elements: elements
                .into_iter()
                .map(|arg| replace_self_placeholder(arg, replacement))
                .collect(),
            element_type,
            data_type,
        },
        Expression::Tuple {
            elements,
            data_type,
        } => Expression::Tuple {
            elements: elements
                .into_iter()
                .map(|arg| replace_self_placeholder(arg, replacement))
                .collect(),
            data_type,
        },
        Expression::Dict {
            entries,
            key_type,
            value_type,
            data_type,
        } => Expression::Dict {
            entries: entries
                .into_iter()
                .map(|(key, value)| {
                    (
                        replace_self_placeholder(key, replacement),
                        replace_self_placeholder(value, replacement),
                    )
                })
                .collect(),
            key_type,
            value_type,
            data_type,
        },
        Expression::Index {
            target,
            index,
            data_type,
        } => Expression::Index {
            target: Box::new(replace_self_placeholder(*target, replacement)),
            index: Box::new(replace_self_placeholder(*index, replacement)),
            data_type,
        },
        Expression::MemberAccess {
            target,
            member,
            data_type,
        } => Expression::MemberAccess {
            target: Box::new(replace_self_placeholder(*target, replacement)),
            member,
            data_type,
        },
        Expression::Reference {
            expr,
            is_mutable,
            data_type,
            referenced_type,
        } => Expression::Reference {
            expr: Box::new(replace_self_placeholder(*expr, replacement)),
            is_mutable,
            data_type,
            referenced_type,
        },
        Expression::Dereference { expr, data_type } => Expression::Dereference {
            expr: Box::new(replace_self_placeholder(*expr, replacement)),
            data_type,
        },
        Expression::Box { value, data_type } => Expression::Box {
            value: Box::new(replace_self_placeholder(*value, replacement)),
            data_type,
        },
        Expression::Pipeline {
            input,
            stage,
            safe,
            data_type,
        } => Expression::Pipeline {
            input: Box::new(replace_self_placeholder(*input, replacement)),
            stage: Box::new(replace_self_placeholder(*stage, replacement)),
            safe,
            data_type,
        },
        Expression::Match {
            value,
            cases,
            default,
            data_type,
        } => Expression::Match {
            value: Box::new(replace_self_placeholder(*value, replacement)),
            cases: cases
                .into_iter()
                .map(|(p, r)| {
                    (
                        replace_self_placeholder(p, replacement),
                        replace_self_placeholder(r, replacement),
                    )
                })
                .collect(),
            default: Box::new(replace_self_placeholder(*default, replacement)),
            data_type,
        },
        Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads,
            data_type,
        } => Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads: payloads
                .into_iter()
                .map(|payload| replace_self_placeholder(payload, replacement))
                .collect(),
            data_type,
        },
        other => other,
    }
}
