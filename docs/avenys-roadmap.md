## Estado de Avenys (Actualizado)

### Benchmarks - Resultados:

| Benchmark | Compile | Run | Python | Speedup |
|-----------|---------|-----|--------|---------|
| flow_stress | 119ms | 3.5ms | 425ms | **121x faster** |

### Lo que FUNCIONA en Avenys:

**Sintaxis básica:**
- Funciones: `fn`, `pub fn`
- Variables: `set x = 10 :i64`
- Operadores: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `>`, `<`, `>=`, `<=`, `and`, `or`
- Unarios: `-`, `not`
- Bucles: `while`, `for in range()`, `do...while`
- Condicionales: `if...else`
- Control: `break`, `continue`, `return`
- Output: `use dasu(...)` (texto sin comillas)
- Imports: `import time as time`

**Builtins implementados en LLVM:**
- `time.mark()` - marca de tiempo
- `time.elapsed_ms(start)` - tiempo transcurrido en ms
- `mem.format(bytes)` - formatear bytes (stub)
- `mem.process()` - memoria del proceso (stub)
- `lists.push(list, value)` - añadir a lista (stub)
- `math.sum(list)` - suma (stub)
- `strings.replace(str, old, new)` - reemplazar
- `len(str)` - longitud de string
- `abs()`, `sqrt()`, `pow()`, `floor()`, `ceil()`, `round()`
- `min()`, `max()` - comparación
- `range(n)` - generación de rango

**Llamadas a funciones de módulos:**
- `module.function(args)` - soportado (ej: `time.mark()`)

### Lo que NO funciona o sigue incompleto:
- `vec[vec[T]]` todavía no conserva suficientemente bien el tipo interno en todas las rutas
- Member access avanzado
- Semántica profunda de traits/skills más allá de conformance directa
- Algunas rutas de builtins siguen siendo stubs secundarios (`split`, `join`, `to_upper`, `to_lower`, `trim`)

### Lo que ya funciona en la práctica:
- `mem.format()` y `mem.process()`
- `lists.push()` y `lists.get()` para rutas numéricas
- `math.sum()`
- Diccionarios dinámicos `map[str i64]` con `dicts.get()` y `dicts.set()`
- Indexación con `value at index`
- Arrays anidados `arr[arr[i64 N] M]`
- Structs nominales, enums nominales, `impl` y `match`
- `if` como expresión con tipo unificado entre ramas
- Benchmarks reales de:
  - vectores
  - mapas
  - arrays anidados

### Tipos soportados en LLVM:
- `i64` (int)
- `i1` (bool)
- `ptr` (strings, listas - como punteros)
