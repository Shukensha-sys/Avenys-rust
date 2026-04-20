# Todo - Pendiente de Implementar

Próximos cambios y mejoras para Avenys. Ver `avenyslogs.md` para cambios ya completados.

---

## 🚧 SYNTAX IMPROVEMENTS (Propuestas)

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

### Boolean Operators (@ prefix)
```mire
@| a b   # OR: a o b
@& a b   # AND: a y b
@! a     # NOT: negación
@^ a b   # XOR: a xor b
```

---

## 🚧 PENDING (Próximas tareas)

### HIGH PRIORITY
1. ~~Match Multiline Body~~ - ✅ RESOLVED
2. **Boolean Operators (@)** - Agregar operadores lógicos con @ prefix

### MEDIUM PRIORITY
3. Match with Comparison (sintaxis alternativa)
4. Deprecated syntax cleanup
4. Block parsing unificado
5. Parser warnings cleanup
6. Struct field validation

### LOW PRIORITY
7. Pipelines semantics
8. Traits & Skills profundos
9. extern lib/fn semantics
10. Diagnostic regression tests

---

## 📝 Notas de Desarrollo

### Reglas de Implementación
- **Antes de modificar src/**: crear backup con git commit
- **Aplicar SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Sin warnings**: todo código debe compilar sin warnings de rustc

### Priority Order Actual
1. Fase 1: Match Multilínea (syntax improvement)
2. Fase 2: Boolean Operators (@ prefix)
3. Fase 3: Fixes menores y diagnostics

---

## 📝 Referencias

- Cambios completados: `avenyslogs.md`
- Limitaciones conocidas: `docs/issues.md`
- Síntaxis actual: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`