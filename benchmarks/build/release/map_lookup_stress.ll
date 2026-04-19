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
@.str0 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str1 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str2 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str3 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str4 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str5 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str6 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str7 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str8 = private unnamed_addr constant [7 x i8] c"total \00"
@.str9 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str10 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str11 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str12 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t18 = alloca i64
  %t19 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_dict_set_i64(ptr %t6, i64 3, i64 1, i64 0, ptr %t7, i64 11)
  store ptr %t8, ptr %t4
  %t9 = load ptr, ptr %t4
  %t10 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t11 = call ptr @mire_dict_set_i64(ptr %t9, i64 3, i64 1, i64 0, ptr %t10, i64 22)
  store ptr %t11, ptr %t4
  %t12 = load ptr, ptr %t4
  %t13 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t14 = call ptr @mire_dict_set_i64(ptr %t12, i64 3, i64 1, i64 0, ptr %t13, i64 33)
  store ptr %t14, ptr %t4
  %t15 = load ptr, ptr %t4
  %t16 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t17 = call ptr @mire_dict_set_i64(ptr %t15, i64 3, i64 1, i64 0, ptr %t16, i64 44)
  store ptr %t17, ptr %t4
  store i64 0, ptr %t18
  store i64 0, ptr %t19
  br label %while_cond_0
while_cond_0:
  %t20 = load i64, ptr %t18
  %t21 = icmp slt i64 %t20, 40000
  br i1 %t21, label %while_body_1, label %while_end_2
while_body_1:
  %t22 = load i64, ptr %t19
  %t23 = load ptr, ptr %t4
  %t24 = getelementptr inbounds [6 x i8], ptr @.str4, i64 0, i64 0
  %t25 = call i64 @mire_dict_get_i64(ptr %t23, i64 3, i64 0, ptr %t24, i64 0)
  %t26 = add i64 %t22, %t25
  store i64 %t26, ptr %t19
  %t27 = load i64, ptr %t19
  %t28 = load ptr, ptr %t4
  %t29 = getelementptr inbounds [5 x i8], ptr @.str5, i64 0, i64 0
  %t30 = call i64 @mire_dict_get_i64(ptr %t28, i64 3, i64 0, ptr %t29, i64 0)
  %t31 = add i64 %t27, %t30
  store i64 %t31, ptr %t19
  %t32 = load i64, ptr %t19
  %t33 = load ptr, ptr %t4
  %t34 = getelementptr inbounds [6 x i8], ptr @.str6, i64 0, i64 0
  %t35 = call i64 @mire_dict_get_i64(ptr %t33, i64 3, i64 0, ptr %t34, i64 0)
  %t36 = add i64 %t32, %t35
  store i64 %t36, ptr %t19
  %t37 = load i64, ptr %t19
  %t38 = load ptr, ptr %t4
  %t39 = getelementptr inbounds [6 x i8], ptr @.str7, i64 0, i64 0
  %t40 = call i64 @mire_dict_get_i64(ptr %t38, i64 3, i64 0, ptr %t39, i64 0)
  %t41 = add i64 %t37, %t40
  store i64 %t41, ptr %t19
  %t42 = load i64, ptr %t18
  %t43 = add i64 %t42, 1
  store i64 %t43, ptr %t18
  br label %while_cond_0
while_end_2:
  %t44 = getelementptr inbounds [7 x i8], ptr @.str8, i64 0, i64 0
  %t45 = load i64, ptr %t19
  %t46 = call ptr @mire_i64_to_string(i64 %t45)
  %t47 = call ptr @concat(ptr %t44, ptr %t46)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t47)
  %t48 = getelementptr inbounds [9 x i8], ptr @.str9, i64 0, i64 0
  %t49 = load i64, ptr %t0
  %t50 = call ptr @mire_wall_elapsed_ms_str(i64 %t49)
  %t51 = call ptr @concat(ptr %t48, ptr %t50)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t51)
  %t52 = getelementptr inbounds [8 x i8], ptr @.str10, i64 0, i64 0
  %t53 = load i64, ptr %t2
  %t54 = call ptr @mire_cpu_elapsed_ms_str(i64 %t53)
  %t55 = call ptr @concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [16 x i8], ptr @.str11, i64 0, i64 0
  %t57 = load i64, ptr %t2
  %t58 = call i64 @mire_cpu_cycles_est(i64 %t57)
  %t59 = call ptr @mire_i64_to_string(i64 %t58)
  %t60 = call ptr @concat(ptr %t56, ptr %t59)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t60)
  %t61 = getelementptr inbounds [13 x i8], ptr @.str12, i64 0, i64 0
  %t62 = call i64 @mire_mem_process_bytes()
  %t63 = call ptr @mire_mem_format(i64 %t62)
  %t64 = call ptr @concat(ptr %t61, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  ret i32 0
}
