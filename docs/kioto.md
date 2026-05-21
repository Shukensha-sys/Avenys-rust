# Kioto

**Kioto** es la biblioteca estándar oficial de Mire.

Es una biblioteca **escrita en Mire** que expone APIs funcionales, multiplataforma y ergonómicas para el desarrollo de aplicaciones y herramientas (como Owl).

Kioto no está acoplada al compilador. No tiene entrada especial en el typechecker, no tiene registros hardcodeados en el backend, y no requiere cambios en el pipeline de compilación. Es simplemente código Mire que —cuando hace falta— declara bindings nativos via `extern fn`.

Conceptualmente, Kioto es a Mire lo que libc es a C: la plataforma.

---

## Filosofía

1. **Kioto es una biblioteca, no parte del compilador.**  
   No debe haber código de Kioto en `typeck.rs`, `runtime_support.c`, ni en el loader (salvo la mecánica genérica de `import`).

2. **Kioto envuelve builtins existentes sin reemplazarlos.**  
   Los builtins del compilador (`fs_read`, `dasu`, `lists.push`, etc.) siguen existiendo y funcionando. Kioto los documenta como internos y deja de recomendarlos, pero **no los elimina** para no romper compatibilidad.

3. **Kioto prioriza ergonomía, APIs reales y tooling usable.**  
   Pureza, bootstrap y colecciones puras vienen después de tener APIs estables que Owl y otras herramientas puedan usar hoy.

4. **Kioto es modular y explícito.**  
   No hay re-export masiva. Cada sub-módulo se importa explícitamente:
   ```
   import kioto: (fs env proc)
   ```

5. **Kioto es multiplataforma.**  
   El objetivo es ejecutar código Mire en todo lo que LLVM IR permite compilar. La capa de abstracción de plataforma se construye progresivamente.

---

## Sintaxis de uso

| Contexto | Sintaxis | Estado |
|----------|----------|:------:|
| Import | `import kioto: (fs env proc)` | ✅ |
| Import completo | `import kioto` (carga `lib.mire` mínimo) | ✅ |
| Llamada como statement | `use kioto::fs::read("file")` | ✅ |
| Llamada como expresión | `set x = kioto::fs::read("file")` | ✅ |
| Compatibilidad legacy | `use fs.read("file")` (con `import kioto: (fs)`) | ✅ |
| Binding | `set content = kioto::fs::read("path")` | ✅ |
| Métodos | `list.push(42)` | ✅ |

Las llamadas recomendadas de Kioto usan `::` como separador de namespace:

```
use kioto::fs::read("/etc/config.toml")
use kioto::time::sleep_ms(500)
set files = kioto::fs::list("/tmp")

# Compatibilidad mantenida (legacy)
use fs.read("/etc/config.toml")
```

Los imports usan la sintaxis actual con `:` y paréntesis:

```
import kioto: (fs env time proc)
import kioto
```

---

## Estructura de módulos

```
src/modules/kioto/
├── lib.mire          # Metadata, versión, constantes, platform detect
├── fs.mire           # Operaciones de archivos y directorios
├── env.mire          # Variables de entorno y argumentos
├── time.mire         # Tiempo de sistema, marcas, pausas
├── term.mire         # Terminal: colores, estilos, líneas
├── proc.mire         # Procesos hijo, shell, señales
├── mem.mire          # Memoria del sistema
├── cpu.mire          # CPU: frecuencia, conteo, carga
├── math.mire         # Matemáticas: pure + intrinsic (híbrido)
├── strings.mire      # Manipulación de cadenas
├── lists.mire        # Funcional/alta sobre listas (no reemplazo de builtins)
└── dicts.mire        # Funcional/alta sobre diccionarios (no reemplazo de builtins)
```

### `lib.mire` — Punto de entrada

Mínimo. Sin re-export de sub-módulos. Solo metadata, versión, constantes y helpers pequeños.

```
pub const VERSION = "0.1.0"

pub fn version: () :str {
    return VERSION
}

pub fn platform: () :str {
    return __kioto_platform()
}
```

### `fs` — Archivos y directorios

Envuelve builtins existentes (`fs_read`, `fs_write`, etc.).

```
kioto::fs::read(path)       -> str
kioto::fs::write(path, data)
kioto::fs::append(path, data)
kioto::fs::exists(path)     -> bool
kioto::fs::size(path)       -> i64
kioto::fs::copy(src, dst)
kioto::fs::move(src, dst)
kioto::fs::drop(path)
kioto::fs::list(path)       -> [str]
kioto::fs::mkdir(path)
kioto::fs::rmdir(path)
kioto::fs::join(a, b)       -> str
kioto::fs::dir(path)        -> str
kioto::fs::name(path)       -> str
kioto::fs::ext(path)        -> str
```

### `env` — Entorno

```
kioto::env::get(key)        -> str
kioto::env::set(key, value)
kioto::env::all()           -> dict
kioto::env::args()          -> [str]
kioto::env::cwd()           -> str
kioto::env::chdir(path)
```

### `time` — Tiempo

```
kioto::time::unix_ms()      -> i64
kioto::time::unix_ns()      -> i64
kioto::time::mark()         -> i64
kioto::time::elapsed(mark)  -> i64
kioto::time::sleep_ms(ms)
```

### `term` — Terminal

```
kioto::term::clear()
kioto::term::style(text, style)  -> str
kioto::term::hr()                -> str
```

### `proc` — Procesos

```
kioto::proc::run(cmd, args)      -> str
kioto::proc::spawn(cmd, args)    -> i64
kioto::proc::shell(cmd)          -> str
kioto::proc::kill(handle)
kioto::proc::wait(handle)        -> i64
kioto::proc::exists(name)        -> bool
kioto::proc::exec(cmd, args)     -> str
```

### `mem` — Memoria

```
kioto::mem::used()          -> i64
kioto::mem::total()         -> i64
kioto::mem::percent()       -> f64
kioto::mem::snapshot()      -> dict
```

### `cpu` — CPU

```
kioto::cpu::count()         -> i64
kioto::cpu::freq_mhz()      -> i64
kioto::cpu::loadavg()       -> dict
kioto::cpu::snapshot()      -> dict
```

### `math` — Matemáticas (híbrido)

**Pure-Mire** (implementadas en Mire, sin builtins):

```
kioto::math::abs(x)         -> i64/f64
kioto::math::min(a, b)      -> i64/f64
kioto::math::max(a, b)      -> i64/f64
kioto::math::clamp(x, lo, hi)
kioto::math::sum(values)    -> i64/f64
kioto::math::avg(values)    -> f64
kioto::math::lerp(a, b, t)  -> f64
kioto::math::sign(x)        -> i64
kioto::math::is_even(x)     -> bool
kioto::math::is_odd(x)      -> bool
```

**Builtin/Intrinsic** (delegan a LLVM/libm):

```
kioto::math::sin(x)         -> f64
kioto::math::cos(x)         -> f64
kioto::math::tan(x)         -> f64
kioto::math::sqrt(x)        -> f64
kioto::math::pow(x, y)      -> f64
kioto::math::round(x)       -> f64
kioto::math::floor(x)       -> f64
kioto::math::ceil(x)        -> f64
kioto::math::log(x)         -> f64
kioto::math::log10(x)       -> f64
kioto::math::exp(x)         -> f64
kioto::math::atan2(y, x)    -> f64
kioto::math::asin(x)        -> f64
kioto::math::acos(x)        -> f64
```

### `strings` — Cadenas

```
kioto::strings::split(s, delim)     -> [str]
kioto::strings::contains(s, sub)    -> bool
kioto::strings::replace(s, from, to) -> str
kioto::strings::upper(s)            -> str
kioto::strings::lower(s)            -> str
kioto::strings::trim(s)             -> str
kioto::strings::ltrim(s)            -> str
kioto::strings::rtrim(s)            -> str
kioto::strings::substr(s, start, len) -> str
kioto::strings::pad_left(s, n, c)   -> str
kioto::strings::pad_right(s, n, c)  -> str
kioto::strings::repeat(s, n)        -> str
kioto::strings::len(s)              -> i64
```

### `lists` — Solo funcional/alto nivel

NO incluye `push`, `pop`, `insert`, `remove`, `len`, `get`, `set`. Esas operaciones pertenecen al runtime/lenguaje y eventualmente serán métodos y traits.

```
kioto::lists::map(list, f)          -> [T]
kioto::lists::filter(list, pred)    -> [T]
kioto::lists::fold(list, init, f)   -> T
kioto::lists::reduce(list, f)       -> T
kioto::lists::find(list, pred)      -> T?
kioto::lists::any(list, pred)       -> bool
kioto::lists::all(list, pred)       -> bool
kioto::lists::chunk(list, n)        -> [[T]]
kioto::lists::zip(a, b)             -> [(A, B)]
kioto::lists::flatten(list)         -> [T]
kioto::lists::reverse(list)         -> [T]
kioto::lists::sort(list)            -> [T]
kioto::lists::unique(list)          -> [T]
kioto::lists::concat(lists)         -> [T]
kioto::lists::slice(list, start, end) -> [T]
```

### `dicts` — Solo funcional/alto nivel

NO incluye `get`, `set`, `has`, `remove`, `delete`. Esas pertenecen al runtime/lenguaje.

```
kioto::dicts::merge(a, b)           -> dict
kioto::dicts::invert(d)             -> dict
kioto::dicts::filter(d, pred)       -> dict
kioto::dicts::map_values(d, f)      -> dict
kioto::dicts::entries(d)            -> [(K, V)]
kioto::dicts::keys(d)               -> [K]
kioto::dicts::values(d)             -> [V]
kioto::dicts::is_empty(d)           -> bool
```

---

## Módulos futuros (fuera de P0)

| Módulo | Dependencia | Fase estimada |
|--------|-------------|:------------:|
| `gpu` | Drivers, CUDA, Vulkan, Metal | P4+ |
| `net` | Sockets, HTTP | P3 |
| `crypto` | Hashing, cifrado | P3 |
| `thread` | Concurrencia | P3 |
| `sync` | Sincronización | P3 |
| `path` | Rutas multiplataforma | P2 |
| `platform` | Detección de OS/arch | P2 |

---

## Prioridades de implementación

| Paso | Módulos | Justificación |
|:----:|---------|--------------|
| **1** | `fs`, `env`, `time`, `term` | Owl necesita leer archivos, entorno, medir tiempo, y mostrar feedback en terminal |
| **2** | `proc`, `mem`, `cpu` | Owl necesita ejecutar procesos hijo y monitorear el sistema |
| **3** | `math` (híbrido) | Utilidad general para cálculos |
| **4** | `strings` | Logging, formateo, manipulación de texto |
| **5** | `lists`, `dicts` | Solo funcional; deliberadamente mínimo y no duplicador |

---

## Estrategia de simplificación de `std`

El módulo `std` actual está acoplado al compilador:
- Sus funciones están hardcodeadas en `typeck.rs` (`builtin_returns`, `import_std_members`)
- Se auto-importa via `__std_all__`
- Sus implementaciones viven en `runtime_support.c` (POSIX)

### Objetivo

Que `std` deje de ser la biblioteca recomendada y pase a ser infraestructura interna del compilador/runtime, mientras Kioto se vuelve la plataforma oficial.

### Pasos

1. **Documentar std como interno.**  
   No se elimina nada. Los builtins siguen existiendo. Pero la documentación y ejemplos usan Kioto, no std.

2. **No crear wrappers duplicadores.**  
   Kioto no envuelve `lists.push` o `dicts.get` — esas son operaciones del lenguaje que eventualmente serán métodos/traits. Kioto solo expone APIs de alto nivel que std no cubre.

3. **Congelar std.**  
   No se añaden nuevas funciones a `builtin_returns` ni a `runtime_support.c` para std. Todo nuevo binding nativo va con nombre `__kioto_*` y se declara via `extern fn` en los módulos de Kioto.

4. **Eventualmente: std opcional.**  
   Cuando Kioto cubra todas las necesidades de Owl y las herramientas, std podrá dejar de auto-importarse o quedar reservado al compilador/runtime. Esto es P5+ y no tiene fecha.

### Mapa de correspondencia std → Kioto

| std actual | Kioto | Nota |
|------------|-------|------|
| `fs_read`, `fs_write`… | `kioto::fs::read`, `write`… | Wrapper directo |
| `env_get`, `env_set`… | `kioto::env::get`, `set`… | Wrapper directo |
| `time_unix_ms`… | `kioto::time::unix_ms`… | Wrapper directo |
| `proc_run`… | `kioto::proc::run`… | Wrapper directo |
| `lists.push`, `pop`, `len` | *(no en Kioto)* | Pertenecen al runtime/lenguaje |
| `dicts.get`, `set`, `has` | *(no en Kioto)* | Pertenecen al runtime/lenguaje |
| `math.abs`, `min`… | `kioto::math::abs`, `min`… | Pure-Mire + builtin |
| `strings.split`… | `kioto::strings::split`… | Wrapper directo |
| *No existe* | `kioto::term` | Nuevo |
| *No existe* | `kioto::lists::map`, `filter`… | Funcional, no builtin |
| *No existe* | `kioto::dicts::merge`, `invert`… | Funcional, no builtin |

---

## Symbol Stub Loading (dirección futura)

Actualmente `import kioto: (fs)` parsea el archivo completo de forma eager. A futuro, se planea:

1. Escaneo rápido de firmas públicas (`pub fn name: (params) :ret`)
2. Construcción de tabla de símbolos + registry sin bodies
3. Typechecking, AST completo e IR solo bajo demanda

Esto reduce tiempo de compilación y permite que Kioto tenga cientos de funciones sin penalizar el startup. No es prioridad P0.

---

## Estructura del proyecto Kioto

```
src/modules/kioto/
├── lib.mire
├── fs.mire
├── env.mire
├── time.mire
├── term.mire
├── proc.mire
├── mem.mire
├── cpu.mire
├── math.mire
├── strings.mire
├── lists.mire
└── dicts.mire
```

Cada archivo es un módulo independiente que puede importarse por separado:

```
import kioto: (fs)                    # solo kioto::fs::*
import kioto: (fs env time)          # múltiples módulos
import kioto                          # solo lib.mire (metadata, versión)
```

No hay re-export automático desde `lib.mire`. Cada sub-módulo se importa explícitamente.

---

## Principios de diseño de API

1. **Nombres cortos y directos.**  
   `kioto::fs::read`, no `kioto::fs::read_file_contents`.

2. **Agrupación por módulo.**  
   El módulo ya aporta contexto: `kioto::fs::read` es claramente una operación de archivos.

3. **Sin prefijos redundantes.**  
   `kioto::fs::list`, no `kioto::fs::list_files_in_directory`.

4. **Explicitud sobre magia.**  
   No ocultar el módulo real. No importar funciones sueltas por defecto.

5. **Errores claros.**  
   Las funciones retornan tipos que permiten distinguir éxito de fracaso cuando corresponde.

6. **No duplicar el runtime.**  
   Si el lenguaje/runtime ya provee una operación (`lists.push`, `dicts.get`, operadores), Kioto no la envuelve.
