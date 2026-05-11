# Todo - Estado del Compilador Avenys

Última actualización: Mayo 2026

---

## ✅ Deuda Técnica Completa (Mayo 2026)

### D2: Blob Store Compactation
- **Estado:** ✅ Completado
- **Descripción:** Compactación automática cuando ratio < 0.7

### D3: Unicode Case Conversion
- **Estado:** ✅ Completado (Mayo 4, 2026)
- **Descripción:** Extendido to_upper/to_lower para Latin-1 Supplement (0xC0-0xFF)
- **Tests:** 167 passed (87 unit + 80 integration), 0 failed

### D4: Memory Leak Dict Format
- **Estado:** ✅ Completado (Mayo 4, 2026)
- **Descripción:** Arreglada doble asignación en mire_dict_format_value para nested maps

### D5: Reference Mutability Semantics
- **Estado:** ✅ Completado (Mayo 4, 2026)
- **Descripción:** &x infiere mutabilidad del binding, &mut x rechazado si inmutable

---

## 📝 Compilador Estable (Mayo 4, 2026)

### Estado Final:
- ✅ Deuda técnica D2-D5 resuelta
- ✅ Recursión funciona correctamente (fib, factorial, mutual, etc.)
- ✅ Vectores hasta 10M+ elementos
- ✅ Strings hasta 1M caracteres
- ✅ Loops hasta 10k+ iteraciones
- ✅ 167 tests passing

---

**Feedback (Mayo 4, 2026):**
- Compilador estable y listo para producción

---

## ✅ Features Implementadas (v2.1.x)

### Clippy Clean (0 warnings)
```
cargo clippy  # 0 warnings (v2.1.1)
```

### Reference Type Unification
```mire
fn read_ref: (value :&i64) :i64 {
    return *value
}

pub fn main: () {
    set x = 41 :i64
    set rx = &x
    set y = read_ref(rx)
    use dasu(y + 1)  # 42
}
```

---

## ✅ Features Implementadas (v2.x)

### Match Multilínea
```mire
match x {
    Pattern {
        body line 1
        body line 2
    }
    _ => { default }
}
```

### Operadores Lógicos (C-style)
```
!a      # NOT lógico
a && b  # AND con short-circuit
a || b  # OR con short-circuit
a ^ b   # XOR
```

### Operadores Bitwise
```
a & b   # Bitwise AND
a | b   # Bitwise OR
a ^ b   # Bitwise XOR
a << b   # Shift left
a >> b   # Shift right
```

### Struct Field Reassignment
```mire
struct Counter { value :i64 }
set c = (Counter value: 0) mut
set c.value = 1  # ✅ Funciona
```

---

## ✅ Features Investigadas (Diseño, No Bugs)

### Member Access
El compilador ya lanza errores cuando no encuentra fields/methods.

### Pipeline Typing
Usa elem_type como fallback - comportamiento razonable.

### Reference Types
Infiere tipo del target expression.

---

## 📝 Notas de Desarrollo

### Próximas Líneas (Post v2.3.x)
1. ✅ Hardening de cache incremental:
- Tests de corrupción parcial de `.cache/incremental.bin`
- Recuperación graceful (sin crash, fallback limpio)
- Auto-saneado del archivo corrupto/incompatible para evitar degradación repetida
2. ✅ Performance del frontend de análisis:
- Bench/perf tests para `analysis_units_for_program`
- Bench/perf tests para `compute_invalidation_report` en programas grandes
3. ✅ Limpieza operativa del backlog:
- Separar "histórico resuelto" vs "pendiente real" en `docs/issues.md`
- Mantener tablero accionable por prioridad real

### Reglas de Implementación
- Antes de modificar src/: crear backup con git commit
- Aplicar SOLID principles
- Sin warnings en compilación (objetivo: cargo clippy 0 warnings)
- Documentar cambios en: `avenyslogs.md`, `docs/issues.md`, `docs/avenys-roadmap.md`

### Priority Order
1. ✅ Clippy Clean (v2.1.1) - 67 warnings → 0 warnings
2. ✅ Reference Type Unification (v2.1.1) - `&T`↔`T` en unify_types e is_assignable
3. ✅ Match Multilínea
4. ✅ Logical Operators (C-style)
5. ✅ Match with Comparison
6. ✅ Short-circuit evaluation
7. ✅ Bitwise operators
8. ✅ Struct field reassignment
9. ✅ Critical borrow/semantic (ya estaban)
10. ✅ Type checking (investigados)
11. ✅ D2 Blob store compactación automática (Mayo 2026)
12. ✅ B3 return-safety scope alignment verificado con test de regresión (Mayo 2026)
13. ✅ M1 hash estructural directo del AST (sin serialización) (Mayo 2026)
14. ✅ M2 contexto explícito de fuente en type checker validado con regresiones (Mayo 2026)
15. ✅ Literales Avanzados (bin/oct/hex, raw strings, char) (Mayo 2026)

---

## 📝 Referencias

- Cambios: `avenyslogs.md`
- Limitaciones: `docs/issues.md`
- Síntaxis: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`

---

## ✅ Literales Avanzados (v2.5.x)

Implementación completada bajo tus reglas, con respaldo previo creado.

**Commit de respaldo (antes de tocar esta fase):**
- `1eced89` (backup: estado previo antes de implementar literales numericos avanzados, raw strings y char)

**Cambios realizados:**

- Literales bin/oct/hex:
  - Soporte en lexer para 0b, 0o, 0x con validación y conversión segura.
  - Archivo: `src/lexer/mod.rs`

- Raw strings con delimitadores:
  - Soporte `r"..."`, `r#"..."#`, `r##"..."##` en lexer.
  - Se preserva contenido literal sin escapes procesados.
  - Archivo: `src/lexer/mod.rs`

- Character literals + tipo char:
  - Nuevo token `CharLit`.
  - Nuevo `Literal::Char(u32)` y `DataType::Char`.
  - Parseo de `'a'`, `'\n'`, Unicode directo como escalar u32.
  - Type checking actualizado para char.
  - Lowering Avenys actualizado (char mapeado a escalar entero en backend).
  - Archivos:
    - `src/lexer/mod.rs`
    - `src/parser/ast.rs`
    - `src/parser/mod.rs`
    - `src/compiler/typeck.rs`
    - `src/avens/mod.rs`
    - `src/incremental.rs`

**Tests agregados/actualizados:**

- Parser:
  - `parses_prefixed_integer_literals`
  - `parses_raw_strings_with_hash_delimiters`
  - `parses_char_literals_as_unicode_scalar_u32`
  - Archivo: `src/parser/mod.rs`

- Integración:
  - `advanced_literals_compile_and_run` (bin/oct/hex + raw + char)
  - Archivo: `tests/language_regressions.rs`

**Documentación actualizada:**

- Sintaxis oficial ampliada:
  - for con segundo binding, tipo char, formas literales nuevas.
  - Archivo: `SYNTAX.md`
- Roadmap actualizado con estado real de sintaxis implementada:
  - Archivo: `docs/avenys-roadmap.md`
- Changelog actualizado con los tres features:
  - Archivo: `CHANGELOG.md`

**Validación final:**
- `cargo test` completo ejecutado: **78 passed; 0 failed**

---

## 🔜 Pendiente: Nuevas Features de Sintaxis

### 5. Uniform Call Syntax (Piping) |>
```
set doubled = [1 2 3]
    |> lists.map((x) => x * 2)
    |> lists.filter((x) => x > 2)
```
- **Nota:** Diferente al pipeline `=>` existente
- **Propósito:** Encadenar funciones de libs de forma legible
- **Falta:** Nuevo token + parsing

### 6. Unsafe Blocks
```
unsafe {
    set x = 2 :i64
}
```
- **Estado:** ✅ Implementado (lexer + parsing + typecheck/borrowck + lowering Avenys)

### 7. Extern / FFI
```
extern lib "c" "libc.so.6"
extern fn printf: (fmt :*const i8) :i32 lib "c"
```
- **Estado:** ✅ Implementado (lexer + parsing + integración en firmas de typecheck)
- **Nota actual:** Parámetros puntero `*const/*mut` se normalizan como escalar `i64` en frontend.
- **Backend (v2.5.5):** `extern fn` emite `declare` LLVM.
- **Pendiente:** Linking/ABI completo multi-plataforma.

### 8. Inline Assembly
```
asm {
    mov rax, rbx
    add rax, rcx
}
```
- **Estado:** ✅ Implementado (lexer + parsing de bloque asm)
- **Backend (v2.5.5):** emite inline asm mínimo con `asm sideeffect`.
- **Pendiente:** modelado de constraints avanzadas y clobbers por target.

### Backend Pass (v2.5.5) - Estado actualizado
- ✅ Cobertura ampliada en lowering de backend (`src/avens/mod.rs`)
  - `for` soporta `range(...)` y colección (`list/vector/slice`).
  - `list.pop`, `contains/strings.contains`, `sqrt`, `strings.substr/pad_left/pad_right/repeat` con lowering real.
  - `match` distingue `str` (strcmp) y punteros no-string (comparación de puntero).
  - `Drop` y `Move` ya bajan a IR.
  - `extern fn` y `asm` ya no son no-op.
  - Literales `List/Dict/Tuple` ahora se compilan.
  - `map_type` ampliado para tipos antes no mapeados.
- ⏳ Pendiente real (siguiente iteración):
  - FFI real (ABI/link completo), inline asm avanzada, `range` first-class completo.

---

## 🦉 Owl (Gestor de Proyecto Mire) - Estado Mayo 2026

### ✅ Completado reciente
- Corrección de `owl test`:
  - acumulación de imports en harness (sin overwrite)
  - workaround para corrupción de strings en nombre de función del harness
  - validación `--filter` sin valor
- `mkdir_p` ahora soporta rutas absolutas.
- `cmd_clean` con mensaje consistente.
- Documentación de Owl actualizada a v0.3.1.

### ⏳ Pendiente real
1. Extracción robusta de paquetes para `owl install url:` (`.tar.gz`) sin edge-cases.
2. `owl.lock` con metadata de dependencia.
3. Parser de Semver y validación de rangos.
4. Verificación de hashes SHA-256.

---

# 🔷 D6: Sistema de Diagnóstico Unificado (Error + Warning) — ✅ Completado v2.6.0

**Prioridad:** Alta
**Estado:** ✅ Completado (Mayo 2026)
**Versión:** v2.6.0
**Commits:**
  - `383bd4f` — checkpoint: before unified diagnostic system refactor
  - `050f49f` — feat(diagnostics): unify error/warning pipeline, add warning filters, and `mire check`
**Docs de diseño:** `docs/diagnostic-system.md`, `MORE/0004-diagnostic-system.md`
**Tests:** cargo test ✅ (87 + 80 pasando)

---

## Resumen

Se reemplazó el sistema dual de errors (`MireError` + `ErrorKind`) y warnings (`Warning` struct) por un sistema de diagnóstico unificado donde ambos comparten la misma infraestructura, formato de salida y códigos únicos.

Antes: las warnings **nunca se emitían** — `Warnings::analyze()` existía pero nunca se llamaba.
Ahora: warnings integradas en el pipeline con `WarningFilter`, formato rico con contexto de código, y control via CLI.

---

## Cambios Realizados

| Fase | Archivos | Estado |
|------|----------|--------|
| 1. Base Diagnostic | `src/error/diagnostic.rs` (nuevo), `src/error/format.rs` (nuevo) | ✅ |
| 2. Refactor MireError | `src/error/mod.rs`, `src/error/mss.rs` | ✅ |
| 3. Refactor Warnings | `src/compiler/warnings.rs` | ✅ |
| 4. Pipeline Integration | `src/compiler/mod.rs`, `src/avens/mod.rs` | ✅ |
| 5. `mire check` command | `src/main.rs` | ✅ |
| 6. CLI flags `-W`/`--deny` | `src/main.rs` | ✅ |
| 7. Tests | `tests/warnings/` | ✅ |

### Detalle por Fase

**Fase 1:** `diagnostic.rs` con `Diagnostic`, `Severity`, `DiagnosticCode` (E0001–E0015, W0001–W0027), `Label`, `Suggestion`, `WarningFilter`, `WarningCategory`. `format.rs` con `format_diagnostic()` con contexto de código, colores, labels, notes, help.

**Fase 2:** `MireError` ahora envuelve `Diagnostic` con `Severity::Error`. `ErrorKind` migrado a `DiagnosticCode`. `generate_explanation()` reemplazado por mensajes fijos por código. `MssError` mapeado a E0007–E0013. Retrocompatibilidad de API preservada.

**Fase 3:** Warnings reescritas para emitir `Diagnostic`. Tracking de variables/funciones arreglado (unused warnings ahora funcionan). `line`/`column` real propagados desde AST. Notas contextuales añadidas. Warnings ruidosas (W044–W046) eliminadas.

**Fase 4:** `analyze_program_with_warnings()` en pipeline. `WarningConfig` con `filter` + `deny`. Warnings se imprimen por stderr sin detener compilación. `BuildOptions` incluye `warning_filter` + `deny_warnings`.

**Fase 5:** `mire check <file>` ejecuta análisis completo sin generar binario. Exit 0 si solo warnings, 1 si hay errores.

**Fase 6:** `--warn-all`, `-W <Wxxxx>`, `--deny <Wxxxx>` en todos los comandos.

**Fase 7:** Tests de warnings en `tests/warnings/`. Formateador verificado con/sin color.

---

## Códigos de Diagnóstico

| Código | Severidad | Categoría | Descripción |
|--------|-----------|-----------|-------------|
| E0001 | Error | Lexer | Carácter inesperado |
| E0002 | Error | Lexer | String/comment no terminado |
| E0003 | Error | Parser | Token esperado no encontrado |
| E0004 | Error | Parser | Token inesperado |
| E0005 | Error | Type | Type mismatch |
| E0006 | Error | Type | Unknown identifier |
| E0007 | Error | Borrow | Use after move |
| E0008 | Error | Borrow | Multiple mutable refs |
| E0009 | Error | Borrow | Mutation while shared |
| E0010 | Error | Borrow | Move while borrowed |
| E0011 | Error | Borrow | Drop while borrowed |
| E0012 | Error | Borrow | Double drop |
| E0013 | Error | Borrow | Borrow out of scope |
| E0014 | Error | Backend | Construct not yet lowered |
| E0015 | Error | Runtime | Error general de runtime |
| W0001 | Warning | Unused | Unused variable |
| W0002 | Warning | Unused | Unused function |
| W0003 | Warning | Unused | Unused import |
| W0004 | Warning | Type | Implicit type annotation |
| W0005 | Warning | Type | Implicit return type |
| W0006 | Warning | Style | Empty function body |
| W0007 | Warning | Performance | Multiplication by zero |
| W0008 | Warning | Performance | Division by zero |
| W0009 | Warning | Performance | Modulo by zero |
| W0010 | Warning | Deprecated | Deprecated syntax usage |
| W0011 | Warning | Complexity | Overly long function |
| W0012 | Warning | Style | Too many parameters |
| W0013 | Warning | Style | Empty loop body |
| W0014 | Warning | Style | Empty if branches |
| W0015 | Warning | Logic | Condition always true/false |
| W0016 | Warning | Logic | Infinite loop (while true) |
| W0017 | Warning | Logic | Unreachable loop body |
| W0018 | Warning | Complexity | Deeply nested loops |
| W0019 | Warning | Logic | Break/continue outside loop |
| W0020 | Warning | Type | Call to undefined function |
| W0021 | Warning | Type | Negative index access |
| W0022 | Warning | Style | Negative literal used directly |
| W0023 | Warning | Style | Useless literal expression |
| W0024 | Warning | Style | Very long string literal |
| W0025 | Warning | Memory | Large list/dict literal |
| W0026 | Warning | Style | Magic number 0 or 1 |
| W0027 | Warning | Performance | Unnecessary clone call |

### Comportamiento por defecto

| Comando | Warnings activas |
|---------|-----------------|
| `mire run` / `mire build` | W0001–W0005 (unused, implicit types) |
| `mire check` | Todas (W0001–W0027) |
| `mire run --warn-all` | Todas |
| `mire run -W W0010` | Default + deprecated |

---

## Formato de Salida

```
error[E0005] ── Type Mismatch
╭─[ main.mire:5:12 ]
│ 4 │     set x = 42 :int
│ 5 │     set y = "hello" :char
│   │             ^^^^^^^ expected `char`, found `str`
│ 6 │     use dasu(x)
╰─ Cannot assign `str` to variable of type `char`
   ─┬─ help: try converting with `.to_char()` or change the type annotation

warning[W0001] ── Unused Variable
╭─[ main.mire:3:9 ]
│ 2 │     set hi = "hola" :char
│ 3 │     set bye = "adios" :char
│   │         ^^^
│ 4 │
│ 5 │     use dasu(hi)
╰─ Variable 'bye' is never used
   ─┬─ note: prefix with `_` to suppress this warning
```

---

## Estructura de Archivos Final

```
src/error/
├── mod.rs           # MireError → envuelve Diagnostic { severity: Error }
├── mss.rs           # MssError → migrado a DiagnosticCode (E0007-E0013)
├── diagnostic.rs    # Diagnostic, Severity, DiagnosticCode, Label, Suggestion
└── format.rs        # format_diagnostic() con contexto + colores
```

---

## Notas Técnicas

- `MireError` debe mantener tamaño ≤ 80 bytes (hay test que lo verifica)
- Formateador debe funcionar con y sin color (ANSI)
- Warnings en `mire run`/`build`: stderr, no detienen compilación
- `mire check`: exit 0 si solo warnings, exit 1 si hay errores
- Compatibilidad hacia atrás: toda API pública de `MireError` debe seguir funcionando
- Documentar cambios en: `avenyslogs.md`, `docs/issues.md`, `docs/diagnostic-system.md`
