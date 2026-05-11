use crate::error::diagnostic::{Diagnostic, DiagnosticCode, Label, LabelStyle, Severity, WarningFilter};
use crate::parser::Program;
use crate::parser::ast::{DataType, Expression, Identifier, Literal, Statement};
use std::collections::HashSet;

pub struct WarningAnalyzer {
    diagnostics: Vec<Diagnostic>,
    filter: WarningFilter,
    deny: HashSet<DiagnosticCode>,
    defined_variables: HashSet<String>,
    used_variables: HashSet<String>,
    defined_functions: HashSet<String>,
    used_functions: HashSet<String>,
    imported_modules: Vec<Identifier>,
    used_imports: HashSet<String>,
    loop_depth: usize,
}

impl WarningAnalyzer {
    pub fn new(filter: WarningFilter, deny: HashSet<DiagnosticCode>) -> Self {
        Self {
            diagnostics: Vec::new(),
            filter,
            deny,
            defined_variables: HashSet::new(),
            used_variables: HashSet::new(),
            defined_functions: HashSet::new(),
            used_functions: HashSet::new(),
            imported_modules: Vec::new(),
            used_imports: HashSet::new(),
            loop_depth: 0,
        }
    }

    pub fn analyze(mut self, program: &Program, source: &str, filename: Option<&str>) -> Vec<Diagnostic> {
        for stmt in &program.statements {
            self.scan_defs(stmt);
        }
        for stmt in &program.statements {
            self.scan_usage(stmt);
        }

        let defined_variables: Vec<String> = self.defined_variables.iter().cloned().collect();
        for name in &defined_variables {
            if !name.starts_with('_') && !self.used_variables.contains(name) {
                self.push_warn(
                    DiagnosticCode::W0001,
                    "Unused Variable",
                    format!("Variable '{}' is never used", name),
                    1,
                    1,
                    Some("prefix with '_' to suppress this warning".to_string()),
                );
            }
        }

        let defined_functions: Vec<String> = self.defined_functions.iter().cloned().collect();
        for name in &defined_functions {
            if name != "main" && !name.starts_with('_') && !self.used_functions.contains(name) {
                self.push_warn(
                    DiagnosticCode::W0002,
                    "Unused Function",
                    format!("Function '{}' is never used", name),
                    1,
                    1,
                    None,
                );
            }
        }

        let imported_modules = self.imported_modules.clone();
        for import in &imported_modules {
            if !self.used_imports.contains(&import.name) {
                self.push_warn(
                    DiagnosticCode::W0003,
                    "Unused Import",
                    format!("Import '{}' is never used", import.name),
                    import.line,
                    import.column,
                    None,
                );
            }
        }

        for diag in &mut self.diagnostics {
            diag.source = Some(source.to_string());
            if let Some(filename) = filename {
                diag.filename = Some(filename.to_string());
            }
        }
        self.diagnostics
    }

    fn scan_defs(&mut self, stmt: &Statement) {
        match stmt {
            Statement::Let { name, data_type, .. } => {
                self.defined_variables.insert(name.clone());
                if *data_type == DataType::Unknown {
                    self.push_warn(
                        DiagnosticCode::W0004,
                        "Implicit Type Annotation",
                        format!("Variable '{}' relies on implicit typing", name),
                        1,
                        1,
                        None,
                    );
                }
            }
            Statement::Function { name, params, return_type, body, .. } => {
                self.defined_functions.insert(name.clone());
                if *return_type == DataType::Unknown {
                    self.push_warn(
                        DiagnosticCode::W0005,
                        "Implicit Return Type",
                        format!("Function '{}' has implicit return type", name),
                        1,
                        1,
                        None,
                    );
                }
                if body.is_empty() {
                    self.push_warn(
                        DiagnosticCode::W0006,
                        "Empty Function Body",
                        format!("Function '{}' has an empty body", name),
                        1,
                        1,
                        Some("add statements to the function body".to_string()),
                    );
                }
                if body.len() > 60 {
                    self.push_warn(
                        DiagnosticCode::W0011,
                        "Long Function",
                        format!("Function '{}' is very long ({} statements)", name, body.len()),
                        1,
                        1,
                        None,
                    );
                }
                if params.len() > 5 {
                    self.push_warn(
                        DiagnosticCode::W0012,
                        "Many Parameters",
                        format!("Function '{}' has many parameters ({})", name, params.len()),
                        1,
                        1,
                        None,
                    );
                }
                for b in body {
                    self.scan_defs(b);
                }
            }
            Statement::Use { path, is_local, .. } => {
                if !*is_local {
                    self.imported_modules.push(Identifier {
                        name: path.clone(),
                        data_type: DataType::Unknown,
                        line: 1,
                        column: 1,
                    });
                }
            }
            Statement::If { then_branch, else_branch, .. } => {
                for s in then_branch {
                    self.scan_defs(s);
                }
                if let Some(else_branch) = else_branch {
                    for s in else_branch {
                        self.scan_defs(s);
                    }
                }
            }
            Statement::While { body, .. }
            | Statement::For { body, .. }
            | Statement::Find { body, .. } => {
                for s in body {
                    self.scan_defs(s);
                }
            }
            Statement::Match { cases, default, .. } => {
                for (_, body) in cases {
                    for s in body {
                        self.scan_defs(s);
                    }
                }
                for s in default {
                    self.scan_defs(s);
                }
            }
            _ => {}
        }
    }

    fn scan_usage(&mut self, stmt: &Statement) {
        match stmt {
            Statement::Expression(expr) => self.scan_expr(expr),
            Statement::Assignment { value, .. } => self.scan_expr(value),
            Statement::Return(expr) => {
                if let Some(expr) = expr {
                    self.scan_expr(expr);
                }
            }
            Statement::If { condition, then_branch, else_branch } => {
                self.scan_expr(condition);
                if then_branch.is_empty() && else_branch.as_ref().is_none_or(|v| v.is_empty()) {
                    self.push_warn(
                        DiagnosticCode::W0014,
                        "Empty If Branches",
                        "if statement has empty branches".to_string(),
                        1,
                        1,
                        None,
                    );
                }
                for s in then_branch {
                    self.scan_usage(s);
                }
                if let Some(else_branch) = else_branch {
                    for s in else_branch {
                        self.scan_usage(s);
                    }
                }
            }
            Statement::While { condition, body } => {
                self.loop_depth += 1;
                self.scan_expr(condition);
                if let Expression::Literal(Literal::Bool(true)) = condition {
                    self.push_warn(DiagnosticCode::W0016, "Infinite Loop", "while true can loop forever".to_string(), 1, 1, None);
                }
                if let Expression::Literal(Literal::Bool(false)) = condition {
                    self.push_warn(DiagnosticCode::W0017, "Unreachable Loop", "while false body is unreachable".to_string(), 1, 1, None);
                }
                if self.loop_depth > 4 {
                    self.push_warn(DiagnosticCode::W0018, "Deep Loop Nesting", format!("loop nesting depth is {}", self.loop_depth), 1, 1, None);
                }
                if body.is_empty() {
                    self.push_warn(DiagnosticCode::W0013, "Empty Loop Body", "loop has an empty body".to_string(), 1, 1, None);
                }
                for s in body {
                    self.scan_usage(s);
                }
                self.loop_depth -= 1;
            }
            Statement::For { iterable, body, .. } => {
                self.loop_depth += 1;
                self.scan_expr(iterable);
                if body.is_empty() {
                    self.push_warn(DiagnosticCode::W0013, "Empty Loop Body", "loop has an empty body".to_string(), 1, 1, None);
                }
                for s in body {
                    self.scan_usage(s);
                }
                self.loop_depth -= 1;
            }
            Statement::Break | Statement::Continue => {
                if self.loop_depth == 0 {
                    self.push_warn(DiagnosticCode::W0019, "Control Flow", "break/continue outside loop".to_string(), 1, 1, None);
                }
            }
            Statement::Use { path, .. } => {
                self.used_imports.insert(path.clone());
            }
            Statement::Function { body, .. } => {
                for s in body {
                    self.scan_usage(s);
                }
            }
            Statement::Match { value, cases, default } => {
                self.scan_expr(value);
                for (pat, body) in cases {
                    self.scan_expr(pat);
                    for s in body {
                        self.scan_usage(s);
                    }
                }
                for s in default {
                    self.scan_usage(s);
                }
            }
            _ => {}
        }
    }

    fn scan_expr(&mut self, expr: &Expression) {
        match expr {
            Expression::Identifier(id) => {
                self.used_variables.insert(id.name.clone());
            }
            Expression::Call { name, args, .. } => {
                self.used_functions.insert(name.clone());
                if name == "clone" {
                    self.push_warn(DiagnosticCode::W0027, "Unnecessary Clone", "unnecessary clone call".to_string(), 1, 1, None);
                }
                if args.is_empty() && !self.defined_functions.contains(name) {
                    self.push_warn(
                        DiagnosticCode::W0020,
                        "Unknown Function Call",
                        format!("call to undefined function '{}'", name),
                        1,
                        1,
                        None,
                    );
                }
                for arg in args {
                    self.scan_expr(arg);
                }
            }
            Expression::BinaryOp { operator, left, right, .. } => {
                self.scan_expr(left);
                self.scan_expr(right);
                if let Expression::Literal(Literal::Int(n)) = right.as_ref() {
                    match operator.as_str() {
                        "*" if *n == 0 => self.push_warn(DiagnosticCode::W0007, "Multiplication by Zero", "multiplication by zero".to_string(), 1, 1, None),
                        "/" if *n == 0 => self.push_warn(DiagnosticCode::W0008, "Division by Zero", "division by zero".to_string(), 1, 1, None),
                        "%" if *n == 0 => self.push_warn(DiagnosticCode::W0009, "Modulo by Zero", "modulo by zero".to_string(), 1, 1, None),
                        _ => {}
                    }
                }
            }
            Expression::UnaryOp { operand, .. }
            | Expression::Reference { expr: operand, .. }
            | Expression::Dereference { expr: operand, .. }
            | Expression::Box { value: operand, .. } => self.scan_expr(operand),
            Expression::List { elements, .. } => {
                for e in elements {
                    self.scan_expr(e);
                }
                if elements.len() > 128 {
                    self.push_warn(DiagnosticCode::W0025, "Large List Literal", "large list literal may impact memory".to_string(), 1, 1, None);
                }
            }
            Expression::Dict { entries, .. } => {
                for (k, v) in entries {
                    self.scan_expr(k);
                    self.scan_expr(v);
                }
                if entries.len() > 64 {
                    self.push_warn(DiagnosticCode::W0025, "Large Dict Literal", "large dict literal may impact memory".to_string(), 1, 1, None);
                }
            }
            Expression::Index { target, index, .. } => {
                self.scan_expr(target);
                self.scan_expr(index);
                if let Expression::Literal(Literal::Int(n)) = index.as_ref()
                    && *n < 0
                {
                    self.push_warn(DiagnosticCode::W0021, "Negative Index", "negative index access".to_string(), 1, 1, None);
                }
            }
            Expression::Literal(lit) => {
                if let Literal::Int(n) = lit {
                    if *n == 0 || *n == 1 {
                        self.push_warn(DiagnosticCode::W0026, "Magic Number", "using literal 0/1 directly".to_string(), 1, 1, None);
                    }
                    if *n < 0 {
                        self.push_warn(DiagnosticCode::W0022, "Negative Literal", "negative literal used directly".to_string(), 1, 1, None);
                    }
                }
                if let Literal::Str(s) = lit {
                    if s.len() > 120 {
                        self.push_warn(DiagnosticCode::W0024, "Long String Literal", "very long string literal".to_string(), 1, 1, None);
                    }
                }
            }
            Expression::Tuple { elements, .. } => {
                for e in elements {
                    self.scan_expr(e);
                }
            }
            Expression::MemberAccess { target, .. }
            | Expression::Pipeline { input: target, .. } => self.scan_expr(target),
            Expression::Match { value, cases, default, .. } => {
                self.scan_expr(value);
                for (p, e) in cases {
                    self.scan_expr(p);
                    self.scan_expr(e);
                }
                self.scan_expr(default);
            }
            Expression::EnumVariant { payloads, .. } => {
                for p in payloads {
                    self.scan_expr(p);
                }
            }
            _ => {}
        }
    }

    fn push_warn(
        &mut self,
        code: DiagnosticCode,
        title: &str,
        message: String,
        line: usize,
        column: usize,
        help: Option<String>,
    ) {
        if !self.filter.matches(code) {
            return;
        }
        let severity = if self.deny.contains(&code) {
            Severity::Error
        } else {
            Severity::Warning
        };
        let mut diag = Diagnostic::new(severity, code, title, message, line, column);
        diag.labels.push(Label {
            line,
            column,
            length: 3,
            message: "".to_string(),
            style: LabelStyle::Primary,
        });
        diag.help = help;
        self.diagnostics.push(diag);
    }
}

pub fn check_warnings(
    program: &Program,
    source: &str,
    filename: Option<&str>,
    filter: WarningFilter,
    deny: HashSet<DiagnosticCode>,
) -> Vec<Diagnostic> {
    WarningAnalyzer::new(filter, deny).analyze(program, source, filename)
}
