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
@.str0 = private unnamed_addr constant [4 x i8] c"k00\00"
@.str1 = private unnamed_addr constant [4 x i8] c"k01\00"
@.str2 = private unnamed_addr constant [4 x i8] c"k02\00"
@.str3 = private unnamed_addr constant [4 x i8] c"k03\00"
@.str4 = private unnamed_addr constant [4 x i8] c"k04\00"
@.str5 = private unnamed_addr constant [4 x i8] c"k05\00"
@.str6 = private unnamed_addr constant [4 x i8] c"k06\00"
@.str7 = private unnamed_addr constant [4 x i8] c"k07\00"
@.str8 = private unnamed_addr constant [4 x i8] c"k08\00"
@.str9 = private unnamed_addr constant [4 x i8] c"k09\00"
@.str10 = private unnamed_addr constant [4 x i8] c"k10\00"
@.str11 = private unnamed_addr constant [4 x i8] c"k11\00"
@.str12 = private unnamed_addr constant [4 x i8] c"k12\00"
@.str13 = private unnamed_addr constant [4 x i8] c"k13\00"
@.str14 = private unnamed_addr constant [4 x i8] c"k14\00"
@.str15 = private unnamed_addr constant [4 x i8] c"k15\00"
@.str16 = private unnamed_addr constant [4 x i8] c"k00\00"
@.str17 = private unnamed_addr constant [4 x i8] c"k01\00"
@.str18 = private unnamed_addr constant [4 x i8] c"k02\00"
@.str19 = private unnamed_addr constant [4 x i8] c"k03\00"
@.str20 = private unnamed_addr constant [4 x i8] c"k04\00"
@.str21 = private unnamed_addr constant [4 x i8] c"k05\00"
@.str22 = private unnamed_addr constant [4 x i8] c"k06\00"
@.str23 = private unnamed_addr constant [4 x i8] c"k07\00"
@.str24 = private unnamed_addr constant [4 x i8] c"k08\00"
@.str25 = private unnamed_addr constant [4 x i8] c"k09\00"
@.str26 = private unnamed_addr constant [4 x i8] c"k10\00"
@.str27 = private unnamed_addr constant [4 x i8] c"k11\00"
@.str28 = private unnamed_addr constant [4 x i8] c"k12\00"
@.str29 = private unnamed_addr constant [4 x i8] c"k13\00"
@.str30 = private unnamed_addr constant [4 x i8] c"k14\00"
@.str31 = private unnamed_addr constant [4 x i8] c"k15\00"
@.str32 = private unnamed_addr constant [7 x i8] c"total \00"
@.str33 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str34 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str35 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str36 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t54 = alloca i64
  %t55 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [4 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_dict_set_i64(ptr %t6, i64 3, i64 1, i64 0, ptr %t7, i64 1)
  store ptr %t8, ptr %t4
  %t9 = load ptr, ptr %t4
  %t10 = getelementptr inbounds [4 x i8], ptr @.str1, i64 0, i64 0
  %t11 = call ptr @mire_dict_set_i64(ptr %t9, i64 3, i64 1, i64 0, ptr %t10, i64 2)
  store ptr %t11, ptr %t4
  %t12 = load ptr, ptr %t4
  %t13 = getelementptr inbounds [4 x i8], ptr @.str2, i64 0, i64 0
  %t14 = call ptr @mire_dict_set_i64(ptr %t12, i64 3, i64 1, i64 0, ptr %t13, i64 3)
  store ptr %t14, ptr %t4
  %t15 = load ptr, ptr %t4
  %t16 = getelementptr inbounds [4 x i8], ptr @.str3, i64 0, i64 0
  %t17 = call ptr @mire_dict_set_i64(ptr %t15, i64 3, i64 1, i64 0, ptr %t16, i64 4)
  store ptr %t17, ptr %t4
  %t18 = load ptr, ptr %t4
  %t19 = getelementptr inbounds [4 x i8], ptr @.str4, i64 0, i64 0
  %t20 = call ptr @mire_dict_set_i64(ptr %t18, i64 3, i64 1, i64 0, ptr %t19, i64 5)
  store ptr %t20, ptr %t4
  %t21 = load ptr, ptr %t4
  %t22 = getelementptr inbounds [4 x i8], ptr @.str5, i64 0, i64 0
  %t23 = call ptr @mire_dict_set_i64(ptr %t21, i64 3, i64 1, i64 0, ptr %t22, i64 6)
  store ptr %t23, ptr %t4
  %t24 = load ptr, ptr %t4
  %t25 = getelementptr inbounds [4 x i8], ptr @.str6, i64 0, i64 0
  %t26 = call ptr @mire_dict_set_i64(ptr %t24, i64 3, i64 1, i64 0, ptr %t25, i64 7)
  store ptr %t26, ptr %t4
  %t27 = load ptr, ptr %t4
  %t28 = getelementptr inbounds [4 x i8], ptr @.str7, i64 0, i64 0
  %t29 = call ptr @mire_dict_set_i64(ptr %t27, i64 3, i64 1, i64 0, ptr %t28, i64 8)
  store ptr %t29, ptr %t4
  %t30 = load ptr, ptr %t4
  %t31 = getelementptr inbounds [4 x i8], ptr @.str8, i64 0, i64 0
  %t32 = call ptr @mire_dict_set_i64(ptr %t30, i64 3, i64 1, i64 0, ptr %t31, i64 9)
  store ptr %t32, ptr %t4
  %t33 = load ptr, ptr %t4
  %t34 = getelementptr inbounds [4 x i8], ptr @.str9, i64 0, i64 0
  %t35 = call ptr @mire_dict_set_i64(ptr %t33, i64 3, i64 1, i64 0, ptr %t34, i64 10)
  store ptr %t35, ptr %t4
  %t36 = load ptr, ptr %t4
  %t37 = getelementptr inbounds [4 x i8], ptr @.str10, i64 0, i64 0
  %t38 = call ptr @mire_dict_set_i64(ptr %t36, i64 3, i64 1, i64 0, ptr %t37, i64 11)
  store ptr %t38, ptr %t4
  %t39 = load ptr, ptr %t4
  %t40 = getelementptr inbounds [4 x i8], ptr @.str11, i64 0, i64 0
  %t41 = call ptr @mire_dict_set_i64(ptr %t39, i64 3, i64 1, i64 0, ptr %t40, i64 12)
  store ptr %t41, ptr %t4
  %t42 = load ptr, ptr %t4
  %t43 = getelementptr inbounds [4 x i8], ptr @.str12, i64 0, i64 0
  %t44 = call ptr @mire_dict_set_i64(ptr %t42, i64 3, i64 1, i64 0, ptr %t43, i64 13)
  store ptr %t44, ptr %t4
  %t45 = load ptr, ptr %t4
  %t46 = getelementptr inbounds [4 x i8], ptr @.str13, i64 0, i64 0
  %t47 = call ptr @mire_dict_set_i64(ptr %t45, i64 3, i64 1, i64 0, ptr %t46, i64 14)
  store ptr %t47, ptr %t4
  %t48 = load ptr, ptr %t4
  %t49 = getelementptr inbounds [4 x i8], ptr @.str14, i64 0, i64 0
  %t50 = call ptr @mire_dict_set_i64(ptr %t48, i64 3, i64 1, i64 0, ptr %t49, i64 15)
  store ptr %t50, ptr %t4
  %t51 = load ptr, ptr %t4
  %t52 = getelementptr inbounds [4 x i8], ptr @.str15, i64 0, i64 0
  %t53 = call ptr @mire_dict_set_i64(ptr %t51, i64 3, i64 1, i64 0, ptr %t52, i64 16)
  store ptr %t53, ptr %t4
  store i64 0, ptr %t54
  store i64 0, ptr %t55
  br label %while_cond_0
while_cond_0:
  %t56 = load i64, ptr %t54
  %t57 = icmp slt i64 %t56, 20000
  br i1 %t57, label %while_body_1, label %while_end_2
while_body_1:
  %t58 = load i64, ptr %t55
  %t59 = load ptr, ptr %t4
  %t60 = getelementptr inbounds [4 x i8], ptr @.str16, i64 0, i64 0
  %t61 = call i64 @mire_dict_get_i64(ptr %t59, i64 3, i64 0, ptr %t60, i64 0)
  %t62 = add i64 %t58, %t61
  store i64 %t62, ptr %t55
  %t63 = load i64, ptr %t55
  %t64 = load ptr, ptr %t4
  %t65 = getelementptr inbounds [4 x i8], ptr @.str17, i64 0, i64 0
  %t66 = call i64 @mire_dict_get_i64(ptr %t64, i64 3, i64 0, ptr %t65, i64 0)
  %t67 = add i64 %t63, %t66
  store i64 %t67, ptr %t55
  %t68 = load i64, ptr %t55
  %t69 = load ptr, ptr %t4
  %t70 = getelementptr inbounds [4 x i8], ptr @.str18, i64 0, i64 0
  %t71 = call i64 @mire_dict_get_i64(ptr %t69, i64 3, i64 0, ptr %t70, i64 0)
  %t72 = add i64 %t68, %t71
  store i64 %t72, ptr %t55
  %t73 = load i64, ptr %t55
  %t74 = load ptr, ptr %t4
  %t75 = getelementptr inbounds [4 x i8], ptr @.str19, i64 0, i64 0
  %t76 = call i64 @mire_dict_get_i64(ptr %t74, i64 3, i64 0, ptr %t75, i64 0)
  %t77 = add i64 %t73, %t76
  store i64 %t77, ptr %t55
  %t78 = load i64, ptr %t55
  %t79 = load ptr, ptr %t4
  %t80 = getelementptr inbounds [4 x i8], ptr @.str20, i64 0, i64 0
  %t81 = call i64 @mire_dict_get_i64(ptr %t79, i64 3, i64 0, ptr %t80, i64 0)
  %t82 = add i64 %t78, %t81
  store i64 %t82, ptr %t55
  %t83 = load i64, ptr %t55
  %t84 = load ptr, ptr %t4
  %t85 = getelementptr inbounds [4 x i8], ptr @.str21, i64 0, i64 0
  %t86 = call i64 @mire_dict_get_i64(ptr %t84, i64 3, i64 0, ptr %t85, i64 0)
  %t87 = add i64 %t83, %t86
  store i64 %t87, ptr %t55
  %t88 = load i64, ptr %t55
  %t89 = load ptr, ptr %t4
  %t90 = getelementptr inbounds [4 x i8], ptr @.str22, i64 0, i64 0
  %t91 = call i64 @mire_dict_get_i64(ptr %t89, i64 3, i64 0, ptr %t90, i64 0)
  %t92 = add i64 %t88, %t91
  store i64 %t92, ptr %t55
  %t93 = load i64, ptr %t55
  %t94 = load ptr, ptr %t4
  %t95 = getelementptr inbounds [4 x i8], ptr @.str23, i64 0, i64 0
  %t96 = call i64 @mire_dict_get_i64(ptr %t94, i64 3, i64 0, ptr %t95, i64 0)
  %t97 = add i64 %t93, %t96
  store i64 %t97, ptr %t55
  %t98 = load i64, ptr %t55
  %t99 = load ptr, ptr %t4
  %t100 = getelementptr inbounds [4 x i8], ptr @.str24, i64 0, i64 0
  %t101 = call i64 @mire_dict_get_i64(ptr %t99, i64 3, i64 0, ptr %t100, i64 0)
  %t102 = add i64 %t98, %t101
  store i64 %t102, ptr %t55
  %t103 = load i64, ptr %t55
  %t104 = load ptr, ptr %t4
  %t105 = getelementptr inbounds [4 x i8], ptr @.str25, i64 0, i64 0
  %t106 = call i64 @mire_dict_get_i64(ptr %t104, i64 3, i64 0, ptr %t105, i64 0)
  %t107 = add i64 %t103, %t106
  store i64 %t107, ptr %t55
  %t108 = load i64, ptr %t55
  %t109 = load ptr, ptr %t4
  %t110 = getelementptr inbounds [4 x i8], ptr @.str26, i64 0, i64 0
  %t111 = call i64 @mire_dict_get_i64(ptr %t109, i64 3, i64 0, ptr %t110, i64 0)
  %t112 = add i64 %t108, %t111
  store i64 %t112, ptr %t55
  %t113 = load i64, ptr %t55
  %t114 = load ptr, ptr %t4
  %t115 = getelementptr inbounds [4 x i8], ptr @.str27, i64 0, i64 0
  %t116 = call i64 @mire_dict_get_i64(ptr %t114, i64 3, i64 0, ptr %t115, i64 0)
  %t117 = add i64 %t113, %t116
  store i64 %t117, ptr %t55
  %t118 = load i64, ptr %t55
  %t119 = load ptr, ptr %t4
  %t120 = getelementptr inbounds [4 x i8], ptr @.str28, i64 0, i64 0
  %t121 = call i64 @mire_dict_get_i64(ptr %t119, i64 3, i64 0, ptr %t120, i64 0)
  %t122 = add i64 %t118, %t121
  store i64 %t122, ptr %t55
  %t123 = load i64, ptr %t55
  %t124 = load ptr, ptr %t4
  %t125 = getelementptr inbounds [4 x i8], ptr @.str29, i64 0, i64 0
  %t126 = call i64 @mire_dict_get_i64(ptr %t124, i64 3, i64 0, ptr %t125, i64 0)
  %t127 = add i64 %t123, %t126
  store i64 %t127, ptr %t55
  %t128 = load i64, ptr %t55
  %t129 = load ptr, ptr %t4
  %t130 = getelementptr inbounds [4 x i8], ptr @.str30, i64 0, i64 0
  %t131 = call i64 @mire_dict_get_i64(ptr %t129, i64 3, i64 0, ptr %t130, i64 0)
  %t132 = add i64 %t128, %t131
  store i64 %t132, ptr %t55
  %t133 = load i64, ptr %t55
  %t134 = load ptr, ptr %t4
  %t135 = getelementptr inbounds [4 x i8], ptr @.str31, i64 0, i64 0
  %t136 = call i64 @mire_dict_get_i64(ptr %t134, i64 3, i64 0, ptr %t135, i64 0)
  %t137 = add i64 %t133, %t136
  store i64 %t137, ptr %t55
  %t138 = load i64, ptr %t54
  %t139 = add i64 %t138, 1
  store i64 %t139, ptr %t54
  br label %while_cond_0
while_end_2:
  %t140 = getelementptr inbounds [7 x i8], ptr @.str32, i64 0, i64 0
  %t141 = load i64, ptr %t55
  %t142 = call ptr @mire_i64_to_string(i64 %t141)
  %t143 = call ptr @concat(ptr %t140, ptr %t142)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t143)
  %t144 = getelementptr inbounds [9 x i8], ptr @.str33, i64 0, i64 0
  %t145 = load i64, ptr %t0
  %t146 = call ptr @mire_wall_elapsed_ms_str(i64 %t145)
  %t147 = call ptr @concat(ptr %t144, ptr %t146)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t147)
  %t148 = getelementptr inbounds [8 x i8], ptr @.str34, i64 0, i64 0
  %t149 = load i64, ptr %t2
  %t150 = call ptr @mire_cpu_elapsed_ms_str(i64 %t149)
  %t151 = call ptr @concat(ptr %t148, ptr %t150)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t151)
  %t152 = getelementptr inbounds [16 x i8], ptr @.str35, i64 0, i64 0
  %t153 = load i64, ptr %t2
  %t154 = call i64 @mire_cpu_cycles_est(i64 %t153)
  %t155 = call ptr @mire_i64_to_string(i64 %t154)
  %t156 = call ptr @concat(ptr %t152, ptr %t155)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t156)
  %t157 = getelementptr inbounds [13 x i8], ptr @.str36, i64 0, i64 0
  %t158 = call i64 @mire_mem_process_bytes()
  %t159 = call ptr @mire_mem_format(i64 %t158)
  %t160 = call ptr @concat(ptr %t157, ptr %t159)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t160)
  ret i32 0
}
