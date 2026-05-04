# Issue: Recursion Bug - Funciones Recursivas Retornan 0

**Fecha de investigación:** Mayo 4, 2026
**Estado:** Investigado - Pendiente de Fix
**Severidad:** Alta
**Área afectada:** Backend Avenys (LLVM lowering)

---

## Descripción del Bug

Las funciones recursivas en Mire siempre retornan 0, independientemente del resultado esperado.

### Ejemplo que falla:

```mire
fn fibonacci: (n :i64) :i64 {
    if n <= 1 {
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

pub fn main: () {
    set f = fibonacci(25)
    use dasu(f)  // Retorna 0, esperado 75025
}
```

### Ejemplo que funciona (retorno directo en condition):

```mire
fn fib_fast: (n :i64) :i64 {
    if n <= 1 {
        return n
    }
    return n + fib_fast(n - 1)
}

pub fn main: () {
    set f = fib_fast(10)  // También retorna 0
}
```

### Comportamiento esperado:
- `fibonacci(25)` debería retornar 75025
- `fibonacci(10)` debería retornar 55

### Comportamiento actual:
- Todas las funciones recursivas retornan 0

---

## Análisis de Código Fuente

### 1. Recolección de Funciones (`src/avens/mod.rs:825-833`)

```rust
self.user_functions.insert(
    name.clone(),
    FnInfo {
        llvm_name,
        params: param_types,
        ret,
        returns_value: *return_type != DataType::None,
    },
);
```

Las funciones se registran en `user_functions` HashMap con su metadata.

### 2. Compilación de Llamadas (`src/avens/mod.rs:1629-1641`)

```rust
let tmp = self.tmp();
let ret_ty = fn_info.ret.clone();
self.body.push(format!(
    "  {tmp} = call {} {}({})",
    self.ty(ret_ty.clone()),
    fn_info.llvm_name,
    rendered_args.join(", ")
));
Ok(LlValue {
    ty: ret_ty,
    repr: tmp,
    owned: false,
})
```

El código genera `call` LLVM correctamente.

---

## Hipótesis del Bug

### Hipótesis 1: Falta Forward Declaration en LLVM

Las funciones recursivas necesitan declararse antes de usarse. En LLVM, las funciones se deben declarar antes del primer uso:

```llvm
define i64 @fibonacci(i64 %n) {
    ...
}
```

Si la función se define después de `main`, la llamada recursiva puede fallar.

### Hipótesis 2: Problema en el Registro de Funciones

El `user_functions` HashMap puede no estar populado cuando se hace la llamada recursiva.

### Hipótesis 3: LLVM IR Mal Formado

El orden de generación de funciones puede causar que la función recursiva no esté definida cuando se llama.

---

## Investigación Adicional Requerida

1. **Generar IR para ver:** Ejecutar con `--emit-ir` para ver el LLVM generado
2. **Verificar orden:** Confirmar que las funciones se generan en orden correcto
3. **Test con forward declaration:** Agregar declaration separada

---

## Tests de Regression

```mire
fn factorial: (n :i64) :i64 {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)
}

fn fibonacci: (n :i64) :i64 {
    if n <= 1 {
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

fn sum_to: (n :i64) :i64 {
    if n <= 0 {
        return 0
    }
    return n + sum_to(n - 1)
}

pub fn main: () {
    set f1 = factorial(5)    // Esperado: 120
    set f2 = fibonacci(10)     // Esperado: 55  
    set s = sum_to(100)       // Esperado: 5050
}
```

---

## Notas de Debugging

- El bug afecta TODAS las funciones recursivas
- El bug NO afecta funciones iterativas
- El bug aparece tanto con `return` explícito como con última expresión
- LLVM IR generado parece correcto (call se genera)

---

## possible Fixes

### Fix 1: Reordenar Generación de Funciones
Generar todas las declaraciones de funciones antes de compilar el cuerpo.

### Fix 2: Agregar Forward Declaration
En LLVM, agregar declarations de todas las funciones al inicio.

### Fix 3: Revisar Compilation Context
Verificar que el contexto de compilación mantiene referencias correctas.

---

**Investigación realizada:** Mayo 4, 2026
**Próximo paso:** Generar IR y verificar orden de funciones