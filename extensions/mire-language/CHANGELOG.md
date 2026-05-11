# Changelog

## [1.1.0] - 2026-05-11

### Added
- Semantic token provider for richer colorization.
- Real-time diagnostics engine for fast syntax/structure feedback.
- Optional compiler-backed diagnostics (`mire check`) from extension config.
- Owl project auto-detection via `owl.toml`.
- Owl command integration in command palette:
  - `Owl: Run Project`
  - `Owl: Build Project`
- New command:
  - `Mire: Check File`

### Changed
- Syntax grammar expanded significantly (keywords, types, builtins, functions, operators, numeric forms, strings, comments).
- Completion provider upgraded with context-aware suggestions and snippets.
- Extension metadata updated for Owl-aware workflow.

## [1.0.0] - 2026-05-11

- Initial public extension with base syntax support, completions, hover, symbols and run/build commands.
