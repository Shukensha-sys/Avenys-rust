## Estado de Avenys (Actualizado Mayo 2026)

### Benchmarks - Resultados:

| Benchmark | Compile | Run | Python | Speedup |
|-----------|---------|-----|--------|---------|
| flow_stress | 119ms | 3.5ms | 425ms | **121x faster** |

### Lo que FUNCIONA en Avenys:

**Sintaxis básica:**
- Funciones: `fn`, `pub fn`
- Variables: `set x = 10 :i64`
- Operadores binarios: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `>`, `<`, `>=`, `<=`
- Operadores lógicos: `and`, `or` (keywords)
- Unarios: `-` (negación numérica)
- Bucles: `while`, `for in range()`, `do...while`
- Condicionales: `if...else`
- Control: `break`, `continue`, `return`
- Output: `use dasu("...")` para texto literal, o `use dasu(valor)` para expresiones
- Imports: `import time as time`

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

- `not` como unary operator (usar `if a == false` como workaround)
- Match con comparación directa: `match x >= 5` (usar variable intermedia)
- Struct field reassignment: `c.value = 1` (crear nuevo struct)
- `&&` / `||` operators (usar `and` / `or` keywords)
- `!` operator (no soportado)
- `vec[vec[T]]` - no conserva tipo interno en todas las rutas
- Member access avanzado
- Semántica profunda de traits/skills más allá de conformance directa
- Algunas rutas de builtins son stubs (`split`, `join`, `to_upper`, `to_lower`, `trim`)

### Lo que ya funciona en la práctica:

- `mem.format()` y `mem.process()`
- `lists.push()` y `lists.get()` para rutas numéricas
- `math.sum()`
- Diccionarios dinámicos `map[str i64]` con `dicts.get()` y `dicts.set()`
- Indexación con `value at index`
- Arrays anidados `arr[arr[i64 N] M]`
- Structs nominales, enums nominales, `impl` y `match`
- `if` como expresión con tipo unificado entre ramas
- Closures en pipelines
- Benchmarks reales de:
  - vectores
  - mapas
  - arrays anidados

### Tipos soportados en LLVM:

- `i64` (int)
- `i1` (bool)
- `ptr` (strings, listas - como punteros)

### Propuestas de sintaxis para implementar:

1. **`not` unary operator:** Implementar para consistencia con `and`/`or`
   - Opción A: keyword `not` como unary
   - Opción B: `@!` prefix style

2. **Match con comparación:** Modificar parser para aceptar expresiones en match condition

3. **Struct field reassignment:** Implementar setter semántico para fields mutables