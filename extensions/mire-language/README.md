# Mire Language Extension

Advanced language support for Mire and Owl projects.

## Highlights

- Rich syntax highlighting (keywords, types, builtins, numbers, raw strings, operators).
- Semantic token coloring for functions/types/operators/comments/strings.
- Smart completions:
  - language keywords/snippets,
  - std modules (`strings`, `lists`, `dicts`, `time`, `fs`, `env`, `proc`),
  - builtin functions (`dasu`, `ireru`, `range`, `len`, etc.).
- Early diagnostics in editor:
  - unclosed/unmatched brackets,
  - incomplete assignments,
  - incomplete `import`,
  - probable malformed `fn` signatures.
- Optional compiler-backed diagnostics via `mire check`.
- Owl project integration:
  - auto-detects `owl.toml`,
  - enables `Owl: Run Project` and `Owl: Build Project` commands.

## Commands

- `Mire: Run File`
- `Mire: Check File`
- `Mire: Build Project`
- `Owl: Run Project` (only in Owl workspace)
- `Owl: Build Project` (only in Owl workspace)

## Settings

- `mire.runtimePath` (default: `mire`)
- `mire.owlPath` (default: `owl`)
- `mire.enableDiagnostics` (default: `true`)
- `mire.useCompilerCheck` (default: `false`)
- `mire.autoRun` (default: `false`)

## Build

```bash
cd extensions/mire-language
npm install
npm run compile
```
