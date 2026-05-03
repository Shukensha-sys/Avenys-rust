# Resolucion de `tmp-todo.md` (2026-05-03)

## Completado

- Corregida posicion de columna en lexer para operadores simples y compuestos (`==`, `>=`, `<=`, `=>`, `=>?`, etc.) usando la columna inicial real del token.
- Corregido cache de `mire_cpu_mhz()` en runtime C para acceso thread-safe con atomicos C11.
- Eliminadas fallas silenciosas en parseo de literales numericos (int/float) y tamano de `arr[...]`; ahora reporta error explicito en lugar de degradar a `0`/`0.0`.
- Eliminadas fallas silenciosas en `compile_closure_body`; ahora propaga errores en lugar de ocultarlos con valores por defecto.
- Limpieza de codigo muerto indicada en:
  - `src/main.rs` (`_output`, `_args`, `repeat.max(1)` duplicado, doble `unwrap_or` en status).
  - `src/parser/mod.rs` (parametros `visibility` no usados).
  - `src/incremental.rs` (`let _ = last_start`).
  - `src/error/mod.rs` (helper duplicado/conflictivo `ErrorKind::runtime_at`).
  - `src/loader.rs` (`read_source_file` simplificado y uso explicito de argumento en cache).

## Pendiente por autorizacion de sintaxis

Por regla de trabajo del proyecto, estos cambios requieren tu confirmacion previa porque modifican sintaxis del lenguaje:

- `for item, index in ...` (secondary binding en for-loop)
- Literales `0b`, `0o`, `0x`
- Raw strings (`r"..."`, multilinea)
- Literales de caracter (`'a'`) diferenciados de string

No se aplicaron aun para cumplir tu restriccion de no tocar sintaxis sin consultarte.

## Validacion

- `cargo test` ejecutado tras los cambios.
- Resultado: tests OK (unidad + integracion + doc-tests).
