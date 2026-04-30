# Mire Compiler Bug Report - Issues Encontradas

## Estado: Mayo 2026 - v2.1.1

**Resumen:** Se realizó una prueba exhaustiva del lenguaje Mire. Muchos issues reportados han sido resueltos. Los issues restantes (floats) están documentados para referencia futura.

**Stats actuales:**
- Clippy: **0 warnings** ✅
- Tests: **67/67 pasando** ✅
- Issues resueltos: 11/13

---

## ✅ RESUELTOS

### 1. Declaracion de Funciones - ✅ RESUELTO
- La sintaxis `fn nombre: (params) :tipo >` ahora funciona en todos los directorios
- El parser reconoce correctamente `fn` fuera del directorio benchmarks

### 4. Structs - ✅ RESUELTO
- Los structs ahora funcionan correctamente
- Campo access `p.x`, constructor `(Point x:10 y:20)` ✅
- Validado con tests en `tests/complex/data_structures/`

### 5. Indizado de Arrays - ✅ RESUELTO
- `arr at 0` ahora devuelve el elemento correcto (antes estaba invertido)
- Bounds checking implementado en runtime

### 6. Declaracion de Variables en Ramas If - ✅ RESUELTO
- Las ramas if/else ahora mantienen el scope correctamente
- Variables declaradas en ramas disponibles post-if

### 7. Else en Condicionales Multilinea - ✅ RESUELTO
- `if ... > < else > ... <` ahora funciona correctamente

### 9. Error de LLVM en Structs - ✅ RESUELTO
- El código LLVM generado ahora es válido
- `getelementptr` indices correctos

### 10. Pipelines con `self` - ✅ RESUELTO (Limitado)
- Closures en pipelines funcionan: `nums => (x => x * 2)`
- `self` en pipelines tiene limitaciones documentadas

### 11. Mapas - Sintaxis de Literales - ✅ RESOLVIBLE
- Literal map vacío con tipo: `{} :map![str,i64]` ✅
- `dicts.set()` para construcción dinámica ✅

---

## 🟢 RESUELTO (v2.2.0)

### 2, 3, 12. Float Literals y Conversión

**Descripción:** Float literals y conversión `str(float)` ahora funcionan.

**Estado:** ✅ RESUELTO (Mayo 2026)
- `set x = 3.14 :f64` funciona
- `str(3.14 :f64)` convierte a string

---

*Reporte original: 2026-04-10*
*Actualizado: 2026-05-28*