# Todo - Estado del Compilador Avenys

Última actualización: Abril 2026

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

### Reglas de Implementación
- Antes de modificar src/: crear backup con git commit
- Aplicar SOLID principles
- Sin warnings en compilación
- Documentar cambios en: `avenyslogs.md`, `docs/issues.md`, `docs/avenys-roadmap.md`

### Priority Order
1. ✅ Match Multilínea
2. ✅ Logical Operators (C-style)
3. ✅ Match with Comparison
4. ✅ Short-circuit evaluation
5. ✅ Bitwise operators
6. ✅ Struct field reassignment
7. ✅ Critical borrow/semantic (ya estaban)
8. ✅ Type checking (investigados)

---

## 📝 Referencias

- Cambios: `avenyslogs.md`
- Limitaciones: `docs/issues.md`
- Síntaxis: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`