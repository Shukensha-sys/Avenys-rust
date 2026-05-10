## Estado de Avenys (Actualizado Mayo 2026)

### Version: v2.5.6

### Nuevo: std.mire
- Archivo de Standard Library disponible: `std.mire`
- Contains todas las funciones estándar organizadas por categorías
- Uso con imports de la forma:
  ```
  import std
  
  use std.time.mark()
  use std.lists.push(list 1)
  use std.strings.upper("hello")
  ```
- Categories: MATH, LISTS, STRINGS, DICTS, TIME, TERM, MEM, CPU, GPU, FS, ENV, PROC

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
- For-loop con índice secundario: `for item, index in range(n)`

### Lo que NO funciona o sigue incompleto:

- (Actualizado 2026-05-04) Sin pendientes abiertos en:
  - Float arithmetic `x + 1.5` con variables `:f32/:f64`
  - Conservacion de tipo interno en `vec[vec[T]]` durante inferencia/asignacion/push
- (Actualizado 2026-05-10) Estado backend:
  - `extern fn` ahora emite `declare` LLVM (pendiente: linking ABI completo por plataforma).
  - `asm` ya no es no-op: emite inline asm mínimo (`asm sideeffect`).
  - Resueltos builtins críticos: `list.pop`, `contains/strings.contains`, `sqrt`, `strings.substr`, `strings.pad_left`, `strings.pad_right`, `strings.repeat`.
  - `for` ya soporta `range(...)` y también `list/vector/slice`.
  - Pendiente principal: `range` como valor de primera clase completo (hoy con representación placeholder).

### ✅ Backend Coverage (v2.5.6)
- `compile_statement` ya no falla con catch-all para declaraciones frontend-only:
  `Type`, `Skill`, `Code`, `Class`, `Trait`, `Impl`, `Enum`, `AddLib`, `Module`, `Dmire*`, `Query`, `Find`, `Drop`, `Move`.
- `compile_expr` ahora baja literales compuestos:
  `Literal::List`, `Literal::Dict`, `Literal::Tuple`.
- Builtins `strings.*` cableados adicionales:
  - `strings.contains`
  - `strings.concat`
  - `strings.len`
  - `strings.strip`
  - `strings.ltrim`
  - `strings.rtrim`
  - `strings.is_empty`
- `map_type` amplió soporte para tipos frontend antes no mapeados:
  `Function`, `Db`, `Datetime`, `Box`, `DynTrait`, `Result`.

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

### Estado de sintaxis (actualizado 2026-05-04)

Implementado:

1. Literales numéricos prefijados: `0b`, `0o`, `0x`
2. Raw strings con delimitadores: `r"..."`, `r#"..."#`, `r##"..."##`
3. Character literals con tipo `char` (Unicode scalar `u32`)

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
