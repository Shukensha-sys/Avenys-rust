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
@.str0 = private unnamed_addr constant [1 x i8] c"\00"
@.str1 = private unnamed_addr constant [5 x i8] c"n0de\00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [11 x i8] c"sum_check \00"
@.str4 = private unnamed_addr constant [7 x i8] c"items \00"
@.str5 = private unnamed_addr constant [11 x i8] c"trace_len \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str9 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str10 = private unnamed_addr constant [5 x i8] c"gpu \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca ptr
  %t9 = alloca i64
  %t10 = alloca i64
  %t13 = alloca i64
  %t14 = alloca i64
  %t17 = alloca i64
  %t54 = alloca ptr
  %t62 = alloca i64
  %t64 = alloca i64
  %t65 = alloca i64
  %t93 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t7 = getelementptr inbounds [1 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_string_copy(ptr %t7)
  store ptr %t8, ptr %t6
  store i64 0, ptr %t9
  store i64 0, ptr %t10
  br label %while_cond_0
while_cond_0:
  %t11 = load i64, ptr %t9
  %t12 = icmp slt i64 %t11, 3000
  br i1 %t12, label %while_body_1, label %while_end_2
while_body_1:
  store i64 0, ptr %t13
  store i64 0, ptr %t14
  br label %while_cond_3
while_cond_3:
  %t15 = load i64, ptr %t13
  %t16 = icmp slt i64 %t15, 32
  br i1 %t16, label %while_body_4, label %while_end_5
while_body_4:
  %t18 = load i64, ptr %t9
  %t19 = mul i64 %t18, 3
  %t20 = load i64, ptr %t13
  %t21 = mul i64 %t20, 7
  %t22 = add i64 %t19, %t21
  %t23 = urem i64 %t22, 11
  store i64 %t23, ptr %t17
  %t24 = load i64, ptr %t17
  %t25 = urem i64 %t24, 2
  %t26 = icmp eq i64 %t25, 0
  br i1 %t26, label %if_then_6, label %if_else_7
if_then_6:
  %t27 = load i64, ptr %t14
  %t28 = load i64, ptr %t17
  %t29 = load i64, ptr %t9
  %t30 = add i64 %t28, %t29
  %t31 = add i64 %t27, %t30
  store i64 %t31, ptr %t14
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t32 = load i64, ptr %t17
  %t33 = urem i64 %t32, 3
  %t34 = icmp eq i64 %t33, 0
  br i1 %t34, label %if_then_9, label %if_else_10
if_then_9:
  %t35 = load i64, ptr %t14
  %t36 = load i64, ptr %t13
  %t37 = add i64 %t35, %t36
  store i64 %t37, ptr %t14
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t38 = load i64, ptr %t17
  %t39 = urem i64 %t38, 5
  %t40 = icmp eq i64 %t39, 0
  br i1 %t40, label %if_then_12, label %if_else_13
if_then_12:
  %t41 = load i64, ptr %t14
  %t42 = sub i64 %t41, 1
  store i64 %t42, ptr %t14
  br label %if_end_14
if_else_13:
  br label %if_end_14
if_end_14:
  %t43 = load i64, ptr %t13
  %t44 = add i64 %t43, 1
  store i64 %t44, ptr %t13
  br label %while_cond_3
while_end_5:
  %t45 = load ptr, ptr %t4
  %t46 = load i64, ptr %t14
  %t47 = call ptr @mire_list_push_i64(ptr %t45, i64 %t46)
  store ptr %t47, ptr %t4
  %t48 = load i64, ptr %t10
  %t49 = load i64, ptr %t14
  %t50 = add i64 %t48, %t49
  store i64 %t50, ptr %t10
  %t51 = load i64, ptr %t9
  %t52 = urem i64 %t51, 250
  %t53 = icmp eq i64 %t52, 0
  br i1 %t53, label %if_then_15, label %if_else_16
if_then_15:
  %t55 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t56 = call ptr @mire_string_copy(ptr %t55)
  store ptr %t56, ptr %t54
  %t57 = load ptr, ptr %t54
  %t58 = load ptr, ptr %t6
  %t59 = call ptr @mire_string_append_owned(ptr %t58, ptr %t57)
  store ptr %t59, ptr %t6
  br label %if_end_17
if_else_16:
  br label %if_end_17
if_end_17:
  %t60 = load i64, ptr %t9
  %t61 = add i64 %t60, 1
  store i64 %t61, ptr %t9
  br label %while_cond_0
while_end_2:
  %t63 = load ptr, ptr %t4
  store i64 0, ptr %t64
  store i64 0, ptr %t65
  %t66 = icmp eq ptr %t63, null
  br i1 %t66, label %math_sum_null_18, label %math_sum_cond_19
math_sum_null_18:
  br label %math_sum_end_21
math_sum_cond_19:
  %t67 = load i64, ptr %t63
  %t68 = load i64, ptr %t65
  %t69 = icmp slt i64 %t68, %t67
  br i1 %t69, label %math_sum_body_20, label %math_sum_end_21
math_sum_body_20:
  %t70 = getelementptr i8, ptr %t63, i64 8
  %t71 = mul i64 %t68, 8
  %t72 = getelementptr i8, ptr %t70, i64 %t71
  %t73 = load i64, ptr %t72
  %t74 = load i64, ptr %t64
  %t75 = add i64 %t74, %t73
  store i64 %t75, ptr %t64
  %t76 = add i64 %t68, 1
  store i64 %t76, ptr %t65
  br label %math_sum_cond_19
math_sum_end_21:
  %t77 = load i64, ptr %t64
  store i64 %t77, ptr %t62
  %t78 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t79 = load i64, ptr %t10
  %t80 = call ptr @mire_i64_to_string(i64 %t79)
  %t81 = call ptr @mire_string_concat(ptr %t78, ptr %t80)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t81)
  %t82 = getelementptr inbounds [11 x i8], ptr @.str3, i64 0, i64 0
  %t83 = load i64, ptr %t62
  %t84 = call ptr @mire_i64_to_string(i64 %t83)
  %t85 = call ptr @mire_string_concat(ptr %t82, ptr %t84)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t85)
  %t86 = getelementptr inbounds [7 x i8], ptr @.str4, i64 0, i64 0
  %t87 = load ptr, ptr %t4
  %t88 = load ptr, ptr %t4
  %t89 = getelementptr inbounds i8, ptr %t88, i64 -8
  %t90 = icmp eq ptr %t89, null
  br i1 %t90, label %list_len_null_22, label %list_len_load_23
list_len_null_22:
  store i64 0, ptr %t93
  br label %list_len_end_24
list_len_load_23:
  %t91 = load i64, ptr %t89
  store i64 %t91, ptr %t93
  br label %list_len_end_24
list_len_end_24:
  %t92 = load i64, ptr %t93
  %t94 = call ptr @mire_i64_to_string(i64 %t92)
  %t95 = call ptr @mire_string_concat(ptr %t86, ptr %t94)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t95)
  %t96 = getelementptr inbounds [11 x i8], ptr @.str5, i64 0, i64 0
  %t97 = load ptr, ptr %t6
  %t98 = call i64 @strlen(ptr %t97)
  %t99 = call ptr @mire_i64_to_string(i64 %t98)
  %t100 = call ptr @mire_string_concat(ptr %t96, ptr %t99)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t100)
  %t101 = getelementptr inbounds [9 x i8], ptr @.str6, i64 0, i64 0
  %t102 = load i64, ptr %t0
  %t103 = call ptr @mire_wall_elapsed_ms_str(i64 %t102)
  %t104 = call ptr @mire_string_concat(ptr %t101, ptr %t103)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t104)
  %t105 = getelementptr inbounds [8 x i8], ptr @.str7, i64 0, i64 0
  %t106 = load i64, ptr %t2
  %t107 = call ptr @mire_cpu_elapsed_ms_str(i64 %t106)
  %t108 = call ptr @mire_string_concat(ptr %t105, ptr %t107)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t108)
  %t109 = getelementptr inbounds [16 x i8], ptr @.str8, i64 0, i64 0
  %t110 = load i64, ptr %t2
  %t111 = call i64 @mire_cpu_cycles_est(i64 %t110)
  %t112 = call ptr @mire_i64_to_string(i64 %t111)
  %t113 = call ptr @mire_string_concat(ptr %t109, ptr %t112)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t113)
  %t114 = getelementptr inbounds [13 x i8], ptr @.str9, i64 0, i64 0
  %t115 = call i64 @mire_mem_process_bytes()
  %t116 = call ptr @mire_mem_format(i64 %t115)
  %t117 = call ptr @mire_string_concat(ptr %t114, ptr %t116)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t117)
  %t118 = getelementptr inbounds [5 x i8], ptr @.str10, i64 0, i64 0
  %t119 = call ptr @mire_gpu_snapshot()
  %t120 = call ptr @mire_string_concat(ptr %t118, ptr %t119)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t120)
  ret i32 0
}
