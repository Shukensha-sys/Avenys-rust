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
@.str0 = private unnamed_addr constant [5 x i8] c"seed\00"
@.str1 = private unnamed_addr constant [5 x i8] c"seed\00"
@.str2 = private unnamed_addr constant [5 x i8] c"node\00"
@.str3 = private unnamed_addr constant [3 x i8] c"-x\00"
@.str4 = private unnamed_addr constant [7 x i8] c"total \00"
@.str5 = private unnamed_addr constant [7 x i8] c"items \00"
@.str6 = private unnamed_addr constant [10 x i8] c"text_len \00"
@.str7 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str8 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str9 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str10 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str11 = private unnamed_addr constant [5 x i8] c"gpu \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t7 = alloca ptr
  %t25 = alloca i64
  %t27 = alloca i64
  %t28 = alloca i64
  %t41 = alloca ptr
  %t54 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  store i64 0, ptr %t6
  %t8 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t9 = call ptr @mire_string_copy(ptr %t8)
  store ptr %t9, ptr %t7
  br label %while_cond_0
while_cond_0:
  %t10 = load i64, ptr %t6
  %t11 = icmp slt i64 %t10, 5000
  br i1 %t11, label %while_body_1, label %while_end_2
while_body_1:
  %t12 = load ptr, ptr %t4
  %t13 = load i64, ptr %t6
  %t14 = call ptr @mire_list_push_i64(ptr %t12, i64 %t13)
  store ptr %t14, ptr %t4
  %t15 = load ptr, ptr %t7
  %t16 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t17 = getelementptr inbounds [5 x i8], ptr @.str2, i64 0, i64 0
  %t18 = call ptr @mire_strings_replace(ptr %t15, ptr %t16, ptr %t17)
  %t19 = load ptr, ptr %t7
  call void @mire_string_free(ptr %t19)
  store ptr %t18, ptr %t7
  %t20 = getelementptr inbounds [3 x i8], ptr @.str3, i64 0, i64 0
  %t21 = load ptr, ptr %t7
  %t22 = call ptr @mire_string_append_owned(ptr %t21, ptr %t20)
  store ptr %t22, ptr %t7
  %t23 = load i64, ptr %t6
  %t24 = add i64 %t23, 1
  store i64 %t24, ptr %t6
  br label %while_cond_0
while_end_2:
  %t26 = load ptr, ptr %t4
  store i64 0, ptr %t27
  store i64 0, ptr %t28
  %t29 = icmp eq ptr %t26, null
  br i1 %t29, label %math_sum_null_3, label %math_sum_cond_4
math_sum_null_3:
  br label %math_sum_end_6
math_sum_cond_4:
  %t30 = load i64, ptr %t26
  %t31 = load i64, ptr %t28
  %t32 = icmp slt i64 %t31, %t30
  br i1 %t32, label %math_sum_body_5, label %math_sum_end_6
math_sum_body_5:
  %t33 = getelementptr i8, ptr %t26, i64 8
  %t34 = mul i64 %t31, 8
  %t35 = getelementptr i8, ptr %t33, i64 %t34
  %t36 = load i64, ptr %t35
  %t37 = load i64, ptr %t27
  %t38 = add i64 %t37, %t36
  store i64 %t38, ptr %t27
  %t39 = add i64 %t31, 1
  store i64 %t39, ptr %t28
  br label %math_sum_cond_4
math_sum_end_6:
  %t40 = load i64, ptr %t27
  store i64 %t40, ptr %t25
  %t42 = call ptr @mire_gpu_snapshot()
  store ptr %t42, ptr %t41
  %t43 = getelementptr inbounds [7 x i8], ptr @.str4, i64 0, i64 0
  %t44 = load i64, ptr %t25
  %t45 = call ptr @mire_i64_to_string(i64 %t44)
  %t46 = call ptr @mire_string_concat(ptr %t43, ptr %t45)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t46)
  %t47 = getelementptr inbounds [7 x i8], ptr @.str5, i64 0, i64 0
  %t48 = load ptr, ptr %t4
  %t49 = load ptr, ptr %t4
  %t50 = getelementptr inbounds i8, ptr %t49, i64 -8
  %t51 = icmp eq ptr %t50, null
  br i1 %t51, label %list_len_null_7, label %list_len_load_8
list_len_null_7:
  store i64 0, ptr %t54
  br label %list_len_end_9
list_len_load_8:
  %t52 = load i64, ptr %t50
  store i64 %t52, ptr %t54
  br label %list_len_end_9
list_len_end_9:
  %t53 = load i64, ptr %t54
  %t55 = call ptr @mire_i64_to_string(i64 %t53)
  %t56 = call ptr @mire_string_concat(ptr %t47, ptr %t55)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t56)
  %t57 = getelementptr inbounds [10 x i8], ptr @.str6, i64 0, i64 0
  %t58 = load ptr, ptr %t7
  %t59 = call i64 @strlen(ptr %t58)
  %t60 = call ptr @mire_i64_to_string(i64 %t59)
  %t61 = call ptr @mire_string_concat(ptr %t57, ptr %t60)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t61)
  %t62 = getelementptr inbounds [9 x i8], ptr @.str7, i64 0, i64 0
  %t63 = load i64, ptr %t0
  %t64 = call ptr @mire_wall_elapsed_ms_str(i64 %t63)
  %t65 = call ptr @mire_string_concat(ptr %t62, ptr %t64)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t65)
  %t66 = getelementptr inbounds [8 x i8], ptr @.str8, i64 0, i64 0
  %t67 = load i64, ptr %t2
  %t68 = call ptr @mire_cpu_elapsed_ms_str(i64 %t67)
  %t69 = call ptr @mire_string_concat(ptr %t66, ptr %t68)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t69)
  %t70 = getelementptr inbounds [16 x i8], ptr @.str9, i64 0, i64 0
  %t71 = load i64, ptr %t2
  %t72 = call i64 @mire_cpu_cycles_est(i64 %t71)
  %t73 = call ptr @mire_i64_to_string(i64 %t72)
  %t74 = call ptr @mire_string_concat(ptr %t70, ptr %t73)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t74)
  %t75 = getelementptr inbounds [13 x i8], ptr @.str10, i64 0, i64 0
  %t76 = call i64 @mire_mem_process_bytes()
  %t77 = call ptr @mire_mem_format(i64 %t76)
  %t78 = call ptr @mire_string_concat(ptr %t75, ptr %t77)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t78)
  %t79 = getelementptr inbounds [5 x i8], ptr @.str11, i64 0, i64 0
  %t80 = load ptr, ptr %t41
  %t81 = call ptr @mire_string_concat(ptr %t79, ptr %t80)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t81)
  ret i32 0
}
