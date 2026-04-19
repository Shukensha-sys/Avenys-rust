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
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [5 x i8] c"mid \00"
@.str4 = private unnamed_addr constant [6 x i8] c"last \00"
@.str5 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str6 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str7 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str8 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t14 = alloca i64
  %t16 = alloca i64
  %t17 = alloca i64
  %t31 = alloca i64
  %t38 = alloca i64
  %t45 = alloca i64
  %t63 = alloca i64
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
  %t9 = load ptr, ptr %t4
  %t10 = load i64, ptr %t6
  %t11 = call ptr @mire_list_push_scalar(ptr %t9, i64 %t10, i64 4)
  store ptr %t11, ptr %t4
  %t12 = load i64, ptr %t6
  %t13 = add i64 %t12, 1
  store i64 %t13, ptr %t6
  br label %while_cond_0
while_end_2:
  %t15 = load ptr, ptr %t4
  store i64 0, ptr %t16
  store i64 0, ptr %t17
  %t18 = icmp eq ptr %t15, null
  br i1 %t18, label %math_sum_null_3, label %math_sum_cond_4
math_sum_null_3:
  br label %math_sum_end_6
math_sum_cond_4:
  %t19 = load i64, ptr %t15
  %t20 = load i64, ptr %t17
  %t21 = icmp slt i64 %t20, %t19
  br i1 %t21, label %math_sum_body_5, label %math_sum_end_6
math_sum_body_5:
  %t22 = getelementptr i8, ptr %t15, i64 8
  %t23 = mul i64 %t20, 4
  %t24 = getelementptr i8, ptr %t22, i64 %t23
  %t29 = load i32, ptr %t24
  %t25 = sext i32 %t29 to i64
  %t26 = load i64, ptr %t16
  %t27 = add i64 %t26, %t25
  store i64 %t27, ptr %t16
  %t28 = add i64 %t20, 1
  store i64 %t28, ptr %t17
  br label %math_sum_cond_4
math_sum_end_6:
  %t30 = load i64, ptr %t16
  store i64 %t30, ptr %t14
  %t32 = load ptr, ptr %t4
  %t33 = bitcast ptr %t32 to ptr
  %t34 = mul i64 0, 4
  %t35 = getelementptr inbounds i8, ptr %t33, i64 %t34
  %t36 = load i32, ptr %t35
  %t37 = sext i32 %t36 to i64
  store i64 %t37, ptr %t31
  %t39 = load ptr, ptr %t4
  %t40 = bitcast ptr %t39 to ptr
  %t41 = mul i64 15000, 4
  %t42 = getelementptr inbounds i8, ptr %t40, i64 %t41
  %t43 = load i32, ptr %t42
  %t44 = sext i32 %t43 to i64
  store i64 %t44, ptr %t38
  %t46 = load ptr, ptr %t4
  %t47 = bitcast ptr %t46 to ptr
  %t48 = mul i64 29999, 4
  %t49 = getelementptr inbounds i8, ptr %t47, i64 %t48
  %t50 = load i32, ptr %t49
  %t51 = sext i32 %t50 to i64
  store i64 %t51, ptr %t45
  %t52 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t53 = load i64, ptr %t14
  %t54 = call ptr @mire_i64_to_string(i64 %t53)
  %t55 = call ptr @mire_string_concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t57 = load ptr, ptr %t4
  %t58 = load ptr, ptr %t4
  %t59 = getelementptr inbounds i8, ptr %t58, i64 -8
  %t60 = icmp eq ptr %t59, null
  br i1 %t60, label %list_len_null_7, label %list_len_load_8
list_len_null_7:
  store i64 0, ptr %t63
  br label %list_len_end_9
list_len_load_8:
  %t61 = load i64, ptr %t59
  store i64 %t61, ptr %t63
  br label %list_len_end_9
list_len_end_9:
  %t62 = load i64, ptr %t63
  %t64 = call ptr @mire_i64_to_string(i64 %t62)
  %t65 = call ptr @mire_string_concat(ptr %t56, ptr %t64)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t65)
  %t66 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t67 = load i64, ptr %t31
  %t68 = call ptr @mire_i64_to_string(i64 %t67)
  %t69 = call ptr @mire_string_concat(ptr %t66, ptr %t68)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t69)
  %t70 = getelementptr inbounds [5 x i8], ptr @.str3, i64 0, i64 0
  %t71 = load i64, ptr %t38
  %t72 = call ptr @mire_i64_to_string(i64 %t71)
  %t73 = call ptr @mire_string_concat(ptr %t70, ptr %t72)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t73)
  %t74 = getelementptr inbounds [6 x i8], ptr @.str4, i64 0, i64 0
  %t75 = load i64, ptr %t45
  %t76 = call ptr @mire_i64_to_string(i64 %t75)
  %t77 = call ptr @mire_string_concat(ptr %t74, ptr %t76)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t77)
  %t78 = getelementptr inbounds [9 x i8], ptr @.str5, i64 0, i64 0
  %t79 = load i64, ptr %t0
  %t80 = call ptr @mire_wall_elapsed_ms_str(i64 %t79)
  %t81 = call ptr @mire_string_concat(ptr %t78, ptr %t80)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t81)
  %t82 = getelementptr inbounds [8 x i8], ptr @.str6, i64 0, i64 0
  %t83 = load i64, ptr %t2
  %t84 = call ptr @mire_cpu_elapsed_ms_str(i64 %t83)
  %t85 = call ptr @mire_string_concat(ptr %t82, ptr %t84)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t85)
  %t86 = getelementptr inbounds [16 x i8], ptr @.str7, i64 0, i64 0
  %t87 = load i64, ptr %t2
  %t88 = call i64 @mire_cpu_cycles_est(i64 %t87)
  %t89 = call ptr @mire_i64_to_string(i64 %t88)
  %t90 = call ptr @mire_string_concat(ptr %t86, ptr %t89)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t90)
  %t91 = getelementptr inbounds [13 x i8], ptr @.str8, i64 0, i64 0
  %t92 = call i64 @mire_mem_process_bytes()
  %t93 = call ptr @mire_mem_format(i64 %t92)
  %t94 = call ptr @mire_string_concat(ptr %t91, ptr %t93)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t94)
  ret i32 0
}
