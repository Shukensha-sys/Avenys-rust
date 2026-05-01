# Mire

Mire is a compiled, statically typed programming language with ownership-oriented memory safety checks and an LLVM-based backend.

## Status

- Active backend: Avenys
- Compiler pipeline: lexer, parser, type checker, semantic analysis, borrow checker, LLVM lowering
- Incremental compilation: enabled (cache, reuse, LRU pruning)
- Incremental cache format: `v5` (reduced duplicated metadata in file index)
- Test suite: passing (`cargo test`)

## Performance Notes

- Incremental cache index now avoids duplicating `exports` and `local_imports` metadata already present in blob payloads.
- Loader hot path reduces unnecessary `Program` cloning during parse+cache flow.
- Parser top-level nominal scan path uses fewer transient allocations when collecting enum/type names.
- Build artifacts are no longer tracked in git, improving repository operations and reducing CI/worktree overhead.

## Quick Start

### Build

```bash
cargo build
```

### Run tests

```bash
cargo test
```

### Run lints

```bash
cargo clippy
```

## Documentation

- Language syntax (canonical): [SYNTAX.md](./SYNTAX.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)
- CLI and technical docs: `docs/`

Legacy syntax snapshot remains available at `syntax-V2.0.0.md`, but `SYNTAX.md` is now the single maintained reference.

## Project Layout

- `src/` compiler and runtime integration
- `apps/` executable Mire examples
- `tests/` language tests and regressions
- `benchmarks/` benchmark workloads and comparisons
- `docs/` technical and roadmap documents

## Build Artifacts

Generated build outputs are ignored by default (`target/`, `bin/*`, `benchmarks/build/*`).

## License

GPL-3.0-or-later
