# Benchmark Results 2025

Fecha: 2025-04-14

## Tiempos de ejecución (ms)

| Benchmark | Tiempo | Notas |
|-----------|--------|-------|
| analytics_pass | 505 | Procesamiento GPU |
| arr_test | 433 | Arrays |
| array_index_stress | 433 | Indexación |
| branchy_workload | 460 | Condiciones |
| collections_stress | 469 | Maps/arrays |
| flow_stress | 442 | Control flow |
| fn_multi_args | 425 | Funciones |
| fn_return_vec | 489 | Funciones vector |
| fn_vec_param | 5 | Error (MSS) |
| fn_vec_param2 | 4 | Error (MSS) |
| higher_order_filter | 421 | Filtros |
| higher_order_manual | 428 | Higher-order |
| i8_valid_test | 418 | Validación i8 |
| list_growth | 430 | Listas |
| list_slice_test | 418 | Slicing |
| list_string_ops | - | Error ownership |
| map_dynamic | - | Error |
| map_has_keys | - | Error |
| map_keys_values | - | Error |
| map_lookup_stress | - | Error |
| map_mixed_stress | - | Error |
| map_rollup | - | Error |
| map_stress | - | Error |
| map_to_string_test | - | Error |
| map_vector_stress | - | Error |
| map_wide_lookup_stress | - | Error |
| matrix_2d_stress | - | Error |
| nested_array_stress | - | Error |
| nested_loop_compute | - | OK |
| nested_map_stress | - | Error |
| nested_vec | - | Error ownership |
| nested_vector_stress | - | Error |
| recursion_factorial | - | OK |
| recursion_fib | - | OK |
| recursion_quicksort | - | Error (MSS) |
| ref_test | - | OK |
| replace_noop_stress | - | OK |
| simple_fn_call | - | OK |
| simple_test | - | OK |
| simple_vec_pass | - | Error |
| simple_vec_test | - | Error |
| string_build | - | OK |
| string_case_ops | 430 | Strings |
| string_join_test | 422 | Strings |
| string_ops | 422 | Strings |
| string_pipeline_stress | 433 | Pipeline |
| string_split_join | 427 | Strings |
| string_split_test | 429 | Strings |
| string_trim_test | 419 | Strings |
| struct_test | 422 | Structs |
| sum_loop | 419 | Loops |
| task_queue_sim | 421 | Colas |
| typed_map_mixed_stress | 4 | Error tipo |
| typed_map_scalar_stress | 428 | Maps typed |
| typed_vector_bool_stress | 460 | Vectors typed |
| typed_vector_i32_stress | 526 | Vectors i32 |
| vec_copy_semantics | 420 | Copy semantics |
| vec_index | 418 | Indexing |
| vec_map_op | 431 | Map operations |
| vec_plus_vec | 420 | Vector ops |
| vec_slice | 426 | Slicing |
| vector_stress | 427 | Vector stress |

## Análisis de problemas

### Errors frecuentes

1. **MSS (Move Semantics System)**
   - fn_vec_param, fn_vec_param2
   - recursion_quicksort
   - nested_vec, nested_vector_stress

2. **Type errors**
   - typed_map_mixed_stress
   - map_*, array_*

3. **Ownership**
   - list_string_ops

### Áreas de optimización

1. **Compile time**: ~340ms promedio
   - Parser: podría mejorarse con caching
   - Type checking: podría paralelizarse

2. **Runtime optimizations**:
   - String operations: requieren implementación más eficiente
   - Map operations: pueden ser más lentas que arrays
   - Vec operations: buen rendimiento general

3. **Errores de ownership**:
   - El sistema MSS requiere mejoras para permitir más patrones
   - Referencias y borrowing no funcionan completamente

## Comparativa vs Python (resultados previos)

| Benchmark | Mire | Python | Speedup |
|-----------|------|--------|--------|
| sum_loop | 0.027ms | 120.291ms | **4455x** |
| array_index_stress | 0.048ms | 15.919ms | **331x** |
| typed_vector_bool_stress | 0.120ms | 6.078ms | **50x** |
| branchy_workload | 0.479ms | 34.431ms | **71x** |
| flow_stress | 10.448ms | 382.964ms | **36x** |
| map_lookup_stress | 1.474ms | 14.906ms | **10x** |

## Recomendaciones

1. **Alta prioridad**:
   - Arreglar MSS para fn_vec_param y recursion_quicksort
   - Mejorar typed_map_mixed_stress

2. **Media prioridad**:
   - Optimizar compile time (~340ms → ~200ms目标)
   - Mejorar string operations

3. **Baja prioridad**:
   - Agregar más testes para struct/class
   - Implementar trait checking completo