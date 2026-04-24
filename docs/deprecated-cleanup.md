# Deprecated & Obsolete Syntax Cleanup Plan

Plan para eliminar sintaxis deprecated y obsolete del compilador Avenys.

---

## Inventario Actual

### 🔴 ELIMINAR (Deprecated - Reportado)

| Sintaxis | Estado | Ubicación | Acción |
|---------|--------|-----------|---------|
| `add std` | ✅ ELIMINADO | parser/mod.rs | Eliminado completamente |
| Angle brackets `<>` | ✅ ELIMINADO | parser/mod.rs:3076 | Ya eliminado |

### 🟡 RESERVADO PARA FUTURO

| Sintaxis | Estado | Notas |
|---------|--------|-------|
| `class` | ⚠️ No implementado | Reservado |
| `module` | ⚠️ No implementado | Reservado |
| `unsafe` | ⚠️ No implementado | Reservado para FFI |
| `asm` | ⚠️ No implementado | Reservado |
| `extern lib` | ⚠️ No implementado | Planeado |
| `extern fn` | ⚠️ No implementado | Planeado |

### ✅ RESUELTO (Abril 2026)

| Feature | Estado | Notas |
|---------|--------|-------|
| Block parsing unificado | ✅ RESUELTO | Parser ahora usa helpers unificados para slicing hasta apertura/cierre de bloque y subparser reutilizable |
| MireError (result_large_err) | ✅ RESUELTO | `MireError` compactado moviendo contexto opcional a estructura boxed; `result_large_err` desaparece |
| Parser/Main if warnings | ✅ RESUELTO | Se eliminaron los casos más ruidosos y el clippy focalizado bajó drásticamente |

---

## Plan de Limpieza

### ✅ COMPLETADO (Abril 2026)

#### 1.1 `add` Keyword - ELIMINADO
- **Cambios**:
  - Eliminada función `is_legacy_add_statement()` del parser
  - Eliminado `Statement::AddLib` del AST
  - Eliminados todos los match arms en typeck, borrowck, semantic, incremental
  - Eliminados imports no usados en typeck.rs
  - Actualizado test: ahora `add` es "Unknown identifier"

#### 1.2 Angle Brackets `<>` - Ya eliminado
- Confirmado en tests: rechazado

### Estado Actual

**Eliminado**: `add std`
**Reservado**: `class`, `module`, `unsafe`, `asm`, `extern lib`, `extern fn`

---

## Recomendación

### Completado:
1. ✅ Eliminado `add` - ahora treated as unknown identifier
2. ✅ Angle brackets eliminado
3. ✅ Documentado reservado para futuro: `class`, `module`, `unsafe`, `asm`, `extern`
4. ✅ Parsing de bloque unificado en helpers compartidos del parser
5. ✅ `MireError` compactado sin romper formato ni contexto
6. ✅ Limpieza de warnings investigados en `parser`, `main` y `avens`

---

## Referencias

- Test actual: `tests/language_regressions.rs:56-78` (testea `add` como deprecated)
- Parser: `src/parser/mod.rs:148` (`is_legacy_add_statement`)
