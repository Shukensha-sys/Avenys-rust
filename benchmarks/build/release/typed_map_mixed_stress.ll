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
@.str0 = private unnamed_addr constant [8 x i8] c"enabled\00"
@.str1 = private unnamed_addr constant [9 x i8] c"disabled\00"
@.str2 = private unnamed_addr constant [1 x i8] c"\00"
@.str3 = private unnamed_addr constant [1 x i8] c"\00"
@.str4 = private unnamed_addr constant [7 x i8] c"total \00"
@.str5 = private unnamed_addr constant [8 x i8] c"labels \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str9 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t14 = alloca i64
  %t15 = alloca i64
  %t18 = alloca ptr
  %t24 = alloca ptr
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t8 = zext i1 1 to i64
  %t9 = call ptr @mire_dict_set_ptr(ptr %t6, i64 2, i64 3, i64 %t8, ptr null, ptr %t7)
  store ptr %t9, ptr %t4
  %t10 = load ptr, ptr %t4
  %t11 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t12 = zext i1 0 to i64
  %t13 = call ptr @mire_dict_set_ptr(ptr %t10, i64 2, i64 3, i64 %t12, ptr null, ptr %t11)
  store ptr %t13, ptr %t4
  store i64 0, ptr %t14
  store i64 0, ptr %t15
  br label %while_cond_0
while_cond_0:
  %t16 = load i64, ptr %t15
  %t17 = icmp slt i64 %t16, 40000
  br i1 %t17, label %while_body_1, label %while_end_2
while_body_1:
  %t19 = load ptr, ptr %t4
  %t20 = zext i1 1 to i64
  %t21 = getelementptr inbounds [1 x i8], ptr @.str2, i64 0, i64 0
  %t22 = call ptr @mire_dict_get_ptr(ptr %t19, i64 2, i64 %t20, ptr null, ptr %t21)
  %t23 = call ptr @mire_string_copy(ptr %t22)
  store ptr %t23, ptr %t18
  %t25 = load ptr, ptr %t4
  %t26 = zext i1 0 to i64
  %t27 = getelementptr inbounds [1 x i8], ptr @.str3, i64 0, i64 0
  %t28 = call ptr @mire_dict_get_ptr(ptr %t25, i64 2, i64 %t26, ptr null, ptr %t27)
  %t29 = call ptr @mire_string_copy(ptr %t28)
  store ptr %t29, ptr %t24
  %t30 = load i64, ptr %t14
  %t31 = load ptr, ptr %t18
  %t32 = call i64 @strlen(ptr %t31)
  %t33 = add i64 %t30, %t32
  store i64 %t33, ptr %t14
  %t34 = load i64, ptr %t14
  %t35 = load ptr, ptr %t24
  %t36 = call i64 @strlen(ptr %t35)
  %t37 = add i64 %t34, %t36
  store i64 %t37, ptr %t14
  %t38 = load i64, ptr %t15
  %t39 = add i64 %t38, 1
  store i64 %t39, ptr %t15
  br label %while_cond_0
while_end_2:
  %t40 = getelementptr inbounds [7 x i8], ptr @.str4, i64 0, i64 0
  %t41 = load i64, ptr %t14
  %t42 = call ptr @mire_i64_to_string(i64 %t41)
  %t43 = call ptr @concat(ptr %t40, ptr %t42)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t43)
  %t44 = getelementptr inbounds [8 x i8], ptr @.str5, i64 0, i64 0
  %t45 = load ptr, ptr %t4
  %t46 = call ptr @mire_dict_to_string(ptr %t45)
  %t47 = call ptr @concat(ptr %t44, ptr %t46)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t47)
  %t48 = getelementptr inbounds [9 x i8], ptr @.str6, i64 0, i64 0
  %t49 = load i64, ptr %t0
  %t50 = call ptr @mire_wall_elapsed_ms_str(i64 %t49)
  %t51 = call ptr @concat(ptr %t48, ptr %t50)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t51)
  %t52 = getelementptr inbounds [8 x i8], ptr @.str7, i64 0, i64 0
  %t53 = load i64, ptr %t2
  %t54 = call ptr @mire_cpu_elapsed_ms_str(i64 %t53)
  %t55 = call ptr @concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [16 x i8], ptr @.str8, i64 0, i64 0
  %t57 = load i64, ptr %t2
  %t58 = call i64 @mire_cpu_cycles_est(i64 %t57)
  %t59 = call ptr @mire_i64_to_string(i64 %t58)
  %t60 = call ptr @concat(ptr %t56, ptr %t59)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t60)
  %t61 = getelementptr inbounds [13 x i8], ptr @.str9, i64 0, i64 0
  %t62 = call i64 @mire_mem_process_bytes()
  %t63 = call ptr @mire_mem_format(i64 %t62)
  %t64 = call ptr @concat(ptr %t61, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  ret i32 0
}
