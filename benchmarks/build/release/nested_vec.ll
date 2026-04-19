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
@.str1 = private unnamed_addr constant [6 x i8] c"rows \00"
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
  %t11 = alloca i64
  %t33 = alloca i64
  %t34 = alloca i64
  %t37 = alloca i64
  %t40 = alloca i64
  %t62 = alloca i64
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
  %t8 = icmp slt i64 %t7, 100
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t10 = inttoptr i64 0 to ptr
  store ptr %t10, ptr %t9
  store i64 0, ptr %t11
  br label %while_cond_3
while_cond_3:
  %t12 = load i64, ptr %t11
  %t13 = icmp slt i64 %t12, 100
  br i1 %t13, label %while_body_4, label %while_end_5
while_body_4:
  %t14 = load ptr, ptr %t9
  %t15 = call i8* @malloc(i64 24)
  store i64 1, ptr %t15
  %t16 = getelementptr i8, ptr %t15, i64 8
  store i64 1, ptr %t16
  %t17 = load i64, ptr %t6
  %t18 = mul i64 %t17, 100
  %t19 = load i64, ptr %t11
  %t20 = add i64 %t18, %t19
  %t21 = getelementptr i8, ptr %t16, i64 8
  store i64 %t20, ptr %t21
  %t22 = call ptr @mire_list_concat(ptr %t14, ptr %t16)
  store ptr %t22, ptr %t9
  %t23 = load i64, ptr %t11
  %t24 = add i64 %t23, 1
  store i64 %t24, ptr %t11
  br label %while_cond_3
while_end_5:
  %t25 = load ptr, ptr %t4
  %t26 = call i8* @malloc(i64 24)
  store i64 1, ptr %t26
  %t27 = getelementptr i8, ptr %t26, i64 8
  store i64 1, ptr %t27
  %t28 = load ptr, ptr %t9
  %t29 = getelementptr i8, ptr %t27, i64 8
  store ptr %t28, ptr %t29
  %t30 = call ptr @mire_list_concat(ptr %t25, ptr %t27)
  store ptr %t30, ptr %t4
  %t31 = load i64, ptr %t6
  %t32 = add i64 %t31, 1
  store i64 %t32, ptr %t6
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
  %t41 = load i64, ptr %t34
  %t42 = mul i64 %t41, 100
  %t43 = load i64, ptr %t37
  %t44 = add i64 %t42, %t43
  store i64 %t44, ptr %t40
  %t45 = load i64, ptr %t33
  %t46 = load i64, ptr %t40
  %t47 = add i64 %t45, %t46
  store i64 %t47, ptr %t33
  %t48 = load i64, ptr %t37
  %t49 = add i64 %t48, 1
  store i64 %t49, ptr %t37
  br label %while_cond_9
while_end_11:
  %t50 = load i64, ptr %t34
  %t51 = add i64 %t50, 1
  store i64 %t51, ptr %t34
  br label %while_cond_6
while_end_8:
  %t52 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t53 = load i64, ptr %t33
  %t54 = call ptr @mire_i64_to_string(i64 %t53)
  %t55 = call ptr @concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t57 = load ptr, ptr %t4
  %t58 = load ptr, ptr %t4
  %t59 = icmp eq ptr %t58, null
  br i1 %t59, label %list_len_null_12, label %list_len_load_13
list_len_null_12:
  store i64 0, ptr %t62
  br label %list_len_end_14
list_len_load_13:
  %t60 = load i64, ptr %t58
  store i64 %t60, ptr %t62
  br label %list_len_end_14
list_len_end_14:
  %t61 = load i64, ptr %t62
  %t63 = call ptr @mire_i64_to_string(i64 %t61)
  %t64 = call ptr @concat(ptr %t56, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  %t65 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t66 = load i64, ptr %t0
  %t67 = call ptr @mire_wall_elapsed_ms_str(i64 %t66)
  %t68 = call ptr @concat(ptr %t65, ptr %t67)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t68)
  %t69 = getelementptr inbounds [8 x i8], ptr @.str3, i64 0, i64 0
  %t70 = load i64, ptr %t2
  %t71 = call ptr @mire_cpu_elapsed_ms_str(i64 %t70)
  %t72 = call ptr @concat(ptr %t69, ptr %t71)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t72)
  %t73 = getelementptr inbounds [13 x i8], ptr @.str4, i64 0, i64 0
  %t74 = call i64 @mire_mem_process_bytes()
  %t75 = call ptr @mire_mem_format(i64 %t74)
  %t76 = call ptr @concat(ptr %t73, ptr %t75)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t76)
  ret i32 0
}
