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
@.str1 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str2 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str3 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str4 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str5 = private unnamed_addr constant [2 x i8] c"a\00"
@.str6 = private unnamed_addr constant [2 x i8] c"A\00"
@.str7 = private unnamed_addr constant [8 x i8] c"counts \00"
@.str8 = private unnamed_addr constant [6 x i8] c"sums \00"
@.str9 = private unnamed_addr constant [12 x i8] c"report_len \00"
@.str10 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str11 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str12 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str13 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str14 = private unnamed_addr constant [5 x i8] c"gpu \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca ptr
  %t8 = alloca ptr
  %t11 = alloca i64
  %t14 = alloca ptr
  %t34 = alloca i64
  %t38 = alloca i64
  %t45 = alloca i64
  %t49 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t7 = inttoptr i64 0 to ptr
  store ptr %t7, ptr %t6
  %t9 = getelementptr inbounds [1 x i8], ptr @.str0, i64 0, i64 0
  %t10 = call ptr @mire_string_copy(ptr %t9)
  store ptr %t10, ptr %t8
  store i64 0, ptr %t11
  br label %while_cond_0
while_cond_0:
  %t12 = load i64, ptr %t11
  %t13 = icmp slt i64 %t12, 20000
  br i1 %t13, label %while_body_1, label %while_end_2
while_body_1:
  %t15 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t16 = call ptr @mire_string_copy(ptr %t15)
  store ptr %t16, ptr %t14
  %t17 = load i64, ptr %t11
  %t18 = urem i64 %t17, 7
  %t19 = icmp eq i64 %t18, 0
  br i1 %t19, label %if_then_3, label %if_else_4
if_then_3:
  %t20 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t21 = load ptr, ptr %t14
  call void @mire_string_free(ptr %t21)
  %t22 = call ptr @mire_string_copy(ptr %t20)
  store ptr %t22, ptr %t14
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t23 = load ptr, ptr %t14
  %t24 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t26 = call i32 @strcmp(ptr %t23, ptr %t24)
  %t25 = icmp eq i32 %t26, 0
  %t27 = load i64, ptr %t11
  %t28 = urem i64 %t27, 5
  %t29 = icmp eq i64 %t28, 0
  %t30 = and i1 %t25, %t29
  br i1 %t30, label %if_then_6, label %if_else_7
if_then_6:
  %t31 = getelementptr inbounds [5 x i8], ptr @.str4, i64 0, i64 0
  %t32 = load ptr, ptr %t14
  call void @mire_string_free(ptr %t32)
  %t33 = call ptr @mire_string_copy(ptr %t31)
  store ptr %t33, ptr %t14
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t35 = load ptr, ptr %t4
  %t36 = load ptr, ptr %t14
  %t37 = call i64 @mire_dict_get_i64(ptr %t35, i64 3, i64 0, ptr %t36, i64 0)
  store i64 %t37, ptr %t34
  %t39 = load i64, ptr %t34
  %t40 = add i64 %t39, 1
  store i64 %t40, ptr %t38
  %t41 = load ptr, ptr %t4
  %t42 = load ptr, ptr %t14
  %t43 = load i64, ptr %t38
  %t44 = call ptr @mire_dict_set_i64(ptr %t41, i64 3, i64 1, i64 0, ptr %t42, i64 %t43)
  store ptr %t44, ptr %t4
  %t46 = load ptr, ptr %t6
  %t47 = load ptr, ptr %t14
  %t48 = call i64 @mire_dict_get_i64(ptr %t46, i64 3, i64 0, ptr %t47, i64 0)
  store i64 %t48, ptr %t45
  %t50 = load i64, ptr %t45
  %t51 = load i64, ptr %t11
  %t52 = add i64 %t50, %t51
  store i64 %t52, ptr %t49
  %t53 = load ptr, ptr %t6
  %t54 = load ptr, ptr %t14
  %t55 = load i64, ptr %t49
  %t56 = call ptr @mire_dict_set_i64(ptr %t53, i64 3, i64 1, i64 0, ptr %t54, i64 %t55)
  store ptr %t56, ptr %t6
  %t57 = load i64, ptr %t11
  %t58 = urem i64 %t57, 1000
  %t59 = icmp eq i64 %t58, 0
  br i1 %t59, label %if_then_9, label %if_else_10
if_then_9:
  %t60 = load ptr, ptr %t14
  %t61 = getelementptr inbounds [2 x i8], ptr @.str5, i64 0, i64 0
  %t62 = getelementptr inbounds [2 x i8], ptr @.str6, i64 0, i64 0
  %t63 = call ptr @mire_strings_replace(ptr %t60, ptr %t61, ptr %t62)
  %t64 = load ptr, ptr %t8
  %t65 = call ptr @mire_string_append_owned(ptr %t64, ptr %t63)
  store ptr %t65, ptr %t8
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t66 = load i64, ptr %t11
  %t67 = add i64 %t66, 1
  store i64 %t67, ptr %t11
  br label %while_cond_0
while_end_2:
  %t68 = getelementptr inbounds [8 x i8], ptr @.str7, i64 0, i64 0
  %t69 = load ptr, ptr %t4
  %t70 = call ptr @mire_dict_to_string(ptr %t69)
  %t71 = call ptr @mire_string_concat(ptr %t68, ptr %t70)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t71)
  %t72 = getelementptr inbounds [6 x i8], ptr @.str8, i64 0, i64 0
  %t73 = load ptr, ptr %t6
  %t74 = call ptr @mire_dict_to_string(ptr %t73)
  %t75 = call ptr @mire_string_concat(ptr %t72, ptr %t74)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t75)
  %t76 = getelementptr inbounds [12 x i8], ptr @.str9, i64 0, i64 0
  %t77 = load ptr, ptr %t8
  %t78 = call i64 @strlen(ptr %t77)
  %t79 = call ptr @mire_i64_to_string(i64 %t78)
  %t80 = call ptr @mire_string_concat(ptr %t76, ptr %t79)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t80)
  %t81 = getelementptr inbounds [9 x i8], ptr @.str10, i64 0, i64 0
  %t82 = load i64, ptr %t0
  %t83 = call ptr @mire_wall_elapsed_ms_str(i64 %t82)
  %t84 = call ptr @mire_string_concat(ptr %t81, ptr %t83)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t84)
  %t85 = getelementptr inbounds [8 x i8], ptr @.str11, i64 0, i64 0
  %t86 = load i64, ptr %t2
  %t87 = call ptr @mire_cpu_elapsed_ms_str(i64 %t86)
  %t88 = call ptr @mire_string_concat(ptr %t85, ptr %t87)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t88)
  %t89 = getelementptr inbounds [16 x i8], ptr @.str12, i64 0, i64 0
  %t90 = load i64, ptr %t2
  %t91 = call i64 @mire_cpu_cycles_est(i64 %t90)
  %t92 = call ptr @mire_i64_to_string(i64 %t91)
  %t93 = call ptr @mire_string_concat(ptr %t89, ptr %t92)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t93)
  %t94 = getelementptr inbounds [13 x i8], ptr @.str13, i64 0, i64 0
  %t95 = call i64 @mire_mem_process_bytes()
  %t96 = call ptr @mire_mem_format(i64 %t95)
  %t97 = call ptr @mire_string_concat(ptr %t94, ptr %t96)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t97)
  %t98 = getelementptr inbounds [5 x i8], ptr @.str14, i64 0, i64 0
  %t99 = call ptr @mire_gpu_snapshot()
  %t100 = call ptr @mire_string_concat(ptr %t98, ptr %t99)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t100)
  ret i32 0
}
