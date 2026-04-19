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
@.str1 = private unnamed_addr constant [9 x i8] c"result2 \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i64 @fn_sum_all(ptr %arg_xs) {
entry:
  %t0 = alloca ptr
  %t1 = alloca i64
  %t2 = alloca i64
  %t9 = alloca i64
  store ptr %arg_xs, ptr %t0
  store i64 0, ptr %t1
  store i64 0, ptr %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i64, ptr %t2
  %t4 = load ptr, ptr %t0
  %t5 = load ptr, ptr %t0
  %t6 = icmp eq ptr %t5, null
  br i1 %t6, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t9
  br label %list_len_end_5
list_len_load_4:
  %t7 = load i64, ptr %t5
  store i64 %t7, ptr %t9
  br label %list_len_end_5
list_len_end_5:
  %t8 = load i64, ptr %t9
  %t10 = icmp slt i64 %t3, %t8
  br i1 %t10, label %while_body_1, label %while_end_2
while_body_1:
  %t11 = load i64, ptr %t1
  %t12 = load ptr, ptr %t0
  %t13 = load i64, ptr %t2
  %t14 = getelementptr inbounds i8, ptr %t12, i64 8
  %t15 = mul i64 %t13, 8
  %t16 = getelementptr inbounds i8, ptr %t14, i64 %t15
  %t17 = load i64, ptr %t16
  %t18 = add i64 %t11, %t17
  store i64 %t18, ptr %t1
  %t19 = load i64, ptr %t2
  %t20 = add i64 %t19, 1
  store i64 %t20, ptr %t2
  br label %while_cond_0
while_end_2:
  %t21 = load i64, ptr %t1
  ret i64 %t21
}

define i32 @main() {
entry:
  %t22 = alloca i64
  %t24 = alloca i64
  %t26 = alloca ptr
  %t28 = alloca i64
  %t36 = alloca i64
  %t39 = alloca i64
  %t23 = call i64 @mire_wall_mark_ns()
  store i64 %t23, ptr %t22
  %t25 = call i64 @mire_cpu_mark_ns()
  store i64 %t25, ptr %t24
  %t27 = inttoptr i64 0 to ptr
  store ptr %t27, ptr %t26
  store i64 0, ptr %t28
  br label %while_cond_6
while_cond_6:
  %t29 = load i64, ptr %t28
  %t30 = icmp slt i64 %t29, 5000
  br i1 %t30, label %while_body_7, label %while_end_8
while_body_7:
  %t31 = load ptr, ptr %t26
  %t32 = load i64, ptr %t28
  %t33 = call ptr @mire_list_push_i64(ptr %t31, i64 %t32)
  store ptr %t33, ptr %t26
  %t34 = load i64, ptr %t28
  %t35 = add i64 %t34, 1
  store i64 %t35, ptr %t28
  br label %while_cond_6
while_end_8:
  %t37 = load ptr, ptr %t26
  %t38 = call i64 @fn_sum_all(ptr %t37)
  store i64 %t38, ptr %t36
  %t40 = load ptr, ptr %t26
  %t41 = call i64 @fn_sum_all(ptr %t40)
  store i64 %t41, ptr %t39
  %t42 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t43 = load i64, ptr %t36
  %t44 = call ptr @mire_i64_to_string(i64 %t43)
  %t45 = call ptr @concat(ptr %t42, ptr %t44)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t45)
  %t46 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t47 = load i64, ptr %t39
  %t48 = call ptr @mire_i64_to_string(i64 %t47)
  %t49 = call ptr @concat(ptr %t46, ptr %t48)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t49)
  %t50 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t51 = load i64, ptr %t22
  %t52 = call ptr @mire_wall_elapsed_ms_str(i64 %t51)
  %t53 = call ptr @concat(ptr %t50, ptr %t52)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t53)
  %t54 = getelementptr inbounds [13 x i8], ptr @.str3, i64 0, i64 0
  %t55 = call i64 @mire_mem_process_bytes()
  %t56 = call ptr @mire_mem_format(i64 %t55)
  %t57 = call ptr @concat(ptr %t54, ptr %t56)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t57)
  ret i32 0
}
