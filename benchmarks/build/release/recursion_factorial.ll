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
define ptr @concat(ptr %a, ptr %b) {
  %len_a = call i64 @strlen(ptr %a)
  %len_b = call i64 @strlen(ptr %b)
  %len = add i64 %len_a, %len_b
  %alloc_len = add i64 %len, 1
  %new = call i64 @malloc(i64 %alloc_len)
  %new_ptr = inttoptr i64 %new to ptr
  call void @memcpy(ptr %new_ptr, ptr %a, i64 %len_a)
  %dest = getelementptr i8, ptr %new_ptr, i64 %len_a
  call void @memcpy(ptr %dest, ptr %b, i64 %len_b)
  %end = getelementptr i8, ptr %new_ptr, i64 %len
  store i8 0, ptr %end
  ret ptr %new_ptr
}
@.fmt_i64 = private unnamed_addr constant [5 x i8] c"%ld\0A\00"
@.fmt_str = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.fmt_float = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@.fmt_bool_true = private unnamed_addr constant [5 x i8] c"true\00"
@.fmt_bool_false = private unnamed_addr constant [6 x i8] c"false\00"
@.fmt_i32 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.scanf_str = private unnamed_addr constant [3 x i8] c"%s\00"
@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

define i64 @fn_factorial(i64 %arg_n) {
entry:
  %t0 = alloca i64
  store i64 %arg_n, ptr %t0
  %t1 = load i64, ptr %t0
  %t2 = icmp sle i64 %t1, 1
  br i1 %t2, label %if_then_0, label %if_else_1
if_then_0:
  ret i64 1
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t3 = load i64, ptr %t0
  %t4 = load i64, ptr %t0
  %t5 = sub i64 %t4, 1
  %t6 = call i64 @fn_factorial(i64 %t5)
  %t7 = mul i64 %t3, %t6
  ret i64 %t7
}

define i32 @main() {
entry:
  %t8 = alloca i64
  %t10 = alloca i64
  %t12 = alloca i64
  %t9 = call i64 @mire_wall_mark_ns()
  store i64 %t9, ptr %t8
  %t11 = call i64 @mire_cpu_mark_ns()
  store i64 %t11, ptr %t10
  %t13 = call i64 @fn_factorial(i64 12)
  store i64 %t13, ptr %t12
  %t14 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t15 = load i64, ptr %t12
  %t16 = call ptr @mire_i64_to_string(i64 %t15)
  %t17 = call ptr @concat(ptr %t14, ptr %t16)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t17)
  %t18 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t19 = load i64, ptr %t8
  %t20 = call ptr @mire_wall_elapsed_ms_str(i64 %t19)
  %t21 = call ptr @concat(ptr %t18, ptr %t20)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t21)
  %t22 = getelementptr inbounds [8 x i8], ptr @.str2, i64 0, i64 0
  %t23 = load i64, ptr %t10
  %t24 = call ptr @mire_cpu_elapsed_ms_str(i64 %t23)
  %t25 = call ptr @concat(ptr %t22, ptr %t24)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t25)
  ret i32 0
}
