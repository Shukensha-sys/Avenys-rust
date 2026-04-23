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

### 🟡 INVESTIGADO (Postergar)

| Feature | Estado | Notas |
|---------|--------|-------|
| Block parsing unificado | ⚠️ INVESTIGADO | Sistema actual (AnalysisUnit + max_units) funciona. Requiere refactor significativo - postergar |
| MireError (result_large_err) | ⚠️ INVESTIGADO | Tipo >136 bytes. Requiere cambio arquitectónico - postergar |
| Parser/Main if warnings | ⚠️ INVESTIGADO | ~30 warnings if_same_then_else, collapsible. Esfuerzo medio - postergar |

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

---

## Referencias

- Test actual: `tests/language_regressions.rs:56-78` (testea `add` como deprecated)
- Parser: `src/parser/mod.rs:148` (`is_legacy_add_statement`)