# Owl + Diagnostic System Integration Guide

Since v2.6.0, the Mire compiler (Avenys) has a unified diagnostic system with structured error/warning codes. Owl, being a Mire application, interacts with the compiler through CLI commands and can leverage this system for better error reporting and analysis.

## 1. Compiler Flags Available to Owl

Owl's `cmd_build()`, `cmd_run()`, and `cmd_test()` invoke `mire build`/`mire run` under the hood. These now support:

| Flag | Effect | When Owl should use it |
|------|--------|----------------------|
| `--warn-all` | Enable all warnings | `owl build --check` or `owl test --strict` |
| `-W Wxxxx` | Enable specific warning | `owl build -W W0010` for deprecation checks |
| `--deny Wxxxx` | Treat warning as error | CI/pipeline mode for strict enforcement |
| `mire check <file>` | Analyze without binary output | Pre-build validation step |

## 2. Suggested Integrations

### 2.1 Pre-build validation in `cmd_build()`

Before compiling, run `mire check` to catch warnings early:

```mire
fn cmd_build: () {
    set entry = get_entry_point()
    set check_result = proc_run("mire check " + entry)
    if check_result.status != 0 {
        # Only fail if there are actual errors
        if strings.contains(check_result.stderr, "error[") {
            proc_exit(1)
        }
    }
    # Proceed with actual build
    set build_result = proc_run("mire build " + entry)
    ...
}
```

### 2.2 Warning-aware test runner

`cmd_test()` can use `--deny` to promote warnings to errors in strict mode:

```mire
fn cmd_test: (filter :str strict :bool) {
    set entry = get_test_entry()
    set flags = ""
    if strict {
        flags = flags + " --deny W0001 --deny W0002 --deny W0003"
    }
    set result = proc_run("mire build " + entry + flags)
    ...
}
```

### 2.3 Parsing diagnostics from compiler output

The compiler outputs structured diagnostics in this format:

```
warning[W0001] ── Unused Variable
╭─[ main.mire:3:9 ]
```

Owl can parse this for reporting:

```mire
fn count_warnings: (output :str) :i64 {
    set lines = strings.split(output, "\n")
    set count = 0 :i64
    for line in lines {
        if strings.starts_with(line, "warning[") {
            set count = count + 1
        }
    }
    return count
}

fn count_errors: (output :str) :i64 {
    set lines = strings.split(output, "\n")
    set count = 0 :i64
    for line in lines {
        if strings.starts_with(line, "error[") {
            set count = count + 1
        }
    }
    return count
}
```

## 3. Recommended Workflow

```
owl build
  │
  ├── 1. owl check --warn-all    (optional: pre-check with all warnings)
  ├── 2. mire check <entry>      (compiler analysis, no binary)
  ├── 3. Parse diagnostics        (count warnings/errors)
  ├── 4. If errors → abort
  ├── 5. If warnings → report
  └── 6. mire build <entry>      (actual compilation)
```

## 4. Warning Codes Reference for Owl

Owl can reference these codes in its own messages:

| Code | Description | Relevance to Owl |
|------|-------------|-----------------|
| W0001 | Unused variable | Detect dead code in owl.toml builds |
| W0002 | Unused function | Detect unused helpers |
| W0010 | Deprecated syntax | Flag owl.toml using old syntax |
| W0020 | Call to undefined function | Detect missing imports in build scripts |

## 5. Future: Direct Library Integration

When the compiler exposes a library API (beyond CLI), Owl could call `analyze_program_with_warnings()` directly from Rust FFI instead of shelling out to `mire check`.
