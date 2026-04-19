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
@.str1 = private unnamed_addr constant [5 x i8] c"len \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i64 @fn_sum_vec(ptr %arg_xs) {
entry:
  %t0 = alloca ptr
  %t2 = alloca i64
  %t3 = alloca i64
  store ptr %arg_xs, ptr %t0
  %t1 = load ptr, ptr %t0
  store i64 0, ptr %t2
  store i64 0, ptr %t3
  %t4 = icmp eq ptr %t1, null
  br i1 %t4, label %math_sum_null_0, label %math_sum_cond_1
math_sum_null_0:
  br label %math_sum_end_3
math_sum_cond_1:
  %t5 = load i64, ptr %t1
  %t6 = load i64, ptr %t3
  %t7 = icmp slt i64 %t6, %t5
  br i1 %t7, label %math_sum_body_2, label %math_sum_end_3
math_sum_body_2:
  %t8 = getelementptr i8, ptr %t1, i64 8
  %t9 = mul i64 %t6, 8
  %t10 = getelementptr i8, ptr %t8, i64 %t9
  %t11 = load i64, ptr %t10
  %t12 = load i64, ptr %t2
  %t13 = add i64 %t12, %t11
  store i64 %t13, ptr %t2
  %t14 = add i64 %t6, 1
  store i64 %t14, ptr %t3
  br label %math_sum_cond_1
math_sum_end_3:
  %t15 = load i64, ptr %t2
  ret i64 %t15
}

define i32 @main() {
entry:
  %t16 = alloca i64
  %t18 = alloca i64
  %t20 = alloca ptr
  %t22 = alloca i64
  %t30 = alloca i64
  %t43 = alloca i64
  %t17 = call i64 @mire_wall_mark_ns()
  store i64 %t17, ptr %t16
  %t19 = call i64 @mire_cpu_mark_ns()
  store i64 %t19, ptr %t18
  %t21 = inttoptr i64 0 to ptr
  store ptr %t21, ptr %t20
  store i64 0, ptr %t22
  br label %while_cond_4
while_cond_4:
  %t23 = load i64, ptr %t22
  %t24 = icmp slt i64 %t23, 1000
  br i1 %t24, label %while_body_5, label %while_end_6
while_body_5:
  %t25 = load ptr, ptr %t20
  %t26 = load i64, ptr %t22
  %t27 = call ptr @mire_list_push_i64(ptr %t25, i64 %t26)
  store ptr %t27, ptr %t20
  %t28 = load i64, ptr %t22
  %t29 = add i64 %t28, 1
  store i64 %t29, ptr %t22
  br label %while_cond_4
while_end_6:
  %t31 = load ptr, ptr %t20
  %t32 = call i64 @fn_sum_vec(ptr %t31)
  store i64 %t32, ptr %t30
  %t33 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t34 = load i64, ptr %t30
  %t35 = call ptr @mire_i64_to_string(i64 %t34)
  %t36 = call ptr @concat(ptr %t33, ptr %t35)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t36)
  %t37 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t38 = load ptr, ptr %t20
  %t39 = load ptr, ptr %t20
  %t40 = icmp eq ptr %t39, null
  br i1 %t40, label %list_len_null_7, label %list_len_load_8
list_len_null_7:
  store i64 0, ptr %t43
  br label %list_len_end_9
list_len_load_8:
  %t41 = load i64, ptr %t39
  store i64 %t41, ptr %t43
  br label %list_len_end_9
list_len_end_9:
  %t42 = load i64, ptr %t43
  %t44 = call ptr @mire_i64_to_string(i64 %t42)
  %t45 = call ptr @concat(ptr %t37, ptr %t44)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t45)
  %t46 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t47 = load i64, ptr %t16
  %t48 = call ptr @mire_wall_elapsed_ms_str(i64 %t47)
  %t49 = call ptr @concat(ptr %t46, ptr %t48)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t49)
  %t50 = getelementptr inbounds [8 x i8], ptr @.str3, i64 0, i64 0
  %t51 = load i64, ptr %t18
  %t52 = call ptr @mire_cpu_elapsed_ms_str(i64 %t51)
  %t53 = call ptr @concat(ptr %t50, ptr %t52)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t53)
  %t54 = getelementptr inbounds [13 x i8], ptr @.str4, i64 0, i64 0
  %t55 = call i64 @mire_mem_process_bytes()
  %t56 = call ptr @mire_mem_format(i64 %t55)
  %t57 = call ptr @concat(ptr %t54, ptr %t56)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t57)
  ret i32 0
}
