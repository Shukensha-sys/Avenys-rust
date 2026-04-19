# MireOS

`mireos` es la librería pendiente para comunicar Mire con el sistema operativo.

Este documento define el nombre, la convención de uso y la forma esperada de la API antes de implementar nada.

## Nombre

El nombre oficial de la librería será:

- `mireos`

El alias en código es libre. Un caso común será:

```mire
import mireos as mos
```

En este ejemplo:

- `mireos` es el nombre de la librería
- `mos` es solo un alias local elegido por el usuario

## Forma de importación

La forma objetivo de importación es:

```mire
import mireos as mos
```

También se contempla la importación parcial por superficie o grupo, por ejemplo:

```mire
import mireos as mos: (fs)
```

Esta sintaxis expresa que:

- se importa la librería `mireos`
- se le asigna el alias `mos`
- opcionalmente se restringe la superficie visible al grupo indicado, como `fs`

## Forma de uso

La llamada siempre debe ser explícita desde la librería o alias hasta la función usada.

Uso esperado:

```mire
use mos.fs.read()
use mos.env.get()
use mos.proc.run()
```

La idea es que la ruta completa quede visible:

- alias o librería
- módulo
- función

## Regla de expresiones

Cuando la llamada aparece como expresión, se omite `use`, pero no se acorta la ruta.

Ejemplo:

```mire
set text = mos.fs.read("notes.txt")
set home = mos.env.get("HOME")
set result = mos.proc.run("ls" ["-la"])
```

Regla obligatoria:

- hay que escribir siempre toda la ruta desde la librería o alias hasta la función o método

No se considera válido un acceso abreviado como este:

```mire
set text = fs.read("notes.txt")
```

si antes no se decidió explícitamente que `fs` fuese el alias directo.

La convención preferida para `mireos` es:

```mire
import mireos as mos
set text = mos.fs.read("notes.txt")
```

## Objetivo de diseño

`mireos` no debe ser una librería genérica de utilidades.

Su responsabilidad es exponer acceso al sistema operativo de forma clara, predecible y modular.

## Módulos previstos

La primera versión debe organizarse en módulos claros:

- `mos.fs`
- `mos.env`
- `mos.proc`
- `mos.time`
- `mos.sys`

Más adelante podrían existir:

- `mos.net`
- `mos.io`
- `mos.path`

pero no forman parte del núcleo inicial obligatorio.

## API mínima propuesta

### `mos.fs`

Responsabilidad:

- lectura y escritura de archivos
- directorios
- rutas básicas

Funciones candidatas:

- `mos.fs.read(path)`
- `mos.fs.write(path data)`
- `mos.fs.append(path data)`
- `mos.fs.exists(path)`
- `mos.fs.size(path)`
- `mos.fs.list(path)`
- `mos.fs.mkdir(path)`
- `mos.fs.rmdir(path)`
- `mos.fs.drop(path)`

### `mos.env`

Responsabilidad:

- variables de entorno
- argumentos del proceso
- directorio actual

Funciones candidatas:

- `mos.env.get(key)`
- `mos.env.set(key value)`
- `mos.env.all()`
- `mos.env.args()`
- `mos.env.cwd()`
- `mos.env.chdir(path)`

### `mos.proc`

Responsabilidad:

- ejecución y control de procesos

Funciones candidatas:

- `mos.proc.run(cmd args)`
- `mos.proc.spawn(cmd args)`
- `mos.proc.wait(handle)`
- `mos.proc.kill(handle)`
- `mos.proc.exists(handle_or_pid)`

### `mos.time`

Responsabilidad:

- tiempo de sistema
- pausas
- marcas de tiempo

Funciones candidatas:

- `mos.time.unix_ms()`
- `mos.time.unix_ns()`
- `mos.time.mark()`
- `mos.time.elapsed_ms(mark)`
- `mos.time.elapsed_ns(mark)`
- `mos.time.sleep_ms(ms)`
- `mos.time.sleep_ns(ns)`

### `mos.sys`

Responsabilidad:

- datos del host y del proceso

Funciones candidatas:

- `mos.sys.pid()`
- `mos.sys.platform()`
- `mos.sys.arch()`
- `mos.sys.hostname()`

## Criterios de naming

Las funciones de `mireos` deben seguir estas reglas:

- nombres cortos
- verbos directos
- sin prefijos redundantes
- agrupación por módulo, no por nombre largo

Ejemplos buenos:

- `mos.fs.read`
- `mos.fs.write`
- `mos.env.get`
- `mos.proc.run`

Ejemplos a evitar:

- `mos.read_file_text`
- `mos.get_environment_variable`
- `mos.execute_system_process`

La agrupación por módulo ya aporta el contexto.

## Principio de explicitud

La API de `mireos` debe priorizar explicitud sobre magia.

Eso implica:

- no ocultar el módulo real de la operación
- no importar funciones sueltas por defecto
- no promover atajos ambiguos

Queremos que al leer una línea quede claro si toca:

- filesystem
- entorno
- procesos
- tiempo
- sistema

## Ejemplos de estilo

Importación general:

```mire
import mireos as mos

set config = mos.fs.read("project.toml")
set cwd = mos.env.cwd()
set proc = mos.proc.run("clang" ["main.c" "-o" "main"])
```

Importación parcial:

```mire
import mireos as mos: (fs)

set source = mos.fs.read("code/main.mire")
```

Uso con `use`:

```mire
use mos.fs.read("notes.txt")
use mos.env.get("HOME")
use mos.proc.run("pwd" [])
```

Uso como expresión:

```mire
set source = mos.fs.read("notes.txt")
set home = mos.env.get("HOME")
set child = mos.proc.run("pwd" [])
```

En expresiones se omite `use`, pero no se omite la ruta completa.

## Alcance de la primera implementación

La primera implementación de `mireos` debería ser pequeña y estable.

Prioridad alta:

- `fs`
- `env`
- `proc`
- `time`

Prioridad media:

- `sys`

Fuera de alcance inicial:

- networking
- watchers
- señales avanzadas
- async
- permisos complejos de usuarios y grupos
- API dependiente de una sola plataforma sin capa de abstracción

## Estado actual

Estado:

- especificación pendiente
- implementación no iniciada

Esta documentación debe tratarse como contrato inicial de naming y ergonomía.

Antes de codificar `mireos`, conviene cerrar:

- sintaxis final de `import mireos as mos: (fs)`
- modelo de errores y retornos
- si `mireos` será parte de la stdlib o una librería especial del runtime
- qué módulos forman la v1 mínima
