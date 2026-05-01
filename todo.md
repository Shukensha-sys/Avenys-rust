# Todo - Estado del Compilador Avenys

Última actualización: Mayo 2026

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
13. ✅ M1 stable hash sin buffer intermedio (streaming) (Mayo 2026)

---

## 📝 Referencias

- Cambios: `avenyslogs.md`
- Limitaciones: `docs/issues.md`
- Síntaxis: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`
