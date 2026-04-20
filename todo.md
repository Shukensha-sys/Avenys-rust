# Todo - Pendiente de Implementar

Próximos cambios y mejoras para Avenys. Ver `avenyslogs.md` para cambios ya completados.

---

## 🚧 SYNTAX IMPROVEMENTS

### Match Multilínea
```mire
# ACTUAL:
match x { Pattern { body } }

# PROPUESTO:
match x {
    Pattern => {
        body line 1
        body line 2
    }
    _ => { default }
}
```
- Usar `=>` para indicar caso
- `{ }` para bloque multilínea

### Boolean Operators (@ prefix)
```mire
@| a b   # OR: a o b
@& a b   # AND: a y b
@! a      # NOT: negación
@^ a b   # XOR: a xor b
```
- `@` como prefix para operadores lógicos
- Más claro para parsear

### Comparadores en Match
```mire
# PROPUESTO (expresión fuera del match):
set result = @| (x >= 5) (y < 10)
```

---

## 🚧 COMPLETADO

### L009 - Struct Field Access in Function Parameters

✅ RESOLVER - Ahora funciona correctamente el acceso a campos de struct en funciones

---

## 🚧 PENDING

### Frontend & Parser
1. Deprecated syntax cleanup - más-allá de legacy `add`
2. Block parsing - unificar if/while/for/match
3. Parser warnings cleanup

### Type System
4. Struct field validation
5. impl methods - nominal owner types

### Language Features
6. Pipelines semantics
7. Traits & Skills profundos
8. extern lib/fn semantics
9. unsafe/asm/module semantics

### Backend
10. Diagnostic regression tests expansion

---

## 🔴 PRIORITY ORDER

### Fase 1: Match Multilínea
优先最高 - cambiar sintaxis de match

### Fase 2: Boolean Operators (@)
Priority media - agregar operadores

### Fase 3: Fixes
- Struct field access
- Más diagnostics

---

## 📝 Referencias

- Cambios completados: `avenyslogs.md`
- Síntaxis actual: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`