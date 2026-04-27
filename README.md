# Mire

**Version 2.0.0**

Mire is a compiled, statically typed programming language with an ownership-oriented memory model. Version 2.0.0 is a deliberate syntax break over v1.x focused on making `impl` behavior explicit and predictable.

---

## What this version provides

This section is intentionally honest. V2.0.0 is a working compiler with a real type checker, a real ownership checker, and a real standard library surface, but not every construct in the syntax reference is equally mature. The distinction matters.

## Current Status

Avenys is the active compiled backend for Mire. The current state is:

If you want the practical version: today the compiler is usable for real experiments, small apps, algorithms, structs/enums, and a fair amount of collection work. It is not at the point where every construct in the syntax reference has identical maturity, so it is better to read the supported surface as "working and tested" versus "accepted but still growing".

- Compiled-only toolchain: the old interpreter path is gone from the CLI
- Real frontend pipeline: lexer, parser, type checker, semantic model, ownership/borrow checker, LLVM lowering
- Incremental compilation active: binary cache, lazy loading, LRU, cached analysis successes and failures
- Test baseline: `58` lib tests + regression tests all passing
- Best-supported areas today: functions, control flow, enums, structs, impl methods, imports, runtime diagnostics, incremental builds

### What Avenys supports well right now

- Typed functions with return inference and hard mismatch errors
- Ownership/MSS checks for moves, borrows, mutable/shared aliasing, drop safety, and returning local refs
- Structs and nominal types through parse, type checking, and lowering
- Enums with qualified variants and payload matching in statements
- Array reads and in-place indexed writes with `arr at i` / `set arr at i = value`, including indexed writes on struct fields
- Shared references and dereference lowering, including typed params such as `value :&i64`
- List high-order functions with inline closures: `lists.fold`, `lists.map`, `lists.filter`
- Associated/static methods via `Type::method(...)`
- Instance methods with explicit `self`
- Direct mutable field updates inside `impl`, for example `set self.value = self.value + 1`
- Standard runtime modules already wired into type checking and lowering paths used by the shipped apps/tests
- Incremental build reuse for unchanged programs and unchanged local-import dependency graphs

### What is still partial

- Match expressions are improving, but exhaustive enum-return expressions without an explicit fallback still need more work
- Traits/skills only cover direct conformance today
- Field-level validation during struct/type construction is still incomplete
- Struct fields marked `mut` now parse correctly and direct `self.field = ...` updates in `impl` are working, but field-level mutability validation itself is still not fully enforced everywhere
- List HOF are currently closure-based at the call site; they are not yet exposed as generic first-class callback slots for named functions/values
- `extern`, `unsafe`, `asm`, and `module` are parsed and walked, but not deeply validated end-to-end

### v2.0.0 New Features

- **Struct full support**: struct declaration, constructor with named fields `(Type field: value, ...)`, and field access `object.field`
- **Explicit instance methods**: methods that use `self` must declare it explicitly as `(self)`
- **Associated/static methods**: `Type::method(...)` is now supported and documented as the canonical syntax
- **Enum named payload fields**: enum variants support named field construction like `Status.Loading(progress: 75)` using the same `field: value` style as struct constructors
- Enum with multiple payload variants in match patterns
- Improved type resolution for struct field access

### What the compiler fully checks and enforces

**Type checking** (`typeck.rs`)

- Type inference for variable declarations: `set x = 10` infers `i64` without an annotation
- Type inference across binary expressions: arithmetic, comparison, and logical operators all resolve correctly
- Function return type inference and return type mismatch detection
- Assignment type mismatch errors: assigning `str` to an `i64` binding is a hard error
- Undefined identifier errors at the use site
- Enum-qualified variant construction such as `Result.Ok(42)` or `Pair.Pair(10 20)` resolves and is type-checked against the declared payload types
- `match` arm type consistency: all arm patterns must be compatible with the matched value's type
- Identifier patterns in `match` are treated as comparison-side patterns and are not rejected as undefined bindings during type analysis
- Enum payload bindings introduced by `match` patterns are scoped and available inside statement bodies and match expressions, including variants with multiple payload values
- `match` accepts full comparison/logical expressions as the matched value, for example `match x < 5 :bool { ... }`
- Loop variable type inference: `for i in range(10)` gives `i` type `i64`; iterating over a typed array or vector infers the element type
- `if` and `while` conditions are checked to be bool-like; a condition of type `i64` is an error
- Function call return type propagation: calling a known function resolves the call expression's type
- All standard library modules (`math`, `strings`, `lists`, `dicts`, `time`, `term`, `mem`, `cpu`, `gpu`, `fs`, `env`, `proc`) are registered with known member return types
- Builtin functions (`dasu`, `ireru`, `len`, `range`, `str`, `int`, `float`, `bool`, etc.) have registered return types and are accepted without errors

**Ownership and borrow checking** (`borrowck.rs` / MSS)

- Use-after-move detection: using a binding after it has been explicitly moved is a hard error
- Move-while-borrowed: moving a value that currently has an active borrow is rejected
- Shared borrow exclusivity: taking a mutable reference while a shared borrow is active is rejected
- Multiple mutable references: a second `&mut` to the same binding is rejected
- Mutation-while-shared: writing to a binding that has active shared borrows is rejected
- Drop-while-borrowed: explicitly dropping a borrowed binding is rejected
- Borrow lifetime: borrows are automatically released when their scope ends; post-scope writes to the original owner are permitted
- Return-of-local-reference: returning a reference to a locally scoped binding is a hard error ("borrow outlives owner scope")
- Call argument checking: passing a shared reference to a function that expects a mutable reference is rejected
- Move semantics by type: `str` and non-primitive types consume the binding on pass-by-value; numeric primitives (`i64`, `f32`, etc.) are copy-like and do not
- `unsafe` blocks bypass borrow conflict checks explicitly, as documented

**Semantic analysis** (`semantic.rs`)

- Scope tree construction: every block creates a child scope with a stable ID
- Binding registration with scope depth and kind (`Value`, `SharedRef`, `MutableRef`, `Boxed`, `Parameter`)
- Function signature collection with param types and return types
- Borrow fact recording for all `&` and `&mut` expressions
- Move fact and drop fact recording

**Compiler infrastructure**

- Incremental compilation: cache now uses a binary container at `bin/.cache/incremental.bin`, with metadata indexed in memory and payloads read via `mmap` when the cache is opened read-only
- Incremental cache supports LRU pruning via `[cache].max_units` in `project.toml` and CLI overrides such as `--cache-max-units` / `--no-analysis-cache`
- Analysis failures are cached too, so identical invalid programs do not recompute the same type/ownership failure on every build
- Incremental analysis now persists metadata for top-level units and direct nested members in `Type`, `Class`, `Code`, and `Impl`
- Partial analysis reuse is driven by a shared `AnalysisSelection`, so type checking and borrow checking consume the same unit-selection contract
- Cache payloads stay memory-mapped until a write is needed; on mutation the blob store is promoted to owned memory and then persisted back to disk
- IR kept in RAM for run/build operations; written to disk only for debug mode
- Recursive test discovery: `mire test` recursively finds `.mire` files, excluding negative/fixture suites (`tests/error/`, `tests/broken_mire/`, `tests/test_proyet_mire_cli/`)
- Error diagnostics include line, column, and caret markers (^^^) at error location

### Incremental cache configuration

`project.toml` can define cache behavior without changing language syntax:

```toml
[cache]
max_units = 256
analysis_cache = true
compression = false
```

Current behavior:

- `max_units` limits cached parsed/analyzed units with LRU eviction; `0` means unlimited
- `analysis_cache` reuses successful semantic analysis results when the dependency fingerprint is unchanged
- Failed analysis results are cached too for identical inputs
- The cache now reuses unchanged top-level functions and direct nested members inside `Type`, `Class`, `Code`, and `Impl`
- `compression` is reserved as an opt-in flag; the binary container is ready for it, but payload compression is not enabled yet

---

## Syntax

For the complete language syntax reference, see [syntax-V2.0.0.md](./syntax-V2.0.0.md).

---

## What exists in the parser but is not fully guaranteed

The following constructs parse without errors but the compiler does not currently apply deep type or ownership analysis to them. They may work in practice depending on what you write, but they are not guaranteed:

- **`struct` and `type` construction** — object creation (`User(name="Evelyn" age=20)`) is parsed, and type signatures are collected by the type checker, but field-level type checking during construction is not enforced
- **`impl` and method calls** — instance methods require explicit `self` as the first parameter; associated/static methods use `Type::method(...)`; nominal structs/enums now preserve their concrete identity through parsing, type checking, and lowering
- **Pipelines (`=>`)** — inline closure stages are lowered and tested, but the broader pipeline surface is still less mature than direct calls and standard control flow
- **`trait` and `skill` declarations** — registered in the type checker's scope and checked for direct conformance, but deeper trait semantics are still incomplete
- **`if` as an expression** — parsed and desugared via `__if_expr` builtin; branch result types are now unified during type checking and lowered using the resolved type
- **`extern lib` and `extern fn`** — parsed, walked past in both checkers without analysis
- **`unsafe`, `asm`, `module`** — scopes are created and walked, but the content is not semantically validated beyond what falls inside the normal expression checker

---

## Project structure

```
src/
  avens/
    mod.rs
    runtime_sup.rs
  compiler/
    borrowck.rs     — ownership and borrow checker
    mod.rs
    semantic.rs     — scope and binding model
    typeck.rs       — type inference and type checking
  error/
    mod.rs
    mss.rs          — MSS (Memory Safety System) error types
  lexer/
    mod.rs
  parser/
    ast.rs
    lib.rs
    loader.rs
    main.rs
```

Build artifacts:

- `mire debug` writes binaries and LLVM IR to `bin/debug/`
- `mire run` and `mire build` write only the binary to `bin/release/` by default
- Outside a project, outputs fall back to `debug/` or `release/` next to the source
- Incremental compiler metadata is stored under `bin/.cache/`
- LLVM IR is written to disk only by `mire debug`; normal run/build flows keep IR in memory

---

## Migration from v1.x Mire

V2.0.0 is a hard break over v1.x. The most important source changes are:

- Instance methods must declare `self` explicitly: `fn greet: (self)`, not `fn greet: ()`
- Associated/static methods now use `Type::method(...)` as the canonical call syntax
- Enum variants continue to use `Enum.Variant(...)`, so enums and associated methods are no longer ambiguous
- The `name :Type` style remains unchanged; Mire does not adopt Rust's `name: Type` surface syntax
- Commas remain optional in many argument and payload positions

---

## Standard library

Modules available via `import`: `math`, `strings`, `lists`, `dicts`, `time`, `term`, `mem`, `cpu`, `gpu`, `fs`, `env`, `proc`.

All members of these modules are registered in the type checker. Return types are known for the majority of members; some return `Anything` where the type is collection-generic or polymorphic.

---

## License

Mire is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

---

## Version

`2.0.0` — explicit `self` for instance methods, `Type::method(...)` for associated/static methods, enum-vs-impl path disambiguation, and stronger `impl` dispatch rules.

`1.0.3` — struct support, instance method dispatch, field access fixes, enum payload matching, and improved diagnostics on top of the v1.0.0 syntax family.

`1.0.0` — first stable syntax release. Compiled from the Avenys 0.x codebase with a full parser rewrite and a rewritten `typeck.rs` following a corruption event during development. The semantic and borrow checking layers are original to this release.
