# Mire Compiler Bug Report - Issues Encontradas

## Resumen Ejecutivo

Se realizo una prueba exhaustiva del lenguaje Mire con el objetivo de encontrar fallos y comportamientos inesperados en el compilador. Se probaron diferentes areas: variables, tipos, funciones, condicionales, loops, arrays, vectores, maps, structs, strings, y conversiones de tipos.

A continuacion se documentan todos los problemas encontrados.

---

## 1. Declaracion de Funciones - Error de Tokenizacion

**Severidad:** Alta

**Descripcion:** La declaracion de funciones falla con el error "Expected identifier" cuando la funcion se declara en un archivo que no esta en el directorio de benchmarks.

**Comportamiento Esperado:** Las funciones deben declararse con la sintaxis `fn nombre: (params) :tipo >`.

**Comportamiento Real:** El parser no reconoce `fn` como inicio de declaracion de funcion en archivos fuera del directorio `benchmarks/`.

**Ejemplo Fallido:**
```mire
import std

fn import: (a:i64 b:i64) :i64 >
    return a + b
<

pub fn main: () >
    set result = import(5 3)
    use dasu("result: {result}")
<
```

**Error:**
```
error[parser]: Expected identifier
3 |fn import: (a:i64 b:i64) :i64 >
  |      ^^^...
```

**Nota:** Los benchmarks en el directorio `benchmarks/` funcionan correctamente, pero los archivos en otros directorios fallan.

---

## 2. Conversion de Float a String No Soportada

**Severidad:** Alta

**Descripcion:** No es posible convertir valores float/f64 a string.

**Comportamiento Esperado:** `str(3.14 :f64)` deberia retornar "3.14".

**Comportamiento Real:** Error en tiempo de ejecucion.

**Codigo de prueba:**
```mire
import std

pub fn main: () >
    set x = 3.14 :f64
    set s = str(x)
    use dasu("s: {s}")
<
```

**Error:**
```
error[runtime]: Avenys does not yet lower expression Literal(Float(3.14))
```

**Tipo de dato afectado:** f64, f32

---

## 3. Literales Float No Soportados

**Severidad:** Alta

**Descripcion:** No es posible declarar variables con literales float directamente.

**Codigo de prueba:**
```mire
import std

pub fn main: () >
    set x = 3.14 :f64
    use dasu("x: {x}")
<
```

**Error:**
```
error[runtime]: Avenys does not yet lower expression Literal(Float(3.14))
```

**Solucion temporal:** No existe actualmente.

---

## 4. Structs - Error en Runtime

**Severidad:** Alta

**Descripcion:** La declaracion de structs causa un error de runtime al intentar usarlos.

**Codigo de prueba:**
```mire
import std

struct Point >
    x :i64
    y :i64
<

pub fn main: () >
    set p = (Point x:10 y:20)
    set x = p.x
    set y = p.y
    use dasu("x: {x}")
    use dasu("y: {y}")
<
```

**Error:**
```
error[runtime]: Avenys does not yet lower type Anything
```

---

## 5. Indizado de Arrays Invertido

**Severidad:** Media

**Descripcion:** El indizado de arrays devuelve valores en orden inverso.

**Codigo de prueba:**
```mire
import std

pub fn main: () >
    set arr = [1 2 3 4] :arr[i64 4]
    set val0 = arr at 0
    set val1 = arr at 1
    set val2 = arr at 2
    set val3 = arr at 3
    use dasu("val0: {val0}")
    use dasu("val1: {val1}")
    use dasu("val2: {val2}")
    use dasu("val3: {val3}")
<
```

**Salida esperada:** 1 2 3 4

**Salida real:** 4 1 2 3

---

## 6. Declaracion de Variables en Ramas If No Soportada

**Severidad:** Alta

**Descripcion:** No es posible declarar variables dentro de las ramas if/else.

**Codigo de prueba:**
```mire
import std

pub fn main: () >
    set x = 5 :i64
    if x == 10 > 
        set y = 1
    < else >
        set y = 2
    <
    use dasu("y: {y}")
<
```

**Error:**
```
error[type]: Unknown identifier 'y'
```

**Nota:** Este es un problema con el alcance de variables (scope) en las ramas de los condicionales.

---

## 7. Else en Condicionales con Bloques Multilinea

**Severidad:** Media

**Descripcion:** Los condicionales if-else multilinea no funcionan correctamente.

**Comportamiento esperado:**
```mire
if x == 10 > 
    use dasu(equal)
< else >
    use dasu(not equal)
<
```

**Error:**
```
error[parser]: Expected Lt but found Else
```

**Nota:** La documentacion sugiere que else es valido, pero el parser no lo acepta en formato multilinea.

---

## 8. Llamadas de Funcion Requieren `use`

**Severidad:** Baja (Documentacion)

**Descripcion:** La documentacion indica que las funciones deben llamarse con `use`, pero en algunos contextos funciona sin el.

**Comportamiento observado:**
- En benchmarks funciona: `factorial(12)`
- En archivos de prueba falla

---

## 9. Error de LLVM en Structs

**Severidad:** Alta

**Descripcion:** Al compilar structs se genera codigo LLVM invalido.

**Error en optimizacion LLVM:**
```
opt: bin/release/test_struct.ll:64:37: error: invalid getelementptr indices
  %t3 = getelementptr inbounds ptr, ptr %t2, i32 0, i32 0
```

---

## 10. Pipelines con `self` No Funcionan

**Severidad:** Alta

**Descripcion:** El uso de `self` en pipelines causa error.

**Codigo de prueba:**
```mire
import std

pub fn main: () >
    use dasu(Hello) => use dasu("{self}")
<
```

**Error:**
```
error[runtime]: Avenys does not yet lower call 'dasu'
```

---

## 11. Mapas - Sintaxis de Literales

**Severidad:** Media

**Descripcion:** No es posible crear mapas con literales usando la sintaxis de la documentacion.

**Codigo esperado (documentacion):**
```mire
set m = [one 1, two 2] :map[str i32]
```

**Error:**
```
error[parser]: Unexpected token in expression
```

**Solucion temporal:** Usar `dicts.set` para construir mapas:
```mire
set m = [] :map[str i64] mut
set m = dicts.set(m "a" 1)
set m = dicts.set(m "b" 2)
```

---

## 12. Literales Float en Expresiones No Soportados

**Severidad:** Alta

**Descripcion:** Cualquier uso de literales float causa error.

**Ejemplo:**
```mire
set x = 3.14
```

**Error:** No puede compilar porque el lexer ve el punto y espera algo despues.

---

## 13. Tokenizacion de `import std` Afecta Otros Archivos

**Severidad:** Alta

**Descripcion:** El comando `mire debug --tokens` parece reutilizar tokens de ejecuciones anteriores, causando que archivos simples fallen.

**Observacion:** Al hacer debug de tokens, los primeros tokens sempre muestran `import time as time` aunque el archivo sea `import std`.

---

## Resumen de Issues por Categoria

| Categoria | Issues | Severidad |
|-----------|--------|-----------|
| Funciones | 1, 8 | Alta |
| Floats | 2, 3, 12 | Alta |
| Structs | 4, 9 | Alta |
| Arrays | 5 | Media |
| Condicionales | 6, 7 | Alta/Media |
| Pipelines | 10 | Alta |
| Maps | 11 | Media |
| Sistema/Tokenizacion | 13 | Alta |

---

## Recomendaciones

1. **Verificar el sistema de tokenizacion** - El issue #13 sugiere un problema con el manejo de entrada en la CLI.

2. **Completar soporte para floats** - Los issues 2, 3 y 12 bloquean cualquier uso de numeros flotantes.

3. **Arreglar el alcance de variables en if/else** - Issue #6 es un problema fundamental del compilador.

4. **Arreglar el indizado de arrays** - Issue #5 produce resultados incorrectos.

5. **Documentar el comportamiento real de funciones** - La discrepancia entre benchmarks y archivos de prueba necesita explicacion.

---

*Reporte generado durante la sesion de testing del compilador Mire.*
*Fecha: 2026-04-10*