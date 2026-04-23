# Known Limitations

Limitaciones actuales del compilador Avenys.

---

## 🟡 MEDIUM PRIORITY

### L001 - Match Multiline Body

```mire
# FUNCIONA:
match x { Pattern { body } }

# FUNCIONA (multiline):
match x {
    Pattern {
        multiline
    }
}
```

**Status**: ✅ RESOLVED (Abril 2026)
- Parser ya soporta multilínea via parse_expression_until_block_close()
- Requiere tipo explícito: `match x { ... } :i64`

---

### L002 - Boolean Operators

**Description:**

```mire
# FUNCIONA:
if a && b { }
if a || b { }
if !a { }
if a ^ b { }
```

**Status**: ✅ RESOLVED (Mayo 2026)
- `&&` logical AND implemented with short-circuit evaluation
- `||` logical OR implemented with short-circuit evaluation
- `!` unary NOT implemented
- `^` logical XOR implemented
- Old keywords `and`/`or`/`not` REMOVED

---

### L003 - Match Condition with Comparison

**Description:**

```mire
# FALLA:
match x >= 5 { true { 1 } _ { 0 } }
```

**Error:** "Expected Lbrace but found Gte" - el parser no acepta comparación como condición de match

**Workaround:**
```mire
set is_big = x >= 5
match is_big { true { 1 } _ { 0 } }
```

**Status**: ❌ PENDING

---

## 🟢 LOW PRIORITY

### L004 - Reassign Struct Fields

**Description:**

```mire
struct Counter { value :i64 }
set c = (Counter value: 0)
set c.value = 1  # FALLA
```

**Error:** "Cannot reassign immutable variable 'c.value'"

**Workaround**: Crear nuevo struct con valores actualizados

**Status**: ❌ PENDING

---

### L005 - Arrays in Struct Fields

```mire
# FUNCIONA:
struct Stack { items :arr[i64 10] }
set s = (Stack items: [1 2 3 4 5 6 7 8 9 10])
set first = s.items[0]
set count = len(s.items)
```

**Status**: ✅ RESOLVED

---

### L006 - Closures in Pipelines

```mire
# FUNCIONA:
set nums = [1 2 3 4 5]  :vec![i64] mut
set doubled = nums => (x => x * 2)
# Produces: [2, 4, 6, 8, 10]
```

**Status**: ✅ RESOLVED (Mayo 2026)
- Parser: sintaxis `(param => body)` funciona correctamente
- Typeck: closure parameter type inferred from input element type
- Backend: `compile_pipeline_closure()` implemented with full loop logic
- Full LLVM IR generation with proper memory management
- `mire_list_create` function added to runtime_support.c

---

### L007 - Closure Syntax in Pipeline Stage (Derivada de L006)

```mire
# FUNCIONA:
set doubled = nums => (x => x * 2)
```

**Status**: ✅ RESOLVED (Mayo 2026)
- Parser: `(param => body)` syntax correctly parses as `Expression::Closure`
- Typeck: Pipeline with closure infers parameter type from input element type
- Backend: Full loop implementation with proper LLVM IR generation
- Test: `[1, 2, 3] => (x => x * 2)` produces `[2, 4, 6]` ✅

---

## 📝 Propuestas de Mejora (SYNTAX PROPOSALS)

### 1. Match con Comparación

**Current:** No soporta `match x >= 5`
**Propuesta:** Modificar parser para aceptar comparaciones como match condition

### 2. Struct Field Reassignment

**Current:** `c.value = 1` falla
**Propuesta:** Implementar setter semántico para fields mutables

### 3. Bitwise Operators

**Current:** `&`, `|`, `<<`, `>>` no implementados
**Propuesta:** Implementar operadores bitwise para consistencia con C-style

---

## ✅ RESOLVED ( Mayo 2026 )

- L001: Match Multiline Body ✅
- L002: Boolean Operators ✅ (C-style: !, &&, ||, ^)
- L005: Arrays in Struct Fields ✅
- L006: Closures in Pipelines ✅
- L007: Closure Syntax in Pipeline Stage ✅

---

## ❌ PENDING

- L003: Match with Comparison
- L004: Struct field reassignment

---

## 📊 Resumen de Tests

| Feature | Status | Notes |
|---------|--------|-------|
| `&&`/`\|\|`/`^`/`!` operators | ✅ Works | C-style logical operators |
| Match multiline | ✅ Works | |
| Match with comparison | ❌ Fails | usar workaround |
| Struct field reassign | ❌ Fails | crear nuevo struct |
| Arrays in structs | ✅ Works | |
| Closures in pipelines | ✅ Works | L006/L007 |