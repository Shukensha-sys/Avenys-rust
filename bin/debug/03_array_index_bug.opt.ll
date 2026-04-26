declare i32 @printf(ptr, ...)
declare i32 @scanf(ptr, ...)
declare i64 @strlen(ptr)
declare i64 @clock()
declare ptr @malloc(i64)
declare void @free(ptr)
declare ptr @realloc(ptr, i64)
declare ptr @memcpy(ptr, ptr, i64)
declare i32 @memcmp(ptr, ptr, i64)
declare i32 @strcmp(ptr, ptr)
declare i32 @getpagesize()
declare i64 @getpid()
declare i64 @mire_wall_mark_ns()
declare i64 @mire_wall_elapsed_ms(i64)
declare ptr @mire_wall_elapsed_ms_str(i64)
declare i64 @mire_cpu_mark_ns()
declare i64 @mire_cpu_elapsed_ms(i64)
declare ptr @mire_cpu_elapsed_ms_str(i64)
declare i64 @mire_cpu_cycles_est(i64)
declare i64 @mire_mem_process_bytes()
declare ptr @mire_mem_format(i64)
declare ptr @mire_gpu_snapshot()
declare ptr @mire_i64_to_string(i64)
declare ptr @mire_bool_to_string(i64)
declare ptr @mire_string_copy(ptr)
declare ptr @mire_string_concat(ptr, ptr)
declare ptr @mire_string_append_owned(ptr, ptr)
declare void @mire_string_free(ptr)
declare ptr @mire_string_to_upper(ptr)
declare ptr @mire_string_to_lower(ptr)
declare ptr @mire_strings_replace(ptr, ptr, ptr)
declare ptr @mire_strings_split(ptr, ptr)
declare ptr @mire_strings_join(ptr, i64, ptr)
declare ptr @mire_strings_trim(ptr)
declare ptr @mire_list_create(i64, i64)
declare ptr @mire_list_push_i64(ptr, i64)
declare ptr @mire_list_new()
declare ptr @mire_list_push_scalar(ptr, i64, i64)
declare ptr @mire_list_push_ptr(ptr, ptr)
declare ptr @mire_list_concat(ptr, ptr)
declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64)
declare ptr @mire_dict_get_ptr(ptr, i64, i64, ptr, ptr)
declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64)
declare ptr @mire_dict_set_ptr(ptr, i64, i64, i64, ptr, ptr)
declare ptr @mire_dict_to_string(ptr)
declare ptr @mire_dict_keys(ptr)
declare ptr @mire_dict_values(ptr)
declare ptr @mire_list_slice(ptr, i64, i64)
declare void @mire_runtime_panic(ptr)
declare ptr @fgets(ptr, i64, ptr)
@.fmt_i64 = private unnamed_addr constant [5 x i8] c"%ld\0A\00"
@.fmt_str = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.fmt_float = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@.fmt_bool_true = private unnamed_addr constant [5 x i8] c"true\00"
@.fmt_bool_false = private unnamed_addr constant [6 x i8] c"false\00"
@.fmt_i32 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.fmt_prompt = private unnamed_addr constant [3 x i8] c"%s\00"
@.scanf_str = private unnamed_addr constant [3 x i8] c"%s\00"
@.scanf_i64 = private unnamed_addr constant [4 x i8] c"%ld\00"
@.str0 = private unnamed_addr constant [60 x i8] c"Expected: arr[0]=10 arr[1]=20 arr[2]=30 arr[3]=40 arr[4]=50\00"
@.str1 = private unnamed_addr constant [18 x i8] c"Actual:   arr[0]=\00"
@.str2 = private unnamed_addr constant [9 x i8] c" arr[1]=\00"
@.str3 = private unnamed_addr constant [9 x i8] c" arr[2]=\00"
@.str4 = private unnamed_addr constant [9 x i8] c" arr[3]=\00"
@.str5 = private unnamed_addr constant [9 x i8] c" arr[4]=\00"

define i64 @mire_main() {
entry:
  %t0 = alloca ptr
  %t8 = alloca i64
  %t14 = alloca i64
  %t20 = alloca i64
  %t26 = alloca i64
  %t32 = alloca i64
  %t1 = call i8* @malloc(i64 56)
  store i64 5, ptr %t1
  %t2 = getelementptr i8, ptr %t1, i64 8
  store i64 5, ptr %t2
  %t3 = getelementptr i8, ptr %t2, i64 8
  store i64 10, ptr %t3
  %t4 = getelementptr i8, ptr %t2, i64 16
  store i64 20, ptr %t4
  %t5 = getelementptr i8, ptr %t2, i64 24
  store i64 30, ptr %t5
  %t6 = getelementptr i8, ptr %t2, i64 32
  store i64 40, ptr %t6
  %t7 = getelementptr i8, ptr %t2, i64 40
  store i64 50, ptr %t7
  store ptr %t2, ptr %t0
  %t9 = load ptr, ptr %t0
  %t10 = bitcast ptr %t9 to ptr
  %t11 = mul i64 0, 8
  %t12 = getelementptr inbounds i8, ptr %t10, i64 %t11
  %t13 = load i64, ptr %t12
  store i64 %t13, ptr %t8
  %t15 = load ptr, ptr %t0
  %t16 = bitcast ptr %t15 to ptr
  %t17 = mul i64 1, 8
  %t18 = getelementptr inbounds i8, ptr %t16, i64 %t17
  %t19 = load i64, ptr %t18
  store i64 %t19, ptr %t14
  %t21 = load ptr, ptr %t0
  %t22 = bitcast ptr %t21 to ptr
  %t23 = mul i64 2, 8
  %t24 = getelementptr inbounds i8, ptr %t22, i64 %t23
  %t25 = load i64, ptr %t24
  store i64 %t25, ptr %t20
  %t27 = load ptr, ptr %t0
  %t28 = bitcast ptr %t27 to ptr
  %t29 = mul i64 3, 8
  %t30 = getelementptr inbounds i8, ptr %t28, i64 %t29
  %t31 = load i64, ptr %t30
  store i64 %t31, ptr %t26
  %t33 = load ptr, ptr %t0
  %t34 = bitcast ptr %t33 to ptr
  %t35 = mul i64 4, 8
  %t36 = getelementptr inbounds i8, ptr %t34, i64 %t35
  %t37 = load i64, ptr %t36
  store i64 %t37, ptr %t32
  %t38 = getelementptr inbounds [60 x i8], ptr @.str0, i64 0, i64 0
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t38)
  %t39 = getelementptr inbounds [18 x i8], ptr @.str1, i64 0, i64 0
  %t40 = load i64, ptr %t8
  %t41 = call ptr @mire_i64_to_string(i64 %t40)
  %t42 = call ptr @mire_string_concat(ptr %t39, ptr %t41)
  %t43 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t44 = call ptr @mire_string_concat(ptr %t42, ptr %t43)
  %t45 = load i64, ptr %t14
  %t46 = call ptr @mire_i64_to_string(i64 %t45)
  %t47 = call ptr @mire_string_concat(ptr %t44, ptr %t46)
  %t48 = getelementptr inbounds [9 x i8], ptr @.str3, i64 0, i64 0
  %t49 = call ptr @mire_string_concat(ptr %t47, ptr %t48)
  %t50 = load i64, ptr %t20
  %t51 = call ptr @mire_i64_to_string(i64 %t50)
  %t52 = call ptr @mire_string_concat(ptr %t49, ptr %t51)
  %t53 = getelementptr inbounds [9 x i8], ptr @.str4, i64 0, i64 0
  %t54 = call ptr @mire_string_concat(ptr %t52, ptr %t53)
  %t55 = load i64, ptr %t26
  %t56 = call ptr @mire_i64_to_string(i64 %t55)
  %t57 = call ptr @mire_string_concat(ptr %t54, ptr %t56)
  %t58 = getelementptr inbounds [9 x i8], ptr @.str5, i64 0, i64 0
  %t59 = call ptr @mire_string_concat(ptr %t57, ptr %t58)
  %t60 = load i64, ptr %t32
  %t61 = call ptr @mire_i64_to_string(i64 %t60)
  %t62 = call ptr @mire_string_concat(ptr %t59, ptr %t61)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t62)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
