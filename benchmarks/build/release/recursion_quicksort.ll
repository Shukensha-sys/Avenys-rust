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
@.str0 = private unnamed_addr constant [7 x i8] c"first \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define ptr @fn_quicksort(ptr %arg_arr, i64 %arg_len) {
entry:
  %t0 = alloca ptr
  %t1 = alloca i64
  %t5 = alloca i64
  %t11 = alloca ptr
  %t13 = alloca ptr
  %t15 = alloca i64
  %t19 = alloca i64
  %t46 = alloca ptr
  %t53 = alloca i64
  %t55 = alloca ptr
  %t62 = alloca i64
  store ptr %arg_arr, ptr %t0
  store i64 %arg_len, ptr %t1
  %t2 = load i64, ptr %t1
  %t3 = icmp sle i64 %t2, 1
  br i1 %t3, label %if_then_0, label %if_else_1
if_then_0:
  %t4 = load ptr, ptr %t0
  ret ptr %t4
  br label %if_end_2
if_else_1:
  br label %if_end_2
if_end_2:
  %t6 = load ptr, ptr %t0
  %t7 = getelementptr inbounds i8, ptr %t6, i64 8
  %t8 = mul i64 0, 8
  %t9 = getelementptr inbounds i8, ptr %t7, i64 %t8
  %t10 = load i64, ptr %t9
  store i64 %t10, ptr %t5
  %t12 = inttoptr i64 0 to ptr
  store ptr %t12, ptr %t11
  %t14 = inttoptr i64 0 to ptr
  store ptr %t14, ptr %t13
  store i64 1, ptr %t15
  br label %while_cond_3
while_cond_3:
  %t16 = load i64, ptr %t15
  %t17 = load i64, ptr %t1
  %t18 = icmp slt i64 %t16, %t17
  br i1 %t18, label %while_body_4, label %while_end_5
while_body_4:
  %t20 = load ptr, ptr %t0
  %t21 = load i64, ptr %t15
  %t22 = getelementptr inbounds i8, ptr %t20, i64 8
  %t23 = mul i64 %t21, 8
  %t24 = getelementptr inbounds i8, ptr %t22, i64 %t23
  %t25 = load i64, ptr %t24
  store i64 %t25, ptr %t19
  %t26 = load i64, ptr %t19
  %t27 = load i64, ptr %t5
  %t28 = icmp slt i64 %t26, %t27
  br i1 %t28, label %if_then_6, label %if_else_7
if_then_6:
  %t29 = load ptr, ptr %t11
  %t30 = call i8* @malloc(i64 24)
  store i64 1, ptr %t30
  %t31 = getelementptr i8, ptr %t30, i64 8
  store i64 1, ptr %t31
  %t32 = load i64, ptr %t19
  %t33 = getelementptr i8, ptr %t31, i64 8
  store i64 %t32, ptr %t33
  %t34 = call ptr @mire_list_concat(ptr %t29, ptr %t31)
  store ptr %t34, ptr %t11
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t35 = load i64, ptr %t19
  %t36 = load i64, ptr %t5
  %t37 = icmp sge i64 %t35, %t36
  br i1 %t37, label %if_then_9, label %if_else_10
if_then_9:
  %t38 = load ptr, ptr %t13
  %t39 = call i8* @malloc(i64 24)
  store i64 1, ptr %t39
  %t40 = getelementptr i8, ptr %t39, i64 8
  store i64 1, ptr %t40
  %t41 = load i64, ptr %t19
  %t42 = getelementptr i8, ptr %t40, i64 8
  store i64 %t41, ptr %t42
  %t43 = call ptr @mire_list_concat(ptr %t38, ptr %t40)
  store ptr %t43, ptr %t13
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t44 = load i64, ptr %t15
  %t45 = add i64 %t44, 1
  store i64 %t45, ptr %t15
  br label %while_cond_3
while_end_5:
  %t47 = load ptr, ptr %t11
  %t48 = load ptr, ptr %t11
  %t49 = load ptr, ptr %t11
  %t50 = icmp eq ptr %t49, null
  br i1 %t50, label %list_len_null_12, label %list_len_load_13
list_len_null_12:
  store i64 0, ptr %t53
  br label %list_len_end_14
list_len_load_13:
  %t51 = load i64, ptr %t49
  store i64 %t51, ptr %t53
  br label %list_len_end_14
list_len_end_14:
  %t52 = load i64, ptr %t53
  %t54 = call ptr @fn_quicksort(ptr %t47, i64 %t52)
  store ptr %t54, ptr %t46
  %t56 = load ptr, ptr %t13
  %t57 = load ptr, ptr %t13
  %t58 = load ptr, ptr %t13
  %t59 = icmp eq ptr %t58, null
  br i1 %t59, label %list_len_null_15, label %list_len_load_16
list_len_null_15:
  store i64 0, ptr %t62
  br label %list_len_end_17
list_len_load_16:
  %t60 = load i64, ptr %t58
  store i64 %t60, ptr %t62
  br label %list_len_end_17
list_len_end_17:
  %t61 = load i64, ptr %t62
  %t63 = call ptr @fn_quicksort(ptr %t56, i64 %t61)
  store ptr %t63, ptr %t55
  %t64 = load ptr, ptr %t46
  %t65 = call i8* @malloc(i64 24)
  store i64 1, ptr %t65
  %t66 = getelementptr i8, ptr %t65, i64 8
  store i64 1, ptr %t66
  %t67 = load i64, ptr %t5
  %t68 = getelementptr i8, ptr %t66, i64 8
  store i64 %t67, ptr %t68
  %t69 = call ptr @mire_list_concat(ptr %t64, ptr %t66)
  %t70 = load ptr, ptr %t55
  %t71 = call ptr @mire_list_concat(ptr %t69, ptr %t70)
  ret ptr %t71
}

define i32 @main() {
entry:
  %t72 = alloca i64
  %t74 = alloca i64
  %t76 = alloca ptr
  %t94 = alloca ptr
  %t101 = alloca i64
  %t103 = alloca i64
  %t109 = alloca i64
  %t116 = alloca i64
  %t73 = call i64 @mire_wall_mark_ns()
  store i64 %t73, ptr %t72
  %t75 = call i64 @mire_cpu_mark_ns()
  store i64 %t75, ptr %t74
  %t77 = call i8* @malloc(i64 136)
  store i64 15, ptr %t77
  %t78 = getelementptr i8, ptr %t77, i64 8
  store i64 15, ptr %t78
  %t79 = getelementptr i8, ptr %t78, i64 8
  store i64 5, ptr %t79
  %t80 = getelementptr i8, ptr %t78, i64 16
  store i64 3, ptr %t80
  %t81 = getelementptr i8, ptr %t78, i64 24
  store i64 8, ptr %t81
  %t82 = getelementptr i8, ptr %t78, i64 32
  store i64 1, ptr %t82
  %t83 = getelementptr i8, ptr %t78, i64 40
  store i64 9, ptr %t83
  %t84 = getelementptr i8, ptr %t78, i64 48
  store i64 2, ptr %t84
  %t85 = getelementptr i8, ptr %t78, i64 56
  store i64 7, ptr %t85
  %t86 = getelementptr i8, ptr %t78, i64 64
  store i64 4, ptr %t86
  %t87 = getelementptr i8, ptr %t78, i64 72
  store i64 6, ptr %t87
  %t88 = getelementptr i8, ptr %t78, i64 80
  store i64 0, ptr %t88
  %t89 = getelementptr i8, ptr %t78, i64 88
  store i64 11, ptr %t89
  %t90 = getelementptr i8, ptr %t78, i64 96
  store i64 13, ptr %t90
  %t91 = getelementptr i8, ptr %t78, i64 104
  store i64 12, ptr %t91
  %t92 = getelementptr i8, ptr %t78, i64 112
  store i64 10, ptr %t92
  %t93 = getelementptr i8, ptr %t78, i64 120
  store i64 14, ptr %t93
  store ptr %t78, ptr %t76
  %t95 = load ptr, ptr %t76
  %t96 = load ptr, ptr %t76
  %t97 = load ptr, ptr %t76
  %t98 = icmp eq ptr %t97, null
  br i1 %t98, label %list_len_null_18, label %list_len_load_19
list_len_null_18:
  store i64 0, ptr %t101
  br label %list_len_end_20
list_len_load_19:
  %t99 = load i64, ptr %t97
  store i64 %t99, ptr %t101
  br label %list_len_end_20
list_len_end_20:
  %t100 = load i64, ptr %t101
  %t102 = call ptr @fn_quicksort(ptr %t95, i64 %t100)
  store ptr %t102, ptr %t94
  %t104 = load ptr, ptr %t94
  %t105 = getelementptr inbounds i8, ptr %t104, i64 8
  %t106 = mul i64 0, 8
  %t107 = getelementptr inbounds i8, ptr %t105, i64 %t106
  %t108 = load i64, ptr %t107
  store i64 %t108, ptr %t103
  %t110 = load ptr, ptr %t94
  %t111 = load ptr, ptr %t94
  %t112 = load ptr, ptr %t94
  %t113 = icmp eq ptr %t112, null
  br i1 %t113, label %list_len_null_21, label %list_len_load_22
list_len_null_21:
  store i64 0, ptr %t116
  br label %list_len_end_23
list_len_load_22:
  %t114 = load i64, ptr %t112
  store i64 %t114, ptr %t116
  br label %list_len_end_23
list_len_end_23:
  %t115 = load i64, ptr %t116
  %t117 = sub i64 %t115, 1
  %t118 = getelementptr inbounds i8, ptr %t110, i64 8
  %t119 = mul i64 %t117, 8
  %t120 = getelementptr inbounds i8, ptr %t118, i64 %t119
  %t121 = load i64, ptr %t120
  store i64 %t121, ptr %t109
  %t122 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t123 = load i64, ptr %t103
  %t124 = call ptr @mire_i64_to_string(i64 %t123)
  %t125 = call ptr @concat(ptr %t122, ptr %t124)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t125)
  %t126 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t127 = load i64, ptr %t109
  %t128 = call ptr @mire_i64_to_string(i64 %t127)
  %t129 = call ptr @concat(ptr %t126, ptr %t128)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t129)
  %t130 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t131 = load i64, ptr %t72
  %t132 = call ptr @mire_wall_elapsed_ms_str(i64 %t131)
  %t133 = call ptr @concat(ptr %t130, ptr %t132)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t133)
  %t134 = getelementptr inbounds [13 x i8], ptr @.str3, i64 0, i64 0
  %t135 = call i64 @mire_mem_process_bytes()
  %t136 = call ptr @mire_mem_format(i64 %t135)
  %t137 = call ptr @concat(ptr %t134, ptr %t136)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t137)
  ret i32 0
}
