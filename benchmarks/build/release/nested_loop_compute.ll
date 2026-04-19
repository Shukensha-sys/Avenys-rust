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
@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t3 = alloca i64
  %t6 = alloca i64
  %t9 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  store i64 0, ptr %t2
  store i64 0, ptr %t3
  br label %while_cond_0
while_cond_0:
  %t4 = load i64, ptr %t3
  %t5 = icmp slt i64 %t4, 100
  br i1 %t5, label %while_body_1, label %while_end_2
while_body_1:
  store i64 0, ptr %t6
  br label %while_cond_3
while_cond_3:
  %t7 = load i64, ptr %t6
  %t8 = icmp slt i64 %t7, 100
  br i1 %t8, label %while_body_4, label %while_end_5
while_body_4:
  %t10 = load i64, ptr %t3
  %t11 = mul i64 %t10, 100
  %t12 = load i64, ptr %t6
  %t13 = add i64 %t11, %t12
  store i64 %t13, ptr %t9
  %t14 = load i64, ptr %t2
  %t15 = load i64, ptr %t9
  %t16 = add i64 %t14, %t15
  store i64 %t16, ptr %t2
  %t17 = load i64, ptr %t6
  %t18 = add i64 %t17, 1
  store i64 %t18, ptr %t6
  br label %while_cond_3
while_end_5:
  %t19 = load i64, ptr %t3
  %t20 = add i64 %t19, 1
  store i64 %t20, ptr %t3
  br label %while_cond_0
while_end_2:
  %t21 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t22 = load i64, ptr %t2
  %t23 = call ptr @mire_i64_to_string(i64 %t22)
  %t24 = call ptr @concat(ptr %t21, ptr %t23)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t24)
  %t25 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t26 = load i64, ptr %t0
  %t27 = call ptr @mire_wall_elapsed_ms_str(i64 %t26)
  %t28 = call ptr @concat(ptr %t25, ptr %t27)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t28)
  ret i32 0
}
