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
@.str2 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca ptr
  %t4 = alloca i64
  %t7 = alloca ptr
  %t9 = alloca i64
  %t12 = alloca i64
  %t33 = alloca i64
  %t34 = alloca i64
  %t37 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = inttoptr i64 0 to ptr
  store ptr %t3, ptr %t2
  store i64 0, ptr %t4
  br label %while_cond_0
while_cond_0:
  %t5 = load i64, ptr %t4
  %t6 = icmp slt i64 %t5, 100
  br i1 %t6, label %while_body_1, label %while_end_2
while_body_1:
  %t8 = inttoptr i64 0 to ptr
  store ptr %t8, ptr %t7
  store i64 0, ptr %t9
  br label %while_cond_3
while_cond_3:
  %t10 = load i64, ptr %t9
  %t11 = icmp slt i64 %t10, 100
  br i1 %t11, label %while_body_4, label %while_end_5
while_body_4:
  %t13 = load i64, ptr %t4
  %t14 = mul i64 %t13, 100
  %t15 = load i64, ptr %t9
  %t16 = add i64 %t14, %t15
  store i64 %t16, ptr %t12
  %t17 = load ptr, ptr %t7
  %t18 = call i8* @malloc(i64 24)
  store i64 1, ptr %t18
  %t19 = getelementptr i8, ptr %t18, i64 8
  store i64 1, ptr %t19
  %t20 = load i64, ptr %t12
  %t21 = getelementptr i8, ptr %t19, i64 8
  store i64 %t20, ptr %t21
  %t22 = call ptr @mire_list_concat(ptr %t17, ptr %t19)
  store ptr %t22, ptr %t7
  %t23 = load i64, ptr %t9
  %t24 = add i64 %t23, 1
  store i64 %t24, ptr %t9
  br label %while_cond_3
while_end_5:
  %t25 = load ptr, ptr %t2
  %t26 = call i8* @malloc(i64 24)
  store i64 1, ptr %t26
  %t27 = getelementptr i8, ptr %t26, i64 8
  store i64 1, ptr %t27
  %t28 = load ptr, ptr %t7
  %t29 = getelementptr i8, ptr %t27, i64 8
  store ptr %t28, ptr %t29
  %t30 = call ptr @mire_list_concat(ptr %t25, ptr %t27)
  store ptr %t30, ptr %t2
  %t31 = load i64, ptr %t4
  %t32 = add i64 %t31, 1
  store i64 %t32, ptr %t4
  br label %while_cond_0
while_end_2:
  store i64 0, ptr %t33
  store i64 0, ptr %t34
  br label %while_cond_6
while_cond_6:
  %t35 = load i64, ptr %t34
  %t36 = icmp slt i64 %t35, 100
  br i1 %t36, label %while_body_7, label %while_end_8
while_body_7:
  store i64 0, ptr %t37
  br label %while_cond_9
while_cond_9:
  %t38 = load i64, ptr %t37
  %t39 = icmp slt i64 %t38, 100
  br i1 %t39, label %while_body_10, label %while_end_11
while_body_10:
  %t40 = load i64, ptr %t33
  %t41 = load ptr, ptr %t2
  %t42 = load i64, ptr %t34
  %t43 = getelementptr inbounds i8, ptr %t41, i64 8
  %t44 = mul i64 %t42, 8
  %t45 = getelementptr inbounds i8, ptr %t43, i64 %t44
  %t46 = load ptr, ptr %t45
  %t47 = load i64, ptr %t37
  %t48 = getelementptr inbounds i8, ptr %t46, i64 8
  %t49 = mul i64 %t47, 8
  %t50 = getelementptr inbounds i8, ptr %t48, i64 %t49
  %t51 = load i64, ptr %t50
  %t52 = add i64 %t40, %t51
  store i64 %t52, ptr %t33
  %t53 = load i64, ptr %t37
  %t54 = add i64 %t53, 1
  store i64 %t54, ptr %t37
  br label %while_cond_9
while_end_11:
  %t55 = load i64, ptr %t34
  %t56 = add i64 %t55, 1
  store i64 %t56, ptr %t34
  br label %while_cond_6
while_end_8:
  %t57 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t58 = load i64, ptr %t33
  %t59 = call ptr @mire_i64_to_string(i64 %t58)
  %t60 = call ptr @concat(ptr %t57, ptr %t59)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t60)
  %t61 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t62 = load i64, ptr %t0
  %t63 = call ptr @mire_wall_elapsed_ms_str(i64 %t62)
  %t64 = call ptr @concat(ptr %t61, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  %t65 = getelementptr inbounds [13 x i8], ptr @.str2, i64 0, i64 0
  %t66 = call i64 @mire_mem_process_bytes()
  %t67 = call ptr @mire_mem_format(i64 %t66)
  %t68 = call ptr @concat(ptr %t65, ptr %t67)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t68)
  ret i32 0
}
