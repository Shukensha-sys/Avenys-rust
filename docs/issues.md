# Known Limitations

Limitaciones actuales del compilador Avenys. Ver `avenyslogs.md` para lo ya resuelto.

---

## 🟡 MEDIUM PRIORITY

### L001 - Match Multiline Body

**Description:**

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

### L002 - Boolean OR/AND/NOT Operators

**Description:**

```mire
# NOT SUPPORTED:
if a | b { }
if !a { }
```

**Status**: PENDING - propuesta: usar @ prefix (@|, @&, @!)

---

### L003 - Match Condition with Comparison

**Description:**

```mire
# FALLA:
match x >= 5 { true { 1 } _ { 0 } }
```

**Workaround**:
```mire
set is_big = x >= 5
match is_big { true { 1 } _ { 0 } }
```

---

## 🟢 LOW PRIORITY

### L004 - Reassign Struct Fields

**Description:**

```mire
struct Counter { value :i64 }
set c = (Counter value: 0)
set c.value = 1  # FALLA
```

**Workaround**: Crear nuevo struct

### L005 - Arrays in Struct Fields

```mire
# NOT SUPPORTED
struct Stack { items :arr[i64 10] }
```

### L006 - Closures in Pipelines

```mire
# NOT SUPPORTED:
set doubled = nums => map(n => n * 2)
```

**Status**: ❌ INVESTIGATED (Abril 2026) - REQUIRES REFACTOR
- Parser: sintaxis ya soportada (`=>` syntax funciona para pipelines)
- Typeck: no restringe la forma del stage
- Backend: `src/avens/mod.rs:1586-1710` NO maneja `Expression::Closure` como pipeline stage
- Error: "Pipeline stage must be a function call or identifier"
- Requiere cambios significativos enbackend para compilar closures como funciones inline
- Sugerencia: Postergar hasta nueva fase de optimización

---

## ✅ RESOLVED ( Abril 2026 )

- L001: Match Multiline Body ✅
- L002: Logical Operators C-style (!, &&, ||, ^) ✅
- L003: Match with Comparison ✅
- L004: Struct field reassignment ✅
- L005: Arrays in Struct Fields ✅
- L009: Struct field access in function parameters ✅

## ❌ INVESTIGATED ( Abril 2026 )

- L006: Closures in Pipelines - REQUIRES REFACTOR (postergar)

---

## 📝 Propuestas de Mejora

Ver `todo.md` sección SYNTAX IMPROVEMENTS:
- Match multilínea con `=>`
- Boolean operators con `@` prefix (@|, @&, @!, @^)