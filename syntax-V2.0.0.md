# Mire Syntax v2.0.0

This document defines the current Mire syntax surface introduced by v2.0.0.

The two intentional language changes in this release are:

- instance methods must declare `self` explicitly
- associated/static methods use `Type::method(...)`

Mire keeps its own type-annotation style. The language continues to prefer `name :Type`, not Rust-style `name: Type`.

---

## Minimal Program

```mire
import std

pub fn main: () {
    use dasu("Hello Mire")
}
```

---

## Bindings

```mire
set age = 25 :i64
set name = "mire" :str
set ready = true :bool
set total = 0 :i64 mut
```

Rules:

- `set` declares a binding
- type annotations use `name :Type`
- mutability stays on the binding, not on the type
- commas are optional in many list-like positions

---

## Functions

```mire
fn sum: (left :i64 right :i64) :i64 {
    return left + right
}
```

Notes:

- parameters use the same `name :Type` style
- return types are written after the parameter list as `:Type`
- `pub` and `priv` control visibility

---

## Structs

```mire
struct User {
    name :str
    age :i64
}
```

Construction:

```mire
set user = (User name: "Evelyn", age: 20)
```

Field access:

```mire
use dasu(user.name)
use dasu(user.age)
```

---

## `impl`

### Instance Methods

Instance methods must declare `self` explicitly as the first parameter:

```mire
impl User {
    fn greet: (self) {
        use dasu("Hello {self.name}")
    }

    fn is_adult: (self) :bool {
        return self.age >= 18
    }
}
```

Call syntax:

```mire
use user.greet()
use dasu(user.is_adult())
```

### Associated / Static Methods

Associated methods omit `self` and are called with `::`:

```mire
impl User {
    fn new: (name :str age :i64) :User {
        return (User name: name, age: age)
    }
}

set user = User::new("Evelyn" 20)
```

### Intentional Split

Mire v2.0.0 uses:

- `Enum.Variant(...)` for enum construction and enum-qualified matching
- `Type::method(...)` for associated/static methods
- `value.method(...)` for instance methods

That split is deliberate and is now part of the language direction.

For `trait` / `skill` conformance, Mire now enforces the same split:

- a contract method with leading `self` must be implemented as an instance method
- a contract method without `self` must be implemented as an associated/static method

---

## Enums

```mire
enum Result {
    Ok(value :i64)
    Err(message :str)
    Loading(progress :i64, total :i64)
}
```

Construction (positional or named):

```mire
set result = Result.Ok(42)
set named = Result.Err(message: "boom")
set loading = Status.Loading(progress: 75, total: 100)
```

**Rules**:
- Named and positional payloads cannot be mixed in the same variant construction
- Field names are validated against the enum variant declaration
- Named arguments are normalized to the order declared in the enum

Matching:

```mire
match result {
    Result.Ok(value) {
        use dasu(value)
    }
    Result.Err(message) {
        use dasu(message)
    }
}
```

`match` also accepts a boolean/comparison expression as the matched value:

```mire
set x = 3 :i64

match x < 5 :bool {
    true {
        use dasu("small")
    }
    false {
        use dasu("large")
    }
}
```

---

## Collections

```mire
set fixed = [1 2 3] :arr[i64 3]
set dyn   = [] :vec![i64]
set dict  = {a: 1, b: 2} :map[str i64]
```

---

## Control Flow

```mire
if age >= 18 {
    use dasu("adult")
} else {
    use dasu("minor")
}

while count < 10 {
    set count += 1
}

for i in range(5) {
    use dasu(i)
}
```

---

## Ownership Surface

```mire
set x = 1 :i64
set shared = &x
set owned = box[i64]
```

The ownership checker and MSS remain active. v2.0.0 changes `impl` syntax, not the safety model.

---

## Migration From v1.x

Before:

```mire
impl Point {
    fn sum: () :i64 {
        return self.x + self.y
    }
}

set p = Point::new(1 2)
```

Now:

```mire
impl Point {
    fn sum: (self) :i64 {
        return self.x + self.y
    }

    fn new: (x :i64 y :i64) :Point {
        return (Point x: x, y: y)
    }
}

set p = Point::new(1 2)
```

---

## Stability Notes

Stable in v2.0.0:

- `struct`
- field access
- `impl` instance methods with explicit `self`
- associated/static methods with `::`
- enum-qualified variants with `.`
- enum named payload fields (e.g., `Status.Loading(progress: 75)`)

Still under active compiler improvement:

- nominal type identity as a first-class internal type
- field-level constructor validation
- some advanced trait/skill conformance paths
