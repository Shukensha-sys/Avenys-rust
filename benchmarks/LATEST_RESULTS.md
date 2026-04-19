# Latest Benchmark Results

| Benchmark | Compile | Mire | Python | Speedup |
|-----------|---------|------|--------|---------|
| analytics_pass | 353.957ms | 2.302ms | 7.515ms | 3.26x |
| arr_test | 341.838ms | 10.454ms | n/a | - |
| array_index_stress | 339.070ms | 0.048ms | 15.919ms | 331.65x |
| branchy_workload | 360.418ms | 0.479ms | 34.431ms | 71.88x |
| collections_stress | 350.477ms | 1.717ms | 5.137ms | 2.99x |
| flow_stress | 360.647ms | 10.448ms | 382.964ms | 36.65x |
| fn_multi_args | 336.479ms | 10.462ms | n/a | - |
| fn_return_vec | 347.534ms | 53.740ms | n/a | - |
| fn_vec_param | 0.000ms | [1;34m--> benchmarks/fn_vec_param.mire:1:1[0m
[1;31merror[0m[ownership]: MSS Error: Use after move - value was moved
[1;32m1[0m |import time as time
    |^^^[31m...[0m[1;90m2[0m |[90madd mem as mem[0m
[1;90m3[0m |[90madd cpu as cpu[0m

[1;90mhelp[0m: MSS Error: Use after move - value was moved
 | n/a | - |
| fn_vec_param2 | 0.000ms | [1;34m--> benchmarks/fn_vec_param2.mire:1:1[0m
[1;31merror[0m[ownership]: MSS Error: Use after move - value was moved
[1;32m1[0m |import time as time
    |^^^[31m...[0m[1;90m2[0m |[90madd mem as mem[0m
[1;90m3[0m |[90madd cpu as cpu[0m

[1;90mhelp[0m: MSS Error: Use after move - value was moved
 | n/a | - |
| higher_order_filter | 347.297ms | 0.122ms | 1.199ms | 9.83x |
| higher_order_manual | 346.965ms | 0.065ms | n/a | - |
| i8_valid_test | 343.379ms | 10.409ms | n/a | - |
| list_growth | 349.530ms | 0.224ms | 1.316ms | 5.88x |
| list_slice_test | 344.812ms | 0.174ms | n/a | - |
| list_string_ops | 338.261ms | 0.034ms | 0.002ms | 0.06x |
| map_dynamic | 352.289ms | 1.012ms | n/a | - |
| map_has_keys | 341.342ms | 0.059ms | n/a | - |
| map_keys_values | 342.497ms | 80.972ms | n/a | - |
| map_lookup_stress | 343.690ms | 1.474ms | 14.906ms | 10.11x |
| map_mixed_stress | 340.600ms | 12.158ms | n/a | - |
| map_rollup | 341.970ms | 10.457ms | 20.535ms | 1.96x |
| map_stress | 349.783ms | 1.206ms | 2.686ms | 2.23x |
| map_to_string_test | 343.579ms | 10.428ms | n/a | - |
| map_vector_stress | 347.074ms | 0.036ms | 0.013ms | 0.36x |
| map_wide_lookup_stress | 344.413ms | 2.857ms | 26.027ms | 9.11x |
| matrix_2d_stress | 350.165ms | 101.057ms | n/a | - |
| nested_array_stress | 343.590ms | 91.088ms | 0.013ms | 0.00x |
| nested_loop_compute | 332.516ms | 0.037ms | n/a | - |
| nested_map_stress | 343.504ms | 0.064ms | 0.013ms | 0.20x |
| nested_vec | 341.714ms | 2.902ms | n/a | - |
| nested_vector_stress | 343.758ms | 91.002ms | 0.012ms | 0.00x |
| recursion_factorial | 359.195ms | 0.049ms | 0.002ms | 0.04x |
| recursion_fib | 340.633ms | 0.095ms | 0.743ms | 7.82x |
| recursion_quicksort | 0.000ms | [1;34m--> benchmarks/recursion_quicksort.mire:1:1[0m
[1;31merror[0m[ownership]: MSS Error: Use after move - value was moved
[1;32m1[0m |import time as time
    |^^^[31m...[0m[1;90m2[0m |[90madd mem as mem[0m
[1;90m3[0m |[90madd cpu as cpu[0m

[1;90mhelp[0m: MSS Error: Use after move - value was moved
 | n/a | - |
| ref_test | 335.201ms | 0.067ms | n/a | - |
| replace_noop_stress | 339.722ms | 0.498ms | 1.651ms | 3.32x |
| simple_fn_call | 334.849ms | 10.609ms | n/a | - |
| simple_test | 334.658ms | 10.395ms | n/a | - |
| simple_vec_pass | 339.296ms | 10.440ms | n/a | - |
| simple_vec_test | 336.724ms | 80.969ms | n/a | - |
| string_build | 342.156ms | 9.180ms | 9.352ms | 1.02x |
| string_case_ops | 337.538ms | 0.018ms | n/a | - |
| string_join_test | 346.898ms | 10.535ms | n/a | - |
| string_ops | 340.183ms | 0.975ms | 1.843ms | 1.89x |
| string_pipeline_stress | 338.451ms | 30.466ms | 30.684ms | 1.01x |
| string_split_join | 335.749ms | 0.043ms | n/a | - |
| string_split_test | 341.558ms | 10.472ms | n/a | - |
| string_trim_test | 336.538ms | 10.513ms | n/a | - |
| struct_test | 334.717ms | 10.490ms | n/a | - |
| sum_loop | 339.931ms | 0.027ms | 120.291ms | 4455.22x |
| task_queue_sim | 345.985ms | 10.514ms | 20.709ms | 1.97x |
| typed_map_mixed_stress | 0.000ms | [1;34m--> benchmarks/typed_map_mixed_stress.mire:1:1[0m
[1;31merror[0m[type]: Unknown identifier 'enabled'
[1;32m1[0m |import time as time
    |^^^[31m...[0m[1;90m2[0m |[90madd mem as mem[0m
[1;90m3[0m |[90madd cpu as cpu[0m

 | n/a | - |
| typed_map_scalar_stress | 345.328ms | 1.709ms | 5.735ms | 3.36x |
| typed_vector_bool_stress | 348.437ms | 0.120ms | 6.078ms | 50.65x |
| typed_vector_i32_stress | 351.279ms | 80.967ms | 3.034ms | 0.04x |
| vec_copy_semantics | 343.316ms | 0.119ms | n/a | - |
| vec_index | 342.510ms | 0.185ms | 0.535ms | 2.89x |
| vec_map_op | 351.416ms | 0.047ms | n/a | - |
| vec_plus_vec | 345.417ms | 10.489ms | n/a | - |
| vec_slice | 350.605ms | 0.070ms | n/a | - |
| vector_stress | 349.026ms | 0.379ms | 1.345ms | 3.55x |
