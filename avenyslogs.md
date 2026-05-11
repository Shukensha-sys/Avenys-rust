# Avenys Change Logs

Historial de cambios completados y resueltos. Este archivo documenta lo que ya funciona.

---

## v2.5.6 (Mayo 2026)

### Test Compatibility
- `tests/language_regressions.rs`:
  - Se actualizó `extern_and_inline_asm_declarations_parse_and_compile` para usar asm válido con lowering real (`nop` / `nop`), evitando plantillas ambiguas rechazadas por LLVM/clang.

### Versionado
- Bump semver de parche: `2.5.5` -> `2.5.6`.

### Validación
- `cargo build` ✅
- `cargo test extern_and_inline_asm_declarations_parse_and_compile` ✅

---

## v2.5.5 (Mayo 2026)

### Runtime + Backend Stability
- `src/avens/runtime_support.c`:
  - Endurecido `mire_string_concat`, `mire_string_append_owned`, `mire_strings_replace` contra overflow y corrupción de memoria.
  - Nuevas primitivas: `mire_strings_contains`, `mire_strings_substr`, `mire_strings_repeat`, `mire_strings_pad_left`, `mire_strings_pad_right`, `mire_list_pop_i64`.
- `src/avens/mod.rs`:
  - Implementado lowering real para: `list.pop`, `contains`, `strings.contains`, `strings.substr`, `strings.pad_left`, `strings.pad_right`, `strings.repeat`, `sqrt`.
  - `for` extendido para iterar sobre `list/vector/slice` además de `range(...)`.
  - `match` mejorado para comparar punteros no-string con igualdad de puntero (structs/enums), manteniendo `strcmp` para strings.
  - `extern fn` ahora genera `declare` LLVM.
  - `asm` ahora emite inline asm mínimo (`asm sideeffect`).
  - `Drop` y `Move` dejaron de ser backend-error y ahora bajan a IR.

### Warnings
- `src/compiler/warnings.rs` amplía cobertura con códigos faltantes:
  - `W001`, `W006`, `W010`, `W013`, `W034`, `W036`, `W037`, `W039`, `W043`-`W051`.

### Validación
- `cargo build` ✅

---

## v2.5.4 (Mayo 2026)

### Backend Lowering Coverage
- `src/avens/mod.rs`:
  - Se removió el fallo genérico para múltiples `Statement` frontend-only y se manejan como no-op explícito en codegen.
  - `compile_expr` ahora soporta lowering de `Literal::List`, `Literal::Dict`, `Literal::Tuple`.
  - Se cablearon builtins faltantes del namespace `strings.*`:
    - `strings.contains`, `strings.concat`, `strings.len`
    - `strings.strip`, `strings.ltrim`, `strings.rtrim`, `strings.is_empty`
  - Diagnóstico de llamadas desconocidas actualizado a mensaje explícito de función desconocida.
  - `map_type` ampliado para `Function`, `Db`, `Datetime`, `Box`, `DynTrait`, `Result`.
  - `runtime_kind_code` ampliado para familias `Struct/Enum/Function/Result`.

### Validación
- `cargo build` ✅
- `cargo test` ✅ (87 unit + 80 integration)

---

## v2.6.1 (Mayo 2026)

### std.mire - Standard Library
- Creado archivo `std.mire` con la Standard Library completa
- Todas las funciones organizadas por categorías con comentarios de sección:
  - MATH: abs, min, max, sum, clamp, range, round, floor, ceil
  - LISTS: len, push, pop, append, remove, delete, clear, join, contains, index_of, first, last, slice, concat, flatten, reverse, sort, unique, is_empty, map, filter, fold
  - STRINGS: upper, lower, strip, split, replace, contains, startswith, endswith, len, trim, ltrim, rtrim, substr, pad_left, pad_right, repeat, is_empty
  - DICTS: len, keys, values, has, get, set, remove, delete, entries, merge, is_empty
  - TIME: unix_ms, unix_ns, since_ms, since_ns, mark, elapsed, elapsed_ms, elapsed_ns, sleep_ms, sleep_ns
  - TERM: style, hr, clear
  - MEM: used, total, free, available, percent, process, snapshot, format
  - CPU: time_ns, time_ms, mark, elapsed, elapsed_ms, elapsed_ns, count, freq_mhz, cycles_est, loadavg, snapshot
  - GPU: available, snapshot
  - FS: read, write, append, exists, size, copy, move, drop, list, mkdir, rmdir, join, dir, name, ext
  - ENV: get, set, all, args, cwd, chdir
  - PROC: run, spawn, pipe, shell, read, write, on, exit, err, exec, exec_bg, kill, wait, exists
- Documentación actualizada:
  - CHANGELOG.md: added entrada de std.mire
  - docs/avenys-roadmap.md: actualizado con información de std.mire

### Validación
- `cargo test`: 80/80 tests pasando

---

## v2.6.0 (Mayo 2026)

### Unsafe Blocks
- Lexer + parser reconocen `unsafe { ... }`.
- Semantic model y borrow checker ya contabilizan contexto `unsafe`.
- Backend Avenys compila el contenido del bloque `unsafe` en el flujo normal.

### Extern / FFI
- Parser soporta:
  - `extern lib "alias" "ruta"`
  - `extern fn name: (...) :ret lib "alias"`
- Type checker registra firmas de `extern fn`.
- Tipos FFI puntero (`*const T`, `*mut T`) se normalizan como `i64` en el frontend actual.

### Inline Assembly
- Parser soporta bloques:
  - `asm { mov rax, rbx ... }`
- Instrucciones se preservan en AST.
- Backend Avenys actual acepta `asm` como no-op (sin emisión IR específica todavía).

### Validación
- `cargo test`: 80/80 tests de integración pasando.

---

## v2.0.0 (Abril 2026)

### Compilation & Build
- Compilación sin warnings (`cargo build`)
- Compilación incremental implementada (`src/incremental.rs`)
- IR en RAM para run/build, disco para debug

### Error System
- Error marker positioning (^^^) apunta a la ubicación correcta
- Línea y columna mostrada en diagnósticos
- Tipo de error mostrado (lexer/deprecated/parser/backend/type/runtime)
- Nombre de archivo fuente preservado
- Main compile path preserva source/filename
- Análisis de archivos importados preserva archivo origen
- Legacy `add` reportado como sintaxis deprecated
- "Avenys does not yet lower" reportado como limitación de backend

### Type & Ownership Checking
- Type inference para declaraciones de variables
- Type inference en expresiones binarias
- Function return type inference
- Assignment type mismatch detection
- Undefined identifier errors en sitio de uso
- Loop variable type inference
- If/while conditions verificadas como bool-like

### Standard Library
- Todos los módulos std registrados en typeck
- Builtin functions registradas (dasu, len, range, str, int, float, bool, input, etc.)

### Match Expressions
- Match con integer literals funciona
- Wildcard arm (_) funciona
- Match arm type consistency

### Enums
- Enum declaration parsea correctamente
- Qualified paths (Status.Ok)
- Enum variant instantiation
- Pattern matching con enum variants
- Multi-payload enum variants
- Nominal type: EnumNamed(String) preserva identidad

### Structs
- Struct declaration parsea
- Field access object.field retorna tipo correcto
- Method resolution para instance y associated calls
- Nominal types preservan identidad de tipo
- Structs con misma forma pero diferente nombre NO son intercambiables

### impl Syntax (v2.0.0)
- Instance methods requieren `self` explícito
- Static/associated methods usan Type::method(...)
- Enum-qualified paths bleiben Enum.Variant
- self no es inyectado implícitamente
- Instance dispatch solo para métodos que declaran self

### Tests
- 46 lib tests passing
- Regression tests passing
- Tests cubre: typeck, borrowck, parser, enums, structs, impl methods

### Parser Fixes
- Dict type ascription: parse_expression -> parse_pipeline_free_expression en literales
- Esto permitió `{a: 1} :map[str i64]` funcione correctamente

### Backend Fixes (Abril 2026)
- **Struct field access in function parameters**: Fix en compile_fn_block para propagar struct_name usando los parámetros de la LLAMADA (params.iter()) en lugar de fn_info.params. El error era "Avenys cannot resolve struct member 'x' without concrete struct metadata"

---

## v2.2.0 (Mayo 2026)

### Float Support (Literals & str())
- `LlType` enum: Añadido `F64` para representar `double` en LLVM
- `compile_expr`: Float ahora se compila como valor `double` (no string)
- `map_type`: `F64` ahora mapea a `LlType::F64` (no `Ptr`)
- `str(float)`: Nueva función `mire_f64_to_string(double) -> ptr` en runtime
- Runtime: `mire_f64_to_string()` usando `mire_managed_printf_f64("%.6g")`
- Soporte en `cast_to_i64`, `cast_to_i1`, `store_casted`, `emit_print` y más

**Casos soportados:**
```mire
set x = 3.14 :f64
use dasu(x)        # imprime 3.14

set s = str(3.14 :f64)
use dasu(s)        # imprime 3.14
```

### Tests
- 67/67 tests pasando

---

## v2.1.1 (Mayo 2026)

### Clippy Refactoring
- Reducción de warnings de 67 a 0 (100% clean)
- `from_str` → `parse_type` para evitar confusión con trait estándar
- `eq` → `equals` en MireValue (method independiente)
- `Box<Expression>` en `AssignmentTarget::Index` para reducir tamaño del enum
- Type alias `RunOptionsResult` en main.rs para tipo complejo de retorno

### Reference Type Unification
- `unify_types`: Ahora permite unificar `&T` con `T` (auto-unwrap de referencias)
- `is_assignable`: Ahora permite `&T` como asignable a `T` (auto-deref)
- `is_assignable`: Soporte completo para Ref→Ref y RefMut→Ref/RefMut

**Casos soportados:**
```mire
fn read_ref: (value :&i64) :i64 {
    return *value
}

pub fn main: () {
    set x = 41 :i64
    set rx = &x
    set y = read_ref(rx)
    use dasu(y + 1)  # imprime 42
}
```

### Tests
- 67/67 tests pasando (66 language regressions + 1 lib test)
- Fix: `shared_reference_lowering_compiles_and_runs` ahora pasa

---

## v2.1.0 (Mayo 2026)

### Logical Operators - C-Style Syntax

**Cambio de sintaxis:**
- `and`/`or`/`not` keywords REMOVIDOS
- Nuevos operadores C-style implementados:
  - `&&` - logical AND
  - `||` - logical OR
  - `!` - unary NOT
  - `^` - logical XOR

**Implementación:**
- Lexer: Nuevos tokens `AmpAmp`, `PipePipe`, `Xor`
- Parser: `parse_and()` → `&&`, `parse_or()` → `||`, `parse_not()` → `!`, `parse_xor()` → `^`
- Typeck: Operadores actualizados para usar símbolos
- Backend: Full LLVM IR generation para todos los operadores
- **Short-circuit evaluation**: `&&` y `||` ahora evalúan solo lo necesario usando branching

**Optimizaciones:**
- Short-circuit evaluation reduce work en expresiones booleanas complejas

---

## v1.0.x (Histórico)

### Enum Implementation (v1.0.2)
- Enum declaration
- Qualified paths (Status.Ok)
- Enum variant instantiation
- Pattern matching
- Multi-payload variants
- Nominal type preservation

### if as Expression
- Branch types unificados durante type checking
- Lowering usa el tipo de expresión resuelto

### Backend Improvements
- Diagnostic categorization como backend limitations

---

## 📝 Notas de Síntesis

### Síntaxis Actual del Match (v2.0.0)
```mire
match value {
    Pattern { body }
}
```
- Cuerpo debe ser expresión inline
- NO soporta multilínea directamente
- NO permite comparación en condition

### Síntaxis Propuesta para Futuro
Ver `todo.md` sección SYNTAX IMPROVEMENTS

---

## v2.6.0 (Mayo 2026)

### Sistema de Diagnóstico Unificado (D6)
- Nuevo `src/error/diagnostic.rs`: tipos core `Diagnostic`, `Severity`, `DiagnosticCode` (E0001–E0015, W0001–W0027), `Label`, `Suggestion`, `WarningFilter`.
- Nuevo `src/error/format.rs`: `format_diagnostic()` con contexto de código, colores, labels, notes, help.
- `MireError` refactorizado para envolver `Diagnostic` con `Severity::Error`. Retrocompatibilidad de API preservada.
- `MssError` mapeado a códigos de diagnóstico E0007–E0013.
- Warnings reescritas para emitir `Diagnostic`. Tracking de variables/funciones no usadas reparado.
- Pipeline integrado: `analyze_program_with_warnings()` con `WarningConfig` (filter + deny).
- Nuevo comando `mire check <file>`: análisis completo sin generar binario.
- Nuevos flags CLI: `--warn-all`, `-W <Wxxxx>`, `--deny <Wxxxx>`.
- Tests de warnings en `tests/warnings/`.
- Documentación de diseño: `docs/diagnostic-system.md`, `MORE/0004-diagnostic-system.md`.
- Guía de integración Owl: `docs/owl-diagnostics.md`.

### Archivos modificados
- `src/error/mod.rs`, `src/error/mss.rs` — refactor diagnóstico
- `src/compiler/warnings.rs` — rewrite completo
- `src/compiler/mod.rs`, `src/avens/mod.rs` — pipeline integration
- `src/main.rs`, `src/lib.rs` — CLI + exports
- `Cargo.toml` — bump v2.5.6 → v2.6.0
- `docs/cli.md`, `todo.md`, `CHANGELOG.md` — documentation

### Validación
- `cargo build` ✅
- `cargo test -q` ✅ (87 + 80 pasando)
