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
@.str0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str1 = private unnamed_addr constant [6 x i8] c"world\00"
@.str2 = private unnamed_addr constant [5 x i8] c"test\00"
@.str3 = private unnamed_addr constant [7 x i8] c"first \00"
@.str4 = private unnamed_addr constant [8 x i8] c"second \00"
@.str5 = private unnamed_addr constant [6 x i8] c"last \00"
@.str6 = private unnamed_addr constant [5 x i8] c"len \00"
@.str7 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t15 = alloca ptr
  %t22 = alloca ptr
  %t29 = alloca ptr
  %t36 = alloca i64
  %t42 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_list_push_ptr(ptr %t6, ptr %t7)
  store ptr %t8, ptr %t4
  %t9 = load ptr, ptr %t4
  %t10 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t11 = call ptr @mire_list_push_ptr(ptr %t9, ptr %t10)
  store ptr %t11, ptr %t4
  %t12 = load ptr, ptr %t4
  %t13 = getelementptr inbounds [5 x i8], ptr @.str2, i64 0, i64 0
  %t14 = call ptr @mire_list_push_ptr(ptr %t12, ptr %t13)
  store ptr %t14, ptr %t4
  %t16 = load ptr, ptr %t4
  %t17 = getelementptr inbounds i8, ptr %t16, i64 8
  %t18 = mul i64 0, 8
  %t19 = getelementptr inbounds i8, ptr %t17, i64 %t18
  %t20 = load ptr, ptr %t19
  %t21 = call ptr @mire_string_copy(ptr %t20)
  store ptr %t21, ptr %t15
  %t23 = load ptr, ptr %t4
  %t24 = getelementptr inbounds i8, ptr %t23, i64 8
  %t25 = mul i64 1, 8
  %t26 = getelementptr inbounds i8, ptr %t24, i64 %t25
  %t27 = load ptr, ptr %t26
  %t28 = call ptr @mire_string_copy(ptr %t27)
  store ptr %t28, ptr %t22
  %t30 = load ptr, ptr %t4
  %t31 = getelementptr inbounds i8, ptr %t30, i64 8
  %t32 = mul i64 2, 8
  %t33 = getelementptr inbounds i8, ptr %t31, i64 %t32
  %t34 = load ptr, ptr %t33
  %t35 = call ptr @mire_string_copy(ptr %t34)
  store ptr %t35, ptr %t29
  %t37 = load ptr, ptr %t4
  %t38 = load ptr, ptr %t4
  %t39 = icmp eq ptr %t38, null
  br i1 %t39, label %list_len_null_0, label %list_len_load_1
list_len_null_0:
  store i64 0, ptr %t42
  br label %list_len_end_2
list_len_load_1:
  %t40 = load i64, ptr %t38
  store i64 %t40, ptr %t42
  br label %list_len_end_2
list_len_end_2:
  %t41 = load i64, ptr %t42
  store i64 %t41, ptr %t36
  %t43 = getelementptr inbounds [7 x i8], ptr @.str3, i64 0, i64 0
  %t44 = load ptr, ptr %t15
  %t45 = call ptr @concat(ptr %t43, ptr %t44)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t45)
  %t46 = getelementptr inbounds [8 x i8], ptr @.str4, i64 0, i64 0
  %t47 = load ptr, ptr %t22
  %t48 = call ptr @concat(ptr %t46, ptr %t47)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t48)
  %t49 = getelementptr inbounds [6 x i8], ptr @.str5, i64 0, i64 0
  %t50 = load ptr, ptr %t29
  %t51 = call ptr @concat(ptr %t49, ptr %t50)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t51)
  %t52 = getelementptr inbounds [5 x i8], ptr @.str6, i64 0, i64 0
  %t53 = load i64, ptr %t36
  %t54 = call ptr @mire_i64_to_string(i64 %t53)
  %t55 = call ptr @concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [9 x i8], ptr @.str7, i64 0, i64 0
  %t57 = load i64, ptr %t0
  %t58 = call ptr @mire_wall_elapsed_ms_str(i64 %t57)
  %t59 = call ptr @concat(ptr %t56, ptr %t58)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t59)
  ret i32 0
}
