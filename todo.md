# Todo

Última actualización: Mayo 2026

## Kioto — Biblioteca estándar de Mire (P0)

Kioto es una biblioteca escrita en Mire que envuelve builtins existentes con una API namespaced limpia. No está acoplada al compilador.

Plan completo: [docs/kioto.md](docs/kioto.md)
TODO de implementación: [owl/TODO.md](owl/TODO.md) (sección Kioto)

### Prioridad P0

| Módulo | Estado |
|--------|:------:|
| `fs`, `env`, `time`, `term` | ❌ No iniciado |
| `proc`, `mem`, `cpu` | ❌ No iniciado |
| `math` (híbrido) | ❌ No iniciado |
| `strings` | ❌ No iniciado |
| `lists`, `dicts` (solo funcional) | ❌ No iniciado |

## Siguiente Prioridad (Avenys v3.x)

1. Ownership real en paso por valor.
- Definir y aplicar semántica consistente para parámetros por valor (move/copy/borrow) y cerrar casos de uso-after-move implícito.

2. `match` avanzado completo.
- Implementar `or patterns`, guards (`when`) y ranges (`1..5`) con validación de exhaustividad sólida.

3. `result[T, E]` end-to-end.
- Completar parser/check/runtime para `Ok/Err` y flujo de propagación/validación de errores tipados.

4. Traits orientados a genéricos estables.
- Agregar default methods y associated types para APIs genéricas robustas sin workarounds.

5. Limpieza final de Owl para calidad/CI.
- Reducir código muerto y warnings residuales; endurecer `owl check --strict` como gate de calidad.

## Completado — Compilador (Avenys v2.7.0)

- CLI simplificada a solo: `mire run`, `mire build`, `mire check`, `mire debug`.
- Nivel de optimización configurable tipo Rust: `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Default operativo movido a `debug` (`-O0`) para ciclo de desarrollo rápido.
- Fingerprint de cache incremental ampliado con nivel de optimización.
- Optimización de backend conectada de forma consistente en `opt` + `clang`.

## Completado — Owl (v0.7.0)

- Optimización de Owl y refactor de CLI principal.
- Integración operativa con el compilador vía perfiles/opt-level.
- Flujo fuera de proyecto con `.cache` y `bin`.
- Base lista para siguiente fase de integración nativa profunda Owl/Avenys.

## Referencias

- Kioto: `docs/kioto.md`
- Roadmap consolidado: `docs/roadmap.md`
- Plan Owl actual: `owl/TODO.md`, `owl/docs/roadmap.md`
- Historial técnico: `docs/TECHNICAL.md`, `docs/issues.md`
