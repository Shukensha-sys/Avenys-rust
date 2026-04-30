## Estado de Avenys (Actualizado Mayo 2026)

### Version: v2.2.0

### Compilation Stats
- **Clippy:** 0 warnings ✅
- **Tests:** 67/67 pasando ✅
- **Speedup vs Python:** 121x faster (flow_stress benchmark)

### Benchmarks - Resultados:

| Benchmark | Compile | Run | Python | Speedup |
|-----------|---------|-----|--------|---------|
| flow_stress | 119ms | 3.5ms | 425ms | **121x faster** |

### Lo que FUNCIONA en Avenys:

**Sintaxis básica:**
- Funciones: `fn`, `pub fn`
- Variables: `set x = 10 :i64`
- Operadores binarios: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `>`, `<`, `>=`, `<=`
- Operadores lógicos C-style: `&&`, `||`, `^` (XOR)
- Unarios: `-` (negación numérica), `!` (NOT lógico)
- Bucles: `while`, `for in range()`, `do...while`
- Condicionales: `if...else`
- Control: `break`, `continue`, `return`
- Output: `use dasu("...")` para texto literal, o `use dasu(valor)` para expresiones
- Imports: `import time as time`

**Operadores lógicos (v2.1.0):**
- `&&` - AND lógico con short-circuit evaluation
- `||` - OR lógico con short-circuit evaluation
- `!` - NOT lógico (unary)
- `^` - XOR lógico

**Short-circuit evaluation:**
```mire
# &&: Si LHS es false, RHS no se evalúa
if a && expensive_check() { }

# ||: Si LHS es true, RHS no se evalúa
if a || expensive_check() { }
```

**Builtins implementados en LLVM:**
- `time.mark()` - marca de tiempo
- `time.elapsed_ms(start)` - tiempo transcurrido en ms
- `mem.format(bytes)` - formatear bytes (stub)
- `mem.process()` - memoria del proceso (stub)
- `lists.push(list, value)` - añadir a lista
- `lists.get(list, index)` - obtener elemento
- `math.sum(list)` - suma
- `strings.replace(str, old, new)` - reemplazar
- `len(str)` - longitud de string
- `abs()`, `sqrt()`, `pow()`, `floor()`, `ceil()`, `round()`
- `min()`, `max()` - comparación
- `range(n)` - generación de rango

**Llamadas a funciones de módulos:**
- `module.function(args)` - soportado (ej: `time.mark()`)

**Features avanzadas:**
- Closures en pipelines: `nums => (x => x * 2)`
- Arrays en struct fields: `struct Stack { items :arr[i64 10] }`
- Match multilínea
- Struct field access en impl methods

### Lo que NO funciona o sigue incompleto:

- Float arithmetic `x + 1.5` - type unification issues between literal floats and typed floats
- `vec[vec[T]]` - no conserva tipo interno en todas las rutas

### ✅ Resuelto en v2.2.0:
- Float literals: `3.14`, `3.14 :f64` ✅
- str(f64): `str(3.14 :f64)` → "3.14" ✅
- Struct field reassignment: `c.value = 1` ✅ (requiere `set`)
- Bitwise operators: `&`, `|`, `<<`, `>>` ✅
- Reference lowering con parámetros tipados: `fn read_ref: (value :&i64) :i64` ✅

### Issues Críticos Pendientes:

**✅ CR1-CR3: Borrow Checker & Semantic Model - RESUELTOS (Mayo 2026)**
- CR1: Scope lexical filtrado correctamente en `borrowck.rs` ✅
- CR2: Métodos en Impl/Class ahora registrados en `semantic.rs` ✅
- CR3: `unsafe` procesado con `unsafe_depth` correctamente ✅

**✅ T1-T3: Type Checking - RESUELTOS (Mayo 2026)**
- T1: Member access con error claro cuando no se encuentran fields/methods ✅
- T2: Pipeline typing mejorado con elem_type como fallback ✅
- T3: Referencias ahora almacenan tipo detallado (`referenced_type: DataType`) ✅

**🆕 T4: Reference Type Unification - RESUELTO (Mayo 2026)**
- `unify_types`: permite `&T` ↔ `T` con auto-unwrap
- `is_assignable`: permite `&T` → `T` con auto-deref
- Soporta `&T` ↔ `&T` y `&mut T` ↔ `&T`/`&mut T`
- Fix: `shared_reference_lowering_compiles_and_runs` ahora pasa

### Lo que ya funciona en la práctica:

- `mem.format()` y `mem.process()`
- `lists.push()` y `lists.get()` para rutas numéricas
- `lists.fold()`, `lists.map()` y `lists.filter()` con closures inline
- `math.sum()`
- Diccionarios dinámicos `map[str i64]` con `dicts.get()` y `dicts.set()`
- Indexación con `value at index`
- Arrays anidados `arr[arr[i64 N] M]`
- Structs nominales, enums nominales, `impl` y `match`
- `if` como expresión con tipo unificado entre ramas
- Closures en pipelines
- Operadores lógicos con short-circuit
- Benchmarks reales de:
  - vectores
  - mapas
  - arrays anidados

### Alcance actual a documentar bien:

- Los HOF de listas ya funcionan en Avenys con closures inline del estilo `(x) => ...` y `(acc elem) => ...`
- La inferencia de tipos de parámetros ya no requiere anotaciones explícitas en `fold/map/filter`
- Lo que sigue pendiente no es el lowering de HOF, sino generalizar callbacks de primer nivel más allá de closures inline

### Tipos soportados en LLVM:

- `i64` (int)
- `i1` (bool)
- `ptr` (strings, listas - como punteros)

### Propuestas de sintaxis para implementar:

1. **Struct field reassignment:** Implementar setter semántico para fields mutables

2. **Bitwise operators:** `&`, `|`, `<<`, `>>` (pendientes de implementación)

### Migración de v1.x a v2.x:

```mire
# ANTIGUO (v1.x):
if a and b { }
if a or b { }
if not a { }

# NUEVO (v2.x):
if a && b { }
if a || b { }
if !a { }
```

Los keywords `and`, `or`, `not` fueron eliminados en v2.1.0.
