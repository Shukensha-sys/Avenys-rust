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

### Logical Operators (C-style)
```
!a      # NOT: negación lógica
a && b  # AND: a y b (short-circuit)
a || b  # OR: a o b (short-circuit)
a ^ b   # XOR: a xor b
```

**Status**: ✅ IMPLEMENTED (Mayo 2026)
- `&&`, `||`, `^`, `!` operators now supported
- Old keywords `and`/`or`/`not` REMOVED

#### Bitwise Operators (C-style)
```
a & b   # Bitwise AND - PENDING
a | b   # Bitwise OR - PENDING
a ^ b   # Bitwise XOR - PENDING
a << b  # Shift left - PENDING
a >> b  # Shift right - PENDING
```

---

## 🚧 PENDING (Próximas tareas)

### HIGH PRIORITY
1. ~~Match Multiline Body~~ - ✅ RESOLVED
2. ~~Logical Operators (C-style)~~ - ✅ RESOLVED (!, &&, ||, ^)
3. ~~Match with Comparison~~ - ✅ RESOLVED
   - parse_match_value uses parse_or() for full expressions
   - Soporta !, &&, ||, ^, comparaciones

### MEDIUM PRIORITY
3. Match with Comparison (sintaxis alternativa)
4. ~~Deprecated syntax cleanup~~ - ✅ ELIMINADO (`add`)
5. ~~Block parsing unificado~~ - INVESTIGADO (Requiere refactor significativo)
   - Sistema actual (AnalysisUnit + max_units=256) cumple para la mayoría
   - Funciones >10k líneas deberían dividirse en archivos
   - Postergar hasta nueva fase de optimización
6. ~~Parser warnings cleanup~~ - PARCIAL (arreglado if_same_then_else, collapsible_if en parser/avens)
   - остальные warnings de clippy (~300 result_large_err) postergados
7. ~~Struct field validation~~ - ✅ RESOLVED
   - Field reassignment: c.x = 1 ahora funciona
   - Partial init: (Point x: 10) ahora funciona

### LOW PRIORITY
6. ~~Closures in Pipelines~~ - ❌ INVESTIGATED (Requiere refactor significativo en backend)
   - Parser/typeck soportan sintaxis, pero backend no compila closures como pipeline stages
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
- **Documentación**: Al implementar, actualizar o arreglar algo, documentar en:
  - `avenyslogs.md` - cambios completados
  - `docs/issues.md` - limitaciones resueltas
  - `docs/avenys-roadmap.md` - estado actual
  - NO modificar README.md ni syntax-*.md a menos que sea necesario y manteniendo su formato

### Priority Order Actual
1. Fase 1: Match Multilínea (syntax improvement) - ✅ DONE
2. Fase 2: Logical Operators (C-style) - ✅ DONE (!, &&, ||, ^)
3. Fase 3: Match with Comparison - ✅ DONE
4. Fase 4: Short-circuit evaluation for && and || - ⏳ PENDING
5. Fase 5: Bitwise operators - ⏳ PENDING

---

## 📝 Referencias

- Cambios completados: `avenyslogs.md`
- Limitaciones conocidas: `docs/issues.md`
- Síntaxis actual: `syntax-V2.0.0.md`
- Roadmap: `docs/avenys-roadmap.md`