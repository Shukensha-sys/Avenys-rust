# Roadmap Técnico (Avenys + Owl)

## Completado en Avenys (v2.8.0)

- CLI reducida a `run`, `build`, `check`, `debug`.
- Perfiles de compilación simplificados con default `debug`.
- Niveles de optimización tipo Rust expuestos por CLI: `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Pipeline de optimización de IR y `clang` sincronizado con `OptLevel`.
- Fingerprint incremental de build extendido para incluir nivel de optimización.
- Diagnósticos de errores/warnings reanclados con contexto AST activo (sin falsos positivos en `import std`/`1:1`).
- Warnings sin ubicación fuente real ahora se suprimen para evitar ruido y anclaje engañoso.

## Completado en Owl (v0.9.0)

- CLI rediseñada con banner+help por defecto.
- Flujo `new/run/build/test/install/remove/purge/update/clean/info`.
- Soporte `run/build` en modo proyecto y sin proyecto (`.cache` + `bin`).
- Flags de perfil y optimización (`--debug`, `--release`, `-O`).
- Fast-path de ejecución por hash para reducir compilaciones repetidas.
- Refactor de `owl/code/main.mire` para consolidar flujo en módulos (`deps`, `tests`, `fs_ops`) y reducir legacy duplicado.
- Hardening de ownership en `modules/deps.mire` y eliminación de colisiones de símbolos globales (`lock`, `toml`, `mkdir_p`) en compilación completa de Owl.

## Siguiente en Owl (pendiente)

- Integración nativa Owl <-> Avenys sobre `mire check/build/run` con profiles y `-O` unificados.
- Optimización de resolución de dependencias (lock/update/install) con validación semver y hashes.
- Refactor de comandos para reducir duplicación de parsing y mejorar tiempos de arranque.
