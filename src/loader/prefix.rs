use crate::loader::*;
pub(crate) fn prefix_loaded_statements_scoped(
    statements: Vec<ExpandedStatement>,
    module_name: &str,
    module_path: &Path,
) -> Vec<ExpandedStatement> {
    let mut symbols_by_prefix: HashMap<String, HashSet<String>> = HashMap::new();
    for statement in &statements {
        let prefix = statement_prefix(module_name, module_path, &statement.origin);
        if let Some(name) = statement_export_name(&statement.statement) {
            symbols_by_prefix
                .entry(prefix)
                .or_default()
                .insert(name.to_string());
        }
    }

    statements
        .into_iter()
        .map(|mut statement| {
            let prefix = statement_prefix(module_name, module_path, &statement.origin);
            if prefix.is_empty() {
                return statement;
            }
            let module_symbols = symbols_by_prefix.get(&prefix).cloned().unwrap_or_default();
            let renamer = ModuleRenamer {
                prefix: &prefix,
                module_symbols: &module_symbols,
            };
            statement.statement = renamer.rename_statement(statement.statement, true);
            statement
        })
        .collect()
}

fn statement_prefix(module_name: &str, module_path: &Path, origin: &Path) -> String {
    if origin == module_path {
        let file_stem = module_path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("");
        if file_stem.starts_with('_') {
            return String::new();
        }
        return module_name.to_string();
    }

    let base = module_path.parent().unwrap_or(module_path);
    let Ok(relative) = origin.strip_prefix(base) else {
        return String::new();
    };
    let mut parts = Vec::new();
    for component in relative.components() {
        let part = component.as_os_str().to_string_lossy().to_string();
        if !part.is_empty() {
            parts.push(part);
        }
    }

    if parts.is_empty() {
        return module_name.to_string();
    }

    let file_name = parts.pop().unwrap();
    let file_stem = Path::new(&file_name)
        .file_stem()
        .and_then(|value| value.to_str())
        .unwrap_or(&file_name)
        .to_string();

    if file_stem.starts_with('_') {
        return String::new();
    }

    if file_stem == "mod" {
        if !parts.is_empty() && (parts[0] == "core" || parts[0] == "ext") {
            parts.remove(0);
        }
        if parts.is_empty() {
            module_name.to_string()
        } else {
            parts.join(".")
        }
    } else {
        if !parts.is_empty() && (parts[0] == "core" || parts[0] == "ext") {
            parts.remove(0);
        }
        parts.push(file_stem);
        if parts.is_empty() {
            module_name.to_string()
        } else {
            parts.join(".")
        }
    }
}

