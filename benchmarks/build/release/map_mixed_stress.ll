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
@.str1 = private unnamed_addr constant [4 x i8] c"cat\00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t9 = alloca ptr
  %t15 = alloca ptr
  %t21 = alloca i64
  %t30 = alloca i64
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
  %t8 = icmp slt i64 %t7, 30000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t10 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t11 = load i64, ptr %t6
  %t12 = urem i64 %t11, 1000
  %t13 = call ptr @mire_i64_to_string(i64 %t12)
  %t14 = call ptr @concat(ptr %t10, ptr %t13)
  store ptr %t14, ptr %t9
  %t16 = getelementptr inbounds [4 x i8], ptr @.str1, i64 0, i64 0
  %t17 = load i64, ptr %t6
  %t18 = urem i64 %t17, 100
  %t19 = call ptr @mire_i64_to_string(i64 %t18)
  %t20 = call ptr @concat(ptr %t16, ptr %t19)
  store ptr %t20, ptr %t15
  %t22 = load ptr, ptr %t4
  %t23 = load ptr, ptr %t9
  %t24 = call i64 @mire_dict_get_i64(ptr %t22, i64 3, i64 0, ptr %t23, i64 0)
  store i64 %t24, ptr %t21
  %t25 = load ptr, ptr %t4
  %t26 = load ptr, ptr %t9
  %t27 = load i64, ptr %t21
  %t28 = add i64 %t27, 1
  %t29 = call ptr @mire_dict_set_i64(ptr %t25, i64 3, i64 1, i64 0, ptr %t26, i64 %t28)
  store ptr %t29, ptr %t4
  %t31 = load ptr, ptr %t4
  %t32 = load ptr, ptr %t15
  %t33 = call i64 @mire_dict_get_i64(ptr %t31, i64 3, i64 0, ptr %t32, i64 0)
  store i64 %t33, ptr %t30
  %t34 = load ptr, ptr %t4
  %t35 = load ptr, ptr %t15
  %t36 = load i64, ptr %t30
  %t37 = add i64 %t36, 1
  %t38 = call ptr @mire_dict_set_i64(ptr %t34, i64 3, i64 1, i64 0, ptr %t35, i64 %t37)
  store ptr %t38, ptr %t4
  %t39 = load i64, ptr %t6
  %t40 = add i64 %t39, 1
  store i64 %t40, ptr %t6
  br label %while_cond_0
while_end_2:
  %t41 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t42 = load i64, ptr %t0
  %t43 = call ptr @mire_wall_elapsed_ms_str(i64 %t42)
  %t44 = call ptr @concat(ptr %t41, ptr %t43)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t44)
  %t45 = getelementptr inbounds [8 x i8], ptr @.str3, i64 0, i64 0
  %t46 = load i64, ptr %t2
  %t47 = call ptr @mire_cpu_elapsed_ms_str(i64 %t46)
  %t48 = call ptr @concat(ptr %t45, ptr %t47)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t48)
  %t49 = getelementptr inbounds [13 x i8], ptr @.str4, i64 0, i64 0
  %t50 = call i64 @mire_mem_process_bytes()
  %t51 = call ptr @mire_mem_format(i64 %t50)
  %t52 = call ptr @concat(ptr %t49, ptr %t51)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t52)
  ret i32 0
}
