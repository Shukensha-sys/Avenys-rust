# Open Issues

Estado operativo de issues abiertas del compilador Avenys.

Última actualización: Mayo 2026

## Resumen

- Críticas abiertas: 1
- Bugs reales abiertos: 1
- Deuda técnica abierta: 0
- Diseño/optimización abierta: 0

## Bugs Abiertos

### REC-1: Funciones Recursivas Retornan 0

**Severidad:** Alta
**Estado:** Investigado (Mayo 2026)
**Área:** Backend Avenys (LLVM lowering)

Las funciones recursivas siempre retornan 0 en lugar del valor calculado.

**Ejemplo:**
```mire
fn fibonacci: (n :i64) :i64 {
    if n <= 1 { return n }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

pub fn main: () {
    set f = fibonacci(10)  // Retorna 0, esperado 55
}
```

**Investigación:** `docs/issues/recursion_bug_investigation.md`

**Posibles causas:**
1. Falta forward declaration en LLVM IR
2. Orden de generación de funciones incorrecto
3. Problema en el registro de funciones

---

## Próximos objetivos recomendados

1. Investigar y corregir el bug de recursión (REC-1)
2. Agregar tests de regression para funciones recursivas
3. Verificar generación de LLVM IR para llamadas recursivas
