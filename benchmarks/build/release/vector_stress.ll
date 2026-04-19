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
  %t15 = alloca i64
  %t17 = alloca i64
  %t18 = alloca i64
  %t31 = alloca i64
  %t37 = alloca i64
  %t43 = alloca i64
  %t60 = alloca i64
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
  %t8 = icmp slt i64 %t7, 15000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t9 = load ptr, ptr %t4
  %t10 = load i64, ptr %t6
  %t11 = mul i64 %t10, 3
  %t12 = call ptr @mire_list_push_i64(ptr %t9, i64 %t11)
  store ptr %t12, ptr %t4
  %t13 = load i64, ptr %t6
  %t14 = add i64 %t13, 1
  store i64 %t14, ptr %t6
  br label %while_cond_0
while_end_2:
  %t16 = load ptr, ptr %t4
  store i64 0, ptr %t17
  store i64 0, ptr %t18
  %t19 = icmp eq ptr %t16, null
  br i1 %t19, label %math_sum_null_3, label %math_sum_cond_4
math_sum_null_3:
  br label %math_sum_end_6
math_sum_cond_4:
  %t20 = load i64, ptr %t16
  %t21 = load i64, ptr %t18
  %t22 = icmp slt i64 %t21, %t20
  br i1 %t22, label %math_sum_body_5, label %math_sum_end_6
math_sum_body_5:
  %t23 = getelementptr i8, ptr %t16, i64 8
  %t24 = mul i64 %t21, 8
  %t25 = getelementptr i8, ptr %t23, i64 %t24
  %t26 = load i64, ptr %t25
  %t27 = load i64, ptr %t17
  %t28 = add i64 %t27, %t26
  store i64 %t28, ptr %t17
  %t29 = add i64 %t21, 1
  store i64 %t29, ptr %t18
  br label %math_sum_cond_4
math_sum_end_6:
  %t30 = load i64, ptr %t17
  store i64 %t30, ptr %t15
  %t32 = load ptr, ptr %t4
  %t33 = bitcast ptr %t32 to ptr
  %t34 = mul i64 0, 8
  %t35 = getelementptr inbounds i8, ptr %t33, i64 %t34
  %t36 = load i64, ptr %t35
  store i64 %t36, ptr %t31
  %t38 = load ptr, ptr %t4
  %t39 = bitcast ptr %t38 to ptr
  %t40 = mul i64 7500, 8
  %t41 = getelementptr inbounds i8, ptr %t39, i64 %t40
  %t42 = load i64, ptr %t41
  store i64 %t42, ptr %t37
  %t44 = load ptr, ptr %t4
  %t45 = bitcast ptr %t44 to ptr
  %t46 = mul i64 14999, 8
  %t47 = getelementptr inbounds i8, ptr %t45, i64 %t46
  %t48 = load i64, ptr %t47
  store i64 %t48, ptr %t43
  %t49 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t50 = load i64, ptr %t15
  %t51 = call ptr @mire_i64_to_string(i64 %t50)
  %t52 = call ptr @mire_string_concat(ptr %t49, ptr %t51)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t52)
  %t53 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t54 = load ptr, ptr %t4
  %t55 = load ptr, ptr %t4
  %t56 = getelementptr inbounds i8, ptr %t55, i64 -8
  %t57 = icmp eq ptr %t56, null
  br i1 %t57, label %list_len_null_7, label %list_len_load_8
list_len_null_7:
  store i64 0, ptr %t60
  br label %list_len_end_9
list_len_load_8:
  %t58 = load i64, ptr %t56
  store i64 %t58, ptr %t60
  br label %list_len_end_9
list_len_end_9:
  %t59 = load i64, ptr %t60
  %t61 = call ptr @mire_i64_to_string(i64 %t59)
  %t62 = call ptr @mire_string_concat(ptr %t53, ptr %t61)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t62)
  %t63 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t64 = load i64, ptr %t31
  %t65 = call ptr @mire_i64_to_string(i64 %t64)
  %t66 = call ptr @mire_string_concat(ptr %t63, ptr %t65)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t66)
  %t67 = getelementptr inbounds [5 x i8], ptr @.str3, i64 0, i64 0
  %t68 = load i64, ptr %t37
  %t69 = call ptr @mire_i64_to_string(i64 %t68)
  %t70 = call ptr @mire_string_concat(ptr %t67, ptr %t69)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t70)
  %t71 = getelementptr inbounds [6 x i8], ptr @.str4, i64 0, i64 0
  %t72 = load i64, ptr %t43
  %t73 = call ptr @mire_i64_to_string(i64 %t72)
  %t74 = call ptr @mire_string_concat(ptr %t71, ptr %t73)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t74)
  %t75 = getelementptr inbounds [9 x i8], ptr @.str5, i64 0, i64 0
  %t76 = load i64, ptr %t0
  %t77 = call ptr @mire_wall_elapsed_ms_str(i64 %t76)
  %t78 = call ptr @mire_string_concat(ptr %t75, ptr %t77)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t78)
  %t79 = getelementptr inbounds [8 x i8], ptr @.str6, i64 0, i64 0
  %t80 = load i64, ptr %t2
  %t81 = call ptr @mire_cpu_elapsed_ms_str(i64 %t80)
  %t82 = call ptr @mire_string_concat(ptr %t79, ptr %t81)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t82)
  %t83 = getelementptr inbounds [16 x i8], ptr @.str7, i64 0, i64 0
  %t84 = load i64, ptr %t2
  %t85 = call i64 @mire_cpu_cycles_est(i64 %t84)
  %t86 = call ptr @mire_i64_to_string(i64 %t85)
  %t87 = call ptr @mire_string_concat(ptr %t83, ptr %t86)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t87)
  %t88 = getelementptr inbounds [13 x i8], ptr @.str8, i64 0, i64 0
  %t89 = call i64 @mire_mem_process_bytes()
  %t90 = call ptr @mire_mem_format(i64 %t89)
  %t91 = call ptr @mire_string_concat(ptr %t88, ptr %t90)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t91)
  ret i32 0
}
