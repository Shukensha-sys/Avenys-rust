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

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca ptr
  %t15 = alloca ptr
  %t17 = alloca i64
  %t25 = alloca i64
  %t27 = alloca i64
  %t41 = alloca i64
  %t43 = alloca i64
  %t44 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i8* @malloc(i64 96)
  store i64 10, ptr %t3
  %t4 = getelementptr i8, ptr %t3, i64 8
  store i64 10, ptr %t4
  %t5 = getelementptr i8, ptr %t4, i64 8
  store i64 1, ptr %t5
  %t6 = getelementptr i8, ptr %t4, i64 16
  store i64 2, ptr %t6
  %t7 = getelementptr i8, ptr %t4, i64 24
  store i64 3, ptr %t7
  %t8 = getelementptr i8, ptr %t4, i64 32
  store i64 4, ptr %t8
  %t9 = getelementptr i8, ptr %t4, i64 40
  store i64 5, ptr %t9
  %t10 = getelementptr i8, ptr %t4, i64 48
  store i64 6, ptr %t10
  %t11 = getelementptr i8, ptr %t4, i64 56
  store i64 7, ptr %t11
  %t12 = getelementptr i8, ptr %t4, i64 64
  store i64 8, ptr %t12
  %t13 = getelementptr i8, ptr %t4, i64 72
  store i64 9, ptr %t13
  %t14 = getelementptr i8, ptr %t4, i64 80
  store i64 10, ptr %t14
  store ptr %t4, ptr %t2
  %t16 = inttoptr i64 0 to ptr
  store ptr %t16, ptr %t15
  store i64 0, ptr %t17
  br label %while_cond_0
while_cond_0:
  %t18 = load i64, ptr %t17
  %t19 = load ptr, ptr %t2
  %t20 = load ptr, ptr %t2
  %t21 = getelementptr inbounds i8, ptr %t20, i64 -8
  %t22 = icmp eq ptr %t21, null
  br i1 %t22, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t25
  br label %list_len_end_5
list_len_load_4:
  %t23 = load i64, ptr %t21
  store i64 %t23, ptr %t25
  br label %list_len_end_5
list_len_end_5:
  %t24 = load i64, ptr %t25
  %t26 = icmp slt i64 %t18, %t24
  br i1 %t26, label %while_body_1, label %while_end_2
while_body_1:
  %t28 = load ptr, ptr %t2
  %t29 = load i64, ptr %t17
  %t30 = bitcast ptr %t28 to ptr
  %t31 = mul i64 %t29, 8
  %t32 = getelementptr inbounds i8, ptr %t30, i64 %t31
  %t33 = load i64, ptr %t32
  store i64 %t33, ptr %t27
  %t34 = load ptr, ptr %t15
  %t35 = load i64, ptr %t27
  %t36 = load i64, ptr %t27
  %t37 = mul i64 %t35, %t36
  %t38 = call ptr @mire_list_push_i64(ptr %t34, i64 %t37)
  store ptr %t38, ptr %t15
  %t39 = load i64, ptr %t17
  %t40 = add i64 %t39, 1
  store i64 %t40, ptr %t17
  br label %while_cond_0
while_end_2:
  %t42 = load ptr, ptr %t15
  store i64 0, ptr %t43
  store i64 0, ptr %t44
  %t45 = icmp eq ptr %t42, null
  br i1 %t45, label %math_sum_null_6, label %math_sum_cond_7
math_sum_null_6:
  br label %math_sum_end_9
math_sum_cond_7:
  %t46 = load i64, ptr %t42
  %t47 = load i64, ptr %t44
  %t48 = icmp slt i64 %t47, %t46
  br i1 %t48, label %math_sum_body_8, label %math_sum_end_9
math_sum_body_8:
  %t49 = getelementptr i8, ptr %t42, i64 8
  %t50 = mul i64 %t47, 8
  %t51 = getelementptr i8, ptr %t49, i64 %t50
  %t52 = load i64, ptr %t51
  %t53 = load i64, ptr %t43
  %t54 = add i64 %t53, %t52
  store i64 %t54, ptr %t43
  %t55 = add i64 %t47, 1
  store i64 %t55, ptr %t44
  br label %math_sum_cond_7
math_sum_end_9:
  %t56 = load i64, ptr %t43
  store i64 %t56, ptr %t41
  %t57 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t58 = load i64, ptr %t41
  %t59 = call ptr @mire_i64_to_string(i64 %t58)
  %t60 = call ptr @mire_string_concat(ptr %t57, ptr %t59)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t60)
  %t61 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t62 = load i64, ptr %t0
  %t63 = call ptr @mire_wall_elapsed_ms_str(i64 %t62)
  %t64 = call ptr @mire_string_concat(ptr %t61, ptr %t63)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t64)
  ret i32 0
}
