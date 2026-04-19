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
@.str0 = private unnamed_addr constant [6 x i8] c"HELLO\00"
@.str1 = private unnamed_addr constant [6 x i8] c"world\00"
@.str2 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str3 = private unnamed_addr constant [7 x i8] c"upper \00"
@.str4 = private unnamed_addr constant [7 x i8] c"lower \00"
@.str5 = private unnamed_addr constant [9 x i8] c"trimmed \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca ptr
  %t5 = alloca ptr
  %t8 = alloca ptr
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t4 = call ptr @mire_string_copy(ptr %t3)
  store ptr %t4, ptr %t2
  %t6 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t7 = call ptr @mire_string_copy(ptr %t6)
  store ptr %t7, ptr %t5
  %t9 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t10 = call ptr @mire_string_copy(ptr %t9)
  store ptr %t10, ptr %t8
  %t11 = getelementptr inbounds [7 x i8], ptr @.str3, i64 0, i64 0
  %t12 = load ptr, ptr %t2
  %t13 = call ptr @mire_string_concat(ptr %t11, ptr %t12)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t13)
  %t14 = getelementptr inbounds [7 x i8], ptr @.str4, i64 0, i64 0
  %t15 = load ptr, ptr %t5
  %t16 = call ptr @mire_string_concat(ptr %t14, ptr %t15)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t16)
  %t17 = getelementptr inbounds [9 x i8], ptr @.str5, i64 0, i64 0
  %t18 = load ptr, ptr %t8
  %t19 = call ptr @mire_string_concat(ptr %t17, ptr %t18)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t19)
  %t20 = getelementptr inbounds [9 x i8], ptr @.str6, i64 0, i64 0
  %t21 = load i64, ptr %t0
  %t22 = call ptr @mire_wall_elapsed_ms_str(i64 %t21)
  %t23 = call ptr @mire_string_concat(ptr %t20, ptr %t22)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t23)
  ret i32 0
}
