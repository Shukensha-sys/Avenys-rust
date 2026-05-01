# Known Limitations

Limitaciones actuales del compilador Avenys.

> **Nota**: Para información técnica detallada sobre arquitectura y próximos pasos, ver [`docs/TECHNICAL.md`](TECHNICAL.md)

---

## 📊 RESUMEN EJECUTIVO (Mayo 2026)

| Severidad | Cantidad | Descripción |
|-----------|----------|-------------|
| 🔴 Crítico | 0 | Rompe funcionalidad core |
| 🟠 Bug Real | 0 | Resultados incorrectos/falsos |
| 🟡 Deuda | 0 | Comportamiento incorrecto |
| ℹ️ Diseño | 2 | Mantenimiento/diseño |
| ✅ Verificado | 24 | Fixes ya aplicados |

**Tests:**
- Unit/internos: 79/79 ✅
- Regresiones: 73/73 ✅

**Fix Completados:**
- C1: FxHasher (FNV-1a) para cache determinista
- C2: strings.split retorna lista correctamente
- C3: Codegen strings.split implementado
- B1: latest_successful_analysis usa timestamp de creación
- B2: No reproducible (lenguaje previene el problema)
- D1: prune_lru ahora incluye builds
- D3: to_upper/to_lower con soporte Latin-1
- D4: Memory leak en MAP fixeado
- D5: mutabilidad de referencias inferida/validada correctamente
- Hardening cache: auto-saneado de cache corrupto/incompatible al cargar
- Perf incremental: `compute_invalidation_report` optimizado con índice inverso de dependencias

---

# Secciones Detalladas

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

## 🆕 Float Support (v2.2.0)

### Issue: Float Literals

**Description:**
Float literals and conversion to string now work.

```mire
set x = 3.14 :f64
use dasu(x)        # prints 3.14

set s = str(3.14 :f64)
use dasu(s)        # prints 3.14
```

**Fix:**
- Added `LlType::F64` to LLVM type system
- Fixed `map_type` to map `F64` -> `LlType::F64` (not `Ptr`)
- Added `mire_f64_to_string(double)` runtime function
- Added F64 support in cast operations, print, store, etc.

**Status**: ✅ RESOLVED (Mayo 2026)

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
| Reference types | ✅ Works | Preserves inner type, `&x`/`*ref` lowering, typed params like `:&i64`, and now type unification `&T`↔`T` in type checker |
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

---

## 🆕 Test Suite Observations

### Array Indexing

**Issue**: Se había reportado que `arr at N` devolvía elementos desplazados.

```mire
set arr = [10 20 30 40 50] :arr[i64 5]
arr at 0  # 10
arr at 1  # 20
arr at 2  # 30
```

**Status**: ✅ RESOLVED (Abril 2026)
- Validado otra vez con `tests/edge/arrays/03_array_index_bug.mire`
- El acceso `arr at index` produce el elemento correcto
- Se mantiene la comprobación de bounds en runtime

### Reference Lowering

**Issue**: Reference expressions `&x` used to pass type checking but fail at LLVM lowering.

```mire
set x = 1 :i64
set rx = &x
set y = *rx
```

**Status**: ✅ RESOLVED (Abril 2026)
- AST and parser now preserve the referenced inner type for `&T`
- Type checking keeps typed refs through locals and params like `value :&i64`
- Avenys lowers shared refs and dereference directly as pointers

### math.avg Function

**Issue**: `math.avg` function not available in standard library.

**Status**: ⚠️ MISSING FUNCTION - Use `math.sum(x) / len(x)` instead

### High-Order Functions

**Issue**: `lists.fold`, `lists.map`, `lists.filter` estaban incompletas y dependían de workarounds en closures.

```mire
set result = lists.fold(0, (a b) => a + b, [1 2 3 4 5])
```

**Status**: ✅ RESOLVED (Abril 2026)
- Parser: reconoce la sintaxis de closure con firma `(a b) => ...` y `(x: i64) => ...`
- Type checker: infiere tipos de parámetros desde el contexto de `fold/map/filter`
- Backend Avenys: ejecuta el cuerpo real de la closure para `fold`, `map` y `filter`
- La sintaxis existente se mantiene; ya no hace falta anotar parámetros solo para que compile
- Alcance actual: el soporte resuelto es para closures inline; los callbacks de primer nivel como valor/identificador siguen siendo una ampliación futura, no un bug de este fix

### Array Mutation Syntax

**Issue**: Antes no se podía asignar a un elemento con `at`.

```mire
set arr = [1 2 3] :arr[i64 3]
set arr at 0 = 10
```

**Status**: ✅ RESOLVED (Abril 2026)
- Parser: `set arr at i = value` ya se reconoce como target indexado
- Type checker: valida el tipo del elemento y conserva el tipo del contenedor
- Backend: escribe in-place con bounds checks
- También funciona sobre fields indexables, por ejemplo `set self.data at idx = val`

### Struct impl with Mutable Fields

**Issue**: Struct methods used to fail on mutable field updates via `self.field = value`.

```mire
fn increment: (self) {
    set self.value = self.value + 1
}
```

**Status**: ✅ RESOLVED (Abril 2026)
- Direct field mutation inside `impl` now compiles and runs
- The parser now consumes `mut` correctly in struct fields such as `value :i64 mut`
- Validated with `tests/complex/data_structures/06_counter_impl.mire` and `10_student_impl.mire`

---

## 🆕 Ref/RefMut Type Unification (v2.1.1)

### Issue: Reference Type Inference Mismatch

**Description:**
Funciones con parámetros tipados como `&T` fallaban al compilar porque `unify_types` e `is_assignable` no manejan referencias.

```mire
fn read_ref: (value :&i64) :i64 {
    return *value
}

pub fn main: () {
    set x = 41 :i64
    set rx = &x
    set y = read_ref(rx)
    use dasu(y + 1)
}
```

**Error original:** `Cannot unify incompatible types I64 and Ref { inner: I64 }`

**Fix:**
- `unify_types` (`typeck.rs`): Auto-unwrap de Ref/RefMut cuando un lado es referencia y el otro es el tipo base
- `is_assignable` (`typeck.rs`): Auto-deref de expected Ref al comparar con actual (no-Ref)

**Casos soportados:**
- `&T` puede unificarse con `T` (ej: tipo de retorno `&i64` inferido como `i64`)
- `&T` asignable a `T` (auto-deref en `is_assignable`)
- `&T` asignable a `&T`, `&mut T` asignable a `&T` o `&mut T`
- `&T` no satisface parámetros o bindings que exigen `&mut T`

**Status**: ✅ RESOLVED (Mayo 2026)

---

## 🆕 Clippy Refactoring (v2.1.1)

### Issue: Naming Conflicts with Standard Traits

**Description:**
Métodos `from_str` y `eq` causaban advertencias de clippy porque pueden confundirse con métodos de traits estándar.

**Fixes aplicados:**
| Cambio | Archivo | Descripción |
|--------|---------|-------------|
| `from_str` → `parse_type` | parser/ast.rs | Evita confusión con `std::str::FromStr` |
| `eq` → `equals` | parser/ast.rs | Evita confusión con `std::cmp::PartialEq::eq` |
| Box en `Index` variant | parser/ast.rs | Reduce tamaño de `AssignmentTarget` de 240b a ~24b |
| Type alias | main.rs | Simplifica tipo de retorno complejo |

**Resultado:** 67 warnings → 0 warnings (100% clean)

**Status**: ✅ RESOLVED (Mayo 2026)

---

## 🚨 CRITICAL ISSUES (Abril 2026)

### C1 - DefaultHasher en Cache Incremental

**Descripción:**
`DefaultHasher` usa internas aleatorias (rand seed) que cambian entre ejecuciones de proceso. Esto invalida:
- `stable_statement_hash` - cache de análisis nunca es válido entre procesos
- `source_hash` - cache de archivos siempre falla entre ejecuciones

**Fix Aplicado:**
- Implementado `FxHasher` (FNV-1a) determinista en `src/incremental.rs:17-70`
- Reemplazado `DefaultHasher::new()` por `FxHasher::new()` en:
  - `source_hash()` (línea ~880)
  - `build_fingerprint()` (línea ~890)
  - `stable_statement_hash()` (línea ~2110)

**Verificación:**
- Tests pasan: 74/74 ✅
- Cache funciona entre procesos separados ✅

**Status:** ✅ RESOLVED (Mayo 2026)

### C2 - strings.split Retorna String Concatenada

**Descripción:**
`mire_strings_split` en `runtime_support.c` retornaba una string plana con espacios en vez de una lista. Esto rompía completamente `strings.split`.

**Fix Aplicado:**
- `mire_strings_split_list` ahora usa parser lineal con `strstr` (sin `strtok`):
  - soporta delimitadores multi-caracter correctamente
  - preserva segmentos vacíos (`"a,,b,"` -> `["a", "", "b", ""]`)
  - evita copia mutable completa del input y reduce overhead
- `compile_split` en `avenys/mod.rs` llama a `mire_strings_split_list` y retorna lista nativa
- Actualizado type checker para devolver `DataType::List` para `strings.split` (typeck.rs)

**Verificación:**
```mire
set parts = strings.split("a,b,c" ",")
set joined = strings.join(parts "-")  # "a-b-c" ✅
```
- Regresiones añadidas:
  - delimitador multi-caracter (`"--"`)
  - preservación de vacíos en split

**Status:** ✅ RESOLVED (Mayo 2026)

### C3 - strings.split Falla en Codegen

**Descripción:**
El backend `avenys/mod.rs` retorna `Err(Backend)` correctamente para `strings.split`, pero la feature no está implementada.

**Ubicación:** `src/avens/mod.rs:1469-1483`

**Status:** ✅ RESOLVED (Mayo 2026) - Ahora funciona correctamente

---

## 🟠 REAL BUGS (Abril 2026)

### B1 - latest_successful_analysis Usa last_access

**Descripción:**
`latest_successful_analysis` seleccionaba por `last_access_epoch_ms` (tiempo de acceso) en vez de timestamp de creación. Puede retornar análisis de una versión anterior del código si un archivo fue accedido recientemente.

**Fix Aplicado:**
- Añadido campo `created_epoch_ms` a `AnalysisCacheEntry` (incremental.rs:287)
- Actualizada lógica de `latest_successful_analysis` para usar `created_epoch_ms` (incremental.rs:748)
- Añadido fallback para cache antiguo: si `created_epoch_ms == 0`, usa `last_access_epoch_ms` (incremental.rs:1106-1116)
- Actualizado serialización/deserialización del cache

**Verificación:**
- Tests: 74/74 ✅
- Ahora selecciona por timestamp de creación, no de acceso

**Status:** ✅ RESOLVED (Mayo 2026)

### B2 - semantic_binding con Nombres Duplicados en Scopes

**Descripción:**
`semantic_binding` busca por `scope_depth` pero puede retornar el binding incorrecto cuando hay nombres duplicados en scopes distintos. Afecta `check_call_argument` para tipos movibles.

**Investigación (Mayo 2026):**
- El lenguaje NO permite shadowing con `set x = ...` - el parser/type checker rechaza esta sintaxis
- Probado: `set x = "outer"` → `set x = "inner"` produce error "Cannot reassign immutable variable"
- El código usa `scope_depth` para filtrar, lo cual funciona correctamente para el caso real
- Verificación: `process(value value)` para tipo movible produce el error esperado "Use after move"

**Status:** ✅ NOT REPRODUCIBLE - El lenguaje previene las condiciones que causarían este bug

### B3 - ensure_return_is_safe y Scope IDs

**Descripción:**
Puede no detectar ref escapes si los scope IDs del modelo semántico no alinean con el checker.

**Ubicación:** `src/compiler/borrowck.rs:711-732`

**Verificación (Mayo 2026):**
- Se añadió test de regresión para método `impl` que retorna referencia a binding local temporal.
- El checker rechaza correctamente el escape con error `Borrow outlives owner scope`.
- Test: `rejects_returning_reference_to_local_from_impl_method` en `src/compiler/borrowck.rs`.

**Status:** ✅ RESOLVED (Mayo 2026)

---

## 🟡 COMPORTAMIENTO INCORRECTO / DEUDA TÉCNICA

### D1 - prune_lru No Incluye Builds

**Descripción:**
`prune_lru` solo contaba `files` y `analyses`, no incluía builds. El mapa de builds crece sin límite.

**Fix Aplicado:**
- Añadido `CacheVictim::Build` al enum
- Actualizado `prune_lru` para incluir `self.db.builds.len()` en el conteo
- Añadido manejo de `CacheVictim::Build` en la eviction

**Verificación:**
- Tests: 74/74 ✅

**Status:** ✅ RESOLVED (Mayo 2026)

### D2 - Blob Store Sin Compactación

**Descripción:**
El archivo `.cache/incremental.bin` crece indefinidamente aunque haya pocas entradas activas. El blob store appende datos sin liberar los offsets huérfanos cuando las entradas de cache se eliminan.

---

## Análisis Técnico (Mayo 2026)

### Estructura Actual

```rust
// incremental.rs:305-313
enum BlobStore {
    Owned(Vec<u8>),                    // En memoria
    Mapped {                          // Memory-mapped desde archivo
        mapping: MemoryMappedFile,
        layout: BlobStoreLayout,       // { start: usize, len: usize }
    },
}
```

Cada entrada de cache (File, Analysis, Build) almacena:
- `blob_offset: u64` - posición en el blob store
- `blob_len: u64` - tamaño del dato

### Cómo Funciona el Append

```rust
// incremental.rs:346-349
fn append(&mut self, blob: &[u8]) -> (u64, u64) {
    let store = self.ensure_owned();
    append_blob(store, blob)  // Returns (offset, len)
}
```

```rust
// incremental.rs:1171-1176
fn append_blob(blob_store: &mut Vec<u8>, blob: &[u8]) -> (u64, u64) {
    let offset = blob_store.len() as u64;
    blob_store.extend_from_slice(blob);  // Solo append, nunca limpia
    (offset, blob.len() as u64)
}
```

### El Problema

1. Cuando se guarda un análisis, se追加 nuevos datos al blob store
2. Si el análisis se invalida (por cambio en código fuente), `prune_lru` elimina la entrada de `db.analyses`
3. PERO el blob store NUNCA se compacta - los datos huérfanos quedan ahí
4. Con el tiempo, el archivo crece aunque la cantidad real de datos útiles sea pequeña

### Código Relevante

| Archivo | Línea | Función/Variable | Descripción |
|---------|-------|------------------|-------------|
| incremental.rs | 305 | `BlobStore` enum | Tipos de almacenamiento |
| incremental.rs | 346 | `BlobStore::append` | Añade datos sin compactar |
| incremental.rs | 520 | `load()` → `blob_store` | Carga el blob store completo |
| incremental.rs | 538 | `save()` → `encode_cache_db` | Guarda blob tal cual |
| incremental.rs | 601, 673, 711 | `blob_store.append()` | Todos los lugares que añaden datos |
| incremental.rs | 1023 | `encode_cache_db()` | Serializa blob sin procesar |
| incremental.rs | 1093 | Lectura de cache | Lee `blob_offset` y `blob_len` |

### Tracking de Offsets

Para implementar compactación, necesitas rastrear qué offsets están en uso:

```rust
// Estructura sugerida para tracking:
struct BlobRef {
    offset: u64,
    len: u64,
}

// En cada CacheDb entry, ya se tiene:
struct AnalysisCacheEntry {
    blob_offset: u64,
    blob_len: u64,
    // ...
}
```

### Posibles Soluciones

**Opción 1: Compactación al Guardar (más simple)**
- Antes de `save()`, reconstruir el blob store con solo entradas válidas
- Ventaja: Código simple
- Desventaja: Puede ser lento con mucho datos

**Opción 2: GC incremental (más complejo)**
- Mantener un mapa de offsets válidos
- Compactar cuando la proporción huérfanos > 70%

**Opción 3: Sistema de generaciones**
- Usar IDs de generación y limpiar generaciones antiguas

### Pasos para Implementar

1. **Crear función de compactación**:
```rust
fn compact_blob_store(
    db: &CacheDb,
    blob_store: &[u8]
) -> Vec<u8> {
    // 1. Recolectar todos los offsets usados
    // 2. Crear nuevo blob solo con datos válidos
    // 3. Actualizar todos los blob_offset en db entries
    // 4. Retornar nuevo blob y mappings
}
```

2. **Invocar en save()**:
```rust
pub fn save(&mut self) -> Result<()> {
    self.prune_lru();
    
    // Añadir compactación si hay muchos huérfanos
    let used = self calculate_used_offsets();
    let total = self.blob_store.len();
    if total > 1024 * 1024 && (used as f64 / total as f64) < BLOB_COMPACT_THRESHOLD_RATIO {
        self.compact_blob_store();
    }
    
    let raw = encode_cache_db(&self.db, self.blob_store.bytes())?;
    // ...
}
```

3. **Actualizar formato de versión** (ya hecho: CACHE_FORMAT_VERSION = 4)

### Tests a Crear

- Test que verifique crecimiento del blob store con muchas invalidaciones
- Test de compactación automática
- Test de restauración después de compactación

**Implementación (Mayo 2026):**
- Se añadió compactación automática del blob store cuando la densidad útil cae por debajo de 70%.
- La compactación actualiza offsets en `db.files` y `db.analyses` para mantener consistencia.
- Se agregó test rápido de regresión:
  `blob_store_compacts_when_sparse_after_overwrites` en `src/incremental.rs`.
- También se redujo el umbral mínimo para activar compactación en blobs medianos.
- Optimización adicional: compactación por rangos vivos fusionados (evita sobrecontar bytes vivos)
  y remapeo correcto de offsets internos en rangos compactados.
- Regresión adicional:
  `blob_store_compaction_preserves_offsets_inside_merged_ranges` en `src/incremental.rs`.

**Status:** ✅ RESOLVED (Mayo 2026)

### D3 - to_upper/to_lower Solo ASCII

**Status:** ✅ RESOLVED (Mayo 2026)
- Implementadas funciones `mire_unicode_to_lower`/`mire_unicode_to_upper`
- Manejan Latin-1: À-Ö (192-214), Ø-Þ (216-222) / à-ö (224-246), ø-þ (248-254)
- No incluye acentos (documentado como limitación)

---

## Análisis Técnico (Mayo 2026)

### Ubicación del Código

```c
// runtime_support.c:830-844
char *mire_string_to_upper(const char *value) {
    // ...
    for (size_t i = 0; i < len; i++) {
        // Solo maneja rango ASCII
        result[i] = (value[i] >= 'a' && value[i] <= 'z') 
            ? (value[i] - 32)  // Convierte a mayúscula ASCII
            : value[i];
    }
    // ...
}

// runtime_support.c:846-860 - Similar para to_lower
```

### Problema

Para convertir "ño" a mayúsculas:
- 'ñ' = 0xF1 (Latin-1) o 0xC3B1 (UTF-8)
- El código actual NO reconoce estos bytes
- Retorna el carácter sin cambios o podría causar garbage

### Solución Propuesta

UsarICU o implementar Unicode handling básico:

```c
// Opción 1: Implementar básica para Latin-1
char *mire_string_to_upper_latin1(const char *value) {
    // Manejar: á->Á, é->É, í->Í, ó->Ó, ú->Ú, ñ->Ñ, ü->Ü
}

// Opción 2: Usar biblioteca externa (ej. libunistring)

// Opción 3: Limitar a ASCII documentado (actual)
```

### Código Relevante

| Archivo | Línea | Descripción |
|---------|-------|-------------|
| runtime_support.c | 830-844 | `mire_string_to_upper` |
| runtime_support.c | 846-860 | `mire_string_to_lower` |
| avens/mod.rs | 3335-3375 | Compilación LLVM |
| typeck.rs | 353-354 | Registro de tipos |

### Impacto

- **Usuario**: Strings como "Hola Mundo" funcionan, pero "ánimo" → "áNIMO" (incorrecto)
- **Severity**: Baja - solo afecta casos edge con acentos

### Tests Existentes

```bash
# Ejecutar y verificar con acentos
./target/release/mire run tests/complex/math/02_string_math.mire
# Output actual: HOLA MUNDO → HOLA MUNDO (correcto)
# Input con acentos: "ánimo" → resultado incorrecto
```

**Status:** ✅ RESOLVED (Mayo 2026)
- Removido `mire_strdup_raw` innecesario en branch MAP
- `mire_dict_to_string` retorna memoria managed que se libera automáticamente

---

### D4 - Memory Leak en mire_dict_format_value

**Status:** ✅ RESOLVED (Mayo 2026)
- Bug fix: removido strdup redundante
- No hay más leak de memoria para tipos MAP
- Verificado con test de ejecución rápida:
  `nested_map_string_render_executes_without_runtime_errors` (`tests/language_regressions.rs`)
- Continuación D4 (runtime output): corregido `dasu(map)` para usar `mire_dict_to_string`
  y corregida liberación de `repr` temporales (managed vs raw) en `mire_dict_to_string`.
- Regresión reforzada: el test ahora exige presencia de `child`, `x`, `y` en salida.

**Descripción (histórico):**
`mire_dict_format_value` para tipos MAP (línea 933) tenía leak:
```c
if (kind == MIRE_KIND_MAP) {
    return mire_strdup_raw(mire_dict_to_string(...));  // Leak: interno no se libera
}
```

---

## Análisis Técnico (Mayo 2026)

### El Bug

```c
// runtime_support.c:932-933
if (kind == MIRE_KIND_MAP) {
    // PROBLEMA: mire_dict_to_string retorna string allocado con mire_managed_alloc
    // luego mire_strdup_raw hace otro malloc + copy
    // pero el string ORIGINAL de mire_dict_to_string NUNCA se libera
    return mire_strdup_raw(mire_dict_to_string(mire_dict_read_ptr(dict, entry_index)));
}
```

```c
// mirar lo que hace mire_dict_to_string (línea 1052+):
// Retorna resultado de mire_managed_alloc, que es memoria gestionada
// Pero al llamar mire_strdup_raw se hace otro malloc y el original se pierde
```

### Cómo Verificar

```c
// Agregar logging o usar valgrind:
// valgrind --leak-check=full ./target/release/mire run test.mire
```

### Fix Sugerido

```c
// Opción 1: No usar mire_strdup_raw, retornar lo de mire_dict_to_string directamente
if (kind == MIRE_KIND_MAP) {
    return mire_dict_to_string(mire_dict_read_ptr(dict, entry_index));
}

// Opción 2: Liberar el string interno si no se usa
if (kind == MIRE_KIND_MAP) {
    char *inner = mire_dict_to_string(mire_dict_read_ptr(dict, entry_index));
    char *result = mire_strdup_raw(inner);
    mire_string_free(inner);  // Si hay función para liberar
    return result;
}
```

### Llamadores de esta función

```c
// Línea 1061: mire_dict_to_string usa mire_dict_format_value para cada valor
// Línea 1076: también en el segundo loop de mire_dict_to_string
```

### Impacto (histórico)

- Afectaba `use dasu(dict)` con valores MAP anidados.
- Queda cerrado tras remover `mire_strdup_raw(...)` redundante en el branch MAP.

---

### D5 - &mut x No Requiere Que x Sea Mutable

**Descripción:**
El compilador permite `set rx = &x` donde `x` no es `mut`. Ej.:
```mire
set x = 5 :i64        # x no es mutable
set rx = &x           # shared ref (correcto)

set m = 5 :i64 mut
set rm = &m           # mutable ref inferida (correcto)
```

**Implementación (Mayo 2026):**
- `&x` ahora deriva mutabilidad desde el binding original:
  - si `x` es `mut` => referencia mutable
  - si `x` no es `mut` => referencia compartida
- Se mantiene validación explícita: `&mut x` sobre `x` inmutable produce error.
- Tests rápidos añadidos en `src/compiler/typeck.rs`:
  - `mutable_binding_reference_is_inferred_as_refmut`
  - `immutable_binding_reference_is_inferred_as_shared_ref`
  - `explicit_mut_reference_rejected_for_immutable_binding`

**Status:** ✅ RESOLVED (Mayo 2026)

---

## ℹ️ DISEÑO / MANTENIMIENTO

### M1 - stable_statement_hash Serializa a JSON

**Descripción:**
`stable_statement_hash` serializa a JSON completo antes de hashear. Costoso para statements grandes; podría hashearse estructuralmente.

```rust
// Línea 2056: serialización innecesaria
let serialized = serde_json::to_vec(statement).unwrap_or_default();
let mut hasher = DefaultHasher::new();
serialized.hash(&mut hasher);
```

**Mejora aplicada (Mayo 2026):**
- `stable_statement_hash` ahora hashea en streaming con `serde_json::to_writer` hacia un writer sobre `FxHasher`.
- Se elimina el buffer intermedio `Vec<u8>` para cada statement, reduciendo presión de RAM.

**Status:** ✅ IMPROVED (Mayo 2026)

### M2 - TYPE_CHECKER_SOURCE como thread_local

**Descripción:**
`TYPE_CHECKER_SOURCE` como thread_local en typeck causa estado implícito, dificulta razonamiento.

**Implementación (Mayo 2026):**
- Eliminado `thread_local TYPE_CHECKER_SOURCE` en `typeck.rs`.
- El contexto de fuente ahora vive en `TypeChecker` (`base_source`) y se adjunta explícitamente vía `attach_current_context`.
- `check_program_types` y `check_program_types_partial_with_origins` inicializan el checker con fuente explícita.
- Se mantiene el comportamiento de diagnóstico (línea/columna + source) sin estado global implícito.

**Status:** ✅ RESOLVED (Mayo 2026)

---

## ✅ VERIFIED FIXES (Lo que YA estaba corregido)

| Fix | Archivo | Estado |
|-----|---------|--------|
| udiv/urem → sdiv/srem | runtime_support.c | ✅ VERIFICADO |
| i8* → ptr en list literal | avens/mod.rs | ✅ VERIFICADO |
| @malloc con i64 en compile_input_expr | avens/mod.rs | ✅ VERIFICADO |
| Stubs silenciosos → Err(Backend) | avens/mod.rs | ✅ VERIFICADO |
| strings.join con count=0 | runtime_support.c | ✅ VERIFICADO |
| Duplicado de lists.push en dispatch | avens/mod.rs | ✅ VERIFICADO |
| Parser: subparser_from_slice sin contexto nominal | parser/mod.rs | ✅ VERIFICADO |
| Parser: } final del match | parser/mod.rs | ✅ VERIFICADO |
| Parser: shorthand Ok(v) ambiguo | parser/mod.rs | ✅ VERIFICADO |
| Parser: visibilidad consumida dos veces | parser/mod.rs | ✅ VERIFICADO |
| Parser: for i, j silencioso → error | parser/mod.rs | ✅ VERIFICADO |
| Typeck: validate_int_literal_range | compiler/typeck.rs | ✅ VERIFICADO |
| Typeck: unify_types para referencias | compiler/typeck.rs | ✅ VERIFICADO |
| Typeck: segundo lookup duplicado | compiler/typeck.rs | ✅ VERIFICADO |
| Typeck: bind_struct_name con data_type | compiler/typeck.rs | ✅ VERIFICADO |

---

## 📊 COBERTURA DE TESTS

| Categoría | Tests | Estado |
|-----------|-------|--------|
| level/beginner | 5 | ✅ Passing |
| level/intermediate | 5 | ✅ Passing |
| level/advanced | 2 | ✅ Passing |
| type/structs | 2 | ✅ Passing |
| type/enums | 2 | ✅ Passing |
| type/collections | 2 | ✅ Passing |
| type/primitives | 1 | ✅ Passing |
| complex/algorithms | 9 | 7 ✅, 2 ⚠️ |
| complex/data_structures | 14 | 11 ✅, 3 ⚠️ |
| complex/math | 2 | ✅ Passing |
| edge/arrays | 4 | ✅ Passing |
| edge/loops | 3 | ✅ Passing |
| edge/recursion | 1 | ✅ Passing |
| edge/error_handling | 1 | ✅ Passing |
| behavior/typeck | 2 | ✅ Passing |
| behavior/borrowck | 3 | ✅ Passing |
| modules | 1 | ✅ Passing |
| **Total** | **74** | **74 ✅, 0 ❌** |

---

## 🎯 PRIORIDADES REALES (ABIERTAS)

No hay issues críticas/medias abiertas en este documento al corte actual.

### Siguientes objetivos recomendados
1. Benchmarks dedicados para `analysis_units_for_program` y rutas calientes de invalidación incremental.
2. Hardening extra de cache: casos de corrupción truncada con fuzzing/light property tests.
3. Separar este documento en `open-issues.md` + `resolved-history.md` para reducir ruido operativo.
