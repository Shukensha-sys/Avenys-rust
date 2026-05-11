# MORE-4: Unified Diagnostic System

- **Status:** Implemented (v2.6.0)
- **Commits:** `383bd4f` (checkpoint before), `050f49f` (implementation)
- **Proposed:** May 2026
- **Category:** Compiler Architecture

## Summary

Replace the current dual error/warning system (`MireError` + `Warning`) with a unified `Diagnostic` framework where both errors and warnings share the same data structures, formatting pipeline, and unique diagnostic codes.

## Motivation

The compiler has two parallel systems that don't interoperate:

1. **Errors** (`src/error/mod.rs`): `MireError` + `ErrorKind` enum + heuristic `generate_explanation()` — decent formatting with source context, but error codes are generic category strings (`"lexer"`, `"parser"`) rather than unique identifiers.
2. **Warnings** (`src/compiler/warnings.rs`): `Warning` struct with 52 defined codes (W001–W052) — but `Warnings::analyze()` is **never called** from the compilation pipeline. All warnings are dead code.

This causes several problems:
- Unused variable/function warnings are silent even though the analysis exists.
- Warning output is a single line with no source context, no line/column.
- No CLI control to enable/disable/deny specific warnings.
- Error messages are inconsistent and not searchable.
- No way to suggest fixes.

## Design

### Core Types

```rust
pub enum Severity { Error, Warning, Note, Help }

pub struct Diagnostic {
    pub severity: Severity,
    pub code: DiagnosticCode,   // E0001, W0001, etc.
    pub message: String,
    pub line: usize,
    pub column: usize,
    pub labels: Vec<Label>,     // multiple spans per diagnostic
    pub notes: Vec<String>,
    pub help: Option<String>,
    pub suggestions: Vec<Suggestion>,
    pub source: Option<String>,
    pub filename: Option<String>,
}
```

### Diagnostic Codes

**Errors (E0001–E0015):**

| Code | Category | Description |
|------|----------|-------------|
| E0001 | Lexer | Unexpected character |
| E0002 | Lexer | Unterminated string/comment |
| E0003 | Parser | Expected token not found |
| E0004 | Parser | Unexpected token |
| E0005 | Type | Type mismatch |
| E0006 | Type | Unknown identifier |
| E0007 | Borrow | Use after move |
| E0008 | Borrow | Multiple mutable references |
| E0009 | Borrow | Mutation while shared |
| E0010 | Borrow | Move while borrowed |
| E0011 | Borrow | Drop while borrowed |
| E0012 | Borrow | Double drop |
| E0013 | Borrow | Borrow out of scope |
| E0014 | Backend | Construct not yet lowered |
| E0015 | Runtime | General error |

**Warnings (W0001–W0027):**

| Code | Category | Description |
|------|----------|-------------|
| W0001 | Unused | Unused variable |
| W0002 | Unused | Unused function |
| W0003 | Unused | Unused import |
| W0004 | Type | Implicit type annotation |
| W0005 | Type | Implicit return type |
| W0006 | Style | Empty function body |
| W0007 | Performance | Multiplication by zero |
| W0008 | Performance | Division by zero |
| W0009 | Performance | Modulo by zero |
| W0010 | Deprecated | Deprecated syntax |
| W0011 | Complexity | Overly long function |
| W0012 | Style | Too many parameters |
| W0013 | Style | Empty loop body |
| W0014 | Style | Empty if branches |
| W0015 | Logic | Condition always true/false |
| W0016 | Logic | Infinite loop |
| W0017 | Logic | Unreachable loop body |
| W0018 | Complexity | Deeply nested loops |
| W0019 | Logic | Break/continue outside loop |
| W0020 | Type | Call to undefined function |
| W0021 | Type | Negative index access |
| W0022 | Style | Negative literal used directly |
| W0023 | Style | Useless literal expression |
| W0024 | Style | Very long string literal |
| W0025 | Memory | Large list/dict/tuple literal |
| W0026 | Style | Magic number 0 or 1 |
| W0027 | Performance | Unnecessary clone call |

### WarningFilter

Controls which warnings are emitted per command:

```rust
pub enum WarningFilter {
    Default,  // W0001–W0005 only (for mire run/build)
    All,      // W0001–W0027 (for mire check)
    Codes(HashSet<DiagnosticCode>),
}
```

### Pipeline

```
mire run/build  → WarningFilter::Default → unused + implicit type warnings only
mire check      → WarningFilter::All      → all warnings + full analysis
-W <code>       → WarningFilter::Codes({code})
--deny <code>   → Diagnostic severity promoted to Error
```

### Output Format

```
warning[W0001] ── Unused Variable
╭─[ main.mire:3:9 ]
│ 1 │ pub fn main: () {
│ 2 │     set hi = "hola" :char
│ 3 │     set bye = "adios" :char
│   │         ^^^
│ 4 │
│ 5 │     use dasu(hi)
╰─ Variable 'bye' is never used
   ─┬─ note: prefix with `_` to suppress this warning

error[E0005] ── Type Mismatch
╭─[ main.mire:5:12 ]
│ 4 │     set x = 42 :int
│ 5 │     set y = "hello" :char
│   │             ^^^^^^^ expected `char`, found `str`
│ 6 │     use dasu(x)
╰─ Cannot assign `str` to variable of type `char`
   ─┬─ help: try converting with `.to_char()` or change the annotation
```

## Implementation Plan

### Phase 1: Core Types

Create `src/error/diagnostic.rs` with `Diagnostic`, `Severity`, `DiagnosticCode`, `Label`, `Suggestion`, `WarningFilter`. Create `src/error/format.rs` with `format_diagnostic()` providing rich source-context output.

### Phase 2: Refactor MireError

Wrap `MireError` around `Diagnostic` with `Severity::Error`. Migrate `ErrorKind` variants to `DiagnosticCode` enums. Replace `generate_explanation()` with per-code messages. Migrate `MssError` ownership variants.

### Phase 3: Refactor Warnings

Replace `Warning` struct with `Diagnostic`. Fix variable/function tracking so unused detection works. Propagate real `line`/`column` from AST. Remove noisy warnings (W044–W046).

### Phase 4: Pipeline Integration

Wire `check_warnings()` into `analyze_program()`. Respect `WarningFilter`. Print warnings to stderr without stopping compilation.

### Phase 5: mire check Command

New subcommand that runs full analysis with all warnings and exits without generating a binary.

### Phase 6: CLI Flags

Add `-W <code>`, `--deny <code>`, `--warn-all` to `main.rs`.

### Phase 7: Tests

Verify unused variable warning, `_` prefix suppression, `-W` / `--deny` flags, formatter output.

## Migration

Old warning codes W001–W052 are consolidated into W0001–W0027. Noisy/trivial warnings (empty list/dict, single char/bool/none literals, short-circuit hints) are removed entirely. See `docs/diagnostic-system.md` for the full mapping table.

## Unresolved Questions

- Should `mire check` require a file or run on the project entry by default?
- Should warnings include a summary line at the end (e.g. "2 warnings emitted")?
