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
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str3 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t15 = alloca i64
  %t16 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = call i8* @malloc(i64 80)
  store i64 8, ptr %t5
  %t6 = getelementptr i8, ptr %t5, i64 8
  store i64 8, ptr %t6
  %t7 = getelementptr i8, ptr %t6, i64 8
  store i64 3, ptr %t7
  %t8 = getelementptr i8, ptr %t6, i64 16
  store i64 5, ptr %t8
  %t9 = getelementptr i8, ptr %t6, i64 24
  store i64 8, ptr %t9
  %t10 = getelementptr i8, ptr %t6, i64 32
  store i64 13, ptr %t10
  %t11 = getelementptr i8, ptr %t6, i64 40
  store i64 21, ptr %t11
  %t12 = getelementptr i8, ptr %t6, i64 48
  store i64 34, ptr %t12
  %t13 = getelementptr i8, ptr %t6, i64 56
  store i64 55, ptr %t13
  %t14 = getelementptr i8, ptr %t6, i64 64
  store i64 89, ptr %t14
  store ptr %t6, ptr %t4
  store i64 0, ptr %t15
  store i64 0, ptr %t16
  br label %while_cond_0
while_cond_0:
  %t17 = load i64, ptr %t15
  %t18 = icmp slt i64 %t17, 30000
  br i1 %t18, label %while_body_1, label %while_end_2
while_body_1:
  %t19 = load i64, ptr %t16
  %t20 = load ptr, ptr %t4
  %t21 = bitcast ptr %t20 to ptr
  %t22 = mul i64 0, 8
  %t23 = getelementptr inbounds i8, ptr %t21, i64 %t22
  %t24 = load i64, ptr %t23
  %t25 = add i64 %t19, %t24
  store i64 %t25, ptr %t16
  %t26 = load i64, ptr %t16
  %t27 = load ptr, ptr %t4
  %t28 = bitcast ptr %t27 to ptr
  %t29 = mul i64 1, 8
  %t30 = getelementptr inbounds i8, ptr %t28, i64 %t29
  %t31 = load i64, ptr %t30
  %t32 = add i64 %t26, %t31
  store i64 %t32, ptr %t16
  %t33 = load i64, ptr %t16
  %t34 = load ptr, ptr %t4
  %t35 = bitcast ptr %t34 to ptr
  %t36 = mul i64 2, 8
  %t37 = getelementptr inbounds i8, ptr %t35, i64 %t36
  %t38 = load i64, ptr %t37
  %t39 = add i64 %t33, %t38
  store i64 %t39, ptr %t16
  %t40 = load i64, ptr %t16
  %t41 = load ptr, ptr %t4
  %t42 = bitcast ptr %t41 to ptr
  %t43 = mul i64 3, 8
  %t44 = getelementptr inbounds i8, ptr %t42, i64 %t43
  %t45 = load i64, ptr %t44
  %t46 = add i64 %t40, %t45
  store i64 %t46, ptr %t16
  %t47 = load i64, ptr %t16
  %t48 = load ptr, ptr %t4
  %t49 = bitcast ptr %t48 to ptr
  %t50 = mul i64 4, 8
  %t51 = getelementptr inbounds i8, ptr %t49, i64 %t50
  %t52 = load i64, ptr %t51
  %t53 = add i64 %t47, %t52
  store i64 %t53, ptr %t16
  %t54 = load i64, ptr %t16
  %t55 = load ptr, ptr %t4
  %t56 = bitcast ptr %t55 to ptr
  %t57 = mul i64 5, 8
  %t58 = getelementptr inbounds i8, ptr %t56, i64 %t57
  %t59 = load i64, ptr %t58
  %t60 = add i64 %t54, %t59
  store i64 %t60, ptr %t16
  %t61 = load i64, ptr %t16
  %t62 = load ptr, ptr %t4
  %t63 = bitcast ptr %t62 to ptr
  %t64 = mul i64 6, 8
  %t65 = getelementptr inbounds i8, ptr %t63, i64 %t64
  %t66 = load i64, ptr %t65
  %t67 = add i64 %t61, %t66
  store i64 %t67, ptr %t16
  %t68 = load i64, ptr %t16
  %t69 = load ptr, ptr %t4
  %t70 = bitcast ptr %t69 to ptr
  %t71 = mul i64 7, 8
  %t72 = getelementptr inbounds i8, ptr %t70, i64 %t71
  %t73 = load i64, ptr %t72
  %t74 = add i64 %t68, %t73
  store i64 %t74, ptr %t16
  %t75 = load i64, ptr %t15
  %t76 = add i64 %t75, 1
  store i64 %t76, ptr %t15
  br label %while_cond_0
while_end_2:
  %t77 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t78 = load i64, ptr %t16
  %t79 = call ptr @mire_i64_to_string(i64 %t78)
  %t80 = call ptr @mire_string_concat(ptr %t77, ptr %t79)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t80)
  %t81 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t82 = load i64, ptr %t0
  %t83 = call ptr @mire_wall_elapsed_ms_str(i64 %t82)
  %t84 = call ptr @mire_string_concat(ptr %t81, ptr %t83)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t84)
  %t85 = getelementptr inbounds [8 x i8], ptr @.str2, i64 0, i64 0
  %t86 = load i64, ptr %t2
  %t87 = call ptr @mire_cpu_elapsed_ms_str(i64 %t86)
  %t88 = call ptr @mire_string_concat(ptr %t85, ptr %t87)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t88)
  %t89 = getelementptr inbounds [16 x i8], ptr @.str3, i64 0, i64 0
  %t90 = load i64, ptr %t2
  %t91 = call i64 @mire_cpu_cycles_est(i64 %t90)
  %t92 = call ptr @mire_i64_to_string(i64 %t91)
  %t93 = call ptr @mire_string_concat(ptr %t89, ptr %t92)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t93)
  %t94 = getelementptr inbounds [13 x i8], ptr @.str4, i64 0, i64 0
  %t95 = call i64 @mire_mem_process_bytes()
  %t96 = call ptr @mire_mem_format(i64 %t95)
  %t97 = call ptr @mire_string_concat(ptr %t94, ptr %t96)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t97)
  ret i32 0
}
