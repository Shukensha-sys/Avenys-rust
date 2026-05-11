# Issues Index

Este archivo actúa como índice operativo.

- Pendientes reales: ver [docs/open-issues.md](open-issues.md)
- Histórico de fixes e investigación: ver [docs/resolved-history.md](resolved-history.md)
- Contexto técnico general: ver [docs/TECHNICAL.md](TECHNICAL.md)

## Estado actual (Mayo 2026)

- Críticas abiertas: 0
- Bugs reales abiertos: 0
- Deuda técnica abierta: 0
- Diseño/optimización abierta: 0

## Entrada: Diagnósticos con línea imprecisa (import std / 1:1)

- ID: `DIAG-LOC-2026-05-11`
- Estado: `Resuelto`
- Síntoma:
  - Algunos errores (sobre todo ownership/type) aparecían en `main.mire:1:1` y visualmente caían sobre `import std`.
- Causa raíz:
  - Fallback genérico de posición (`1:1`) cuando el checker no propagaba contexto activo de statement/expression.
- Implementación aplicada:
  - `borrowck` y `typeck` ahora mantienen cursor contextual `(line,column)` durante el recorrido AST.
  - Cuando un error sale con posición default, se reubica con el contexto activo antes de formatear diagnóstico.
  - `MireError` incorpora `with_position(...)` para reanclar diagnósticos y etiqueta primaria.
- Resultado:
  - Errores `E0007`-`E0013` y errores de type checking emitidos desde contexto ya no caen sistemáticamente en `import std`.
  - Cuando una ruta no-posicionada (backend/runtime) no puede dar ubicación exacta, el renderer evita anclar visualmente el error sobre código fuente engañoso y lo marca explícitamente como aproximado.
  - Warnings de `unused function`/`unused variable` ahora priorizan posición real del símbolo (línea de `fn`/`set`) y no emiten diagnóstico si la ubicación proviene de nodos internos no trazables a código fuente.

## Nota

Para mantener trazabilidad sin ruido operativo:
- `open-issues.md` contiene solo trabajo pendiente/accionable.
- `resolved-history.md` conserva el detalle completo de cambios históricos.
