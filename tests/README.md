# Mire Test Suite

This directory contains organized tests for the Mire compiler.

## Structure

```
tests/
├── level/
│   ├── beginner/      # Basic syntax and features
│   ├── intermediate/  # Functions, collections, loops
│   └── advanced/      # Structs, enums, impl
├── type/
│   ├── structs/       # Struct tests
│   ├── enums/         # Enum tests
│   ├── collections/   # Vector, array, map tests
│   └── primitives/    # Basic types
├── behavior/
│   ├── typeck/        # Type checking behavior
│   └── borrowck/      # Ownership/borrow checking
└── verify/
    └── expected/       # Expected output verification
```

## Running Tests

Use the Mire CLI to run tests:

```bash
# Run a single test
mire run tests/level/beginner/01_hello_world.mire

# Run all tests in a directory
for f in tests/level/beginner/*.mire; do mire run "$f"; done
```

## Test Status

| Category | Files | Status |
|----------|-------|--------|
| beginner | 5 | ✅ Passing |
| intermediate | 5 | ✅ Passing |
| advanced | 2 | ✅ Passing |
| type/structs | 2 | ✅ Passing |
| type/enums | 2 | ✅ Passing |
| type/collections | 2 | ✅ Passing |
| type/primitives | 1 | ✅ Passing |
| behavior/typeck | 2 | ✅ Passing |
| behavior/borrowck | 3 | ⚠️ Partial |

## Known Issues

See `docs/issues.md` for documented issues and limitations.