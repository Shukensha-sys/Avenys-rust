# Mire Syntax Reference v2.0.0

Complete language syntax derived from 188 test files and working examples.

---

## Table of Contents

1. [Minimal Program](#1-minimal-program)
2. [Bindings](#2-bindings)
3. [Functions](#3-functions)
4. [Structs](#4-structs)
5. [Impl and Methods](#5-impl-and-methods)
6. [Enums](#6-enums)
7. [Collections](#7-collections)
8. [Control Flow](#8-control-flow)
9. [String Interpolation](#9-string-interpolation)
10. [Imports](#10-imports)
11. [Traits/Skills](#11-traitsskills)
12. [Operators](#12-operators)
13. [Ownership](#13-ownership)
14. [Types](#14-types)

---

## 1. Minimal Program

```mire
import std

pub fn main: () {
    use dasu("Hello Mire")
}
```

---

## 2. Bindings

```mire
set age = 25 :i64
set name = "mire" :str
set ready = true :bool
set total = 0 :i64 mut
set counts = [] :vec![i64] mut
set counts = lists.push(counts 4)
```

Rules:
- `set` declares a binding
- Type annotations use `name :Type`
- `mut` enables reassignment
- Commas optional in many positions

---

## 3. Functions

```mire
fn add: (a :i64, b :i64) :i64 {
    return a + b
}

fn get_str: () :str {
    return "hello"
}

pub fn main: () {
    set result = add(5 3) :i64
}
```

Parameter and return types use `name :Type` syntax.

---

## 4. Structs

```mire
struct Point {
    x :i64
    y :i64
}

struct Box {
    width :i64
    height :i64
}

struct Stack {
    items :arr[i64 10]
    count :i64
}
```

Construction with named fields:

```mire
set p = (Point x: 1, y: 2)
set b = (Box width: 10, height: 20)
```

Field access:

```mire
use dasu(p.x)
set p.x = 5
```

---

## 5. Impl and Methods

### Instance Methods (with explicit `self`)

```mire
impl Point {
    fn sum: (self) :i64 {
        return self.x + self.y
    }
}
```

Call via instance:

```mire
use dasu(p.sum())
```

### Associated/Static Methods (with `::`)

```mire
impl Point {
    fn new: (x :i64, y :i64) :Point {
        return (Point x: x, y: y)
    }
}
```

Call via type:

```mire
set p = Point::new(1 2)
```

### Intentional Split

- `Enum.Variant(...)` for enum construction
- `Type::method(...)` for associated/static methods
- `value.method(...)` for instance methods

---

## 6. Enums

```mire
enum Color {
    Red
    Green
    Blue
}

enum Maybe {
    None
    Some(value :i64)
}

enum Result {
    Ok(value :i64)
    Err(message :str)
}

enum Status {
    Ok
    Error
    Loading(progress :i64, total :i64)
}

enum Token {
    Num(value :i64)
    Str(text :str)
    Op(name :str)
}
```

Construction:

```mire
set c = Color.Red
set m = Maybe.Some(value: 42)
set r = Result.Ok(42)
set s = Status.Loading(progress: 75, total: 100)
```

Match patterns:

```mire
match c {
    Color.Red { use dasu("red") }
    Color.Green { use dasu("green") }
    Color.Blue { use dasu("blue") }
}

match m {
    Maybe.None { use dasu("nothing") }
    Maybe.Some(v) { use dasu(v) }
}
```

---

## 7. Collections

### Arrays (fixed-size)

```mire
set arr = [1 2 3] :arr[i64 3]
```

### Vectors (dynamic)

```mire
set counts = [] :vec![i64] mut
set counts = lists.push(counts 4)
set counts = lists.push(counts 7)
set first = lists.get(counts 0)
```

### Dicts/Maps

```mire
set m = {a: 1, b: 2} :map![str,i64]
```

---

## 8. Control Flow

### If/Else

```mire
if age >= 18 {
    use dasu("adult")
} else {
    use dasu("minor")
}

if x > 10 {
    use dasu("greater")
} elif x == 10 {
    use dasu("equal")
} else {
    use dasu("lower")
}
```

### While

```mire
while count < 10 {
    set count += 1
}
```

### For

```mire
for i in range(10) {
    use dasu(i)
}
```

### Do-While

```mire
do {
    set count += 1
} while count != 10
```

### Match

```mire
match code {
    200 { use dasu("ok") }
    _ { use dasu("error") }
}

match x < 5 :bool {
    true { 1 }
    false { 2 }
}
```

---

## 9. String Interpolation

```mire
use dasu("Hello {name}")
use dasu("Count: {count}")
use dasu("Result: {add(5 3)}")
```

Variables, function calls, and method calls inside `{}`.

---

## 10. Imports

```mire
import std
import math
import strings
import fs as fs
import ./utils
import strings: (split replace trim)
```

Specific imports:

```mire
import strings: (split replace trim)
```

---

## 11. Traits/Skills

```mire
pub skill Show {
    fn show: (self) :str
}

pub skill Size {
    fn size: (self) :i64
}

impl Show for Box {
    fn show: (self) :str {
        return "Box"
    }
}
```

---

## 12. Operators

### Arithmetic

```mire
set sum = a + b
set diff = a - b
set prod = a * b
set quot = a / b
```

### Comparison

```mire
if x >= 18 { }
if x == 10 { }
if x != 5 { }
```

### Logical

```mire
if a && b { }
if a || b { }
if !flag { }
```

### Bitwise

```mire
set result = a & b
set result = a | b
set result = a << b
set result = a >> b
```

---

## 13. Ownership

```mire
set x = 1 :i64
set shared = &x
set owned = box[i64]
```

The ownership checker enforces:
- No use-after-move
- No mutation while shared borrow exists
- No multiple mutable references
- No return of local references

`unsafe` blocks bypass checks:

```mire
unsafe {
    set x = 2
}
```

---

## 14. Types

### Primitive Types

| Type | Description |
|------|-------------|
| `i8`, `i16`, `i32`, `i64` | Signed integers |
| `u8`, `u16`, `u32`, `u64` | Unsigned integers |
| `f32`, `f64` | Floating point |
| `str` | String |
| `bool` | Boolean |
| `none` | Unit type |

### Collection Types

| Type | Syntax |
|------|--------|
| Array | `arr[T N]` |
| Vector | `vec![T]` |
| Map | `map![K,V]` |

### Custom Types

```mire
set user = "mire" :str
set p = (Point x: 1, y: 2) :Point
```

---

## Examples from Working Tests

### Arithmetic

```mire
set a = 5 :i64
set b = 3 :i64
set sum = a + b
set prod = a * b
```

### Struct with Impl

```mire
struct Point {
    x :i64
    y :i64
}

impl Point {
    fn new: (x :i64, y :i64) :Point {
        return (Point x: x, y: y)
    }

    fn sum: (self) :i64 {
        return self.x + self.y
    }
}

set p = Point::new(1 2)
set s = p.sum()
```

### Enum with Match

```mire
enum Maybe {
    None
    Some(value :i64)
}

set m = Maybe.Some(value: 42)

match m {
    Maybe.None { use dasu("nothing") }
    Maybe.Some(v) { use dasu(v) }
}
```

### Vector Operations

```mire
set counts = [] :vec![i64] mut
set counts = lists.push(counts 4)
set counts = lists.push(counts 7)
set counts = lists.push(counts 9)
set total = math.sum(counts)
```

---

## Notes

- Commas are optional in many positions
- The `name :Type` style is consistent throughout
- Empty collections with type annotation:

```mire
set arr = [] :vec![i64] mut
set m = {} :map![str,i64] mut
```

---

## Stability

**Stable in v2.0.0:**
- `struct`, field access
- `impl` with explicit `self`
- `Type::method(...)` with `::`
- `enum` with named variants
- Collections with type annotations
- Ownership checks

**Still improving:**
- Field-level constructor validation
- Advanced trait conformance
- Pipelines (`=>`)