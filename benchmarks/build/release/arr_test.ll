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
declare ptr @mire_list_push_i64(ptr, i64)
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
@.str0 = private unnamed_addr constant [8 x i8] c"x_at_0 \00"
@.str1 = private unnamed_addr constant [10 x i8] c"y_at - 0 \00"

define i64 @mire_main() {
entry:
  %t0 = alloca ptr
  %t5 = alloca ptr
  %t1 = call i8* @malloc(i64 32)
  store i64 2, ptr %t1
  %t2 = getelementptr i8, ptr %t1, i64 8
  store i64 2, ptr %t2
  %t3 = getelementptr i8, ptr %t2, i64 8
  store i64 1, ptr %t3
  %t4 = getelementptr i8, ptr %t2, i64 16
  store i64 2, ptr %t4
  store ptr %t2, ptr %t0
  %t6 = call i8* @malloc(i64 32)
  store i64 2, ptr %t6
  %t7 = getelementptr i8, ptr %t6, i64 8
  store i64 2, ptr %t7
  %t8 = getelementptr i8, ptr %t7, i64 8
  store i64 3, ptr %t8
  %t9 = getelementptr i8, ptr %t7, i64 16
  store i64 4, ptr %t9
  store ptr %t7, ptr %t5
  %t10 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t11 = load ptr, ptr %t0
  %t12 = bitcast ptr %t11 to ptr
  %t13 = mul i64 0, 8
  %t14 = getelementptr inbounds i8, ptr %t12, i64 %t13
  %t15 = load i64, ptr %t14
  %t16 = call ptr @mire_i64_to_string(i64 %t15)
  %t17 = call ptr @mire_string_concat(ptr %t10, ptr %t16)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t17)
  %t18 = getelementptr inbounds [10 x i8], ptr @.str1, i64 0, i64 0
  %t19 = load ptr, ptr %t5
  %t20 = bitcast ptr %t19 to ptr
  %t21 = mul i64 0, 8
  %t22 = getelementptr inbounds i8, ptr %t20, i64 %t21
  %t23 = load i64, ptr %t22
  %t24 = call ptr @mire_i64_to_string(i64 %t23)
  %t25 = call ptr @mire_string_concat(ptr %t18, ptr %t24)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t25)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
