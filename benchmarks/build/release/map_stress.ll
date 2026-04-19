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
@.str0 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str1 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str2 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str3 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str4 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str5 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str6 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str7 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str8 = private unnamed_addr constant [7 x i8] c"alpha \00"
@.str9 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str10 = private unnamed_addr constant [6 x i8] c"beta \00"
@.str11 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str12 = private unnamed_addr constant [7 x i8] c"gamma \00"
@.str13 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str14 = private unnamed_addr constant [7 x i8] c"delta \00"
@.str15 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str16 = private unnamed_addr constant [7 x i8] c"total \00"
@.str17 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str18 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str19 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str20 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t12 = alloca ptr
  %t15 = alloca i64
  %t28 = alloca ptr
  %t31 = alloca i64
  %t44 = alloca ptr
  %t47 = alloca i64
  %t60 = alloca ptr
  %t63 = alloca i64
  %t75 = alloca i64
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
  %t8 = icmp slt i64 %t7, 12000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t9 = load i64, ptr %t6
  %t10 = urem i64 %t9, 4
  %t11 = icmp eq i64 %t10, 0
  br i1 %t11, label %if_then_3, label %if_else_4
if_then_3:
  %t13 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t14 = call ptr @mire_string_copy(ptr %t13)
  store ptr %t14, ptr %t12
  %t16 = load ptr, ptr %t4
  %t17 = load ptr, ptr %t12
  %t18 = call i64 @mire_dict_get_i64(ptr %t16, i64 3, i64 0, ptr %t17, i64 0)
  store i64 %t18, ptr %t15
  %t19 = load ptr, ptr %t4
  %t20 = load ptr, ptr %t12
  %t21 = load i64, ptr %t15
  %t22 = load i64, ptr %t6
  %t23 = add i64 %t21, %t22
  %t24 = call ptr @mire_dict_set_i64(ptr %t19, i64 3, i64 1, i64 0, ptr %t20, i64 %t23)
  store ptr %t24, ptr %t4
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t25 = load i64, ptr %t6
  %t26 = urem i64 %t25, 4
  %t27 = icmp eq i64 %t26, 1
  br i1 %t27, label %if_then_6, label %if_else_7
if_then_6:
  %t29 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t30 = call ptr @mire_string_copy(ptr %t29)
  store ptr %t30, ptr %t28
  %t32 = load ptr, ptr %t4
  %t33 = load ptr, ptr %t28
  %t34 = call i64 @mire_dict_get_i64(ptr %t32, i64 3, i64 0, ptr %t33, i64 0)
  store i64 %t34, ptr %t31
  %t35 = load ptr, ptr %t4
  %t36 = load ptr, ptr %t28
  %t37 = load i64, ptr %t31
  %t38 = load i64, ptr %t6
  %t39 = add i64 %t37, %t38
  %t40 = call ptr @mire_dict_set_i64(ptr %t35, i64 3, i64 1, i64 0, ptr %t36, i64 %t39)
  store ptr %t40, ptr %t4
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t41 = load i64, ptr %t6
  %t42 = urem i64 %t41, 4
  %t43 = icmp eq i64 %t42, 2
  br i1 %t43, label %if_then_9, label %if_else_10
if_then_9:
  %t45 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t46 = call ptr @mire_string_copy(ptr %t45)
  store ptr %t46, ptr %t44
  %t48 = load ptr, ptr %t4
  %t49 = load ptr, ptr %t44
  %t50 = call i64 @mire_dict_get_i64(ptr %t48, i64 3, i64 0, ptr %t49, i64 0)
  store i64 %t50, ptr %t47
  %t51 = load ptr, ptr %t4
  %t52 = load ptr, ptr %t44
  %t53 = load i64, ptr %t47
  %t54 = load i64, ptr %t6
  %t55 = add i64 %t53, %t54
  %t56 = call ptr @mire_dict_set_i64(ptr %t51, i64 3, i64 1, i64 0, ptr %t52, i64 %t55)
  store ptr %t56, ptr %t4
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t57 = load i64, ptr %t6
  %t58 = urem i64 %t57, 4
  %t59 = icmp eq i64 %t58, 3
  br i1 %t59, label %if_then_12, label %if_else_13
if_then_12:
  %t61 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t62 = call ptr @mire_string_copy(ptr %t61)
  store ptr %t62, ptr %t60
  %t64 = load ptr, ptr %t4
  %t65 = load ptr, ptr %t60
  %t66 = call i64 @mire_dict_get_i64(ptr %t64, i64 3, i64 0, ptr %t65, i64 0)
  store i64 %t66, ptr %t63
  %t67 = load ptr, ptr %t4
  %t68 = load ptr, ptr %t60
  %t69 = load i64, ptr %t63
  %t70 = load i64, ptr %t6
  %t71 = add i64 %t69, %t70
  %t72 = call ptr @mire_dict_set_i64(ptr %t67, i64 3, i64 1, i64 0, ptr %t68, i64 %t71)
  store ptr %t72, ptr %t4
  br label %if_end_14
if_else_13:
  br label %if_end_14
if_end_14:
  %t73 = load i64, ptr %t6
  %t74 = add i64 %t73, 1
  store i64 %t74, ptr %t6
  br label %while_cond_0
while_end_2:
  %t76 = load ptr, ptr %t4
  %t77 = getelementptr inbounds [6 x i8], ptr @.str4, i64 0, i64 0
  %t78 = call i64 @mire_dict_get_i64(ptr %t76, i64 3, i64 0, ptr %t77, i64 0)
  %t79 = load ptr, ptr %t4
  %t80 = getelementptr inbounds [5 x i8], ptr @.str5, i64 0, i64 0
  %t81 = call i64 @mire_dict_get_i64(ptr %t79, i64 3, i64 0, ptr %t80, i64 0)
  %t82 = add i64 %t78, %t81
  %t83 = load ptr, ptr %t4
  %t84 = getelementptr inbounds [6 x i8], ptr @.str6, i64 0, i64 0
  %t85 = call i64 @mire_dict_get_i64(ptr %t83, i64 3, i64 0, ptr %t84, i64 0)
  %t86 = add i64 %t82, %t85
  %t87 = load ptr, ptr %t4
  %t88 = getelementptr inbounds [6 x i8], ptr @.str7, i64 0, i64 0
  %t89 = call i64 @mire_dict_get_i64(ptr %t87, i64 3, i64 0, ptr %t88, i64 0)
  %t90 = add i64 %t86, %t89
  store i64 %t90, ptr %t75
  %t91 = getelementptr inbounds [7 x i8], ptr @.str8, i64 0, i64 0
  %t92 = load ptr, ptr %t4
  %t93 = getelementptr inbounds [6 x i8], ptr @.str9, i64 0, i64 0
  %t94 = call i64 @mire_dict_get_i64(ptr %t92, i64 3, i64 0, ptr %t93, i64 0)
  %t95 = call ptr @mire_i64_to_string(i64 %t94)
  %t96 = call ptr @concat(ptr %t91, ptr %t95)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t96)
  %t97 = getelementptr inbounds [6 x i8], ptr @.str10, i64 0, i64 0
  %t98 = load ptr, ptr %t4
  %t99 = getelementptr inbounds [5 x i8], ptr @.str11, i64 0, i64 0
  %t100 = call i64 @mire_dict_get_i64(ptr %t98, i64 3, i64 0, ptr %t99, i64 0)
  %t101 = call ptr @mire_i64_to_string(i64 %t100)
  %t102 = call ptr @concat(ptr %t97, ptr %t101)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t102)
  %t103 = getelementptr inbounds [7 x i8], ptr @.str12, i64 0, i64 0
  %t104 = load ptr, ptr %t4
  %t105 = getelementptr inbounds [6 x i8], ptr @.str13, i64 0, i64 0
  %t106 = call i64 @mire_dict_get_i64(ptr %t104, i64 3, i64 0, ptr %t105, i64 0)
  %t107 = call ptr @mire_i64_to_string(i64 %t106)
  %t108 = call ptr @concat(ptr %t103, ptr %t107)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t108)
  %t109 = getelementptr inbounds [7 x i8], ptr @.str14, i64 0, i64 0
  %t110 = load ptr, ptr %t4
  %t111 = getelementptr inbounds [6 x i8], ptr @.str15, i64 0, i64 0
  %t112 = call i64 @mire_dict_get_i64(ptr %t110, i64 3, i64 0, ptr %t111, i64 0)
  %t113 = call ptr @mire_i64_to_string(i64 %t112)
  %t114 = call ptr @concat(ptr %t109, ptr %t113)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t114)
  %t115 = getelementptr inbounds [7 x i8], ptr @.str16, i64 0, i64 0
  %t116 = load i64, ptr %t75
  %t117 = call ptr @mire_i64_to_string(i64 %t116)
  %t118 = call ptr @concat(ptr %t115, ptr %t117)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t118)
  %t119 = getelementptr inbounds [9 x i8], ptr @.str17, i64 0, i64 0
  %t120 = load i64, ptr %t0
  %t121 = call ptr @mire_wall_elapsed_ms_str(i64 %t120)
  %t122 = call ptr @concat(ptr %t119, ptr %t121)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t122)
  %t123 = getelementptr inbounds [8 x i8], ptr @.str18, i64 0, i64 0
  %t124 = load i64, ptr %t2
  %t125 = call ptr @mire_cpu_elapsed_ms_str(i64 %t124)
  %t126 = call ptr @concat(ptr %t123, ptr %t125)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t126)
  %t127 = getelementptr inbounds [16 x i8], ptr @.str19, i64 0, i64 0
  %t128 = load i64, ptr %t2
  %t129 = call i64 @mire_cpu_cycles_est(i64 %t128)
  %t130 = call ptr @mire_i64_to_string(i64 %t129)
  %t131 = call ptr @concat(ptr %t127, ptr %t130)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t131)
  %t132 = getelementptr inbounds [13 x i8], ptr @.str20, i64 0, i64 0
  %t133 = call i64 @mire_mem_process_bytes()
  %t134 = call ptr @mire_mem_format(i64 %t133)
  %t135 = call ptr @concat(ptr %t132, ptr %t134)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t135)
  ret i32 0
}
