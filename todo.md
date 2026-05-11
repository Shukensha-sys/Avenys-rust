# Todo

Última actualización: Mayo 2026

## Completado — Compilador (Avenys v2.7.0)

- CLI simplificada a solo: `mire run`, `mire build`, `mire check`, `mire debug`.
- Nivel de optimización configurable tipo Rust: `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Default operativo movido a `debug` (`-O0`) para ciclo de desarrollo rápido.
- Fingerprint de cache incremental ampliado con nivel de optimización.
- Optimización de backend conectada de forma consistente en `opt` + `clang`.

## Siguiente entrada — Owl (pendiente de confirmación previa)

- Optimizar Owl e implementar integración nativa con el compilador.
- Mantener ecosistema ultra optimizado entre Owl y Avenys.
- Rediseñar comandos Owl con UX simplificada y flujos fuera de proyecto (`.cache` + `bin/`).

## Referencias

- Roadmap consolidado: `docs/roadmap.md`
- Plan Owl actual: `owl/TODO.md`, `owl/docs/roadmap.md`
- Historial técnico: `docs/TECHNICAL.md`, `docs/issues.md`
