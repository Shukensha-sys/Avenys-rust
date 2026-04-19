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
@.str0 = private unnamed_addr constant [5 x i8] c"left\00"
@.str1 = private unnamed_addr constant [6 x i8] c"right\00"
@.str2 = private unnamed_addr constant [6 x i8] c"right\00"
@.str3 = private unnamed_addr constant [5 x i8] c"left\00"
@.str4 = private unnamed_addr constant [5 x i8] c"left\00"
@.str5 = private unnamed_addr constant [5 x i8] c"left\00"
@.str6 = private unnamed_addr constant [7 x i8] c"total \00"
@.str7 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str8 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str9 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str10 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str11 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t12 = alloca ptr
  %t20 = alloca ptr
  %t22 = alloca ptr
  %t32 = alloca ptr
  %t37 = alloca i64
  %t82 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = call ptr @mire_list_push_i64(ptr %t6, i64 2)
  store ptr %t7, ptr %t4
  %t8 = load ptr, ptr %t4
  %t9 = call ptr @mire_list_push_i64(ptr %t8, i64 4)
  store ptr %t9, ptr %t4
  %t10 = load ptr, ptr %t4
  %t11 = call ptr @mire_list_push_i64(ptr %t10, i64 6)
  store ptr %t11, ptr %t4
  %t13 = inttoptr i64 0 to ptr
  store ptr %t13, ptr %t12
  %t14 = load ptr, ptr %t12
  %t15 = call ptr @mire_list_push_i64(ptr %t14, i64 3)
  store ptr %t15, ptr %t12
  %t16 = load ptr, ptr %t12
  %t17 = call ptr @mire_list_push_i64(ptr %t16, i64 5)
  store ptr %t17, ptr %t12
  %t18 = load ptr, ptr %t12
  %t19 = call ptr @mire_list_push_i64(ptr %t18, i64 7)
  store ptr %t19, ptr %t12
  %t21 = inttoptr i64 0 to ptr
  store ptr %t21, ptr %t20
  %t23 = inttoptr i64 0 to ptr
  store ptr %t23, ptr %t22
  %t24 = load ptr, ptr %t22
  %t25 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t26 = load ptr, ptr %t4
  %t27 = call ptr @mire_dict_set_ptr(ptr %t24, i64 3, i64 5, i64 0, ptr %t25, ptr %t26)
  store ptr %t27, ptr %t22
  %t28 = load ptr, ptr %t22
  %t29 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t30 = load ptr, ptr %t12
  %t31 = call ptr @mire_dict_set_ptr(ptr %t28, i64 3, i64 5, i64 0, ptr %t29, ptr %t30)
  store ptr %t31, ptr %t22
  %t33 = load ptr, ptr %t22
  %t34 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t35 = load ptr, ptr %t20
  %t36 = call ptr @mire_dict_get_ptr(ptr %t33, i64 3, i64 0, ptr %t34, ptr %t35)
  store ptr %t36, ptr %t32
  %t38 = load ptr, ptr %t22
  %t39 = getelementptr inbounds [5 x i8], ptr @.str3, i64 0, i64 0
  %t40 = load ptr, ptr %t20
  %t41 = call ptr @mire_dict_get_ptr(ptr %t38, i64 3, i64 0, ptr %t39, ptr %t40)
  %t42 = getelementptr inbounds i8, ptr %t41, i64 8
  %t43 = mul i64 0, 8
  %t44 = getelementptr inbounds i8, ptr %t42, i64 %t43
  %t45 = load i64, ptr %t44
  %t46 = load ptr, ptr %t22
  %t47 = getelementptr inbounds [5 x i8], ptr @.str4, i64 0, i64 0
  %t48 = load ptr, ptr %t20
  %t49 = call ptr @mire_dict_get_ptr(ptr %t46, i64 3, i64 0, ptr %t47, ptr %t48)
  %t50 = getelementptr inbounds i8, ptr %t49, i64 8
  %t51 = mul i64 1, 8
  %t52 = getelementptr inbounds i8, ptr %t50, i64 %t51
  %t53 = load i64, ptr %t52
  %t54 = add i64 %t45, %t53
  %t55 = load ptr, ptr %t22
  %t56 = getelementptr inbounds [5 x i8], ptr @.str5, i64 0, i64 0
  %t57 = load ptr, ptr %t20
  %t58 = call ptr @mire_dict_get_ptr(ptr %t55, i64 3, i64 0, ptr %t56, ptr %t57)
  %t59 = getelementptr inbounds i8, ptr %t58, i64 8
  %t60 = mul i64 2, 8
  %t61 = getelementptr inbounds i8, ptr %t59, i64 %t60
  %t62 = load i64, ptr %t61
  %t63 = add i64 %t54, %t62
  %t64 = load ptr, ptr %t32
  %t65 = getelementptr inbounds i8, ptr %t64, i64 8
  %t66 = mul i64 0, 8
  %t67 = getelementptr inbounds i8, ptr %t65, i64 %t66
  %t68 = load i64, ptr %t67
  %t69 = add i64 %t63, %t68
  %t70 = load ptr, ptr %t32
  %t71 = getelementptr inbounds i8, ptr %t70, i64 8
  %t72 = mul i64 1, 8
  %t73 = getelementptr inbounds i8, ptr %t71, i64 %t72
  %t74 = load i64, ptr %t73
  %t75 = add i64 %t69, %t74
  %t76 = load ptr, ptr %t32
  %t77 = getelementptr inbounds i8, ptr %t76, i64 8
  %t78 = mul i64 2, 8
  %t79 = getelementptr inbounds i8, ptr %t77, i64 %t78
  %t80 = load i64, ptr %t79
  %t81 = add i64 %t75, %t80
  store i64 %t81, ptr %t37
  %t83 = load ptr, ptr %t32
  %t84 = getelementptr inbounds i8, ptr %t83, i64 8
  %t85 = mul i64 2, 8
  %t86 = getelementptr inbounds i8, ptr %t84, i64 %t85
  %t87 = load i64, ptr %t86
  store i64 %t87, ptr %t82
  %t88 = getelementptr inbounds [7 x i8], ptr @.str6, i64 0, i64 0
  %t89 = load i64, ptr %t37
  %t90 = call ptr @mire_i64_to_string(i64 %t89)
  %t91 = call ptr @concat(ptr %t88, ptr %t90)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t91)
  %t92 = getelementptr inbounds [6 x i8], ptr @.str7, i64 0, i64 0
  %t93 = load i64, ptr %t82
  %t94 = call ptr @mire_i64_to_string(i64 %t93)
  %t95 = call ptr @concat(ptr %t92, ptr %t94)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t95)
  %t96 = getelementptr inbounds [9 x i8], ptr @.str8, i64 0, i64 0
  %t97 = load i64, ptr %t0
  %t98 = call ptr @mire_wall_elapsed_ms_str(i64 %t97)
  %t99 = call ptr @concat(ptr %t96, ptr %t98)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t99)
  %t100 = getelementptr inbounds [8 x i8], ptr @.str9, i64 0, i64 0
  %t101 = load i64, ptr %t2
  %t102 = call ptr @mire_cpu_elapsed_ms_str(i64 %t101)
  %t103 = call ptr @concat(ptr %t100, ptr %t102)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t103)
  %t104 = getelementptr inbounds [16 x i8], ptr @.str10, i64 0, i64 0
  %t105 = load i64, ptr %t2
  %t106 = call i64 @mire_cpu_cycles_est(i64 %t105)
  %t107 = call ptr @mire_i64_to_string(i64 %t106)
  %t108 = call ptr @concat(ptr %t104, ptr %t107)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t108)
  %t109 = getelementptr inbounds [13 x i8], ptr @.str11, i64 0, i64 0
  %t110 = call i64 @mire_mem_process_bytes()
  %t111 = call ptr @mire_mem_format(i64 %t110)
  %t112 = call ptr @concat(ptr %t109, ptr %t111)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t112)
  ret i32 0
}
