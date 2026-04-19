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
declare ptr @mire_string_concat(ptr, ptr)
declare ptr @mire_string_append_owned(ptr, ptr)
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
@.fmt_i64 = private unnamed_addr constant [5 x i8] c"%ld\0A\00"
@.fmt_str = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.fmt_float = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@.fmt_bool_true = private unnamed_addr constant [5 x i8] c"true\00"
@.fmt_bool_false = private unnamed_addr constant [6 x i8] c"false\00"
@.fmt_i32 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.fmt_prompt = private unnamed_addr constant [3 x i8] c"%s\00"
@.scanf_str = private unnamed_addr constant [3 x i8] c"%s\00"
@.scanf_i64 = private unnamed_addr constant [4 x i8] c"%ld\00"
@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

define ptr @fn_filter_even(ptr %arg_xs) {
entry:
  %t0 = alloca ptr
  %t1 = alloca ptr
  %t3 = alloca i64
  %t11 = alloca i64
  %t13 = alloca i64
  store ptr %arg_xs, ptr %t0
  %t2 = inttoptr i64 0 to ptr
  store ptr %t2, ptr %t1
  store i64 0, ptr %t3
  br label %while_cond_0
while_cond_0:
  %t4 = load i64, ptr %t3
  %t5 = load ptr, ptr %t0
  %t6 = load ptr, ptr %t0
  %t7 = getelementptr inbounds i8, ptr %t6, i64 -8
  %t8 = icmp eq ptr %t7, null
  br i1 %t8, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t11
  br label %list_len_end_5
list_len_load_4:
  %t9 = load i64, ptr %t7
  store i64 %t9, ptr %t11
  br label %list_len_end_5
list_len_end_5:
  %t10 = load i64, ptr %t11
  %t12 = icmp slt i64 %t4, %t10
  br i1 %t12, label %while_body_1, label %while_end_2
while_body_1:
  %t14 = load ptr, ptr %t0
  %t15 = load i64, ptr %t3
  %t16 = bitcast ptr %t14 to ptr
  %t17 = mul i64 %t15, 8
  %t18 = getelementptr inbounds i8, ptr %t16, i64 %t17
  %t19 = load i64, ptr %t18
  store i64 %t19, ptr %t13
  %t20 = load i64, ptr %t13
  %t21 = urem i64 %t20, 2
  %t22 = icmp eq i64 %t21, 0
  br i1 %t22, label %if_then_6, label %if_else_7
if_then_6:
  %t23 = load ptr, ptr %t1
  %t24 = load i64, ptr %t13
  %t25 = call ptr @mire_list_push_i64(ptr %t23, i64 %t24)
  store ptr %t25, ptr %t1
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t26 = load i64, ptr %t3
  %t27 = add i64 %t26, 1
  store i64 %t27, ptr %t3
  br label %while_cond_0
while_end_2:
  %t28 = load ptr, ptr %t1
  ret ptr %t28
}

define i32 @main() {
entry:
  %t29 = alloca i64
  %t31 = alloca i64
  %t33 = alloca ptr
  %t35 = alloca i64
  %t43 = alloca ptr
  %t46 = alloca i64
  %t53 = alloca i64
  %t30 = call i64 @mire_wall_mark_ns()
  store i64 %t30, ptr %t29
  %t32 = call i64 @mire_cpu_mark_ns()
  store i64 %t32, ptr %t31
  %t34 = inttoptr i64 0 to ptr
  store ptr %t34, ptr %t33
  store i64 0, ptr %t35
  br label %while_cond_9
while_cond_9:
  %t36 = load i64, ptr %t35
  %t37 = icmp slt i64 %t36, 10000
  br i1 %t37, label %while_body_10, label %while_end_11
while_body_10:
  %t38 = load ptr, ptr %t33
  %t39 = load i64, ptr %t35
  %t40 = call ptr @mire_list_push_i64(ptr %t38, i64 %t39)
  store ptr %t40, ptr %t33
  %t41 = load i64, ptr %t35
  %t42 = add i64 %t41, 1
  store i64 %t42, ptr %t35
  br label %while_cond_9
while_end_11:
  %t44 = load ptr, ptr %t33
  %t45 = call ptr @fn_filter_even(ptr %t44)
  store ptr %t45, ptr %t43
  %t47 = load ptr, ptr %t43
  %t48 = load ptr, ptr %t43
  %t49 = getelementptr inbounds i8, ptr %t48, i64 -8
  %t50 = icmp eq ptr %t49, null
  br i1 %t50, label %list_len_null_12, label %list_len_load_13
list_len_null_12:
  store i64 0, ptr %t53
  br label %list_len_end_14
list_len_load_13:
  %t51 = load i64, ptr %t49
  store i64 %t51, ptr %t53
  br label %list_len_end_14
list_len_end_14:
  %t52 = load i64, ptr %t53
  store i64 %t52, ptr %t46
  %t54 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t55 = load i64, ptr %t46
  %t56 = call ptr @mire_i64_to_string(i64 %t55)
  %t57 = call ptr @mire_string_concat(ptr %t54, ptr %t56)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t57)
  %t58 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t59 = load i64, ptr %t29
  %t60 = call ptr @mire_wall_elapsed_ms_str(i64 %t59)
  %t61 = call ptr @mire_string_concat(ptr %t58, ptr %t60)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t61)
  %t62 = getelementptr inbounds [8 x i8], ptr @.str2, i64 0, i64 0
  %t63 = load i64, ptr %t31
  %t64 = call ptr @mire_cpu_elapsed_ms_str(i64 %t63)
  %t65 = call ptr @mire_string_concat(ptr %t62, ptr %t64)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t65)
  ret i32 0
}
