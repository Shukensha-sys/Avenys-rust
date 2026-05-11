# Diagnostic System — Unified Error & Warning Framework

**Status:** Implemented (v2.6.0)
**Last updated:** May 2026
**Commits:** `383bd4f` (checkpoint), `050f49f` (implementation)
**Design doc for:** D6 (see `todo.md`)
**MORE:** `MORE/0004-diagnostic-system.md`

---

## 1. Motivation

The compiler currently has two separate systems:

- **Errors** (`src/error/mod.rs`): `MireError` + `ErrorKind` + `generate_explanation()` heuristic
- **Warnings** (`src/compiler/warnings.rs`): `Warning` struct + `format_warning()` one-liner

Problems:
1. Warnings are **never emitted** — `Warnings::analyze()` exists but is never called from the pipeline.
2. Warning format is a bare one-line string with no source context, no line/column, no color.
3. Unused variable/function detection doesn't work in practice.
4. Error codes are generic category strings (`"lexer"`, `"parser"`) — not unique, not searchable.
5. No CLI control for warnings (enable/disable/deny).

---

## 2. Design

### 2.1 Core Types

```rust
/// Severity of a diagnostic message
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
    Note,
    Help,
}

/// Unique diagnostic code
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum DiagnosticCode {
    // Errors
    E0001, // Lexer: unexpected character
    E0002, // Lexer: unterminated string/comment
    E0003, // Parser: expected token
    E0004, // Parser: unexpected token
    E0005, // Type: type mismatch
    E0006, // Type: unknown identifier
    E0007, // Borrow: use after move
    E0008, // Borrow: multiple mutable refs
    E0009, // Borrow: mutation while shared
    E0010, // Borrow: move while borrowed
    E0011, // Borrow: drop while borrowed
    E0012, // Borrow: double drop
    E0013, // Borrow: borrow out of scope
    E0014, // Backend: not yet lowered
    E0015, // Runtime: general

    // Warnings
    W0001, // Unused variable
    W0002, // Unused function
    W0003, // Unused import
    W0004, // Implicit type annotation
    W0005, // Implicit return type
    W0006, // Empty function body
    W0007, // Multiplication by zero
    W0008, // Division by zero
    W0009, // Modulo by zero
    W0010, // Deprecated syntax
    W0011, // Overly long function
    W0012, // Too many parameters
    W0013, // Empty loop body
    W0014, // Empty if branches
    W0015, // Condition always true/false
    W0016, // Infinite loop (while true)
    W0017, // Unreachable loop body (while false)
    W0018, // Deeply nested loops
    W0019, // Break/continue outside loop
    W0020, // Call to undefined function
    W0021, // Negative index access
    W0022, // Negative literal used directly
    W0023, // Useless literal expression
    W0024, // Very long string literal
    W0025, // Large list/dict literal
    W0026, // Magic number 0 or 1
    W0027, // Unnecessary clone call
}

/// A labeled span in source code
#[derive(Debug, Clone)]
pub struct Label {
    pub line: usize,
    pub column: usize,
    pub length: usize,       // length of the span in characters
    pub message: String,
    pub style: LabelStyle,   // Primary, Secondary
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LabelStyle {
    Primary,   // The main focus (^^^)
    Secondary, // Additional context (---)
}

/// An auto-fix suggestion (display only, no --fix)
#[derive(Debug, Clone)]
pub struct Suggestion {
    pub message: String,
    pub replacement: Option<String>, // If the fix is a simple text replacement
}

/// Unified diagnostic message
#[derive(Debug, Clone)]
pub struct Diagnostic {
    pub severity: Severity,
    pub code: DiagnosticCode,
    pub message: String,
    pub line: usize,
    pub column: usize,
    pub labels: Vec<Label>,
    pub notes: Vec<String>,
    pub help: Option<String>,
    pub suggestions: Vec<Suggestion>,
    pub source: Option<String>,
    pub filename: Option<String>,
}
```

### 2.2 WarningFilter

Controls which warnings are emitted based on the command context:

```rust
#[derive(Debug, Clone)]
pub enum WarningFilter {
    /// Only common warnings: W0001-W0005 (unused, implicit types)
    Default,
    /// All warnings: W0001-W0027
    All,
    /// Specific codes only
    Codes(HashSet<DiagnosticCode>),
}

impl WarningFilter {
    pub fn matches(&self, code: DiagnosticCode) -> bool {
        match self {
            WarningFilter::Default => matches!(
                code,
                DiagnosticCode::W0001
                    | DiagnosticCode::W0002
                    | DiagnosticCode::W0003
                    | DiagnosticCode::W0004
                    | DiagnosticCode::W0005
            ),
            WarningFilter::All => matches!(
                code,
                DiagnosticCode::W0001..=DiagnosticCode::W0027
            ),
            WarningFilter::Codes(codes) => codes.contains(&code),
        }
    }
}
```

---

## 3. Integration with MireError

`MireError` becomes a thin wrapper that always holds `Severity::Error`:

```rust
#[derive(Debug, Clone)]
pub struct MireError {
    diagnostic: Diagnostic, // always severity = Error
}

impl MireError {
    pub fn new(code: DiagnosticCode, message: String, line: usize, column: usize) -> Self {
        Self {
            diagnostic: Diagnostic {
                severity: Severity::Error,
                code,
                message,
                line,
                column,
                labels: Vec::new(),
                notes: Vec::new(),
                help: None,
                suggestions: Vec::new(),
                source: None,
                filename: None,
            },
        }
    }

    pub fn to_diagnostic(&self) -> &Diagnostic {
        &self.diagnostic
    }
}
```

Backward compatibility constructors are preserved:
- `MireError::type_error_at(line, col, msg)` → creates with `E0005`
- `MireError::ownership_error(line, col, kind)` → creates with `E0007`–`E0013`
- `MireError::runtime(msg)` → creates with `E0015`

---

## 4. Formatter

### 4.1 Output format

```
error[{code}] ── {title}
╭─[ {filename}:{line}:{column} ]
│ {ctx} │ {source_line}
│ {pad} │ {underline} {label_message}
...
╰─ {message}
   ─┬─ note: {note}
   ─┬─ help: {help}
```

### 4.2 Color scheme (ANSI)

| Element         | ANSI code         | Color     |
|-----------------|-------------------|-----------|
| Container      | `\x1b[1;36m`      | Cyan bold |
| `error[...]`   | `\x1b[1;31m`      | Red bold  |
| `warning[...]` | `\x1b[1;33m`      | Yellow bold |
| Filename       | `\x1b[1;36m`      | Cyan bold |
| Source line    | `\x1b[1;37m`      | White bold |
| `^^^`          | `\x1b[1;31m`      | Red bold  |
| `---`          | `\x1b[1;33m`      | Yellow bold |
| Labels         | `\x1b[90m`        | Bright black |
| Notes/help     | `\x1b[90m`        | Bright black |
| Message        | `\x1b[1;37m`      | White bold |

### 4.3 Context window

- Show 2 lines before and 2 lines after the error line
- Line numbers are right-aligned with padding
- Window shrinks at file boundaries

---

## 5. Warning Categories

Warnings are organized by category to allow `-W <category>` filtering:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WarningCategory {
    Unused,
    Type,
    Performance,
    Style,
    Complexity,
    Logic,
    Memory,
    Deprecated,
}

impl DiagnosticCode {
    pub fn category(self) -> Option<WarningCategory> {
        match self {
            Self::W0001 | Self::W0002 | Self::W0003 => Some(WarningCategory::Unused),
            Self::W0004 | Self::W0005 | Self::W0020 | Self::W0021 => Some(WarningCategory::Type),
            Self::W0007 | Self::W0008 | Self::W0009 | Self::W0027 => Some(WarningCategory::Performance),
            Self::W0006 | Self::W0010 | Self::W0012 | Self::W0013
                | Self::W0014 | Self::W0022 | Self::W0023 | Self::W0024
                | Self::W0026 => Some(WarningCategory::Style),
            Self::W0011 | Self::W0018 => Some(WarningCategory::Complexity),
            Self::W0015 | Self::W0016 | Self::W0017 | Self::W0019 => Some(WarningCategory::Logic),
            Self::W0025 => Some(WarningCategory::Memory),
            _ => None,
        }
    }
}
```

---

## 6. Pipeline Integration

### 6.1 Current flow (compiler/mod.rs)

```rust
pub fn analyze_program(program: &mut Program, source: &str) -> Result<SemanticModel> {
    typeck::check_program_types(program, source)?;   // returns on error
    let semantic_model = semantic::analyze_program(program); // no errors
    borrowck::check_program(program, &semantic_model)?;      // returns on error
    Ok(semantic_model)
}
```

### 6.2 New flow

```rust
pub fn analyze_program(
    program: &mut Program,
    source: &str,
    filter: WarningFilter,
) -> Result<(SemanticModel, Vec<Diagnostic>), MireError> {
    typeck::check_program_types(program, source)?;
    let semantic_model = semantic::analyze_program(program);
    borrowck::check_program(program, &semantic_model)?;

    let mut warnings = Vec::new();
    let all_warnings = warnings::check_warnings(program);
    for w in all_warnings {
        if filter.matches(w.code) {
            warnings.push(w);
        }
    }

    Ok((semantic_model, warnings))
}
```

### 6.3 Warning emission

Warnings are emitted via stderr after successful compilation:

```rust
fn emit_warnings(warnings: &[Diagnostic]) {
    for w in warnings {
        eprintln!("{}", format_diagnostic(w));
    }
}
```

---

## 7. CLI Integration

### 7.1 `mire check` command

```
mire check [file] [options]

Performs full analysis (lexer → parser → typeck → borrow → all warnings).
Does NOT generate binary or IR.

Options:
  -W <code|category>       Enable specific warning(s)
  --deny <code|category>   Treat warning as error
  --warn-all               Enable all warnings

Exit codes:
  0  Analysis passed (warnings OK)
  1  Errors found
```

### 7.2 `mire run` / `mire build` warning behavior

- Default: only W0001–W0005 emitted
- `--warn-all`: all warnings
- `-W W0010`: default + deprecated warnings
- `--deny W0001`: treat unused variable warning as error

### 7.3 Flag parsing

```
-W <CODE>        → WarningFilter::Codes({CODE})
-W <CATEGORY>    → WarningFilter::Codes(all codes in category)
--deny <CODE>    → emit diagnostic with Severity::Error instead
--deny <CATEGORY>→ same for whole category
--warn-all       → WarningFilter::All
```

---

## 8. Migration: Old → New Codes

### Errors

| Old ErrorKind | New Code | Notes |
|---------------|----------|-------|
| `Lexer { .. }` — unexpected char | E0001 | |
| `Lexer { .. }` — unterminated | E0002 | |
| `Parser { .. }` — expected | E0003 | |
| `Parser { .. }` — unexpected | E0004 | |
| `Type { .. }` — mismatch | E0005 | |
| `Type { .. }` — unknown identifier | E0006 | |
| `Ownership { UseAfterMove }` | E0007 | |
| `Ownership { MultipleMutableRefs }` | E0008 | |
| `Ownership { MutationWhileShared }` | E0009 | |
| `Ownership { MoveWhileBorrowed }` | E0010 | |
| `Ownership { DropWhileBorrowed }` | E0011 | |
| `Ownership { DoubleDrop }` | E0012 | |
| `Ownership { BorrowOutOfScope }` | E0013 | |
| `Backend { .. }` | E0014 | |
| `Runtime { .. }` | E0015 | |

### Warnings

| Old Code | Old Description | New Code | Notes |
|----------|----------------|----------|-------|
| W001 | Suspicious import | W0003 | |
| W002 | Unused variable | W0001 | |
| W003 | Implicit type | W0004 | |
| W004 | Unused function | W0002 | |
| W005 | Implicit return type | W0005 | |
| W006 | Useless literal expression | W0023 | |
| W007 | && always false | — | Removed |
| W008 | \|\| always true | — | Removed |
| W009 | Condition always false | W0015 | Merged |
| W010 | Empty function body | W0006 | |
| W011 | Many parameters | W0012 | |
| W012 | Long function | W0011 | |
| W013 | Empty if branches | W0014 | |
| W014 | Long variable name | — | Removed |
| W015 | Unnecessary clone | W0027 | |
| W016 | Use dasu() instead | — | Removed |
| W017 | Call to undefined fn | W0020 | |
| W018 | Deref unused var | — | Merged into W0001 |
| W019 | Empty list | — | Removed |
| W020 | Empty dict | — | Removed |
| W021 | Negative index | W0021 | |
| W022 | Many closure params | — | Removed |
| W023 | Empty string add (left) | — | Removed |
| W024 | Empty string add (right) | — | Removed |
| W025 | Mul by zero (left) | W0007 | Merged |
| W026 | Mul by zero (right) | W0007 | Merged |
| W027 | Mul by 1 | — | Removed |
| W028 | Div by zero | W0008 | |
| W029 | Div by 1 | — | Removed |
| W030 | Mod by zero | W0009 | |
| W031 | Mod by 1 | — | Removed |
| W032 | Condition always true | W0015 | Merged |
| W033 | Infinite loop | W0016 | |
| W034 | Unreachable loop body | W0017 | |
| W035 | Nested loops (depth > 3) | W0018 | Merged |
| W036 | Very deep nesting | W0018 | Merged |
| W037 | Empty loop body | W0013 | |
| W038 | Return literal int | — | Removed |
| W039 | Return literal string | — | Removed |
| W040 | Very long string | W0024 | |
| W041 | Empty string | — | Removed |
| W042 | Magic number 0/1 | W0026 | |
| W043 | Float literal | — | Removed |
| W044 | Bool literal | — | Removed |
| W045 | Char literal | — | Removed |
| W046 | None literal | — | Removed |
| W047 | Large list | W0025 | |
| W048 | Large dict | W0025 | Merged |
| W049 | Large tuple | W0025 | Merged |
| W050 | Control chars in string | — | Removed |
| W051 | Negative literal | W0022 | |
| W052 | Break/continue outside loop | W0019 | |

---

## 9. Implementation Order

1. **Phase 1**: Create `diagnostic.rs` + `format.rs` (core types, formatter)
2. **Phase 2**: Refactor `MireError` to wrap `Diagnostic`, migrate codes
3. **Phase 3**: Refactor `compiler/warnings.rs` to emit `Diagnostic`, fix unused tracking
4. **Phase 4**: Integrate warnings into `compiler/mod.rs` pipeline
5. **Phase 5**: Add `mire check` command to `main.rs`
6. **Phase 6**: Add `-W`/`--deny` CLI flags
7. **Phase 7**: Tests

---

## 10. Open Questions

- Should `mire check` also run the LLVM IR generation or stop after analysis? → Stop after analysis.
- Should warnings include a "suggestion" to run `mire check` for more? → Yes, at end of `mire run` output if warnings exist.
- What exit code for `mire run` when there are warnings but no errors? → 0 (warnings don't fail compilation).
