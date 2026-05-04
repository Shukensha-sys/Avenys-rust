# Changelog

All notable changes to Mire are documented in this file.

## [Unreleased]

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
