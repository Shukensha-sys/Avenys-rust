use crate::parser::ast::{DataType, Expression, Statement, Literal};
use crate::parser::Program;
use std::collections::HashSet;

#[derive(Debug, Clone)]
pub struct Warning {
    pub code: String,
    pub message: String,
    pub severity: WarningSeverity,
    pub line: usize,
    pub column: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WarningSeverity {
    Hint,
    Warning,
    Error,
}

pub struct Warnings {
    pub warnings: Vec<Warning>,
    pub defined_variables: HashSet<String>,
    pub defined_functions: HashSet<String>,
    pub used_variables: HashSet<String>,
    pub used_functions: HashSet<String>,
}

impl Default for Warnings {
    fn default() -> Self {
        Self::new()
    }
}

impl Warnings {
    pub fn new() -> Self {
        Self {
            warnings: Vec::new(),
            defined_variables: HashSet::new(),
            defined_functions: HashSet::new(),
            used_variables: HashSet::new(),
            used_functions: HashSet::new(),
        }
    }

    pub fn analyze(program: &Program) -> Vec<Warning> {
        let mut warnings = Warnings::new();
        warnings.collect_definitions(program);
        warnings.check_program(program);
        warnings.warnings
    }

    fn collect_definitions(&mut self, program: &Program) {
        for stmt in &program.statements {
            match stmt {
                Statement::Let { name, .. } => {
                    self.defined_variables.insert(name.clone());
                }
                Statement::Function { name, .. } => {
                    self.defined_functions.insert(name.clone());
                }
                _ => {}
            }
        }
    }

    fn check_program(&mut self, program: &Program) {
        self.analyze_statements(&program.statements);

        for stmt in &program.statements {
            match stmt {
                Statement::Let { name, data_type, .. } => {
                    if !self.used_variables.contains(name) && !name.starts_with('_') {
                        self.warnings.push(Warning {
                            code: "W002".to_string(),
                            message: format!("Unused variable: '{}'", name),
                            severity: WarningSeverity::Hint,
                            line: 0,
                            column: 0,
                        });
                    }
                    if *data_type == DataType::Unknown {
                        self.warnings.push(Warning {
                            code: "W003".to_string(),
                            message: format!("Variable '{}' has implicit type", name),
                            severity: WarningSeverity::Hint,
                            line: 0,
                            column: 0,
                        });
                    }
                }
                Statement::Function { name, return_type, .. } => {
                    if !self.used_functions.contains(name) && name != "main" {
                        self.warnings.push(Warning {
                            code: "W004".to_string(),
                            message: format!("Unused function: '{}'", name),
                            severity: WarningSeverity::Hint,
                            line: 0,
                            column: 0,
                        });
                    }
                    if *return_type == DataType::Unknown {
                        self.warnings.push(Warning {
                            code: "W005".to_string(),
                            message: format!("Function '{}' has implicit return type", name),
                            severity: WarningSeverity::Hint,
                            line: 0,
                            column: 0,
                        });
                    }
                }
                _ => {}
            }
        }
    }

    fn analyze_statements(&mut self, statements: &[Statement]) {
        for stmt in statements {
            match stmt {
                Statement::Let { name, value, .. } => {
                    if let Some(expr) = value {
                        self.analyze_expression(expr);
                    }
                    self.used_variables.insert(name.clone());
                }
                Statement::Assignment { target, value, .. } => {
                    self.analyze_assignment_target(target);
                    self.analyze_expression(value);
                }
                Statement::Return(expr) => {
                    if let Some(e) = expr {
                        self.analyze_expression(e);
                    }
                }
                Statement::If { condition, then_branch, else_branch, .. } => {
                    self.analyze_expression(condition);
                    self.analyze_statements(then_branch);
                    if let Some(else_br) = else_branch {
                        self.analyze_statements(else_br);
                    }
                }
                Statement::While { condition, body, .. } => {
                    self.check_condition_always(condition, "while");
                    self.analyze_expression(condition);
                    self.analyze_statements(body);
                }
                Statement::For { variable, iterable, body, .. } => {
                    self.used_variables.insert(variable.clone());
                    self.analyze_expression(iterable);
                    self.analyze_statements(body);
                }
                Statement::Function { name, body, .. } => {
                    self.used_functions.insert(name.clone());
                    self.analyze_statements(body);
                }
                Statement::Match { value, cases, .. } => {
                    self.analyze_expression(value);
                }
                Statement::Expression(expr) => {
                    self.analyze_expression(expr);
                }
                _ => {}
            }
        }
    }

    fn analyze_expression(&mut self, expr: &Expression) {
        match expr {
            Expression::Identifier(id) => {
                if self.defined_variables.contains(&id.name) || self.defined_functions.contains(&id.name) {
                    self.used_variables.insert(id.name.clone());
                }
            }
            Expression::Call { name, args, .. } => {
                self.used_functions.insert(name.clone());
                for arg in args {
                    self.analyze_expression(arg);
                }
            }
            Expression::BinaryOp { operator, left, right, .. } => {
                if *operator == "&&" {
                    self.check_short_circuit_left(left);
                } else if *operator == "||" {
                    self.check_short_circuit_right(left);
                }
                self.analyze_expression(left);
                self.analyze_expression(right);
            }
            Expression::UnaryOp { operand, .. } => {
                self.analyze_expression(operand);
            }
            Expression::List { elements, .. } => {
                for elem in elements {
                    self.analyze_expression(elem);
                }
            }
            Expression::Dict { entries, .. } => {
                for (key, value) in entries {
                    self.analyze_expression(key);
                    self.analyze_expression(value);
                }
            }
            Expression::Tuple { elements, .. } => {
                for elem in elements {
                    self.analyze_expression(elem);
                }
            }
            Expression::Index { target, index, .. } => {
                self.analyze_expression(target);
                self.analyze_expression(index);
            }
            Expression::MemberAccess { target, .. } => {
                self.analyze_expression(target);
            }
            Expression::Closure { body, .. } => {
                self.analyze_statements(body);
            }
            Expression::Pipeline { input, stage, .. } => {
                self.analyze_expression(input);
                self.analyze_expression(stage);
            }
            Expression::Match { value, cases, .. } => {
                self.analyze_expression(value);
            }
            Expression::Reference { expr, .. } => {
                self.analyze_expression(expr);
            }
            Expression::Dereference { expr, .. } => {
                self.analyze_expression(expr);
            }
            Expression::Box { value, .. } => {
                self.analyze_expression(value);
            }
            Expression::EnumVariant { payloads, .. } => {
                for payload in payloads {
                    self.analyze_expression(payload);
                }
            }
            _ => {}
        }
    }

    fn analyze_assignment_target(&mut self, target: &crate::parser::ast::AssignmentTarget) {
        match target {
            crate::parser::ast::AssignmentTarget::Variable(name) => {
                self.used_variables.insert(name.clone());
            }
            crate::parser::ast::AssignmentTarget::Field(path) => {
                if let Some(root) = path.split('.').next() {
                    self.used_variables.insert(root.to_string());
                }
            }
            crate::parser::ast::AssignmentTarget::Index { target, index, .. } => {
                self.analyze_expression(target);
                self.analyze_expression(index);
            }
        }
    }

    fn check_short_circuit_left(&mut self, expr: &Expression) {
        if let Expression::Literal(Literal::Bool(false)) = expr {
            self.warnings.push(Warning {
                code: "W007".to_string(),
                message: "Left side of '&&' is always false (short-circuit)".to_string(),
                severity: WarningSeverity::Hint,
                line: 0,
                column: 0,
            });
        }
    }

    fn check_short_circuit_right(&mut self, expr: &Expression) {
        if let Expression::Literal(Literal::Bool(true)) = expr {
            self.warnings.push(Warning {
                code: "W008".to_string(),
                message: "Left side of '||' is always true (short-circuit)".to_string(),
                severity: WarningSeverity::Hint,
                line: 0,
                column: 0,
            });
        }
    }

    fn check_condition_always(&mut self, condition: &Expression, context: &str) {
        if let Expression::Literal(Literal::Bool(false)) = condition {
            self.warnings.push(Warning {
                code: "W009".to_string(),
                message: format!("Dead code: {} will never execute", context),
                severity: WarningSeverity::Warning,
                line: 0,
                column: 0,
            });
        }
    }
}

pub fn check_warnings(program: &Program) -> Vec<Warning> {
    Warnings::analyze(program)
}