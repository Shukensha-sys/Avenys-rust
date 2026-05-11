# Changelog

All notable changes to Mire are documented in this file.

## [2.7.0] - 2026-05-11

### Added
- New backend optimization level model (`OptLevel`) with `-O0/-O1/-O2/-O3/-Os/-Oz`.
- New roadmap document: `docs/roadmap.md` consolidating completed compiler work and pending Owl integration.

### Changed
- CLI reduced to four commands only: `run`, `build`, `check`, `debug`.
- Default compilation profile switched to `debug` (`-O0`) for faster feedback.
- Build fingerprint now includes optimization level to guarantee cache correctness.
- LLVM `opt` and `clang` flags are now driven by selected optimization level.
- Version bump: `2.6.0` → `2.7.0`.

## [2.6.0] - 2026-05-11

### Added
- Unified diagnostic system (`src/error/diagnostic.rs`, `src/error/format.rs`):
  - `Diagnostic` struct with `Severity`, `DiagnosticCode` (E0001–E0015, W0001–W0027), `Label`, `Suggestion`.
  - `format_diagnostic()` with source context, colors, labels, notes, help.
  - `WarningFilter` enum (`Default`, `All`, `Codes`).
- New CLI command `mire check <file>` for analysis-only mode without binary generation.
- New CLI flags: `--warn-all`, `-W <Wxxxx>`, `--deny <Wxxxx>`.
- `analyze_program_with_warnings()` in pipeline with `WarningConfig` (filter + deny).
- Warning tests in `tests/warnings/`.
- Integration guide `docs/owl-diagnostics.md` for Owl tooling.

### Changed
- `MireError` refactored to wrap `Diagnostic` (backward-compatible API).
- `MssError` mapped to diagnostic codes E0007–E0013.
- Warnings rewritten to emit `Diagnostic` instead of `Warning` struct.
- Unused variable/function tracking now works (previously silent).
- `BuildOptions` now includes `warning_filter` + `deny_warnings`.
- Docs updated: `docs/cli.md`, `docs/diagnostic-system.md`, `MORE/0004-diagnostic-system.md`.
- Version bump: `2.5.6` → `2.6.0`.

## [2.5.6] - 2026-05-10

### Fixed
- Updated integration test `extern_and_inline_asm_declarations_parse_and_compile` to use assembly templates compatible with real LLVM inline asm emission.

### Changed
- Patch semver bump: `2.5.5` -> `2.5.6`.

## [2.5.5] - 2026-05-10

### Added
- Runtime string helpers in `src/avens/runtime_support.c`:
  - `mire_strings_contains`
  - `mire_strings_substr`
  - `mire_strings_repeat`
  - `mire_strings_pad_left`
  - `mire_strings_pad_right`
  - `mire_list_pop_i64`
- Backend handlers in `src/avens/mod.rs` for:
  - `list.pop`
  - `contains` / `strings.contains`
  - `strings.substr`
  - `strings.pad_left`
  - `strings.pad_right`
  - `strings.repeat`

### Changed
- Hardened string memory operations (`concat`, `append_owned`, `replace`) with overflow guards and safer capacity math.
- `for` lowering now supports list/vector/slice iteration in addition to `range(...)`.
- `match` pointer comparisons now distinguish string vs non-string pointer semantics:
  - strings -> `strcmp`
  - struct/enum/pointer values -> pointer equality
- Backend now accepts `extern fn` declarations by emitting LLVM `declare` signatures.
- Backend now emits minimal inline `asm` via LLVM `asm sideeffect`.
- Warning set expanded with missing warning codes (`W001`, `W006`, `W010`, `W013`, `W034`, `W036`, `W037`, `W039`, `W043`-`W051`).

### Fixed
- `sqrt(...)` lowering now calls `libm` `sqrt(double)`.
- `Drop` and `Move` statements now lower with concrete backend behavior.

### Added
- Created `std.mire` - Standard Library de Mire con todas las funciones estándar organizadas por categorías:
  - MATH: abs, min, max, sum, clamp, range, round, floor, ceil
  - LISTS: len, push, pop, append, remove, delete, clear, join, contains, index_of, first, last, slice, concat, flatten, reverse, sort, unique, is_empty, map, filter, fold
  - STRINGS: upper, lower, strip, split, replace, contains, startswith, endswith, len, trim, ltrim, rtrim, substr, pad_left, pad_right, repeat, is_empty
  - DICTS: len, keys, values, has, get, set, remove, delete, entries, merge, is_empty
  - TIME: unix_ms, unix_ns, since_ms, since_ns, mark, elapsed, elapsed_ms, elapsed_ns, sleep_ms, sleep_ns
  - TERM: style, hr, clear
  - MEM: used, total, free, available, percent, process, snapshot, format
  - CPU: time_ns, time_ms, mark, elapsed, elapsed_ms, elapsed_ns, count, freq_mhz, cycles_est, loadavg, snapshot
  - GPU: available, snapshot
  - FS: read, write, append, exists, size, copy, move, drop, list, mkdir, rmdir, join, dir, name, ext
  - ENV: get, set, all, args, cwd, chdir
  - PROC: run, spawn, pipe, shell, read, write, on, exit, err, exec, exec_bg, kill, wait, exists

### Changed
- Repository hygiene improvements: standard `.gitignore` added to prevent committing build artifacts (`target/`, `bin/*`, `benchmarks/build/`).
- Removed tracked generated artifacts from git index (`target/`, `benchmarks/build/`, `bin/debug`, `bin/release`) to keep repository lean.
- Syntax documentation standardized into a single canonical file: `SYNTAX.md`.
- `README.md` rewritten for current project status and clearer onboarding.
- Incremental cache format updated to `v5` to reduce in-memory and on-disk metadata duplication.
- Incremental cache blob store now auto-compacts when sparse to avoid unbounded growth under frequent invalidations.
- `stable_statement_hash` now hashes in streaming mode (no intermediate JSON `Vec<u8>` allocation).
- Type checker source context no longer relies on thread-local state; diagnostics now use explicit checker context.

### Fixed
- Backend lowering coverage expanded in Avenys (`src/avens/mod.rs`):
  - Frontend-only statements now handled explicitly as no-op in codegen instead of generic backend failure (`Type`, `Skill`, `Code`, `Class`, `Trait`, `Impl`, `Enum`, `AddLib`, `Module`, `Dmire*`, `Query`, `Find`, `Drop`, `Move`).
  - Added lowering for literal compound forms in `compile_expr`: `Literal::List`, `Literal::Dict`, `Literal::Tuple`.
  - Added qualified string builtin wiring: `strings.contains`, `strings.concat`, `strings.len`, `strings.strip`, `strings.ltrim`, `strings.rtrim`, `strings.is_empty`.
  - Improved unknown function diagnostics from "does not yet lower call" to explicit "unknown function".
  - Expanded `map_type` support for previously unmapped frontend types (`Function`, `Db`, `Datetime`, `Box`, `DynTrait`, `Result`) by mapping to pointer backend representation.
  - Expanded runtime kind classification for struct/enum/function/result families.
- Removed unused constant in incremental cache module (`src/incremental.rs`) to keep warnings clean.
- Simplified enum top-level scan patterns in parser (`src/parser/mod.rs`) by collapsing nested match/if branches without behavior changes.
- Reduced unnecessary `Program` cloning in loader parse/cache path (`src/loader.rs`).
- Added borrow-check regression coverage for impl-method local-reference escapes.
- Lexer token column tracking now preserves start-column for compound operators, improving diagnostic accuracy.
- Runtime CPU MHz cache is now thread-safe via C11 atomics.
- Parser and closure-lowering paths now propagate numeric/closure compilation errors instead of silently defaulting to zero values.
- Avenys numeric lowering now emits real floating-point arithmetic/comparison (`fadd/fsub/fmul/fdiv/frem/fcmp`) when operands are float-typed.
- Type checking now preserves nested vector element types across assignability checks and rejects incompatible inner element pushes (for example `vec[vec[i64]]` + `vec[str]`).
- `for item, index in range(...)` is now fully supported end-to-end (parser/AST/scopes/type-checking/backend lowering).
- Lexer/parser now support prefixed integer literals (`0b`, `0o`, `0x`) and normalize them safely to integer values.
- Raw string literals with hash delimiters are now supported (`r"..."`, `r#"..."#`, `r##"..."##`).
- Added `char` type and character literals; chars are represented as Unicode scalar values (`u32`) in the type system.
- Added frontend support for `unsafe { ... }` blocks (lexer/parser + semantic/type/borrow integration) and backend lowering by compiling contained statements.
- Added frontend support for `extern lib ...` and `extern fn ... lib ...` declarations, including FFI pointer-shape parsing (`*const/*mut`) as scalar `i64` in the current type model.
- Added frontend support for `asm { ... }` blocks and AST preservation; current Avenys backend accepts them as no-op (no target-specific IR emission yet).
- Extended Unicode case conversion: `to_upper`/`to_lower` now handle full Latin-1 supplement range (0xC0-0xFF).
- Fixed memory leak in dict format: nested map values now properly copied instead of returning managed pointer directly.
- Reference mutability semantics: `&x` now infers mutability from original binding (`mut` → mutable ref, otherwise shared), explicit `&mut x` rejected for immutable bindings.

## [2.2.0]

### Added
- Incremental compilation cache improvements (binary cache container, LRU pruning, partial analysis reuse).
- Broader support across structs, enums, methods, collections, and diagnostics.

### Changed
- Avenys backend is the active compiled path.
- Significant maturity improvements in type checking and ownership checking.

## [2.0.0]

### Changed
- Breaking syntax update from v1.x.
- Explicit `self` required for instance methods.
- Associated/static methods use `Type::method(...)`.
- Enum vs impl path behavior clarified.

## [1.0.3]

### Added
- Struct support and method dispatch improvements.
- Field access and enum payload matching fixes.

## [1.0.0]

### Added
- First stable syntax family and compiler baseline.
