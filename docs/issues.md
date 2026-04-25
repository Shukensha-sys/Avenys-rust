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
# FUNCIONA:
match x >= 5 :bool {
    true { 1 }
    _ { 0 }
}
```

También funciona con igualdad y operadores lógicos:

```mire
match y == 10 :bool {
    true { "ten" }
    false { "other" }
}

match a && b :bool {
    true { 1 }
    false { 0 }
}
```

**Status**: ✅ RESOLVED (Abril 2026)

---

## 🟢 LOW PRIORITY

### L004 - Struct Field Reassignment

**Descripción:**

```mire
struct Counter { value :i64 }
set c = (Counter value: 0) mut
set c.value = 1  # ✅ FUNCIONA (requiere 'set')
```

**Workaround**: None needed - works with `set` keyword

**Status**: ✅ RESOLVED (Abril 2026)
- Typeck now handles field assignment via struct reconstruction
- Requires `set` keyword (consistent con sintaxis Mire)
- Tests passing: `direct_struct_field_assignment_updates_mutable_binding`

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

## 🚨 CRITICAL ISSUES

### CR1 - Scope Lexical en Borrow Checker

**Descripción:**
El borrow checker filtraba por scope al consultar binding semántico.

**Status:** ✅ RESOLVED (Investigado Abril 2026)
- `semantic_binding()` ya filtra por `binding_scope_depth` (borrowck.rs:808-816)
- El modelo mantiene `scope_depth` en cada binding
- Verificación activa en llamadas a funciones

---

### CR2 - Métodos en Impl/Class No Registrados

**Descripción:**
El modelo semántico sí registra métodos de impl/class.

**Status:** ✅ RESOLVED (Investigado Abril 2026)
- `Statement::Impl` ya llama `visit_statements(methods)` (semantic.rs:317-322)
- Los métodos se registran en el modelo semántico
- Funciones con scope_id para control de ownership

---

### CR3 - Unsafe No Seguido

**Descripción:**
La capa semántica ya procesa statements unsafe.

**Status:** ✅ RESOLVED (Investigado Abril 2026)
- `Statement::Unsafe` ya incrementa `unsafe_depth` (semantic.rs:328-332)
- `unsafe_blocks` se cuenta correctamente
- Modelo representa el programa real

---

## 🔶 TYPE CHECKING IMPROVEMENTS

### T1 - Member Access Fallback Permisivo

**Descripción:**
El acceso a miembros ya maneja errores cuando no puede resolver el tipo.

**Status:** ✅ INVESTIGATED (Abril 2026)
- Código actual (typeck.rs:1571-1613) ya lanza errores cuando no encuentra fields/methods
- Fallback a Anything solo para tipos Unknown (comportamiento esperado en lenguaje dinámico)
- Considerar como diseño, no bug

---

### T2 - Pipeline Typing Incompleto

**Descripción:**
El tipado de Pipeline usar defaults cuando no puede inferir.

**Status:** ✅ INVESTIGATED (Abril 2026)
- Usa elem_type como fallback cuando return_type es Unknown (typeck.rs:1747)
- Comportamiento razonable para lenguajes dinámicos
- Considerar como diseño: flexibilidad vs type safety

---

### T3 - Referencias Sin Tipo Apuntado

**Descripción:**
Las referencias no almacenaban tipo detallado en el AST.

**Fix:**
- AST ahora tiene campo `referenced_type: DataType` (ast.rs:207-211)
- Parser poblá el campo como `DataType::Unknown` (mod.rs:1285)
- Type checker poblá con el tipo real del valor referido (typeck.rs:1686)
- Permite mejor inferencia y mensajes de error precisos

**Status:** ✅ RESOLVED (Mayo 2026)

---

## 📝 Propuestas de Mejora (SYNTAX PROPOSALS)

### 1. Match con Comparación

**Status:** ✅ RESOLVED (Abril 2026)
**Current:** Soporta `match x >= 5 :bool`, igualdad y operadores lógicos booleanos

### 2. Struct Field Reassignment

**Current:** `c.value = 1` falla
**Propuesta:** Implementar setter semántico para fields mutables

### 3. Bitwise Operators

**Status**: ✅ RESOLVED (Mayo 2026)
- `&` - Bitwise AND
- `|` - Bitwise OR
- `<<` - Left shift
- `>>` - Right shift
- `^` - Bitwise XOR (int operands) / Logical XOR (bool operands)

---

## ✅ RESOLVED ( Abril 2026 )

- L001: Match Multiline Body ✅
- L002: Boolean Operators ✅ (C-style: !, &&, ||, ^)
- L003: Match with Comparison ✅
- L004: Struct Field Reassignment ✅
- L005: Arrays in Struct Fields ✅
- L006: Closures in Pipelines ✅
- L007: Closure Syntax in Pipeline Stage ✅

---

## ❌ PENDING

### High Priority (Type Checking)
- None remaining

---

## ✅ RESOLVED (Mayo 2026)

### T3: References Con Tipo Apuntado

**Description:**
Expression::Reference now stores the type of the referenced value.

**Fix:**
- AST field `referenced_type: DataType` added (ast.rs:207-211)
- Parser initializes to `DataType::Unknown` (mod.rs:1285)
- Type checker populates with actual target type (typeck.rs:1686)
- Enables better type inference and error messages

**Status**: ✅ RESOLVED (Mayo 2026)

### T1: Member Access Fallback

**Description:**
Member access was too permissive - allowed any member access on Unknown types.

**Fix:**
- Now rejects member access on Unknown types with clear error message
- Only allows on Anything type with warning

**Status**: ✅ RESOLVED (Mayo 2026)

---

### T2: Pipeline Typing

**Description:**
Pipeline used `element_type` as fallback when return_type was Unknown.

**Fix:**
- Now requires explicit return type or proper inference
- Throws error if return type cannot be determined

**Status**: ✅ RESOLVED (Mayo 2026)

---

### Test Fix: Missing Variable Definition

**Description:**
`tests/stress/enum_stress.mire` referenced undefined variable.

**Status**: ✅ FIXED (Abril 2026)
- Fixed by adding proper enum construction `set test = Status.Ok`

---

## 📊 Resumen de Tests

| Feature | Status | Notes |
|---------|--------|-------|
| `&&`/`\|\|`/`^`/`!` operators | ✅ Works | C-style logical operators |
| Bitwise operators | ✅ Works | &, \|, <<, >> |
| Match multiline | ✅ Works | |
| Match with comparison | ✅ Works | comparisons, equality, and logical expressions |
| Struct field reassign | ✅ Works | requires `set` keyword |
| Arrays in structs | ✅ Works | |
| Closures in pipelines | ✅ Works | L006/L007 |
| Borrow checker scope | ✅ Works | filters by scope_depth |
| Impl/Class methods | ✅ Works | registered in semantic |
| Unsafe tracking | ✅ Works | unsafe_depth tracked |
| Member access | ✅ Works | throws errors when not found |
| Pipeline typing | ✅ Works | uses elem_type as fallback |
| Reference types | ✅ Works | infers from target expression via referenced_type |
| String interpolation | ✅ Works | supports nested function calls {func(x)} |
| Empty vec literal | ✅ Works | `[] :vec![i64]` now works with `lists.push` |
| Empty dict literal | ✅ Works | `{} :map![str,i64]` now works with dict operations |

---

## 🆕 Empty Vec Literal with Type Annotation

**Description:**
Empty vec literals `[]` with type annotation `[] :vec![i64]` now work with `lists.push`.

```mire
# NOW WORKS:
set arr = [] :vec![i64] mut
set arr = lists.push(arr 1)
set arr = lists.push(arr 2)
```

**Fix:**
- Parser: propagates type annotation to list literal (mod.rs:245-256)
- Typeck: checks for `DataType::Vector` before inferring (typeck.rs:1499-1512)
- `lists.push`: accepts static vectors by promoting to dynamic (typeck.rs:1384-1400)

**Status**: ✅ RESOLVED (Mayo 2026)

---

## 🆕 Empty Dict Literal with Type Annotation

**Description:**
Empty dict literals `{}` with type annotation `{} :map![K,V]` now preserve type information.

```mire
# NOW WORKS:
set m = {} :map![str,i64] mut
```

**Fix:**
- AST: added `key_type` and `value_type` fields to `Expression::Dict` (ast.rs:190-195)
- Parser: propagates type annotation to dict literal (mod.rs:256-266)
- Parser: added `apply_map_type_to_dict` helper function (mod.rs:3183-3194)
- Typeck: checks for `DataType::Map` before inferring (typeck.rs:1520-1538)

**Status**: ✅ RESOLVED (Mayo 2026)
