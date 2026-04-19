# Mire CLI

La CLI de Mire sigue teniendo comandos auxiliares, pero el flujo básico recomendado es este:

- `mire run [file] [options]`
- `mire build [file]`
- `mire new [name]`
- `mire debug [file] [options]`

Si `mire` está en tu `PATH`, puedes invocarlo directamente:

```bash
mire run app.mire
```

## Comandos básicos

### `mire run [file] [options]`

Compila y ejecuta el programa.

Si no pasas `[file]`, Mire intenta usar la entrada definida en `project.toml`.

Persistencia de artefactos:

- En proyectos Mire: guarda el binario en `bin/release/`
- Fuera de un proyecto: guarda el binario en `release/` junto al archivo fuente
- No guarda `.ll` en disco
- La caché incremental se guarda en `bin/.cache/` dentro del proyecto, o en `.cache/` si no hay proyecto

Opciones útiles:

- `--ms`: muestra el tiempo wall-clock del proceso compilado
- `--memory` o `-m`: muestra el pico de memoria del proceso
- `--cpu`: muestra el tiempo de CPU del proceso
- `--cache-max-units N`: sobreescribe el límite LRU del `project.toml`
- `--no-analysis-cache`: desactiva la caché de análisis para esa ejecución
- `--analysis-cache`: fuerza la caché de análisis para esa ejecución

Ejemplo:

```bash
mire run benchmarks/string_build.mire --ms --cpu --memory
```

### `mire build [file]`

Compila sin ejecutar.

Persistencia de artefactos:

- En proyectos Mire: guarda el binario en `bin/release/`
- Fuera de un proyecto: guarda el binario en `release/`
- No guarda LLVM IR en disco
- Mantiene metadatos de compilación incremental en caché
- Soporta overrides de cache: `--cache-max-units`, `--no-analysis-cache`, `--analysis-cache`

Ejemplo:

```bash
mire build code/main.mire
```

### `mire new [name]`

Crea un proyecto nuevo.

Si no pasas nombre, usa `default`.

Estructura generada:

- `project.toml`
- `project.lock`
- `code/main.mire`
- `tests/smoke.mire`
- `bin/debug/`
- `bin/release/`

Ejemplos:

```bash
mire new
mire new hello_world
```

### `mire debug [file] [options]`

Compila en modo debug y permite inspeccionar el frontend y el IR.

Persistencia de artefactos:

- En proyectos Mire: guarda binario e IR en `bin/debug/`
- Fuera de un proyecto: guarda binario e IR en `debug/`
- `debug` es el modo que materializa `.ll` en disco

Opciones soportadas:

- `--ast` o `-p`: muestra el AST parseado
- `--tokens` o `-t`: muestra los tokens
- `--run` o `-r`: ejecuta el binario compilado en debug
- `--log` o `-l`: muestra información relevante de compilación
- `--ir`: compila solo a LLVM IR y no enlaza binario
- `--cache-max-units N`: sobreescribe el límite LRU del proyecto
- `--no-analysis-cache`: desactiva la reutilización del análisis semántico
- `--analysis-cache`: fuerza la reutilización de análisis aunque el proyecto lo desactive

Ejemplos:

```bash
mire debug code/main.mire --tokens --ast --log
mire debug code/main.mire --ir --log
mire debug code/main.mire --run --log
```

## Qué hace cada uno

- `run`: compila, guarda solo binario y usa IR en memoria
- `build`: compila, guarda solo binario y usa IR en memoria
- `new`: crea proyecto
- `debug`: compila en debug, guarda `.ll` en disco y sirve para inspección, trazas e IR

## Configuración de cache

La cache incremental vive en `bin/.cache/incremental.bin`, usa un índice en memoria y abre los payloads con `mmap` cuando la cache se consume en modo lectura.

Configuración en `project.toml`:

```toml
[cache]
max_units = 256
analysis_cache = true
compression = false
```

Notas:

- `max_units = 0` deja la cache sin límite
- `analysis_cache` reutiliza resultados exitosos de type checking + borrow checking cuando el fingerprint del grafo no cambió
- La cache también guarda errores de análisis para entradas idénticas inválidas
- Cuando una entrada necesita mutarse, el blob store deja de usar `mmap`, se promociona a memoria propia y luego se persiste en el siguiente save
- En modo debug, la compilación puede mostrar un resumen de unidades cambiadas/invalidadas del grafo top-level incremental
- `compression` queda expuesto como flag de configuración, pero por ahora no comprime payloads

## Comandos auxiliares

Siguen existiendo, pero no son el flujo principal:

- `mire test`
- `mire bench`
- `mire clean`
- `mire info`
- `mire version`
- `mire init`

### `mire test`

- Recorre `tests/` de forma recursiva y ejecuta archivos `.mire` positivos.
- Omite por defecto `tests/error/`, `tests/broken_mire/` y fixtures como `tests/test_proyet_mire_cli/`.
- Si pasas un archivo explícito, ejecuta solo ese archivo.

## Sobre `mire bench` y `--compare-python`

`mire bench` es para benchmarks, no para uso normal.

`--compare-python` hace esto:

1. compila y ejecuta el benchmark `.mire`
2. busca el benchmark Python equivalente
3. ejecuta `python3` sobre ese archivo
4. compara tiempos en la misma salida

No cambia el comportamiento de Python ni acelera nada por sí mismo. Solo automatiza la comparación entre ambos lados.

Si quieres correr Python de forma normal, sigue siendo:

```bash
python3 benchmarks/string_build.py
```

Si no te interesa comparar con Python, puedes desactivarlo:

```bash
mire bench --no-compare-python
```
