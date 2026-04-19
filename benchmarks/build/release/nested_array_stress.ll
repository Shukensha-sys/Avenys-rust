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
@.str0 = private unnamed_addr constant [6 x i8] c"rows \00"
@.str1 = private unnamed_addr constant [6 x i8] c"cols \00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str6 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str7 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t11 = alloca ptr
  %t18 = alloca ptr
  %t25 = alloca ptr
  %t34 = alloca i64
  %t40 = alloca i64
  %t41 = alloca ptr
  %t47 = alloca ptr
  %t53 = alloca ptr
  %t59 = alloca i64
  %t65 = alloca i64
  %t66 = alloca i64
  %t151 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = call i8* @malloc(i64 48)
  store i64 4, ptr %t5
  %t6 = getelementptr i8, ptr %t5, i64 8
  store i64 4, ptr %t6
  %t7 = getelementptr i8, ptr %t6, i64 8
  store i64 1, ptr %t7
  %t8 = getelementptr i8, ptr %t6, i64 16
  store i64 2, ptr %t8
  %t9 = getelementptr i8, ptr %t6, i64 24
  store i64 3, ptr %t9
  %t10 = getelementptr i8, ptr %t6, i64 32
  store i64 4, ptr %t10
  store ptr %t6, ptr %t4
  %t12 = call i8* @malloc(i64 48)
  store i64 4, ptr %t12
  %t13 = getelementptr i8, ptr %t12, i64 8
  store i64 4, ptr %t13
  %t14 = getelementptr i8, ptr %t13, i64 8
  store i64 5, ptr %t14
  %t15 = getelementptr i8, ptr %t13, i64 16
  store i64 6, ptr %t15
  %t16 = getelementptr i8, ptr %t13, i64 24
  store i64 7, ptr %t16
  %t17 = getelementptr i8, ptr %t13, i64 32
  store i64 8, ptr %t17
  store ptr %t13, ptr %t11
  %t19 = call i8* @malloc(i64 48)
  store i64 4, ptr %t19
  %t20 = getelementptr i8, ptr %t19, i64 8
  store i64 4, ptr %t20
  %t21 = getelementptr i8, ptr %t20, i64 8
  store i64 9, ptr %t21
  %t22 = getelementptr i8, ptr %t20, i64 16
  store i64 10, ptr %t22
  %t23 = getelementptr i8, ptr %t20, i64 24
  store i64 11, ptr %t23
  %t24 = getelementptr i8, ptr %t20, i64 32
  store i64 12, ptr %t24
  store ptr %t20, ptr %t18
  %t26 = call i8* @malloc(i64 40)
  store i64 3, ptr %t26
  %t27 = getelementptr i8, ptr %t26, i64 8
  store i64 3, ptr %t27
  %t28 = load ptr, ptr %t4
  %t29 = getelementptr i8, ptr %t27, i64 8
  store ptr %t28, ptr %t29
  %t30 = load ptr, ptr %t11
  %t31 = getelementptr i8, ptr %t27, i64 16
  store ptr %t30, ptr %t31
  %t32 = load ptr, ptr %t18
  %t33 = getelementptr i8, ptr %t27, i64 24
  store ptr %t32, ptr %t33
  store ptr %t27, ptr %t25
  %t35 = load ptr, ptr %t25
  %t36 = load ptr, ptr %t25
  %t37 = icmp eq ptr %t36, null
  br i1 %t37, label %list_len_null_0, label %list_len_load_1
list_len_null_0:
  store i64 0, ptr %t40
  br label %list_len_end_2
list_len_load_1:
  %t38 = load i64, ptr %t36
  store i64 %t38, ptr %t40
  br label %list_len_end_2
list_len_end_2:
  %t39 = load i64, ptr %t40
  store i64 %t39, ptr %t34
  %t42 = load ptr, ptr %t25
  %t43 = getelementptr inbounds i8, ptr %t42, i64 8
  %t44 = mul i64 0, 8
  %t45 = getelementptr inbounds i8, ptr %t43, i64 %t44
  %t46 = load ptr, ptr %t45
  store ptr %t46, ptr %t41
  %t48 = load ptr, ptr %t25
  %t49 = getelementptr inbounds i8, ptr %t48, i64 8
  %t50 = mul i64 1, 8
  %t51 = getelementptr inbounds i8, ptr %t49, i64 %t50
  %t52 = load ptr, ptr %t51
  store ptr %t52, ptr %t47
  %t54 = load ptr, ptr %t25
  %t55 = getelementptr inbounds i8, ptr %t54, i64 8
  %t56 = mul i64 2, 8
  %t57 = getelementptr inbounds i8, ptr %t55, i64 %t56
  %t58 = load ptr, ptr %t57
  store ptr %t58, ptr %t53
  %t60 = load ptr, ptr %t41
  %t61 = load ptr, ptr %t41
  %t62 = icmp eq ptr %t61, null
  br i1 %t62, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t65
  br label %list_len_end_5
list_len_load_4:
  %t63 = load i64, ptr %t61
  store i64 %t63, ptr %t65
  br label %list_len_end_5
list_len_end_5:
  %t64 = load i64, ptr %t65
  store i64 %t64, ptr %t59
  store i64 0, ptr %t66
  %t67 = load i64, ptr %t66
  %t68 = load ptr, ptr %t41
  %t69 = getelementptr inbounds i8, ptr %t68, i64 8
  %t70 = mul i64 0, 8
  %t71 = getelementptr inbounds i8, ptr %t69, i64 %t70
  %t72 = load i64, ptr %t71
  %t73 = add i64 %t67, %t72
  store i64 %t73, ptr %t66
  %t74 = load i64, ptr %t66
  %t75 = load ptr, ptr %t41
  %t76 = getelementptr inbounds i8, ptr %t75, i64 8
  %t77 = mul i64 1, 8
  %t78 = getelementptr inbounds i8, ptr %t76, i64 %t77
  %t79 = load i64, ptr %t78
  %t80 = add i64 %t74, %t79
  store i64 %t80, ptr %t66
  %t81 = load i64, ptr %t66
  %t82 = load ptr, ptr %t41
  %t83 = getelementptr inbounds i8, ptr %t82, i64 8
  %t84 = mul i64 2, 8
  %t85 = getelementptr inbounds i8, ptr %t83, i64 %t84
  %t86 = load i64, ptr %t85
  %t87 = add i64 %t81, %t86
  store i64 %t87, ptr %t66
  %t88 = load i64, ptr %t66
  %t89 = load ptr, ptr %t41
  %t90 = getelementptr inbounds i8, ptr %t89, i64 8
  %t91 = mul i64 3, 8
  %t92 = getelementptr inbounds i8, ptr %t90, i64 %t91
  %t93 = load i64, ptr %t92
  %t94 = add i64 %t88, %t93
  store i64 %t94, ptr %t66
  %t95 = load i64, ptr %t66
  %t96 = load ptr, ptr %t47
  %t97 = getelementptr inbounds i8, ptr %t96, i64 8
  %t98 = mul i64 0, 8
  %t99 = getelementptr inbounds i8, ptr %t97, i64 %t98
  %t100 = load i64, ptr %t99
  %t101 = add i64 %t95, %t100
  store i64 %t101, ptr %t66
  %t102 = load i64, ptr %t66
  %t103 = load ptr, ptr %t47
  %t104 = getelementptr inbounds i8, ptr %t103, i64 8
  %t105 = mul i64 1, 8
  %t106 = getelementptr inbounds i8, ptr %t104, i64 %t105
  %t107 = load i64, ptr %t106
  %t108 = add i64 %t102, %t107
  store i64 %t108, ptr %t66
  %t109 = load i64, ptr %t66
  %t110 = load ptr, ptr %t47
  %t111 = getelementptr inbounds i8, ptr %t110, i64 8
  %t112 = mul i64 2, 8
  %t113 = getelementptr inbounds i8, ptr %t111, i64 %t112
  %t114 = load i64, ptr %t113
  %t115 = add i64 %t109, %t114
  store i64 %t115, ptr %t66
  %t116 = load i64, ptr %t66
  %t117 = load ptr, ptr %t47
  %t118 = getelementptr inbounds i8, ptr %t117, i64 8
  %t119 = mul i64 3, 8
  %t120 = getelementptr inbounds i8, ptr %t118, i64 %t119
  %t121 = load i64, ptr %t120
  %t122 = add i64 %t116, %t121
  store i64 %t122, ptr %t66
  %t123 = load i64, ptr %t66
  %t124 = load ptr, ptr %t53
  %t125 = getelementptr inbounds i8, ptr %t124, i64 8
  %t126 = mul i64 0, 8
  %t127 = getelementptr inbounds i8, ptr %t125, i64 %t126
  %t128 = load i64, ptr %t127
  %t129 = add i64 %t123, %t128
  store i64 %t129, ptr %t66
  %t130 = load i64, ptr %t66
  %t131 = load ptr, ptr %t53
  %t132 = getelementptr inbounds i8, ptr %t131, i64 8
  %t133 = mul i64 1, 8
  %t134 = getelementptr inbounds i8, ptr %t132, i64 %t133
  %t135 = load i64, ptr %t134
  %t136 = add i64 %t130, %t135
  store i64 %t136, ptr %t66
  %t137 = load i64, ptr %t66
  %t138 = load ptr, ptr %t53
  %t139 = getelementptr inbounds i8, ptr %t138, i64 8
  %t140 = mul i64 2, 8
  %t141 = getelementptr inbounds i8, ptr %t139, i64 %t140
  %t142 = load i64, ptr %t141
  %t143 = add i64 %t137, %t142
  store i64 %t143, ptr %t66
  %t144 = load i64, ptr %t66
  %t145 = load ptr, ptr %t53
  %t146 = getelementptr inbounds i8, ptr %t145, i64 8
  %t147 = mul i64 3, 8
  %t148 = getelementptr inbounds i8, ptr %t146, i64 %t147
  %t149 = load i64, ptr %t148
  %t150 = add i64 %t144, %t149
  store i64 %t150, ptr %t66
  %t152 = load ptr, ptr %t53
  %t153 = getelementptr inbounds i8, ptr %t152, i64 8
  %t154 = mul i64 3, 8
  %t155 = getelementptr inbounds i8, ptr %t153, i64 %t154
  %t156 = load i64, ptr %t155
  store i64 %t156, ptr %t151
  %t157 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t158 = load i64, ptr %t34
  %t159 = call ptr @mire_i64_to_string(i64 %t158)
  %t160 = call ptr @concat(ptr %t157, ptr %t159)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t160)
  %t161 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t162 = load i64, ptr %t59
  %t163 = call ptr @mire_i64_to_string(i64 %t162)
  %t164 = call ptr @concat(ptr %t161, ptr %t163)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t164)
  %t165 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t166 = load i64, ptr %t66
  %t167 = call ptr @mire_i64_to_string(i64 %t166)
  %t168 = call ptr @concat(ptr %t165, ptr %t167)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t168)
  %t169 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t170 = load i64, ptr %t151
  %t171 = call ptr @mire_i64_to_string(i64 %t170)
  %t172 = call ptr @concat(ptr %t169, ptr %t171)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t172)
  %t173 = getelementptr inbounds [9 x i8], ptr @.str4, i64 0, i64 0
  %t174 = load i64, ptr %t0
  %t175 = call ptr @mire_wall_elapsed_ms_str(i64 %t174)
  %t176 = call ptr @concat(ptr %t173, ptr %t175)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t176)
  %t177 = getelementptr inbounds [8 x i8], ptr @.str5, i64 0, i64 0
  %t178 = load i64, ptr %t2
  %t179 = call ptr @mire_cpu_elapsed_ms_str(i64 %t178)
  %t180 = call ptr @concat(ptr %t177, ptr %t179)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t180)
  %t181 = getelementptr inbounds [16 x i8], ptr @.str6, i64 0, i64 0
  %t182 = load i64, ptr %t2
  %t183 = call i64 @mire_cpu_cycles_est(i64 %t182)
  %t184 = call ptr @mire_i64_to_string(i64 %t183)
  %t185 = call ptr @concat(ptr %t181, ptr %t184)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t185)
  %t186 = getelementptr inbounds [13 x i8], ptr @.str7, i64 0, i64 0
  %t187 = call i64 @mire_mem_process_bytes()
  %t188 = call ptr @mire_mem_format(i64 %t187)
  %t189 = call ptr @concat(ptr %t186, ptr %t188)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t189)
  ret i32 0
}
