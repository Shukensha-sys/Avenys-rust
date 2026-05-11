# Mire

Mire is a compiled, statically typed programming language with ownership-oriented memory safety checks and an LLVM-based backend.

Current compiler crate version: `2.7.0`.

## Status

- Active backend: Avenys
- Compiler pipeline: lexer, parser, type checker, semantic analysis, borrow checker, LLVM lowering
- Incremental compilation: enabled (cache, reuse, LRU pruning)
- Optimization profiles: `debug/release` + `-O0/-O1/-O2/-O3/-Os/-Oz`
- Public CLI surface: `run`, `build`, `check`, `debug`

## Quick Start

```bash
cargo build
cargo test
```

## CLI

```bash
mire run [file] [options] [-- args]
mire build [file] [options]
mire check [file] [options]
mire debug [file] [options]
```

Default profile is `debug` (`-O0`).

## Documentation

- Language syntax (canonical): [SYNTAX.md](./SYNTAX.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)
- CLI and technical docs: `docs/`
