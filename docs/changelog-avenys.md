# Avenys Changelog (Consolidated)

Este archivo consolida el historial operativo principal del compilador Avenys.

## [2.9.0] - 2026-05-18

- Integración de sintaxis lifecycle (`new::`, `own::`, `move::`, `drop::`) en lexer/parser y validadores.
- Eliminación de `vec![T]` como sintaxis de tipo; estándar consolidado en `vec[T]`.
- Refuerzo de diagnósticos orientados a ownership explícito (`W0028`-`W0033`), alineado con flujos Owl.
- Match reforzado: detección de brazos duplicados por variante enum y chequeo de exhaustividad cuando no existe `_`.
- Parser de `match` endurecido: error en múltiples defaults `_` y en casos declarados después del default.
- Reglas de lifecycle ampliadas en type checker:
  - `new::` restringido a objetivos de construcción en stack (`arr/vec/map`).
  - `own::` restringido a tipos heap-allocatables con error explícito por tipo inválido.

## [2.8.0] - 2026-05-11

- Precisión de diagnósticos reforzada en type checker, borrow checker y backend.
- Reanclaje de errores contextuales para evitar reportes engañosos en `1:1`.
- Mejoras de integración compilador<->Owl detectando/fijando casos reales de ownership y colisiones de símbolos multi-módulo.

## [2.7.0] - 2026-05-11

- CLI simplificada a: `run`, `build`, `check`, `debug`.
- Perfil por defecto `debug` + niveles de optimización `-O0/-O1/-O2/-O3/-Os/-Oz`.
- Fingerprint incremental incluye `opt_level`.
- Pipeline `opt`/`clang` unificado por nivel de optimización.

## [2.6.0] - 2026-05-11

- Sistema unificado de diagnósticos (`E/W` codes, labels, severity, formatter).
- Comando `mire check` y filtros de warnings (`--warn-all`, `-W`, `--deny`).

## [2.5.x] - 2026-05-10

- Cobertura backend ampliada para lowering de statements/expresiones antes parciales.
- Nuevos builtins de strings/listas/dicts y mejoras de runtime.
- Mejoras importantes en incremental cache y estabilidad de tipos/referencias.

## [2.2.0] y [2.0.0]

- Consolidación de backend Avenys y maduración de type/borrow checking.
- Actualización de sintaxis mayor (v2.x) y reglas de métodos/self.

## [1.x]

- Base inicial estable del lenguaje y compilador.

---

Fuente canónica detallada: `CHANGELOG.md`.
