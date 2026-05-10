use crate::parser::ast::{DataType, Expression, Statement, Literal};
use crate::parser::Program;
use std::collections::HashSet;

#[derive(Debug, Clone)]
pub struct Warning {
    pub code: String,
    pub message: String,
    pub severity: WarningSeverity,
    pub category: WarningCategory,
    pub line: usize,
    pub column: usize,
    pub source_file: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WarningSeverity {
    Hint,
    Info,
    Warning,
    Error,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WarningCategory {
    Unused,
    Type,
    Performance,
    Security,
    Style,
    Complexity,
    BestPractice,
    Deprecated,
    NullSafety,
    Concurrency,
    Memory,
}

impl WarningSeverity {
    pub fn as_str(&self) -> &'static str {
        match self {
            WarningSeverity::Hint => "hint",
            WarningSeverity::Info => "info",
            WarningSeverity::Warning => "warning",
            WarningSeverity::Error => "error",
        }
    }
}

impl WarningCategory {
    pub fn as_str(&self) -> &'static str {
        match self {
            WarningCategory::Unused => "unused",
            WarningCategory::Type => "type",
            WarningCategory::Performance => "performance",
            WarningCategory::Security => "security",
            WarningCategory::Style => "style",
            WarningCategory::Complexity => "complexity",
            WarningCategory::BestPractice => "best-practice",
            WarningCategory::Deprecated => "deprecated",
            WarningCategory::NullSafety => "null-safety",
            WarningCategory::Concurrency => "concurrency",
            WarningCategory::Memory => "memory",
        }
    }
}

pub struct Warnings {
    pub warnings: Vec<Warning>,
    defined_variables: HashSet<String>,
    defined_functions: HashSet<String>,
    used_variables: HashSet<String>,
    used_functions: HashSet<String>,
    loop_depth: usize,
    max_loop_depth: usize,
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
            loop_depth: 0,
            max_loop_depth: 0,
        }
    }

    pub fn analyze(program: &Program) -> Vec<Warning> {
        let mut warnings = Warnings::new();
        warnings.analyze_program(program);
        warnings.warnings
    }

    fn analyze_program(&mut self, program: &Program) {
        self.analyze_statements(&program.statements);
        
        for stmt in &program.statements {
            self.check_statement_warnings(stmt);
        }
        
        self.check_unused_definitions();
    }

    fn check_statement_warnings(&mut self, stmt: &Statement) {
        match stmt {
            Statement::Use { path, items, .. } => {
                if path.trim().is_empty() || matches!(items, Some(v) if v.is_empty()) {
                    self.add_warning("W001", "Suspicious or empty import",
                        WarningSeverity::Hint, WarningCategory::Unused, 0, 0);
                }
            }
            Statement::Function { name, body, .. } => {
                if body.len() > 50 {
                    self.add_warning("W012", &format!("Function '{}' is too long ({} lines)", name, body.len()),
                        WarningSeverity::Info, WarningCategory::Complexity, 0, 0);
                }
                for s in body {
                    self.check_statement_warnings(s);
                }
                if body.is_empty() {
                    self.add_warning("W010", &format!("Function '{}' has empty body", name),
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
            }
            Statement::While { condition, body, .. } => {
                self.loop_depth += 1;
                self.max_loop_depth = self.max_loop_depth.max(self.loop_depth);
                
                self.check_loop_warnings(condition);
                for s in body {
                    self.check_statement_warnings(s);
                }
                
                self.loop_depth -= 1;
            }
            Statement::For { body, .. } => {
                self.loop_depth += 1;
                self.max_loop_depth = self.max_loop_depth.max(self.loop_depth);
                if body.is_empty() {
                    self.add_warning("W037", "Loop has empty body",
                        WarningSeverity::Info, WarningCategory::Complexity, 0, 0);
                }
                for s in body {
                    self.check_statement_warnings(s);
                }
                self.loop_depth -= 1;
            }
            Statement::If { condition, then_branch, else_branch, .. } => {
                self.check_condition_warnings(condition);
                if then_branch.is_empty() && else_branch.as_ref().map(|b| b.is_empty()).unwrap_or(true) {
                    self.add_warning("W013", "If statement has empty branches",
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                for s in then_branch {
                    self.check_statement_warnings(s);
                }
                if let Some(else_br) = else_branch {
                    for s in else_br {
                        self.check_statement_warnings(s);
                    }
                }
            }
            Statement::Match { value, cases, default, .. } => {
                self.check_expression_warnings(value);
                for (_, body) in cases {
                    for s in body {
                        self.check_statement_warnings(s);
                    }
                }
                for s in default {
                    self.check_statement_warnings(s);
                }
            }
            Statement::Expression(expr) => {
                self.check_expression_warnings(expr);
                if let Expression::Literal(_) = expr {
                    self.add_warning("W006", "Useless literal expression statement",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
            Statement::Return(expr) => {
                if let Some(e) = expr {
                    self.check_return_warnings(e);
                }
            }
            Statement::Break | Statement::Continue => {
                if self.loop_depth == 0 {
                    self.add_warning("W052", "Break/continue outside of loop",
                        WarningSeverity::Error, WarningCategory::Concurrency, 0, 0);
                }
            }
            _ => {}
        }
    }

    fn check_expression_warnings(&mut self, expr: &Expression) {
        match expr {
            Expression::Identifier(id) => {
                if self.defined_variables.contains(&id.name) || self.defined_functions.contains(&id.name) {
                    self.used_variables.insert(id.name.clone());
                }
                
                if id.name.len() > 30 {
                    self.add_warning("W014", &format!("Variable name '{}' is too long", id.name),
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
            }
            Expression::Call { name, args, .. } => {
                self.used_functions.insert(name.clone());
                
                if name == "clone" {
                    self.add_warning("W015", "Unnecessary clone call",
                        WarningSeverity::Info, WarningCategory::Performance, 0, 0);
                }
                
                if name == "println" || name == "print" {
                    self.add_warning("W016", "Consider using dasu() for output",
                        WarningSeverity::Hint, WarningCategory::BestPractice, 0, 0);
                }
                
                if args.is_empty() && !self.defined_functions.contains(name) {
                    self.add_warning("W017", &format!("Call to undefined function: '{}'", name),
                        WarningSeverity::Error, WarningCategory::Type, 0, 0);
                }
                
                for arg in args {
                    self.check_expression_warnings(arg);
                }
            }
            Expression::BinaryOp { operator, left, right, .. } => {
                self.check_binary_op_warnings(operator, left, right);
                self.check_expression_warnings(left);
                self.check_expression_warnings(right);
            }
            Expression::UnaryOp { operator, operand, .. } => {
                if *operator == "*" {
                    if let Expression::Identifier(id) = operand.as_ref() {
                        if !self.used_variables.contains(&id.name) {
                            self.add_warning("W018", &format!("Dereferencing unused variable: '{}'", id.name),
                                WarningSeverity::Hint, WarningCategory::Unused, 0, 0);
                        }
                    }
                }
                self.check_expression_warnings(operand);
            }
            Expression::List { elements, .. } => {
                if elements.is_empty() {
                    self.add_warning("W019", "Empty list literal",
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                for elem in elements {
                    self.check_expression_warnings(elem);
                }
            }
            Expression::Dict { entries, .. } => {
                if entries.is_empty() {
                    self.add_warning("W020", "Empty dict literal",
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                for (key, value) in entries {
                    self.check_expression_warnings(key);
                    self.check_expression_warnings(value);
                }
            }
            Expression::Index { target, index, .. } => {
                if let Expression::Literal(Literal::Int(n)) = index.as_ref() {
                    if *n < 0 {
                        self.add_warning("W021", "Negative index access",
                            WarningSeverity::Error, WarningCategory::Type, 0, 0);
                    }
                }
                self.check_expression_warnings(target);
                self.check_expression_warnings(index);
            }
            Expression::Closure { params, body, .. } => {
                if params.len() > 3 {
                    self.add_warning("W022", "Closure has many parameters",
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                self.analyze_statements(body);
            }
            Expression::Literal(lit) => {
                self.check_literal_warnings(lit);
            }
            Expression::Match { value, cases, .. } => {
                self.check_expression_warnings(value);
                for (case_expr, case_body) in cases {
                    self.check_expression_warnings(case_expr);
                    if let Expression::List { elements, .. } = case_body {
                        for elem in elements {
                            self.check_expression_warnings(elem);
                        }
                    }
                }
            }
            Expression::Reference { expr, .. } => {
                self.check_expression_warnings(expr);
            }
            Expression::Dereference { expr, .. } => {
                self.check_expression_warnings(expr);
            }
            _ => {}
        }
    }

    fn check_binary_op_warnings(&mut self, operator: &String, left: &Expression, right: &Expression) {
        if operator == "&&" {
            if let Expression::Literal(Literal::Bool(false)) = left {
                self.add_warning("W007", "Left side of '&&' is always false (short-circuit)",
                    WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
            }
            self.check_condition_warnings(left);
        } else if operator == "||" {
            if let Expression::Literal(Literal::Bool(true)) = left {
                self.add_warning("W008", "Left side of '||' is always true (short-circuit)",
                    WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
            }
            self.check_condition_warnings(left);
        } else if operator == "+" {
            if let Expression::Literal(Literal::Str(s)) = left {
                if s.is_empty() {
                    self.add_warning("W023", "Adding empty string",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
            if let Expression::Literal(Literal::Str(s)) = right {
                if s.is_empty() {
                    self.add_warning("W024", "Adding empty string",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
        } else if operator == "*" {
            if let Expression::Literal(Literal::Int(n)) = left {
                if *n == 0 {
                    self.add_warning("W025", "Multiplication by zero",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
            if let Expression::Literal(Literal::Int(n)) = right {
                if *n == 0 {
                    self.add_warning("W026", "Multiplication by zero",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
                if *n == 1 {
                    self.add_warning("W027", "Multiplication by 1 is redundant",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
        } else if operator == "/" {
            if let Expression::Literal(Literal::Int(n)) = right {
                if *n == 0 {
                    self.add_warning("W028", "Division by zero",
                        WarningSeverity::Error, WarningCategory::Security, 0, 0);
                }
                if *n == 1 {
                    self.add_warning("W029", "Division by 1 is redundant",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
        } else if operator == "%" {
            if let Expression::Literal(Literal::Int(n)) = right {
                if *n == 0 {
                    self.add_warning("W030", "Modulo by zero",
                        WarningSeverity::Error, WarningCategory::Security, 0, 0);
                }
                if *n == 1 {
                    self.add_warning("W031", "Modulo by 1 is always 0",
                        WarningSeverity::Hint, WarningCategory::Performance, 0, 0);
                }
            }
        }
    }

    fn check_condition_warnings(&mut self, condition: &Expression) {
        if let Expression::Literal(Literal::Bool(false)) = condition {
            self.add_warning("W009", "Condition is always false",
                WarningSeverity::Warning, WarningCategory::Complexity, 0, 0);
        }
        if let Expression::Literal(Literal::Bool(true)) = condition {
            self.add_warning("W032", "Condition is always true",
                WarningSeverity::Warning, WarningCategory::Complexity, 0, 0);
        }
    }

    fn check_loop_warnings(&mut self, condition: &Expression) {
        if let Expression::Literal(Literal::Bool(true)) = condition {
            self.add_warning("W033", "Infinite loop detected (while true)",
                WarningSeverity::Warning, WarningCategory::Performance, 0, 0);
        }
        if let Expression::Literal(Literal::Bool(false)) = condition {
            self.add_warning("W034", "Loop body is unreachable (while false)",
                WarningSeverity::Info, WarningCategory::Complexity, 0, 0);
        }
        
        if self.loop_depth > 3 {
            self.add_warning("W035", &format!("Nested loops (depth: {})", self.loop_depth),
                WarningSeverity::Info, WarningCategory::Complexity, 0, 0);
        }
        if self.loop_depth > 5 {
            self.add_warning("W036", &format!("Very deep loop nesting (depth: {})", self.loop_depth),
                WarningSeverity::Warning, WarningCategory::Complexity, 0, 0);
        }
    }

    fn check_return_warnings(&mut self, expr: &Expression) {
        if let Expression::Literal(Literal::Int(_)) = expr {
            self.add_warning("W038", "Returning literal number, consider using a constant",
                WarningSeverity::Hint, WarningCategory::BestPractice, 0, 0);
        }
        if let Expression::Literal(Literal::Str(_)) = expr {
            self.add_warning("W039", "Returning literal string, consider using a constant",
                WarningSeverity::Hint, WarningCategory::BestPractice, 0, 0);
        }
    }

    fn check_literal_warnings(&mut self, lit: &Literal) {
        match lit {
            Literal::Str(s) => {
                if s.len() > 100 {
                    self.add_warning("W040", "Very long string literal",
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                
                if s.is_empty() {
                    self.add_warning("W041", "Empty string literal",
                        WarningSeverity::Hint, WarningCategory::Style, 0, 0);
                }
                if s.chars().any(|c| c.is_control()) {
                    self.add_warning("W050", "String literal contains control characters",
                        WarningSeverity::Warning, WarningCategory::Security, 0, 0);
                }
            }
            Literal::Int(n) => {
                if *n == 0 || *n == 1 {
                    self.add_warning("W042", "Using magic number, consider using a named constant",
                        WarningSeverity::Hint, WarningCategory::BestPractice, 0, 0);
                }
                if *n < 0 {
                    self.add_warning("W051", "Negative literal used directly",
                        WarningSeverity::Hint, WarningCategory::BestPractice, 0, 0);
                }
            }
            Literal::Float(_) => {
                self.add_warning("W043", "Float literal may reduce deterministic behavior",
                    WarningSeverity::Info, WarningCategory::BestPractice, 0, 0);
            }
            Literal::Bool(_) => {
                self.add_warning("W044", "Boolean literal can hide hardcoded control flow",
                    WarningSeverity::Hint, WarningCategory::Style, 0, 0);
            }
            Literal::Char(_) => {
                self.add_warning("W045", "Character literal used directly",
                    WarningSeverity::Hint, WarningCategory::Style, 0, 0);
            }
            Literal::None => {
                self.add_warning("W046", "None literal used directly",
                    WarningSeverity::Info, WarningCategory::NullSafety, 0, 0);
            }
            Literal::List(values) if values.len() > 128 => {
                self.add_warning("W047", "Large list literal can impact compile/runtime memory",
                    WarningSeverity::Info, WarningCategory::Memory, 0, 0);
            }
            Literal::Dict(values) if values.len() > 64 => {
                self.add_warning("W048", "Large dict literal can impact compile/runtime memory",
                    WarningSeverity::Info, WarningCategory::Memory, 0, 0);
            }
            Literal::Tuple(values) if values.len() > 16 => {
                self.add_warning("W049", "Large tuple literal may hurt readability",
                    WarningSeverity::Info, WarningCategory::Style, 0, 0);
            }
            _ => {}
        }
    }

    fn check_unused_definitions(&mut self) {
        // Check unused variables
        let defined: Vec<String> = self.defined_variables.iter().cloned().collect();
        for var in defined {
            if !self.used_variables.contains(&var) && !var.starts_with('_') {
                self.add_warning("W002", &format!("Unused variable: '{}'", var),
                    WarningSeverity::Hint, WarningCategory::Unused, 0, 0);
            }
        }
        
        // Check unused functions
        let funcs: Vec<String> = self.defined_functions.iter().cloned().collect();
        for func in funcs {
            if !self.used_functions.contains(&func) && func != "main" && !func.starts_with('_') {
                self.add_warning("W004", &format!("Unused function: '{}'", func),
                    WarningSeverity::Hint, WarningCategory::Unused, 0, 0);
            }
        }
    }

    fn analyze_statements(&mut self, statements: &[Statement]) {
        for stmt in statements {
            self.analyze_statement_defs_and_uses(stmt);
        }
    }

    fn analyze_statement_defs_and_uses(&mut self, stmt: &Statement) {
        match stmt {
            Statement::Let { name, data_type, value, .. } => {
                self.defined_variables.insert(name.clone());
                if *data_type == DataType::Unknown {
                    self.add_warning("W003", "Implicit type annotation",
                        WarningSeverity::Hint, WarningCategory::Type, 0, 0);
                }
                if let Some(expr) = value {
                    self.check_expression_warnings(expr);
                }
            }
            Statement::Assignment { target: _, value, .. } => {
                self.check_expression_warnings(value);
            }
            Statement::Return(expr) => {
                if let Some(e) = expr {
                    self.check_expression_warnings(e);
                }
            }
            Statement::If { condition, then_branch, else_branch, .. } => {
                self.check_expression_warnings(condition);
                self.analyze_statements(then_branch);
                if let Some(else_br) = else_branch {
                    self.analyze_statements(else_br);
                }
            }
            Statement::While { condition, body, .. } => {
                self.check_expression_warnings(condition);
                self.analyze_statements(body);
            }
            Statement::For { variable, iterable, body, .. } => {
                self.used_variables.insert(variable.clone());
                self.check_expression_warnings(iterable);
                self.analyze_statements(body);
            }
            Statement::Function { name, params, return_type, body, .. } => {
                self.defined_functions.insert(name.clone());
                if *return_type == DataType::Unknown {
                    self.add_warning("W005", &format!("Function '{}' has implicit return type", name),
                        WarningSeverity::Hint, WarningCategory::Type, 0, 0);
                }
                if params.len() > 5 {
                    self.add_warning("W011", &format!("Function '{}' has many parameters", name),
                        WarningSeverity::Info, WarningCategory::Style, 0, 0);
                }
                self.analyze_statements(body);
            }
            Statement::Match { value, cases, default, .. } => {
                self.check_expression_warnings(value);
                for (pat, body) in cases {
                    self.check_expression_warnings(pat);
                    self.analyze_statements(body);
                }
                self.analyze_statements(default);
            }
            Statement::Find { variable, iterable, body, .. } => {
                self.used_variables.insert(variable.clone());
                self.check_expression_warnings(iterable);
                self.analyze_statements(body);
            }
            Statement::Type { fields, .. } => {
                self.analyze_statements(fields);
            }
            Statement::Code { methods, .. } => {
                self.analyze_statements(methods);
            }
            Statement::Class { methods, .. } => {
                self.analyze_statements(methods);
            }
            Statement::Expression(expr) => {
                self.check_expression_warnings(expr);
            }
            _ => {}
        }
    }

    fn add_warning(&mut self, code: &str, message: &str, severity: WarningSeverity, category: WarningCategory, line: usize, column: usize) {
        self.warnings.push(Warning {
            code: code.to_string(),
            message: message.to_string(),
            severity,
            category,
            line,
            column,
            source_file: None,
        });
    }
}

pub fn check_warnings(program: &Program) -> Vec<Warning> {
    Warnings::analyze(program)
}

pub fn format_warning(w: &Warning) -> String {
    let severity_color = match w.severity {
        WarningSeverity::Error => "\x1b[1;31m",   // bold red
        WarningSeverity::Warning => "\x1b[1;33m", // bold yellow
        WarningSeverity::Info => "\x1b[1;34m",    // bold blue
        WarningSeverity::Hint => "\x1b[1;32m",    // bold green
    };
    let reset = "\x1b[0m";
    format!(
        "{severity_color}warning[{code}]{reset} {category_color}{category}{reset}: {message}",
        severity_color = severity_color,
        code = w.code,
        reset = reset,
        category_color = "\x1b[90m",
        category = w.category.as_str(),
        message = w.message,
    )
}
