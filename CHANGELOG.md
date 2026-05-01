# Changelog

All notable changes to Mire are documented in this file.

## [Unreleased]

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
