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
@.str0 = private unnamed_addr constant [5 x i8] c"item\00"
@.str1 = private unnamed_addr constant [12 x i8] c"total_keys \00"
@.str2 = private unnamed_addr constant [14 x i8] c"total_values \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str4 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str5 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t9 = alloca ptr
  %t15 = alloca i64
  %t26 = alloca ptr
  %t29 = alloca i64
  %t32 = alloca i64
  %t33 = alloca i64
  %t52 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  store i64 0, ptr %t6
  br label %while_cond_0
while_cond_0:
  %t7 = load i64, ptr %t6
  %t8 = icmp slt i64 %t7, 5000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t10 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t11 = load i64, ptr %t6
  %t12 = urem i64 %t11, 100
  %t13 = call ptr @mire_i64_to_string(i64 %t12)
  %t14 = call ptr @concat(ptr %t10, ptr %t13)
  store ptr %t14, ptr %t9
  %t16 = load ptr, ptr %t4
  %t17 = load ptr, ptr %t9
  %t18 = call i64 @mire_dict_get_i64(ptr %t16, i64 3, i64 0, ptr %t17, i64 0)
  store i64 %t18, ptr %t15
  %t19 = load ptr, ptr %t4
  %t20 = load ptr, ptr %t9
  %t21 = load i64, ptr %t15
  %t22 = add i64 %t21, 1
  %t23 = call ptr @mire_dict_set_i64(ptr %t19, i64 3, i64 1, i64 0, ptr %t20, i64 %t22)
  store ptr %t23, ptr %t4
  %t24 = load i64, ptr %t6
  %t25 = add i64 %t24, 1
  store i64 %t25, ptr %t6
  br label %while_cond_0
while_end_2:
  %t27 = load ptr, ptr %t4
  %t28 = call ptr @mire_dict_keys(ptr %t27)
  store ptr %t28, ptr %t26
  %t30 = load ptr, ptr %t4
  %t31 = call ptr @mire_dict_values(ptr %t30)
  store i64 0, ptr %t32
  store i64 0, ptr %t33
  %t34 = icmp eq ptr %t31, null
  br i1 %t34, label %math_sum_null_3, label %math_sum_cond_4
math_sum_null_3:
  br label %math_sum_end_6
math_sum_cond_4:
  %t35 = load i64, ptr %t31
  %t36 = load i64, ptr %t33
  %t37 = icmp slt i64 %t36, %t35
  br i1 %t37, label %math_sum_body_5, label %math_sum_end_6
math_sum_body_5:
  %t38 = getelementptr i8, ptr %t31, i64 8
  %t39 = mul i64 %t36, 8
  %t40 = getelementptr i8, ptr %t38, i64 %t39
  %t41 = load i64, ptr %t40
  %t42 = load i64, ptr %t32
  %t43 = add i64 %t42, %t41
  store i64 %t43, ptr %t32
  %t44 = add i64 %t36, 1
  store i64 %t44, ptr %t33
  br label %math_sum_cond_4
math_sum_end_6:
  %t45 = load i64, ptr %t32
  store i64 %t45, ptr %t29
  %t46 = getelementptr inbounds [12 x i8], ptr @.str1, i64 0, i64 0
  %t47 = load ptr, ptr %t26
  %t48 = load ptr, ptr %t26
  %t49 = icmp eq ptr %t48, null
  br i1 %t49, label %list_len_null_7, label %list_len_load_8
list_len_null_7:
  store i64 0, ptr %t52
  br label %list_len_end_9
list_len_load_8:
  %t50 = load i64, ptr %t48
  store i64 %t50, ptr %t52
  br label %list_len_end_9
list_len_end_9:
  %t51 = load i64, ptr %t52
  %t53 = call ptr @mire_i64_to_string(i64 %t51)
  %t54 = call ptr @concat(ptr %t46, ptr %t53)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t54)
  %t55 = getelementptr inbounds [14 x i8], ptr @.str2, i64 0, i64 0
  %t56 = load i64, ptr %t29
  %t57 = call ptr @mire_i64_to_string(i64 %t56)
  %t58 = call ptr @concat(ptr %t55, ptr %t57)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t58)
  %t59 = getelementptr inbounds [9 x i8], ptr @.str3, i64 0, i64 0
  %t60 = load i64, ptr %t0
  %t61 = call ptr @mire_wall_elapsed_ms_str(i64 %t60)
  %t62 = call ptr @concat(ptr %t59, ptr %t61)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t62)
  %t63 = getelementptr inbounds [8 x i8], ptr @.str4, i64 0, i64 0
  %t64 = load i64, ptr %t2
  %t65 = call ptr @mire_cpu_elapsed_ms_str(i64 %t64)
  %t66 = call ptr @concat(ptr %t63, ptr %t65)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t66)
  %t67 = getelementptr inbounds [13 x i8], ptr @.str5, i64 0, i64 0
  %t68 = call i64 @mire_mem_process_bytes()
  %t69 = call ptr @mire_mem_format(i64 %t68)
  %t70 = call ptr @concat(ptr %t67, ptr %t69)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t70)
  ret i32 0
}
