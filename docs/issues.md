# Known Limitations

Limitaciones actuales del compilador Avenys. Ver `avenyslogs.md` para lo ya resuelto.

---

## 🔴 HIGH PRIORITY

### L001 - Struct Field Access Returns 0

**Severity**: Medium
**Component**: Backend

```mire
struct Point { x :i64 y :i64 }
set p = (Point x: 10 y: 20)
set px = p.x  # Returns 0 instead of 10
```

**Workaround**: Usar funciones getter:
```mire
fn get_x: (p :Point) :i64 { p.x }
```

---

## 🟡 MEDIUM PRIORITY

### L002 - Match Multiline Body

**Severity**: Medium
**Component**: Parser

```mire
# ACTUAL - Works solo inline:
match x {
    Pattern { body }
}

# FALLA - Multiline:
match x {
    Pattern {
        multiline
    }
}
```

**Workaround**: Usar expresiones inline.

### L003 - Match Condition with Comparison

**Severity**: Medium
**Component**: Parser

```mire
# FALLA:
match x >= 5 {
    true { 1 }
    _ { 0 }
}
```

**Workaround**: Usar variable:
```mire
set is_big = x >= 5
match is_big {
    true { 1 }
    _ { 0 }
}
```

---

## 🟢 LOW PRIORITY

### L004 - Boolean OR Not Supported

**Severity**: Low
**Component**: Lexer/Parser

```mire
# NOT SUPPORTED
if a | b { }
```

**Workaround**:
```mire
if a { if b { } }
```

### L005 - Boolean NOT Not Supported

**Severity**: Low
**Component**: Lexer/Parser

```mire
# NOT SUPPORTED
if !a { }
```

**Workaround**:
```mire
if a { } else { }
```

### L006 - Cannot Reassign Struct Fields

**Severity**: Low
**Component**: Type checker

```mire
struct Counter { value :i64 }
set c = (Counter value: 0)
set c.value = 1  # FALLA
```

**Workaround**: Crear nuevo struct:
```mire
fn increment: (c :Counter) :Counter {
    (Counter value: c.value + 1)
}
```

### L007 - Arrays in Struct Fields

**Severity**: Low
**Component**: Parser

```mire
# NOT SUPPORTED
struct Stack {
    items :arr[i64 10]  # FALLA
}
```

### L008 - Closures in Pipelines

**Severity**: Low
**Component**: Backend

```mire
# WORKS:
set len = nums => len()

# NOT SUPPORTED:
set doubled = nums => map(n => n * 2)
```

---

## 🔴 COMPLETADO (Abril 2026)

### L009 - Struct Field Access in Function Parameters

**Status**: ✅ RESOLVED

**Fix aplicado:**
- El backend ahora propaga `struct_name` usando `params.iter()` (parámetros de la LLAMADA)
- Anteriormente usaba `fn_info.params` que contenía tipos LLVM, no DataType
- También guarda `data_type` correcto para el parámetro

**Test case:**
```mire
fn get_x: (p :Point) :i64 { p.x }  # ✅ Ahora funciona
```

---

## 📝 Propuestas de Mejora

Ver `todo.md` sección SYNTAX IMPROVEMENTS para语法mejoras propuestas:
- Match multilínea con `=>`
- Boolean operators con `@` prefix (@|, @&, @!, @^)