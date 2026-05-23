# Todo

Última actualización: Mayo 2026

## Enfoque Actual (Activo)

Estado de avance inmediato:
- ✅ Completado: eliminación de variantes legacy del AST (`Class`, `Trait`, `Code`, `AddLib`, `Dmire*`) y limpieza asociada en parser/typeck/borrowck/semantic/incremental/backend.
- ✅ Completado: actualización de tests internos/regresión para no depender de esas variantes legacy.
- ✅ Completado: primera fase de modularización de responsabilidades:
  - parser lifecycle ops extraídas a `src/parser/lifecycle.rs`
  - parser pipeline/self-placeholder helpers extraídos a `src/parser/pipeline.rs`
  - type checker return-flow helpers extraídos a `src/compiler/typeck/typeck_returns.rs`
- 🔜 Siguiente bloque grande: modularización de `parser` y `typeck`.

### Performance & Optimizations
- Optimizar resolución de imports por reachability real (no cargar módulos no usados).
- Reducir ramas muertas internas en parser/typeck/borrowck/incremental.
- Consolidar caché incremental por unidad alcanzable.
- Preparar extracción de builtins del typechecker para reducir costo por compilación.

### Quality of Life
- Unificar sintaxis estable: `mu` como único unit literal/type.
- Mejorar diagnósticos de sintaxis reservada/no soportada (tokens legacy).
- Mantener SYNTAX.md alineado con lo realmente parseable.
- Incrementar cobertura de regresión para sintaxis/documentación.

## Pendientes Grandes (No cerrados en esta pasada)

1. Modularización del parser (`src/parser/mod.rs`) en submódulos restantes (`statements`, `expressions`, `types`, `patterns`, `imports`).
2. Modularización de `typeck` (`src/compiler/typeck.rs`) en capas (`signatures`, `statements`, `expressions`, `types`, `builtins`, `errors`), partiendo de la fase 1 ya extraída (`typeck_returns`).
3. Migración de builtins del compilador a Kioto (reducción de conocimiento hardcodeado en typechecker).
4. Cleanup incremental fase 2: optimizar hashing/invalidation tras poda legacy y preparar caché por reachability real.

## Prioridad Máxima (P0) — Import Optimization / Dead Code Elimination by Reachability

Objetivo:
- El compilador debe cargar, analizar y compilar solo lo realmente usado por el programa.
- Todo símbolo no alcanzable por imports efectivos debe permanecer invisible para typeck/borrowck/backend.

Problema actual:
- El loader todavía expande módulos de forma amplia en varios caminos, lo que aumenta tiempo de compilación, ruido de warnings y riesgo de colisiones.
- Esto penaliza especialmente Kioto/Owl, donde hay muchos submódulos y APIs parciales.

Alcance técnico esperado:
1. Resolver imports por símbolo exportado (`import x: (a b c)`) con grafo de dependencias preciso.
2. Construir un set de alcance (reachability set) desde `main` + imports efectivos.
3. Ejecutar typeck/borrowck/backend únicamente sobre statements alcanzables.
4. Excluir de warnings de código muerto todo lo no alcanzable por diseño (no es “unused”, es “not imported”).
5. Integrar con incremental cache para invalidación parcial por unidad alcanzable.

Criterios de éxito (medibles):
- Proyectos con `import kioto: (fs)` no cargan ni analizan `kioto/time`, `kioto/cpu`, etc.
- Reducción visible de tiempo de `mire check/build` en proyectos modulares.
- Disminución de warnings falsos de símbolos en módulos no importados.
- Regressions verdes con imports selectivos, imports locales y namespaces `::`.

Riesgos a controlar:
- Orden de resolución de símbolos con alias de namespace.
- Coherencia entre selección de statements e invalidación incremental.
- No romper compatibilidad de sintaxis estable (`::`, lifecycle ops).

Semver recomendado para este cambio:
- Recomendación: **minor** (por ejemplo `3.9.0`) si el comportamiento observable solo mejora rendimiento/diagnósticos sin romper programas válidos.
- Escalar a **major** solo si se cambia semántica pública de imports (por ejemplo rechazar patrones antes aceptados).

## Prioridad Alta (P1) — Kioto Independiente de Avenys (ABI + Portabilidad Real)

Objetivo:
- Convertir Kioto en una API estándar portable, utilizable por múltiples backends/runtime y no solo por Avenys.
- Reducir dependencia estructural de builtins hardcodeados del compilador y de `runtime_support.c`.

Resultado esperado:
- Kioto se comporta como una “libc” de Mire: contratos estables arriba, adaptadores por plataforma/backend abajo.
- Owl y futuras herramientas consumen Kioto sin acoplarse a detalles internos de Avenys.

Problema actual:
- Muchas funciones de Kioto son wrappers directos sobre builtins (`fs_*`, `time_*`, `cpu_*`, `proc_*`, etc.).
- Esos builtins hoy están atados al runtime C de Avenys y a su backend LLVM específico.
- No existe un contrato ABI de Kioto versionado y verificable de forma independiente.

### Plan Técnico Completo

1. Definir ABI base de Kioto (`kioto_abi v1`).
- Catálogo de funciones mínimas por dominio (`fs`, `env`, `time`, `proc`, `mem`, `cpu`, `strings`).
- Firmas, tipos, convenciones de errores, ownership y encoding (`str`, buffers, maps, status codes).
- Política explícita de compatibilidad ABI (qué rompe major/minor/patch).

2. Introducir capa de adaptación (Adapter Layer).
- Kioto llama solo a una capa de símbolos ABI (`extern fn __kioto_*`), no a builtins del compilador.
- Avenys implementa un adapter concreto (`__kioto_* -> runtime actual`).
- Otros backends podrán implementar el mismo contrato sin tocar Kioto alto nivel.

3. Separar niveles en Kioto.
- `kioto/core`: contratos y tipos estables.
- `kioto/platform`: bindings ABI por plataforma/backend.
- `kioto/high`: APIs ergonómicas (las usadas por Owl y apps).
- Evitar mezclar “API pública” con “detalle runtime”.

4. Modelo de errores y resultados portable.
- Estandarizar resultados para operaciones fallables (`result[T,E]` o equivalente estable).
- Eliminar dependencias implícitas de mensajes runtime locales.
- Definir códigos y mapping consistente de errores (`fs`, `proc`, `env`, etc.).

5. Pruebas de conformidad ABI.
- Suite de conformidad de Kioto independiente del compilador:
  - tests de firma/contrato por módulo
  - tests de comportamiento mínimo por backend
  - tests de compatibilidad binaria/semántica por versión ABI
- Gate de CI: no se publica Kioto si rompe ABI sin bump correcto.

6. Migración progresiva `std -> kioto`.
- `std` entra en modo compatibilidad (sin features nuevas).
- Nuevas APIs solo en Kioto.
- Dejar aliases transitorios documentados y plan de deprecación por fases.

7. Integración con Owl y ecosistema.
- Owl consume Kioto estable (`kioto::...`) como única vía preferida para utilidades de sistema.
- Documentar políticas para librerías de terceros (cómo depender de Kioto ABI, cómo testear portabilidad).
- Preparar base para registro/paquetes donde Kioto sea dependencia estándar.

### Entregables Mínimos (Done Criteria)

- Documento formal `kioto_abi_v1` con contratos completos y política semver ABI.
- Capa `extern fn __kioto_*` integrada en Kioto para módulos P0.
- Adapter Avenys funcional y validado para ABI v1.
- Suite de conformidad ABI ejecutable y en CI.
- Owl migrado a consumir rutas estables de Kioto sin llamadas runtime ad-hoc.
- Tabla de estado `std -> kioto` con APIs migradas, aliases y fecha objetivo de deprecación.

### Riesgos y Mitigaciones

- Riesgo: fragmentación de contratos por backend.
  Mitigación: ABI única versionada + tests de conformidad obligatorios.

- Riesgo: overhead por capa de adaptación.
  Mitigación: diseño de ABI minimalista, batching y rutas fast-path para operaciones críticas.

- Riesgo: ruptura silenciosa de Owl/apps.
  Mitigación: migración por fases con aliases, warnings y ventanas de deprecación documentadas.

### Recomendación de SemVer para esta línea

- Cambios de infraestructura ABI sin ruptura visible en API de usuario: **minor**.
- Introducción de `kioto_abi v1` como contrato estable público: **minor** (si coexistente).
- Eliminación de rutas legacy o ruptura de contratos existentes: **major**.

## Prioridad Alta (P1.5) — Resolver de Módulos Declarativo (`owl.toml` + lock)

Objetivo:
- Eliminar resolución hardcodeada de módulos en el compilador.
- Hacer que Avenys siga reglas declaradas por proyecto vía `owl.toml` + lock.
- Delegar en Owl la gestión de instalación, ubicación y versionado de módulos/deps.

Problema actual:
- El loader de Avenys mantiene rutas internas/fallbacks para localizar módulos.
- Eso dificulta portabilidad, reproducibilidad y gestión de dependencias reales.
- Kioto y futuros paquetes todavía dependen de convenciones de ruta implícitas.

Diseño propuesto:

1. Configuración declarativa en `owl.toml`.
- Agregar sección de resolución:
  - `module_paths` (orden de búsqueda explícito)
  - política de resolución (`strict` / `fallback`)
  - allowlist de roots seguros para imports locales.
- Ejemplo conceptual:
  - proyecto local (`./modules`)
  - cache global de Owl (`~/.owl/modules`)
  - dependencias instaladas (`~/.owl/deps`)

2. Lockfile obligatorio para builds reproducibles.
- Owl genera/actualiza lock (si no existe, crear).
- Avenys consume lock resuelto (módulo -> ruta/version/hash).
- Build/check deben resolver por lock primero; sin lock, modo explícito (`--no-lock`) o error configurable.

3. Layout global Owl (gestionado por Owl, no por Avenys).
- `~/.owl/modules`  -> módulos estándar instalados (ej. Kioto).
- `~/.owl/deps`     -> dependencias de proyecto (futuro registry/git).
- `~/.owl/data`     -> caches/datos auxiliares.
- `~/.owl/config`   -> configuración global de usuario/equipo.

4. Contrato Owl -> Avenys.
- Owl “ordena” cómo compilar: paths, max_units, cache policy, lock input, profile.
- Avenys deja de inferir rutas mágicas y ejecuta según configuración recibida.
- Mantener modo standalone mínimo para depuración local, pero fuera del camino principal.

5. Seguridad y aislamiento.
- Resolver imports solo dentro de roots permitidos por config/lock.
- Rechazar escapes de ruta por defecto.
- Hash/checksum en lock para detectar módulos/deps corruptos o reemplazados.

Entregables mínimos:
- Especificación de `owl.toml` (sección resolver) y formato de lock.
- Implementación en Owl de `resolve + lock write/read`.
- Implementación en Avenys de `resolver por config/lock` (sin hardcodes como ruta principal).
- Tests de integración:
  - proyecto A/B/C con configs distintas
  - reproducibilidad con lock
  - fallback controlado y errores claros.

Semver recomendado:
- **Minor** si coexistimos con modo legacy y el comportamiento por defecto no rompe proyectos vigentes.
- **Major** cuando el modo hardcodeado/fallback deje de ser predeterminado o se elimine.

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

### Migración `std` -> `kioto` (anticorrupción de APIs)

Regla operativa:
- Si una API se implementa oficialmente en `kioto`, no se debe duplicar lógica equivalente nueva en `std`.
- `std` pasa a modo compatibilidad/deprecado: wrappers mínimos o aliases transitorios, sin crecimiento funcional nuevo.

Objetivo:
- Reducir redundancia, deuda técnica y rutas de mantenimiento duplicadas.
- Preparar Kioto como base real para runtime en Mire y bootstrap gradual de Avenys.

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

6. Solucionar todos los warnings del compilador.
- `cargo build` debe emitir 0 warnings en toda la base de Rust.
- Incluye: variables no usadas, imports muertos, `#[allow(...)]` innecesarios, `clone()` redundantes, patrones exhaustivos sin manejo explícito, etc.
- Ideal: que `RUSTFLAGS="-D warnings"` pase limpio.

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
