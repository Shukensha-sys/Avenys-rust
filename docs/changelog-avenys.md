# Avenys Changelog (Consolidated)

Este archivo consolida el historial operativo principal del compilador Avenys.

## [3.5.0] - 2026-05-18

- Backend ahora genera símbolos monomórficos estables por call-site genérico (wrappers LLVM).
- Normalización nominal genérica en backend (`Type[T]` / `Type[i64]` -> `Type`) para:
  - resolución de constructores de `type`
  - resolución de miembros/campos de structs genéricos
  - enlazado de métodos `impl[T]` en receptores concretos
- Nueva regresión E2E de codegen para método en `impl` genérico sobre `Box[i64]`.
- Bump de versión menor: `3.4.0` -> `3.5.0`.

## [3.4.0] - 2026-05-18

- Resolución estable de métodos en `impl` genéricos para receptores concretos.
  - Ejemplo: `Box[i64]` ahora enlaza correctamente métodos definidos en `impl[T] Box[T]`.
- El checker preserva y propaga tipo nominal genérico concreto en constructores.
- Cobertura de regresión ampliada para validación de `impl` genérico con call-site concreto.
- Bump de versión menor: `3.3.0` -> `3.4.0`.

## [3.3.0] - 2026-05-18

- Soporte de encabezados `impl` genéricos: `impl[T] Type[T]`.
- Soporte de trait bounds en genéricos de función: `fn f[T: Trait]: (...)`.
- Type checker ahora valida bounds en call-site (inferencia o type args explícitos).
- AST y hashing incremental ampliados para metadata de bounds/type-params en `Function` e `Impl`.
- Bump de versión menor: `3.2.0` -> `3.3.0`.

## [3.2.0] - 2026-05-18

- Soporte nominal genérico ampliado:
  - `type Name[T] { ... }`
  - `enum Name[T] { ... }`
  - uso de tipos `Name[T]` en anotaciones
  - rutas de construcción `Name[T](...)` y `Enum[T].Variant(...)`
- Type checker integra sustitución de genéricos nominales en:
  - validación de constructores
  - validación de payloads enum y bindings de `match`
- AST extendido con `type_params` en `Type` y `Enum`.
- Bump de versión menor: `3.1.0` -> `3.2.0`.

## [3.1.0] - 2026-05-18

- Soporte estable de genéricos en funciones:
  - `fn name[T]: (...) :T`
  - llamadas explícitas `name[T](...)`
  - inferencia de tipo genérico desde argumentos en call-site
- AST extendido:
  - `Statement::Function.type_params`
  - `Expression::Call.type_args`
  - `DataType::Generic`
- Type checker amplía validación de calls genéricas (arity, inferencia y coherencia de tipos).
- Hash incremental actualizado para considerar parámetros de tipo y type-args.
- Bump de versión menor: `3.0.0` -> `3.1.0`.

## [3.0.0] - 2026-05-18

- Implementación completa de `find` en el pipeline compilador:
  - lexer: keyword `find`
  - parser: `find item in iterable { ... }`
  - backend: lowering activo (deja de fallar con error de backend limitation)
- Cobertura de regresión ampliada para:
  - compilación/lowering de `find`
  - bindings `const` con operadores compuestos
- Bump de versión mayor: `2.9.0` -> `3.0.0`.

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
