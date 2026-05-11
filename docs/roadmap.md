# Roadmap Técnico (Avenys + Owl)

## Completado en Avenys (v2.7.0)

- CLI reducida a `run`, `build`, `check`, `debug`.
- Perfiles de compilación simplificados con default `debug`.
- Niveles de optimización tipo Rust expuestos por CLI: `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Pipeline de optimización de IR y `clang` sincronizado con `OptLevel`.
- Fingerprint incremental de build extendido para incluir nivel de optimización.

## Completado en Owl (v0.7.0)

- CLI rediseñada con banner+help por defecto.
- Flujo `new/run/build/test/install/remove/purge/update/clean/info`.
- Soporte `run/build` en modo proyecto y sin proyecto (`.cache` + `bin`).
- Flags de perfil y optimización (`--debug`, `--release`, `-O`).
- Fast-path de ejecución por hash para reducir compilaciones repetidas.
