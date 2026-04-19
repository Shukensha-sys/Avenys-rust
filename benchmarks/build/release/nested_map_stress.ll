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
@.str0 = private unnamed_addr constant [2 x i8] c"x\00"
@.str1 = private unnamed_addr constant [2 x i8] c"y\00"
@.str2 = private unnamed_addr constant [2 x i8] c"x\00"
@.str3 = private unnamed_addr constant [2 x i8] c"y\00"
@.str4 = private unnamed_addr constant [2 x i8] c"x\00"
@.str5 = private unnamed_addr constant [2 x i8] c"y\00"
@.str6 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str7 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str8 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str9 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str10 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str11 = private unnamed_addr constant [2 x i8] c"x\00"
@.str12 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str13 = private unnamed_addr constant [2 x i8] c"y\00"
@.str14 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str15 = private unnamed_addr constant [2 x i8] c"x\00"
@.str16 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str17 = private unnamed_addr constant [2 x i8] c"y\00"
@.str18 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str19 = private unnamed_addr constant [2 x i8] c"x\00"
@.str20 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str21 = private unnamed_addr constant [2 x i8] c"y\00"
@.str22 = private unnamed_addr constant [2 x i8] c"y\00"
@.str23 = private unnamed_addr constant [8 x i8] c"groups \00"
@.str24 = private unnamed_addr constant [7 x i8] c"total \00"
@.str25 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str26 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str27 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str28 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str29 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t12 = alloca ptr
  %t20 = alloca ptr
  %t28 = alloca ptr
  %t30 = alloca ptr
  %t44 = alloca ptr
  %t49 = alloca i64
  %t91 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [2 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_dict_set_i64(ptr %t6, i64 3, i64 1, i64 0, ptr %t7, i64 11)
  store ptr %t8, ptr %t4
  %t9 = load ptr, ptr %t4
  %t10 = getelementptr inbounds [2 x i8], ptr @.str1, i64 0, i64 0
  %t11 = call ptr @mire_dict_set_i64(ptr %t9, i64 3, i64 1, i64 0, ptr %t10, i64 22)
  store ptr %t11, ptr %t4
  %t13 = inttoptr i64 0 to ptr
  store ptr %t13, ptr %t12
  %t14 = load ptr, ptr %t12
  %t15 = getelementptr inbounds [2 x i8], ptr @.str2, i64 0, i64 0
  %t16 = call ptr @mire_dict_set_i64(ptr %t14, i64 3, i64 1, i64 0, ptr %t15, i64 33)
  store ptr %t16, ptr %t12
  %t17 = load ptr, ptr %t12
  %t18 = getelementptr inbounds [2 x i8], ptr @.str3, i64 0, i64 0
  %t19 = call ptr @mire_dict_set_i64(ptr %t17, i64 3, i64 1, i64 0, ptr %t18, i64 44)
  store ptr %t19, ptr %t12
  %t21 = inttoptr i64 0 to ptr
  store ptr %t21, ptr %t20
  %t22 = load ptr, ptr %t20
  %t23 = getelementptr inbounds [2 x i8], ptr @.str4, i64 0, i64 0
  %t24 = call ptr @mire_dict_set_i64(ptr %t22, i64 3, i64 1, i64 0, ptr %t23, i64 55)
  store ptr %t24, ptr %t20
  %t25 = load ptr, ptr %t20
  %t26 = getelementptr inbounds [2 x i8], ptr @.str5, i64 0, i64 0
  %t27 = call ptr @mire_dict_set_i64(ptr %t25, i64 3, i64 1, i64 0, ptr %t26, i64 66)
  store ptr %t27, ptr %t20
  %t29 = inttoptr i64 0 to ptr
  store ptr %t29, ptr %t28
  %t31 = inttoptr i64 0 to ptr
  store ptr %t31, ptr %t30
  %t32 = load ptr, ptr %t30
  %t33 = getelementptr inbounds [6 x i8], ptr @.str6, i64 0, i64 0
  %t34 = load ptr, ptr %t4
  %t35 = call ptr @mire_dict_set_ptr(ptr %t32, i64 3, i64 4, i64 0, ptr %t33, ptr %t34)
  store ptr %t35, ptr %t30
  %t36 = load ptr, ptr %t30
  %t37 = getelementptr inbounds [5 x i8], ptr @.str7, i64 0, i64 0
  %t38 = load ptr, ptr %t12
  %t39 = call ptr @mire_dict_set_ptr(ptr %t36, i64 3, i64 4, i64 0, ptr %t37, ptr %t38)
  store ptr %t39, ptr %t30
  %t40 = load ptr, ptr %t30
  %t41 = getelementptr inbounds [6 x i8], ptr @.str8, i64 0, i64 0
  %t42 = load ptr, ptr %t20
  %t43 = call ptr @mire_dict_set_ptr(ptr %t40, i64 3, i64 4, i64 0, ptr %t41, ptr %t42)
  store ptr %t43, ptr %t30
  %t45 = load ptr, ptr %t30
  %t46 = getelementptr inbounds [5 x i8], ptr @.str9, i64 0, i64 0
  %t47 = load ptr, ptr %t28
  %t48 = call ptr @mire_dict_get_ptr(ptr %t45, i64 3, i64 0, ptr %t46, ptr %t47)
  store ptr %t48, ptr %t44
  %t50 = load ptr, ptr %t30
  %t51 = getelementptr inbounds [6 x i8], ptr @.str10, i64 0, i64 0
  %t52 = load ptr, ptr %t28
  %t53 = call ptr @mire_dict_get_ptr(ptr %t50, i64 3, i64 0, ptr %t51, ptr %t52)
  %t54 = getelementptr inbounds [2 x i8], ptr @.str11, i64 0, i64 0
  %t55 = call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr %t54, i64 0)
  %t56 = load ptr, ptr %t30
  %t57 = getelementptr inbounds [6 x i8], ptr @.str12, i64 0, i64 0
  %t58 = load ptr, ptr %t28
  %t59 = call ptr @mire_dict_get_ptr(ptr %t56, i64 3, i64 0, ptr %t57, ptr %t58)
  %t60 = getelementptr inbounds [2 x i8], ptr @.str13, i64 0, i64 0
  %t61 = call i64 @mire_dict_get_i64(ptr %t59, i64 3, i64 0, ptr %t60, i64 0)
  %t62 = add i64 %t55, %t61
  %t63 = load ptr, ptr %t30
  %t64 = getelementptr inbounds [5 x i8], ptr @.str14, i64 0, i64 0
  %t65 = load ptr, ptr %t28
  %t66 = call ptr @mire_dict_get_ptr(ptr %t63, i64 3, i64 0, ptr %t64, ptr %t65)
  %t67 = getelementptr inbounds [2 x i8], ptr @.str15, i64 0, i64 0
  %t68 = call i64 @mire_dict_get_i64(ptr %t66, i64 3, i64 0, ptr %t67, i64 0)
  %t69 = add i64 %t62, %t68
  %t70 = load ptr, ptr %t30
  %t71 = getelementptr inbounds [5 x i8], ptr @.str16, i64 0, i64 0
  %t72 = load ptr, ptr %t28
  %t73 = call ptr @mire_dict_get_ptr(ptr %t70, i64 3, i64 0, ptr %t71, ptr %t72)
  %t74 = getelementptr inbounds [2 x i8], ptr @.str17, i64 0, i64 0
  %t75 = call i64 @mire_dict_get_i64(ptr %t73, i64 3, i64 0, ptr %t74, i64 0)
  %t76 = add i64 %t69, %t75
  %t77 = load ptr, ptr %t30
  %t78 = getelementptr inbounds [6 x i8], ptr @.str18, i64 0, i64 0
  %t79 = load ptr, ptr %t28
  %t80 = call ptr @mire_dict_get_ptr(ptr %t77, i64 3, i64 0, ptr %t78, ptr %t79)
  %t81 = getelementptr inbounds [2 x i8], ptr @.str19, i64 0, i64 0
  %t82 = call i64 @mire_dict_get_i64(ptr %t80, i64 3, i64 0, ptr %t81, i64 0)
  %t83 = add i64 %t76, %t82
  %t84 = load ptr, ptr %t30
  %t85 = getelementptr inbounds [6 x i8], ptr @.str20, i64 0, i64 0
  %t86 = load ptr, ptr %t28
  %t87 = call ptr @mire_dict_get_ptr(ptr %t84, i64 3, i64 0, ptr %t85, ptr %t86)
  %t88 = getelementptr inbounds [2 x i8], ptr @.str21, i64 0, i64 0
  %t89 = call i64 @mire_dict_get_i64(ptr %t87, i64 3, i64 0, ptr %t88, i64 0)
  %t90 = add i64 %t83, %t89
  store i64 %t90, ptr %t49
  %t92 = load ptr, ptr %t44
  %t93 = getelementptr inbounds [2 x i8], ptr @.str22, i64 0, i64 0
  %t94 = call i64 @mire_dict_get_i64(ptr %t92, i64 3, i64 0, ptr %t93, i64 0)
  store i64 %t94, ptr %t91
  %t95 = getelementptr inbounds [8 x i8], ptr @.str23, i64 0, i64 0
  %t96 = load ptr, ptr %t30
  %t97 = call ptr @mire_dict_to_string(ptr %t96)
  %t98 = call ptr @concat(ptr %t95, ptr %t97)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t98)
  %t99 = getelementptr inbounds [7 x i8], ptr @.str24, i64 0, i64 0
  %t100 = load i64, ptr %t49
  %t101 = call ptr @mire_i64_to_string(i64 %t100)
  %t102 = call ptr @concat(ptr %t99, ptr %t101)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t102)
  %t103 = getelementptr inbounds [6 x i8], ptr @.str25, i64 0, i64 0
  %t104 = load i64, ptr %t91
  %t105 = call ptr @mire_i64_to_string(i64 %t104)
  %t106 = call ptr @concat(ptr %t103, ptr %t105)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t106)
  %t107 = getelementptr inbounds [9 x i8], ptr @.str26, i64 0, i64 0
  %t108 = load i64, ptr %t0
  %t109 = call ptr @mire_wall_elapsed_ms_str(i64 %t108)
  %t110 = call ptr @concat(ptr %t107, ptr %t109)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t110)
  %t111 = getelementptr inbounds [8 x i8], ptr @.str27, i64 0, i64 0
  %t112 = load i64, ptr %t2
  %t113 = call ptr @mire_cpu_elapsed_ms_str(i64 %t112)
  %t114 = call ptr @concat(ptr %t111, ptr %t113)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t114)
  %t115 = getelementptr inbounds [16 x i8], ptr @.str28, i64 0, i64 0
  %t116 = load i64, ptr %t2
  %t117 = call i64 @mire_cpu_cycles_est(i64 %t116)
  %t118 = call ptr @mire_i64_to_string(i64 %t117)
  %t119 = call ptr @concat(ptr %t115, ptr %t118)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t119)
  %t120 = getelementptr inbounds [13 x i8], ptr @.str29, i64 0, i64 0
  %t121 = call i64 @mire_mem_process_bytes()
  %t122 = call ptr @mire_mem_format(i64 %t121)
  %t123 = call ptr @concat(ptr %t120, ptr %t122)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t123)
  ret i32 0
}
