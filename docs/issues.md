# Mire/Avenys Issues Log

This document tracks bugs, unexpected behaviors, and edge cases found during testing.

---

## Issue #001 - Enum Match Expression Returning Values Without Default Arm

**Date**: 2025-04-18 (Updated 2025-04-19)
**Severity**: Medium
**Component**: Type checking + Backend lowering
**Status**: RESOLVED (verified Apr 2026)

### Description

When using an enum `match` expression that returns values (including `str`) without an explicit fallback/default arm, the compiler previously failed with type unification errors.

### What Was Fixed

The following cases now work correctly:

1. **Enum without payload returning i64** (any variant):
```mire
enum Status { Ok Error }
set m = match r { Status.Ok { 100 } Status.Error { 200 } } :i64
```
✅ Works

2. **Enum without payload returning bool**:
```mire
enum Status { Ok Error }
set m = match r { Status.Ok { true } Status.Error { false } } :bool
```
✅ Works

3. **Enum with payload returning i64**:
```mire
enum Color { Red Green Blue }
set result = match c { Color.Red { 1 } Color.Green { 2 } Color.Blue { 3 } } :i64
```
✅ Works

4. **Enum with payload returning str**:
```mire
enum Result { Ok(msg :str) Err(msg :str) }
set v = match r1 { Result.Ok(m) { m } Result.Err(m) { "default" } } :str
```
✅ Works

5. **Simple enum without payload returning str** (match on first variant only):
```mire
enum Status { Ok Error }
set m = match Status.Ok { Status.Ok { "success" } Status.Error { "failed" } } :str
```
✅ Works

### Current State

The previously failing enum `match` expression path now compiles and runs correctly in the current regression suite, including string-returning branches without an explicit fallback arm.

### Reproduction Case

```mire
import std

enum Status {
    Ok
    Error
    Loading(value :i64)
}

pub fn main: () {
    set result = Status.Error
    set msg = match result {
        Status.Ok { "success" }
        Status.Error { "failed" }
        Status.Loading { "loading" }
    } :str
    
    use dasu(msg)
}
```

### Verification Note

This issue remains in the log as historical context, but it should no longer be treated as an active syntax or lowering blocker unless a new reproducible case appears.

---

## Issue #002 - Enum Variant with Named Payload Fields

**Date**: 2025-04-18
**Severity**: Medium
**Component**: Parser
**Status**: RESOLVED (v2.0.0+, Apr 2026)

### Description

Enum variants now support named payload construction with the same `field: value` style already used by struct constructors.

### Reproduction Case

```mire
enum Status {
    Ok
    Error
    Loading(progress :i64)
}

pub fn main: () {
    set loading = Status.Loading(progress: 75)  # Works
}
```

### Rules

- Named and positional payloads cannot be mixed in the same enum variant construction
- Field names are validated against the enum variant declaration
- Duplicate field names are rejected
- Named payloads are normalized to declaration order before lowering

---

## Verified Working Features

- ✅ Struct declaration and construction
- ✅ Struct field access (`p.x`)
- ✅ Instance methods (`p.get_x()`)
- ✅ Static/associated methods (`Point::new(...)`)
- ✅ Match with boolean return
- ✅ Match with simple i64 return
- ✅ Enum variant creation (positional args)
- ✅ Basic ireru/input builtin

---

## Notes for Testers

1. Always test with `./mire` from project root
2. Check both compile-time AND runtime errors
3. Document exact reproduction steps
4. Include full error output when reporting
5. Try to find workarounds when possible

---

## Known Limitations (Discovered during testing)

### Limitation #001 - Match expression cannot be used as direct function return value

**Severity**: Low
**Component**: Parser
**Status**: Known limitation

Functions cannot use `match` directly as the return value:

```mire
fn bad: (x :i64) :i64 {
    return match x { 1 { 10 } _ { 20 } } :i64  # FAILS
}

fn good: (x :i64) :i64 {
    set result = match x { 1 { 10 } _ { 20 } } :i64
    return result  # WORKS
}
```

### Limitation #002 - Boolean OR operator not supported

**Severity**: Low
**Component**: Lexer/Parser
**Status**: Known limitation

The `|` operator is not available for boolean OR:

```mire
# NOT SUPPORTED
if a | b {
    use dasu(yes)
}
```

Workaround: Use nested if statements:

```mire
if a {
    if b {
        use dasu(yes)
    }
}
```

### Limitation #003 - Boolean NOT operator not supported

**Severity**: Low
**Component**: Lexer/Parser
**Status**: Known limitation

The `!` operator is not available for boolean NOT:

```mire
# NOT SUPPORTED
if !a {
    use dasu(no)
}
```

Workaround: Use if-else or match:

```mire
if a {
    # do nothing
} else {
    use dasu(no)
}
```

### Limitation #004 - Cannot assign directly to struct fields

**Severity**: Medium
**Component**: Type checker
**Status**: Known limitation

Cannot reassign struct fields directly:

```mire
struct Counter { value :i64 }

impl Counter {
    fn increment: (self) {
        set self.value = self.value + 1  # FAILS
    }
}
```

Workaround: Use local variables and create new structs:

```mire
fn increment: (c :Counter) :Counter {
    set new_value = c.value + 1
    (Counter value: new_value)
}
```

### Limitation #005 - Arrays cannot be used in struct field declarations

**Severity**: Medium
**Component**: Parser
**Status**: Known limitation

Cannot declare struct with array fields directly:

```mire
# NOT SUPPORTED
struct Stack {
    items :arr[i64 10]  # FAILS
}
```

Workaround: Use separate variables or external arrays.

### Limitation #006 - Pipeline with closures not supported

**Severity**: Low
**Component**: Backend
**Status**: Known limitation

Pipeline `=>` only works with builtins like `len()`, not with closures:

```mire
# WORKS
set len = nums => len()

# NOT SUPPORTED
set doubled = nums => map(n => n * 2)
```

Workaround: Use explicit loops to process arrays.

### Limitation #007 - Function definitions in impl cannot use match as body

**Severity**: Low
**Component**: Parser
**Status**: PARTIALLY FIXED - implicit return added but has a bug

The implicit return feature was added but has a bug where it returns 0 instead of the actual value.

Cannot use match directly as function body in impl blocks:

```mire
# NOW WORKS (with implicit return) but returns wrong value
impl Counter {
    fn get: (self) :i64 {
        self.value  # Returns 0 instead of actual value
    }
}
```

### Limitation #008 - Implicit return fixed

**Severity**: N/A (FIXED)
**Component**: Backend (IR generation)
**Status**: RESOLVED (v2.0.0+, Apr 2026)

Now works correctly for all expression types (literals, variables, binary expressions, function calls).

```mire
fn add: (a :i64, b :i64) :i64 {
    a + b  # ✅ Now returns a+b correctly
}

fn greet: (name :str) :str {
    "hello " + name  # ✅ Now works
}
```

Workaround: Use explicit return:

```mire
fn add: (a :i64, b :i64) :i64 {
    return a + b  # Works correctly
}
```
