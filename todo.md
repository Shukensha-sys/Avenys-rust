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

### 8. Inline Assembly
```
asm {
    mov rax, rbx
    add rax, rcx
}

### Backend Pass (v2.5.4) - Completado
- ✅ Cobertura ampliada en lowering de backend (`src/avens/mod.rs`)
  - Statements frontend-only ya no disparan error genérico en codegen.
  - Literales `List/Dict/Tuple` ahora se compilan.
  - Builtins `strings.*` adicionales cableados en backend.
  - `map_type` ampliado para tipos antes no mapeados.
- ⏳ Pendiente real (siguiente iteración):
  - FFI real (ABI/link), asm real, `list.pop`, `contains` genérico, `sqrt`, `range` first-class, `for` no-range.

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
```
- **Estado:** ✅ Implementado (lexer + parsing de bloque asm)
- **Nota actual:** En backend Avenys, `asm` se acepta pero se trata como no-op de lowering (sin emisión IR específica todavía).
