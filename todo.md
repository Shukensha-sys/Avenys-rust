# Mire Bootstrap TODO

This file collects the main engineering work that should happen before Mire can enter a more serious early bootstrap phase.

The goal is not to add more language surface quickly. The goal is to reduce ambiguity, stabilize the compiler pipeline, and define a reliable subset of Mire that can be trusted to build Mire-owned tooling.

---

## ✅ IMPLEMENTED (v2.0.0 - verified)

### Compilation & Build
- ✅ Compilation with 0 warnings (`cargo build`)
- ✅ Incremental compilation implemented (`src/incremental.rs`)
- ✅ IR in RAM for run/build, disk for debug

### Error System
- ✅ Error marker positioning (^^^) fixed to point to correct location
- ✅ Line and column displayed in diagnostics
- ✅ Error kind displayed (lexer/deprecated/parser/backend/type/runtime)
- ✅ Source filename preserved
- ✅ Main compile path now preserves source/filename through lexer, parser, type, ownership, and backend-limitation failures
- ✅ Imported local-file analysis failures now preserve the imported file as diagnostic origin
- ✅ Legacy `add` now reports as deprecated syntax with `import` guidance
- ✅ Avenys "does not yet lower" diagnostics now report as backend limitations

### Type & Ownership Checking
- ✅ Type inference for variable declarations
- ✅ Type inference across binary expressions
- ✅ Function return type inference
- ✅ Assignment type mismatch detection
- ✅ Undefined identifier errors at use site
- ✅ Loop variable type inference
- ✅ If/while conditions checked to be bool-like

### Standard Library
- ✅ All std modules registered in typeck (math, strings, lists, dicts, time, term, mem, cpu, gpu, fs, env, proc)
- ✅ Builtin functions registered (dasu, len, range, str, int, float, bool, input, etc.)
- ✅ std.output in typeck (typeck.rs:72)

### Match
- ✅ Match with integer literals works
- ✅ Wildcard arm (_) works
- ✅ Match arm type consistency

### Tests
- ✅ 30 lib tests passing
- ✅ 37 regression tests passing
- ✅ 71 total tests passing
- ✅ mire test discovers .mire recursively (main.rs:188)
- ✅ Excludes negative/fixture suites (tests/error/, tests/broken_mire/, etc.)
- ✅ Tests cover: typeck, borrowck, parser, enums, structs, impl methods

### Syntax Normalization (v1.0.1 fixes)
- ✅ data_processing.mire - fixed syntax
- ✅ typed_vec_operations.mire - fixed syntax
- ✅ struct_partial_init.mire - fixed syntax
- ✅ match_exhaustive.mire - fixed syntax

### Enums (partial - v1.0.2)
- ✅ Enum declaration parses correctly
- ✅ Enum name registered in typeck scope
- ✅ Backend handles DataType::Enum
- ✅ Enum name registered in LLVM IR vars

### `impl` Syntax Refresh (v2.0.0)
- ✅ Instance methods now require explicit `self`
- ✅ Static/associated methods now support `Type::method(...)`
- ✅ Enum-qualified paths remain `Enum.Variant`
- ✅ `self` is no longer injected implicitly by parser/typeck
- ✅ Instance dispatch only happens for methods that actually declare `self`
- ✅ Struct return tracking works through associated constructors like `Point::new(...)`

---

## 🔄 IN PROGRESS / PARTIALLY IMPLEMENTED

### Enum Implementation (v1.0.2 - v2.0.0) - COMPLETE
- ✅ Enum declaration - DONE
- ✅ Qualified paths (Status.Ok) - DONE
- ✅ Enum variant instantiation - DONE
- ✅ Pattern matching with enum variants - DONE
- ✅ Multi-payload enum variants - DONE
- ✅ Nominal type: `EnumNamed(String)` preserves concrete type identity

### Struct Implementation (v2.0.0)
- ✅ Struct declaration parses
- ✅ Field access `object.field` returns correct type
- ✅ Method resolution for instance and associated `impl` calls
- ✅ Nominal types: `StructNamed(String)` and `EnumNamed(String)` - preserves concrete type identity
- ✅ Structs with same shape but different name are NOT interchangeable (type safety)

---

## ❌ PENDING / NOT YET IMPLEMENTED

### Frontend & Parser

1. **Deprecated syntax cleanup**
   - Extend migration diagnostics beyond legacy `add`

2. **Block parsing**
   - Refactor block-opening/block-closing helpers
   - Unify `if`, `while`, `for`, `do-while`, `match` on consistent block model

3. **Parser warnings**
   - Remove unreachable-pattern warnings in `src/parser/mod.rs`
   - Remove unused parsing helpers

### Type System

4. **Struct field validation**
   - Field-level type checking during construction not enforced

5. **if as expression**
   - ✅ Branch types are unified during type checking
   - ✅ Lowering now uses the resolved expression type instead of trusting the first branch

6. **impl methods**
   - Use nominal owner types consistently in trait/skill conformance and diagnostics

### Language Features

7. **Pipelines (`=>`)**
   - Semantics not fully resolved
   - May or may not behave as `len(x)` depending on runtime

8. **Traits & Skills**
   - Registered in typeck and checked by direct signature + method-kind match
   - Deeper trait semantics beyond direct conformance are still incomplete

9. **if as expression**
   - Parsed and desugared via `__if_expr` builtin
   - ✅ Return type is unified from branches

10. **extern lib/fn**
    - Parsed, walked past in typeck/borrowck without analysis

11. **unsafe/asm/module**
    - Scopes created and walked but not semantically validated

### Backend

12. **Compiler limitation vs user error**
    - ✅ "Avenys does not yet lower" messages are now reported as backend limitations
    - Continue auditing other backend-facing diagnostics for consistent categorization

13. **Diagnostic regression tests**
    - Started: regressions now cover lexer, parser, type, ownership, deprecated syntax, backend-limitation kinds, imported-file attribution, and filename/headline checks
    - Expand coverage across additional runtime/user-facing diagnostics

---

## 📋 RECOMMENDED PRIORITY ORDER

### Phase 1: Stabilize what's working
1. Document the bootstrap-safe subset
2. Extend deprecated syntax diagnostics beyond `add`
3. Add more runtime diagnostic checks and imported-file edge-case regressions

### Phase 2: Complete enum support (if needed)
4. Add qualified path parsing (Status.Ok)
5. Implement enum variant instantiation
6. Implement pattern matching with enum variants

### Phase 3: Fix known gaps
7. Struct field type checking enforcement
8. Nominal type system for structs/enums
9. Deepen trait/skill semantics beyond direct conformance

### Phase 4: Full feature enablement
10. Pipelines, traits, extern, etc.

---

## 📝 NOTES

- Version updated to **2.0.0** (from 1.0.3)
- v2.0.0 introduces a deliberate syntax break for `impl`:
  - instance methods must declare `self` explicitly
  - associated/static methods use `Type::method(...)`
  - enum variants continue to use `Enum.Variant`
- Changes documented in README.md and Cargo.toml
- Syntax documented in `syntax-V2.0.0.md`
- Issues tracked in `docs/issues.md`
- Tests in `tests/stress/` validate compiler under load

---

## 🔧 INCREMENTAL COMPILATION V2

### Objetivo
Optimizar el sistema de compilación incremental manteniendo la filosofía de Mire: memoria eficiente, velocidad, sin cargas innecesarias.

### Problemas Actuales
- JSON全文 carga en memoria aunque solo se necesite una parte
- Sin LRU - cache crece infinitamente
- Almacena AST completo serializado (~500KB+)
- La granularidad fina ya existe para funciones top-level y miembros directos de `Type`/`Class`/`Code`/`Impl`, pero sigue pendiente paralelizar la fase de análisis
- Carga secuencial de archivos

---

### Fase 1: Cache Binario + Lazy Loading (Semana 1)

**Objetivo**: Reemplazar JSON con binario, cargar solo lo necesario

**Cambios**:
- [x] Nuevo formato binario en `bin/.cache/incremental.bin`
- [x] Index en memoria (lazy load de entries)
- [x] Memory-mapped file para acceso rápido
- [x] Eliminar pretty-print JSON, usar binary compactado

**Arquitectura**:
```
┌──────────────────┐
│   Index (LRU)    │ ← Carga al inicio (solo keys + metadata)
├──────────────────┤
│   Data Store     │ ← Carga bajo demanda (solo datos necesarios)
├──────────────────┤
│ Build Fingerprint│ ← Verificación rápida
└──────────────────┘
```

---

### Fase 2: Analysis Cache (Semana 2-3) [PRIORIDAD ALTA]

**Objetivo**: Cache de resultados typeck/borrowck por función/unidad reusable

**Cambios**:
- [x] Reutilización parcial de typeck por unidad top-level y miembros directos de `Type`/`Class`/`Code`/`Impl`
- [x] Reutilización parcial de borrowck usando la misma selección de unidades reutilizables
- [x] **Cache de errores** - evita recomputar análisis en código inválido
- [x] Base de invalidación granular basada en dependencias top-level reales y aliases de miembros
- [x] Base operativa a nivel de programa/fingerprint para reutilizar typeck+borrowck cuando el grafo no cambió
- [x] Metadata persistida por unidad top-level y miembros directos: `unit_key`, `unit_kind`, `body_hash`, `dependencies`
- [x] Reporte de invalidación granular en debug para inspección

**Key de cache**:
```rust
fn key -> (type_result, borrow_result, errors, body_hash)
```

**Invalidación**:
- Cambio en función → invalidate esa función + dependents
- Cambio en import → invalidate todos los usuarios

---

### Fase 3: LRU + Configuración (Semana 3)

**Objetivo**: Evicción configurable, control de memoria

**Cambios**:
- [x] Diseño de configuración definido
- [x] `cache.max_units=256` (configurable via project.toml)
- [x] Evicción LRU por "compilation unit"
- [x] Métricas: hit/miss/eviction rates
- [x] Soporte para `[cache]` section en project.toml

**Configuración (project.toml)**:
```toml
[project]
name = "mi_proyecto"
version = "0.1.0"
entry = "main.mire"

[cache]
max_units = 256          # default: 256, 0 = unlimited
analysis_cache = true   # default: true, puede desactivarse con --no-analysis-cache
compression = false      # default: false (opt-in)
```

**CLI Override**:
```bash
mire run app.mire --cache-max-units 512    # override project.toml
mire run app.mire --no-analysis-cache      # disable analysis cache
```

---

### Fase 4: Paralelismo (Semana 4) [OPTIMIZACIÓN FINAL]

**Objetivo**: Carga paralela de archivos, thread pool 100%

**Cambios**:
- [ ] Thread pool para loading de archivos
- [ ] Parallel typeck/borrowck por archivo
- [ ] Sincronización de cache con locks finos
- [ ] Prefetch de dependencias

---

### Métricas Esperadas

| Optimización | Velocidad | Memoria |
|--------------|-----------|---------|
| Lazy load binario | ~20% | ~50% |
| **Analysis cache** | **~40%** | +por fn |
| LRU configurable | N/A | ∞→limitado |
| Thread pool | ~15% | +threads |
| **Total** | **~60-70%** | **~-40%** |

---

### Notas de Diseño

1. **Backwards compatibility**: Formato nuevo puede ignorar cache antiguo
2. **Transparencia**: Analysis cache debe ser invisible al usuario
3. **Disable option**: `--no-analysis-cache` para debugging
4. **HIR/IR layer**: Para futura fase (no en este plan)
5. **Granular invalidation**: Dependencias reales no solo archivos
6. **Config source priority**: CLI flag > project.toml > default values

### Estado tras esta iteración

- Cache incremental migrada de `incremental.json` a `incremental.bin`
- La lectura del blob store ahora usa `mmap` en apertura read-only y se promociona a memoria propia solo cuando una escritura necesita append
- Loader y compilación ya usan blobs lazy para no deserializar AST/análisis completos al abrir la cache
- CLI soporta `--cache-max-units`, `--analysis-cache` y `--no-analysis-cache`
- `project.toml` soporta `[cache]`
- LRU funcional sobre unidades parseadas y analizadas
- La cache de análisis ya persiste tanto éxitos como errores
- Se guarda metadata top-level y de miembros directos para reutilización parcial por unidad reusable
- Ya existe cálculo de `changed_units` / `invalidated_units` / `added_units` / `removed_units`
- La compilación ya puede reutilizar sentencias top-level previamente analizadas y re-typecheckear solo unidades invalidadas
- La compilación ya puede reutilizar sentencias top-level previamente analizadas y re-ejecutar borrowck solo en unidades invalidadas
- `Type`, `Class`, `Code` e `Impl` ya pueden reutilizar hijos directos sin reanalizar el contenedor completo cuando solo cambia un subconjunto
- Typecheck y borrowck ya consumen una selección compartida de unidades (`AnalysisSelection`) en lugar de máscaras ad hoc
- El modo debug ya reporta métricas de cache: `file_hit/file_miss`, `analysis_hit/analysis_miss`, `build_hit/build_miss`, `evictions`

---

## ✅ VERIFICACIÓN ACTUAL (Abr 2026)

### Tests Completados
```
Lib tests:       46/46 passed
Regression:      54/54 passed
Total:           100/100 passed
```

### Apps Verificados
- enum_complex.mire ✅
- enum_test_complex.mire ✅
- enum_test_full.mire ✅
- simple_list.mire ✅
- simple_map.mire ✅
- struct_person.mire ✅
- task_manager.mire ✅
- test_impl.mire ✅
- test_struct.mire ✅
- Y otros 8+ apps adicionales...

### Stress/Security/Production Tests
- 18/18 tests passing (100%)

### Build Status
- ✅ 0 warnings
- ✅ 0 errors

---

### Referencias

- Código actual: `src/incremental.rs`
- Cache actual: `bin/.cache/incremental.json` (~500KB)
- Tests: `tests/stress/` para validación de carga
- Schema config: `src/avens/mod.rs` (MireManifest struct)
- CLI options: `src/main.rs` (BuildOptions)
