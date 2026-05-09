# Mire Language Extension

Complete language support for [Mire](https://github.com/anomalyco/mire) - a compiled, statically typed programming language with ownership-oriented memory safety checks and an LLVM-based backend.

## Features

### Syntax Highlighting
- Complete keyword highlighting (`fn`, `struct`, `enum`, `impl`, `skill`, `match`, etc.)
- Type highlighting (primitive types, collection types, custom types)
- String interpolation support (`{variable}`)
- Numeric literals (binary, octal, hex, float)
- Character literals
- Operators (arithmetic, comparison, logical, bitwise, pipe)
- Comments (line and block)

### Autocompletion
- Keywords
- Types (primitives and collections)
- Built-in functions (`dasu`, `ireru`, `type`, `range`)
- Standard library modules and functions:
  - `math`: abs, min, max, sum, range, clamp
  - `strings`: upper, lower, split, replace, contains
  - `lists`: len, push, pop, map, filter, fold
  - `dicts`: len, keys, values, get, set, has
  - `time`: mark, elapsed_ms, sleep_ms
  - `fs`: read, write, exists, list
  - `env`: get, set, args, cwd
  - `proc`: run, spawn, shell

### Snippets
- `main` - Main function
- `fn` - Function declaration
- `pubfn` - Public function
- `struct` - Struct declaration
- `enum` / `enump` - Enum declaration
- `impl` / `implm` - Implementation block
- `skill` - Skill (trait) declaration
- `match` - Match expression
- `if` / `ifelif` - If-else
- `while` - While loop
- `for` / `fori` - For loop
- `do` - Do-while
- `vec` / `map` / `arr` - Collections
- And more...

### Hover Information
- Keywords documentation
- Type documentation
- Built-in function documentation
- Standard library function documentation

### Go to Definition
- Find function definitions
- Find struct definitions
- Find enum definitions
- Find impl blocks
- Find skill definitions

### Document Symbols
- List all symbols in the document
- Navigate to definition

### Code Actions
- Quick fix suggestions

### Run Mire Files
- Execute `.mire` files directly from the editor
- Keyboard shortcut: `F5` or `Ctrl+Shift+P` > "Mire: Run File"

### Build Project
- Build Mire project using cargo
- Keyboard shortcut: `Ctrl+Shift+B` or `Ctrl+Shift+P` > "Mire: Build Project"

## Installation

### From Source

```bash
cd extensions/mire-language
npm install
npm run compile
```

### From VSIX (Visual Studio Code / VSCodium)

1. Open VSCode/VSCodium
2. Go to Extensions
3. Click "..." menu > "Install from VSIX..."
4. Select the `mire-language-*.vsix` file

## Configuration

### Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `mire.runtimePath` | string | `mire` | Path to Mire runtime binary |
| `mire.launchArgs` | string[] | `[]` | Additional arguments to pass |
| `mire.autoRun` | boolean | `false` | Automatically run .mire files on save |

### Example Configuration

```json
{
  "mire.runtimePath": "/path/to/mire",
  "mire.launchArgs": ["-O2"],
  "mire.autoRun": true
}
```

## Usage

### Running a Mire File

1. Open a `.mire` file
2. Press `F5` or `Ctrl+Shift+P` > "Mire: Run File"
3. Output appears in terminal panel

### Using Autocompletion

1. Start typing (e.g., `fn`, `stru`, `lists.`)
2. Suggestions appear automatically
3. Press `Tab` or `Enter` to accept

### Viewing Hover

1. Hover over any keyword, type, or function
2. Documentation appears in tooltip

### Go to Definition

1. Right-click on a symbol
2. Select "Go to Definition"
3. Or press `F12` on the symbol

## Language Server

This extension includes basic language features. For advanced features (full language server), see the [Mire LSP](https://github.com/anomalyco/mire-lsp) project.

## Contributing

Contributions are welcome! Please see the [Mire Contributing Guide](https://github.com/anomalyco/mire/blob/main/CONTRIBUTING.md).

## License

GPL-3.0-or-later - See [LICENSE](LICENSE) for details.

---

**Mire** - A compiled, statically typed programming language with ownership-oriented memory safety.