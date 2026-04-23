# Avenys Change Logs

Historial de cambios completados y resueltos. Este archivo documenta lo que ya funciona.

---

## v2.0.0 (Abril 2026)

### Compilation & Build
- Compilación sin warnings (`cargo build`)
- Compilación incremental implementada (`src/incremental.rs`)
- IR en RAM para run/build, disco para debug

### Error System
- Error marker positioning (^^^) apunta a la ubicación correcta
- Línea y columna mostrada en diagnósticos
- Tipo de error mostrado (lexer/deprecated/parser/backend/type/runtime)
- Nombre de archivo fuente preservado
- Main compile path preserva source/filename
- Análisis de archivos importados preserva archivo origen
- Legacy `add` reportado como sintaxis deprecated
- "Avenys does not yet lower" reportado como limitación de backend

### Type & Ownership Checking
- Type inference para declaraciones de variables
- Type inference en expresiones binarias
- Function return type inference
- Assignment type mismatch detection
- Undefined identifier errors en sitio de uso
- Loop variable type inference
- If/while conditions verificadas como bool-like

### Standard Library
- Todos los módulos std registrados en typeck
- Builtin functions registradas (dasu, len, range, str, int, float, bool, input, etc.)

### Match Expressions
- Match con integer literals funciona
- Wildcard arm (_) funciona
- Match arm type consistency

### Enums
- Enum declaration parsea correctamente
- Qualified paths (Status.Ok)
- Enum variant instantiation
- Pattern matching con enum variants
- Multi-payload enum variants
- Nominal type: EnumNamed(String) preserva identidad

### Structs
- Struct declaration parsea
- Field access object.field retorna tipo correcto
- Method resolution para instance y associated calls
- Nominal types preservan identidad de tipo
- Structs con misma forma pero diferente nombre NO son intercambiables

### impl Syntax (v2.0.0)
- Instance methods requieren `self` explícito
- Static/associated methods usan Type::method(...)
- Enum-qualified paths bleiben Enum.Variant
- self no es inyectado implícitamente
- Instance dispatch solo para métodos que declaran self

### Tests
- 46 lib tests passing
- Regression tests passing
- Tests cubre: typeck, borrowck, parser, enums, structs, impl methods

### Parser Fixes
- Dict type ascription: parse_expression -> parse_pipeline_free_expression en literales
- Esto permitió `{a: 1} :map[str i64]` funcione correctamente

### Backend Fixes (Abril 2026)
- **Struct field access in function parameters**: Fix en compile_fn_block para propagar struct_name usando los parámetros de la LLAMADA (params.iter()) en lugar de fn_info.params. El error era "Avenys cannot resolve struct member 'x' without concrete struct metadata"

---

## v2.1.0 (Mayo 2026)

### Logical Operators - C-Style Syntax

**Cambio de sintaxis:**
- `and`/`or`/`not` keywords REMOVIDOS
- Nuevos operadores C-style implementados:
  - `&&` - logical AND
  - `||` - logical OR
  - `!` - unary NOT
  - `^` - logical XOR

**Implementación:**
- Lexer: Nuevos tokens `AmpAmp`, `PipePipe`, `Xor`
- Parser: `parse_and()` → `&&`, `parse_or()` → `||`, `parse_not()` → `!`, `parse_xor()` → `^`
- Typeck: Operadores actualizados para usar símbolos
- Backend: Full LLVM IR generation para todos los operadores

**Nota:** Short-circuit evaluation pendiente para `&&` y `||` (usa simple AND/OR por ahora)

---

## v1.0.x (Histórico)

### Enum Implementation (v1.0.2)
- Enum declaration
- Qualified paths (Status.Ok)
- Enum variant instantiation
- Pattern matching
- Multi-payload variants
- Nominal type preservation

### if as Expression
- Branch types unificados durante type checking
- Lowering usa el tipo de expresión resuelto

### Backend Improvements
- Diagnostic categorization como backend limitations

---

## 📝 Notas de Síntesis

### Síntaxis Actual del Match (v2.0.0)
```mire
match value {
    Pattern { body }
}
```
- Cuerpo debe ser expresión inline
- NO soporta multilínea directamente
- NO permite comparación en condition

### Síntaxis Propuesta para Futuro
Ver `todo.md` sección SYNTAX IMPROVEMENTS