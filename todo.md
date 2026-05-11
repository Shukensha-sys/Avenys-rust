# Todo

Última actualización: Mayo 2026

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

- Roadmap consolidado: `docs/roadmap.md`
- Plan Owl actual: `owl/TODO.md`, `owl/docs/roadmap.md`
- Historial técnico: `docs/TECHNICAL.md`, `docs/issues.md`
