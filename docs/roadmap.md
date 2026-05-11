# Roadmap Técnico (Avenys + Owl)

## Completado en Avenys (v2.7.0)

- CLI reducida a `run`, `build`, `check`, `debug`.
- Perfiles de compilación simplificados con default `debug`.
- Niveles de optimización tipo Rust expuestos por CLI: `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Pipeline de optimización de IR y `clang` sincronizado con `OptLevel`.
- Fingerprint incremental de build extendido para incluir nivel de optimización.

## Siguiente bloque (Owl)

- Optimizar Owl e implementar integración nativa con Avenys.
- Mantener ecosistema ultra optimizado entre Owl y compilador.
- Rediseñar UX/flujo de comandos de Owl según especificación del proyecto.
