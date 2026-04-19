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
  %t28 = alloca i64
  %t34 = alloca i64
  %t35 = alloca ptr
  %t41 = alloca i64
  %t47 = alloca i64
  %t48 = alloca i64
  %t181 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = call i8* @malloc(i64 40)
  store i64 3, ptr %t5
  %t6 = getelementptr i8, ptr %t5, i64 8
  store i64 3, ptr %t6
  %t7 = call i8* @malloc(i64 48)
  store i64 4, ptr %t7
  %t8 = getelementptr i8, ptr %t7, i64 8
  store i64 4, ptr %t8
  %t9 = getelementptr i8, ptr %t8, i64 8
  store i64 1, ptr %t9
  %t10 = getelementptr i8, ptr %t8, i64 16
  store i64 2, ptr %t10
  %t11 = getelementptr i8, ptr %t8, i64 24
  store i64 3, ptr %t11
  %t12 = getelementptr i8, ptr %t8, i64 32
  store i64 4, ptr %t12
  %t13 = getelementptr i8, ptr %t6, i64 8
  store ptr %t8, ptr %t13
  %t14 = call i8* @malloc(i64 48)
  store i64 4, ptr %t14
  %t15 = getelementptr i8, ptr %t14, i64 8
  store i64 4, ptr %t15
  %t16 = getelementptr i8, ptr %t15, i64 8
  store i64 5, ptr %t16
  %t17 = getelementptr i8, ptr %t15, i64 16
  store i64 6, ptr %t17
  %t18 = getelementptr i8, ptr %t15, i64 24
  store i64 7, ptr %t18
  %t19 = getelementptr i8, ptr %t15, i64 32
  store i64 8, ptr %t19
  %t20 = getelementptr i8, ptr %t6, i64 16
  store ptr %t15, ptr %t20
  %t21 = call i8* @malloc(i64 48)
  store i64 4, ptr %t21
  %t22 = getelementptr i8, ptr %t21, i64 8
  store i64 4, ptr %t22
  %t23 = getelementptr i8, ptr %t22, i64 8
  store i64 9, ptr %t23
  %t24 = getelementptr i8, ptr %t22, i64 16
  store i64 10, ptr %t24
  %t25 = getelementptr i8, ptr %t22, i64 24
  store i64 11, ptr %t25
  %t26 = getelementptr i8, ptr %t22, i64 32
  store i64 12, ptr %t26
  %t27 = getelementptr i8, ptr %t6, i64 24
  store ptr %t22, ptr %t27
  store ptr %t6, ptr %t4
  %t29 = load ptr, ptr %t4
  %t30 = load ptr, ptr %t4
  %t31 = icmp eq ptr %t30, null
  br i1 %t31, label %list_len_null_0, label %list_len_load_1
list_len_null_0:
  store i64 0, ptr %t34
  br label %list_len_end_2
list_len_load_1:
  %t32 = load i64, ptr %t30
  store i64 %t32, ptr %t34
  br label %list_len_end_2
list_len_end_2:
  %t33 = load i64, ptr %t34
  store i64 %t33, ptr %t28
  %t36 = load ptr, ptr %t4
  %t37 = getelementptr inbounds i8, ptr %t36, i64 8
  %t38 = mul i64 1, 8
  %t39 = getelementptr inbounds i8, ptr %t37, i64 %t38
  %t40 = load ptr, ptr %t39
  store ptr %t40, ptr %t35
  %t42 = load ptr, ptr %t35
  %t43 = load ptr, ptr %t35
  %t44 = icmp eq ptr %t43, null
  br i1 %t44, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t47
  br label %list_len_end_5
list_len_load_4:
  %t45 = load i64, ptr %t43
  store i64 %t45, ptr %t47
  br label %list_len_end_5
list_len_end_5:
  %t46 = load i64, ptr %t47
  store i64 %t46, ptr %t41
  store i64 0, ptr %t48
  %t49 = load i64, ptr %t48
  %t50 = load ptr, ptr %t4
  %t51 = getelementptr inbounds i8, ptr %t50, i64 8
  %t52 = mul i64 0, 8
  %t53 = getelementptr inbounds i8, ptr %t51, i64 %t52
  %t54 = load ptr, ptr %t53
  %t55 = getelementptr inbounds i8, ptr %t54, i64 8
  %t56 = mul i64 0, 8
  %t57 = getelementptr inbounds i8, ptr %t55, i64 %t56
  %t58 = load i64, ptr %t57
  %t59 = add i64 %t49, %t58
  store i64 %t59, ptr %t48
  %t60 = load i64, ptr %t48
  %t61 = load ptr, ptr %t4
  %t62 = getelementptr inbounds i8, ptr %t61, i64 8
  %t63 = mul i64 0, 8
  %t64 = getelementptr inbounds i8, ptr %t62, i64 %t63
  %t65 = load ptr, ptr %t64
  %t66 = getelementptr inbounds i8, ptr %t65, i64 8
  %t67 = mul i64 1, 8
  %t68 = getelementptr inbounds i8, ptr %t66, i64 %t67
  %t69 = load i64, ptr %t68
  %t70 = add i64 %t60, %t69
  store i64 %t70, ptr %t48
  %t71 = load i64, ptr %t48
  %t72 = load ptr, ptr %t4
  %t73 = getelementptr inbounds i8, ptr %t72, i64 8
  %t74 = mul i64 0, 8
  %t75 = getelementptr inbounds i8, ptr %t73, i64 %t74
  %t76 = load ptr, ptr %t75
  %t77 = getelementptr inbounds i8, ptr %t76, i64 8
  %t78 = mul i64 2, 8
  %t79 = getelementptr inbounds i8, ptr %t77, i64 %t78
  %t80 = load i64, ptr %t79
  %t81 = add i64 %t71, %t80
  store i64 %t81, ptr %t48
  %t82 = load i64, ptr %t48
  %t83 = load ptr, ptr %t4
  %t84 = getelementptr inbounds i8, ptr %t83, i64 8
  %t85 = mul i64 0, 8
  %t86 = getelementptr inbounds i8, ptr %t84, i64 %t85
  %t87 = load ptr, ptr %t86
  %t88 = getelementptr inbounds i8, ptr %t87, i64 8
  %t89 = mul i64 3, 8
  %t90 = getelementptr inbounds i8, ptr %t88, i64 %t89
  %t91 = load i64, ptr %t90
  %t92 = add i64 %t82, %t91
  store i64 %t92, ptr %t48
  %t93 = load i64, ptr %t48
  %t94 = load ptr, ptr %t4
  %t95 = getelementptr inbounds i8, ptr %t94, i64 8
  %t96 = mul i64 1, 8
  %t97 = getelementptr inbounds i8, ptr %t95, i64 %t96
  %t98 = load ptr, ptr %t97
  %t99 = getelementptr inbounds i8, ptr %t98, i64 8
  %t100 = mul i64 0, 8
  %t101 = getelementptr inbounds i8, ptr %t99, i64 %t100
  %t102 = load i64, ptr %t101
  %t103 = add i64 %t93, %t102
  store i64 %t103, ptr %t48
  %t104 = load i64, ptr %t48
  %t105 = load ptr, ptr %t4
  %t106 = getelementptr inbounds i8, ptr %t105, i64 8
  %t107 = mul i64 1, 8
  %t108 = getelementptr inbounds i8, ptr %t106, i64 %t107
  %t109 = load ptr, ptr %t108
  %t110 = getelementptr inbounds i8, ptr %t109, i64 8
  %t111 = mul i64 1, 8
  %t112 = getelementptr inbounds i8, ptr %t110, i64 %t111
  %t113 = load i64, ptr %t112
  %t114 = add i64 %t104, %t113
  store i64 %t114, ptr %t48
  %t115 = load i64, ptr %t48
  %t116 = load ptr, ptr %t4
  %t117 = getelementptr inbounds i8, ptr %t116, i64 8
  %t118 = mul i64 1, 8
  %t119 = getelementptr inbounds i8, ptr %t117, i64 %t118
  %t120 = load ptr, ptr %t119
  %t121 = getelementptr inbounds i8, ptr %t120, i64 8
  %t122 = mul i64 2, 8
  %t123 = getelementptr inbounds i8, ptr %t121, i64 %t122
  %t124 = load i64, ptr %t123
  %t125 = add i64 %t115, %t124
  store i64 %t125, ptr %t48
  %t126 = load i64, ptr %t48
  %t127 = load ptr, ptr %t4
  %t128 = getelementptr inbounds i8, ptr %t127, i64 8
  %t129 = mul i64 1, 8
  %t130 = getelementptr inbounds i8, ptr %t128, i64 %t129
  %t131 = load ptr, ptr %t130
  %t132 = getelementptr inbounds i8, ptr %t131, i64 8
  %t133 = mul i64 3, 8
  %t134 = getelementptr inbounds i8, ptr %t132, i64 %t133
  %t135 = load i64, ptr %t134
  %t136 = add i64 %t126, %t135
  store i64 %t136, ptr %t48
  %t137 = load i64, ptr %t48
  %t138 = load ptr, ptr %t4
  %t139 = getelementptr inbounds i8, ptr %t138, i64 8
  %t140 = mul i64 2, 8
  %t141 = getelementptr inbounds i8, ptr %t139, i64 %t140
  %t142 = load ptr, ptr %t141
  %t143 = getelementptr inbounds i8, ptr %t142, i64 8
  %t144 = mul i64 0, 8
  %t145 = getelementptr inbounds i8, ptr %t143, i64 %t144
  %t146 = load i64, ptr %t145
  %t147 = add i64 %t137, %t146
  store i64 %t147, ptr %t48
  %t148 = load i64, ptr %t48
  %t149 = load ptr, ptr %t4
  %t150 = getelementptr inbounds i8, ptr %t149, i64 8
  %t151 = mul i64 2, 8
  %t152 = getelementptr inbounds i8, ptr %t150, i64 %t151
  %t153 = load ptr, ptr %t152
  %t154 = getelementptr inbounds i8, ptr %t153, i64 8
  %t155 = mul i64 1, 8
  %t156 = getelementptr inbounds i8, ptr %t154, i64 %t155
  %t157 = load i64, ptr %t156
  %t158 = add i64 %t148, %t157
  store i64 %t158, ptr %t48
  %t159 = load i64, ptr %t48
  %t160 = load ptr, ptr %t4
  %t161 = getelementptr inbounds i8, ptr %t160, i64 8
  %t162 = mul i64 2, 8
  %t163 = getelementptr inbounds i8, ptr %t161, i64 %t162
  %t164 = load ptr, ptr %t163
  %t165 = getelementptr inbounds i8, ptr %t164, i64 8
  %t166 = mul i64 2, 8
  %t167 = getelementptr inbounds i8, ptr %t165, i64 %t166
  %t168 = load i64, ptr %t167
  %t169 = add i64 %t159, %t168
  store i64 %t169, ptr %t48
  %t170 = load i64, ptr %t48
  %t171 = load ptr, ptr %t4
  %t172 = getelementptr inbounds i8, ptr %t171, i64 8
  %t173 = mul i64 2, 8
  %t174 = getelementptr inbounds i8, ptr %t172, i64 %t173
  %t175 = load ptr, ptr %t174
  %t176 = getelementptr inbounds i8, ptr %t175, i64 8
  %t177 = mul i64 3, 8
  %t178 = getelementptr inbounds i8, ptr %t176, i64 %t177
  %t179 = load i64, ptr %t178
  %t180 = add i64 %t170, %t179
  store i64 %t180, ptr %t48
  %t182 = load ptr, ptr %t4
  %t183 = getelementptr inbounds i8, ptr %t182, i64 8
  %t184 = mul i64 2, 8
  %t185 = getelementptr inbounds i8, ptr %t183, i64 %t184
  %t186 = load ptr, ptr %t185
  %t187 = getelementptr inbounds i8, ptr %t186, i64 8
  %t188 = mul i64 3, 8
  %t189 = getelementptr inbounds i8, ptr %t187, i64 %t188
  %t190 = load i64, ptr %t189
  store i64 %t190, ptr %t181
  %t191 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t192 = load i64, ptr %t28
  %t193 = call ptr @mire_i64_to_string(i64 %t192)
  %t194 = call ptr @concat(ptr %t191, ptr %t193)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t194)
  %t195 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t196 = load i64, ptr %t41
  %t197 = call ptr @mire_i64_to_string(i64 %t196)
  %t198 = call ptr @concat(ptr %t195, ptr %t197)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t198)
  %t199 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t200 = load i64, ptr %t48
  %t201 = call ptr @mire_i64_to_string(i64 %t200)
  %t202 = call ptr @concat(ptr %t199, ptr %t201)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t202)
  %t203 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t204 = load i64, ptr %t181
  %t205 = call ptr @mire_i64_to_string(i64 %t204)
  %t206 = call ptr @concat(ptr %t203, ptr %t205)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t206)
  %t207 = getelementptr inbounds [9 x i8], ptr @.str4, i64 0, i64 0
  %t208 = load i64, ptr %t0
  %t209 = call ptr @mire_wall_elapsed_ms_str(i64 %t208)
  %t210 = call ptr @concat(ptr %t207, ptr %t209)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t210)
  %t211 = getelementptr inbounds [8 x i8], ptr @.str5, i64 0, i64 0
  %t212 = load i64, ptr %t2
  %t213 = call ptr @mire_cpu_elapsed_ms_str(i64 %t212)
  %t214 = call ptr @concat(ptr %t211, ptr %t213)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t214)
  %t215 = getelementptr inbounds [16 x i8], ptr @.str6, i64 0, i64 0
  %t216 = load i64, ptr %t2
  %t217 = call i64 @mire_cpu_cycles_est(i64 %t216)
  %t218 = call ptr @mire_i64_to_string(i64 %t217)
  %t219 = call ptr @concat(ptr %t215, ptr %t218)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t219)
  %t220 = getelementptr inbounds [13 x i8], ptr @.str7, i64 0, i64 0
  %t221 = call i64 @mire_mem_process_bytes()
  %t222 = call ptr @mire_mem_format(i64 %t221)
  %t223 = call ptr @concat(ptr %t220, ptr %t222)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t223)
  ret i32 0
}
