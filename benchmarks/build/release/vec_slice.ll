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
@.str0 = private unnamed_addr constant [9 x i8] c"sum_all \00"
@.str1 = private unnamed_addr constant [12 x i8] c"sum_sliced \00"
@.str2 = private unnamed_addr constant [12 x i8] c"sliced_len \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str4 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t14 = alloca i64
  %t21 = alloca i64
  %t23 = alloca ptr
  %t27 = alloca i64
  %t29 = alloca i64
  %t30 = alloca i64
  %t43 = alloca i64
  %t45 = alloca i64
  %t46 = alloca i64
  %t74 = alloca i64
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
  %t9 = load ptr, ptr %t4
  %t10 = load i64, ptr %t6
  %t11 = call ptr @mire_list_push_i64(ptr %t9, i64 %t10)
  store ptr %t11, ptr %t4
  %t12 = load i64, ptr %t6
  %t13 = add i64 %t12, 1
  store i64 %t13, ptr %t6
  br label %while_cond_0
while_end_2:
  %t15 = load ptr, ptr %t4
  %t16 = load ptr, ptr %t4
  %t17 = getelementptr inbounds i8, ptr %t16, i64 -8
  %t18 = icmp eq ptr %t17, null
  br i1 %t18, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t21
  br label %list_len_end_5
list_len_load_4:
  %t19 = load i64, ptr %t17
  store i64 %t19, ptr %t21
  br label %list_len_end_5
list_len_end_5:
  %t20 = load i64, ptr %t21
  %t22 = udiv i64 %t20, 2
  store i64 %t22, ptr %t14
  %t24 = load ptr, ptr %t4
  %t25 = load i64, ptr %t14
  %t26 = call ptr @mire_list_slice(ptr %t24, i64 0, i64 %t25)
  store ptr %t26, ptr %t23
  %t28 = load ptr, ptr %t4
  store i64 0, ptr %t29
  store i64 0, ptr %t30
  %t31 = icmp eq ptr %t28, null
  br i1 %t31, label %math_sum_null_6, label %math_sum_cond_7
math_sum_null_6:
  br label %math_sum_end_9
math_sum_cond_7:
  %t32 = load i64, ptr %t28
  %t33 = load i64, ptr %t30
  %t34 = icmp slt i64 %t33, %t32
  br i1 %t34, label %math_sum_body_8, label %math_sum_end_9
math_sum_body_8:
  %t35 = getelementptr i8, ptr %t28, i64 8
  %t36 = mul i64 %t33, 8
  %t37 = getelementptr i8, ptr %t35, i64 %t36
  %t38 = load i64, ptr %t37
  %t39 = load i64, ptr %t29
  %t40 = add i64 %t39, %t38
  store i64 %t40, ptr %t29
  %t41 = add i64 %t33, 1
  store i64 %t41, ptr %t30
  br label %math_sum_cond_7
math_sum_end_9:
  %t42 = load i64, ptr %t29
  store i64 %t42, ptr %t27
  %t44 = load ptr, ptr %t23
  store i64 0, ptr %t45
  store i64 0, ptr %t46
  %t47 = icmp eq ptr %t44, null
  br i1 %t47, label %math_sum_null_10, label %math_sum_cond_11
math_sum_null_10:
  br label %math_sum_end_13
math_sum_cond_11:
  %t48 = load i64, ptr %t44
  %t49 = load i64, ptr %t46
  %t50 = icmp slt i64 %t49, %t48
  br i1 %t50, label %math_sum_body_12, label %math_sum_end_13
math_sum_body_12:
  %t51 = getelementptr i8, ptr %t44, i64 8
  %t52 = mul i64 %t49, 8
  %t53 = getelementptr i8, ptr %t51, i64 %t52
  %t54 = load i64, ptr %t53
  %t55 = load i64, ptr %t45
  %t56 = add i64 %t55, %t54
  store i64 %t56, ptr %t45
  %t57 = add i64 %t49, 1
  store i64 %t57, ptr %t46
  br label %math_sum_cond_11
math_sum_end_13:
  %t58 = load i64, ptr %t45
  store i64 %t58, ptr %t43
  %t59 = getelementptr inbounds [9 x i8], ptr @.str0, i64 0, i64 0
  %t60 = load i64, ptr %t27
  %t61 = call ptr @mire_i64_to_string(i64 %t60)
  %t62 = call ptr @mire_string_concat(ptr %t59, ptr %t61)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t62)
  %t63 = getelementptr inbounds [12 x i8], ptr @.str1, i64 0, i64 0
  %t64 = load i64, ptr %t43
  %t65 = call ptr @mire_i64_to_string(i64 %t64)
  %t66 = call ptr @mire_string_concat(ptr %t63, ptr %t65)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t66)
  %t67 = getelementptr inbounds [12 x i8], ptr @.str2, i64 0, i64 0
  %t68 = load ptr, ptr %t23
  %t69 = load ptr, ptr %t23
  %t70 = getelementptr inbounds i8, ptr %t69, i64 -8
  %t71 = icmp eq ptr %t70, null
  br i1 %t71, label %list_len_null_14, label %list_len_load_15
list_len_null_14:
  store i64 0, ptr %t74
  br label %list_len_end_16
list_len_load_15:
  %t72 = load i64, ptr %t70
  store i64 %t72, ptr %t74
  br label %list_len_end_16
list_len_end_16:
  %t73 = load i64, ptr %t74
  %t75 = call ptr @mire_i64_to_string(i64 %t73)
  %t76 = call ptr @mire_string_concat(ptr %t67, ptr %t75)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t76)
  %t77 = getelementptr inbounds [9 x i8], ptr @.str3, i64 0, i64 0
  %t78 = load i64, ptr %t0
  %t79 = call ptr @mire_wall_elapsed_ms_str(i64 %t78)
  %t80 = call ptr @mire_string_concat(ptr %t77, ptr %t79)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t80)
  %t81 = getelementptr inbounds [8 x i8], ptr @.str4, i64 0, i64 0
  %t82 = load i64, ptr %t2
  %t83 = call ptr @mire_cpu_elapsed_ms_str(i64 %t82)
  %t84 = call ptr @mire_string_concat(ptr %t81, ptr %t83)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t84)
  ret i32 0
}
