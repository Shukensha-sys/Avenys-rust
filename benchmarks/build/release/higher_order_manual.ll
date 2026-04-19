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
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

define i1 @fn_is_even(i64 %arg_n) {
entry:
  %t0 = alloca i64
  store i64 %arg_n, ptr %t0
  %t1 = load i64, ptr %t0
  %t2 = urem i64 %t1, 2
  %t3 = icmp eq i64 %t2, 0
  ret i1 %t3
}

define i32 @main() {
entry:
  %t4 = alloca i64
  %t6 = alloca ptr
  %t19 = alloca ptr
  %t21 = alloca i64
  %t29 = alloca i64
  %t31 = alloca i64
  %t45 = alloca i64
  %t47 = alloca i64
  %t48 = alloca i64
  %t72 = alloca i64
  %t5 = call i64 @mire_wall_mark_ns()
  store i64 %t5, ptr %t4
  %t7 = call i8* @malloc(i64 96)
  store i64 10, ptr %t7
  %t8 = getelementptr i8, ptr %t7, i64 8
  store i64 10, ptr %t8
  %t9 = getelementptr i8, ptr %t8, i64 8
  store i64 1, ptr %t9
  %t10 = getelementptr i8, ptr %t8, i64 16
  store i64 2, ptr %t10
  %t11 = getelementptr i8, ptr %t8, i64 24
  store i64 3, ptr %t11
  %t12 = getelementptr i8, ptr %t8, i64 32
  store i64 4, ptr %t12
  %t13 = getelementptr i8, ptr %t8, i64 40
  store i64 5, ptr %t13
  %t14 = getelementptr i8, ptr %t8, i64 48
  store i64 6, ptr %t14
  %t15 = getelementptr i8, ptr %t8, i64 56
  store i64 7, ptr %t15
  %t16 = getelementptr i8, ptr %t8, i64 64
  store i64 8, ptr %t16
  %t17 = getelementptr i8, ptr %t8, i64 72
  store i64 9, ptr %t17
  %t18 = getelementptr i8, ptr %t8, i64 80
  store i64 10, ptr %t18
  store ptr %t8, ptr %t6
  %t20 = inttoptr i64 0 to ptr
  store ptr %t20, ptr %t19
  store i64 0, ptr %t21
  br label %while_cond_0
while_cond_0:
  %t22 = load i64, ptr %t21
  %t23 = load ptr, ptr %t6
  %t24 = load ptr, ptr %t6
  %t25 = getelementptr inbounds i8, ptr %t24, i64 -8
  %t26 = icmp eq ptr %t25, null
  br i1 %t26, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t29
  br label %list_len_end_5
list_len_load_4:
  %t27 = load i64, ptr %t25
  store i64 %t27, ptr %t29
  br label %list_len_end_5
list_len_end_5:
  %t28 = load i64, ptr %t29
  %t30 = icmp slt i64 %t22, %t28
  br i1 %t30, label %while_body_1, label %while_end_2
while_body_1:
  %t32 = load ptr, ptr %t6
  %t33 = load i64, ptr %t21
  %t34 = bitcast ptr %t32 to ptr
  %t35 = mul i64 %t33, 8
  %t36 = getelementptr inbounds i8, ptr %t34, i64 %t35
  %t37 = load i64, ptr %t36
  store i64 %t37, ptr %t31
  %t38 = load i64, ptr %t31
  %t39 = call i1 @fn_is_even(i64 %t38)
  br i1 %t39, label %if_then_6, label %if_else_7
if_then_6:
  %t40 = load ptr, ptr %t19
  %t41 = load i64, ptr %t31
  %t42 = call ptr @mire_list_push_i64(ptr %t40, i64 %t41)
  store ptr %t42, ptr %t19
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t43 = load i64, ptr %t21
  %t44 = add i64 %t43, 1
  store i64 %t44, ptr %t21
  br label %while_cond_0
while_end_2:
  %t46 = load ptr, ptr %t19
  store i64 0, ptr %t47
  store i64 0, ptr %t48
  %t49 = icmp eq ptr %t46, null
  br i1 %t49, label %math_sum_null_9, label %math_sum_cond_10
math_sum_null_9:
  br label %math_sum_end_12
math_sum_cond_10:
  %t50 = load i64, ptr %t46
  %t51 = load i64, ptr %t48
  %t52 = icmp slt i64 %t51, %t50
  br i1 %t52, label %math_sum_body_11, label %math_sum_end_12
math_sum_body_11:
  %t53 = getelementptr i8, ptr %t46, i64 8
  %t54 = mul i64 %t51, 8
  %t55 = getelementptr i8, ptr %t53, i64 %t54
  %t56 = load i64, ptr %t55
  %t57 = load i64, ptr %t47
  %t58 = add i64 %t57, %t56
  store i64 %t58, ptr %t47
  %t59 = add i64 %t51, 1
  store i64 %t59, ptr %t48
  br label %math_sum_cond_10
math_sum_end_12:
  %t60 = load i64, ptr %t47
  store i64 %t60, ptr %t45
  %t61 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t62 = load i64, ptr %t45
  %t63 = call ptr @mire_i64_to_string(i64 %t62)
  %t64 = call ptr @mire_string_concat(ptr %t61, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  %t65 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t66 = load ptr, ptr %t19
  %t67 = load ptr, ptr %t19
  %t68 = getelementptr inbounds i8, ptr %t67, i64 -8
  %t69 = icmp eq ptr %t68, null
  br i1 %t69, label %list_len_null_13, label %list_len_load_14
list_len_null_13:
  store i64 0, ptr %t72
  br label %list_len_end_15
list_len_load_14:
  %t70 = load i64, ptr %t68
  store i64 %t70, ptr %t72
  br label %list_len_end_15
list_len_end_15:
  %t71 = load i64, ptr %t72
  %t73 = call ptr @mire_i64_to_string(i64 %t71)
  %t74 = call ptr @mire_string_concat(ptr %t65, ptr %t73)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t74)
  %t75 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t76 = load i64, ptr %t4
  %t77 = call ptr @mire_wall_elapsed_ms_str(i64 %t76)
  %t78 = call ptr @mire_string_concat(ptr %t75, ptr %t77)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t78)
  ret i32 0
}
