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
@.str0 = private unnamed_addr constant [7 x i8] c"score \00"
@.str1 = private unnamed_addr constant [7 x i8] c"flags \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str4 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str5 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t35 = alloca i64
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
  %t8 = icmp slt i64 %t7, 20000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t9 = load ptr, ptr %t4
  %t10 = load i64, ptr %t6
  %t11 = urem i64 %t10, 2
  %t12 = icmp eq i64 %t11, 0
  %t14 = zext i1 %t12 to i64
  %t13 = call ptr @mire_dict_set_i64(ptr %t9, i64 1, i64 2, i64 1, ptr null, i64 %t14)
  store ptr %t13, ptr %t4
  %t15 = load ptr, ptr %t4
  %t16 = load i64, ptr %t6
  %t17 = urem i64 %t16, 3
  %t18 = icmp eq i64 %t17, 0
  %t20 = zext i1 %t18 to i64
  %t19 = call ptr @mire_dict_set_i64(ptr %t15, i64 1, i64 2, i64 2, ptr null, i64 %t20)
  store ptr %t19, ptr %t4
  %t21 = load ptr, ptr %t4
  %t22 = load i64, ptr %t6
  %t23 = urem i64 %t22, 5
  %t24 = icmp eq i64 %t23, 0
  %t26 = zext i1 %t24 to i64
  %t25 = call ptr @mire_dict_set_i64(ptr %t21, i64 1, i64 2, i64 3, ptr null, i64 %t26)
  store ptr %t25, ptr %t4
  %t27 = load ptr, ptr %t4
  %t28 = load i64, ptr %t6
  %t29 = urem i64 %t28, 7
  %t30 = icmp eq i64 %t29, 0
  %t32 = zext i1 %t30 to i64
  %t31 = call ptr @mire_dict_set_i64(ptr %t27, i64 1, i64 2, i64 4, ptr null, i64 %t32)
  store ptr %t31, ptr %t4
  %t33 = load i64, ptr %t6
  %t34 = add i64 %t33, 1
  store i64 %t34, ptr %t6
  br label %while_cond_0
while_end_2:
  store i64 0, ptr %t35
  %t36 = load ptr, ptr %t4
  %t37 = zext i1 0 to i64
  %t38 = call i64 @mire_dict_get_i64(ptr %t36, i64 1, i64 1, ptr null, i64 %t37)
  %t39 = icmp ne i64 %t38, 0
  br i1 %t39, label %if_then_3, label %if_else_4
if_then_3:
  %t40 = load i64, ptr %t35
  %t41 = add i64 %t40, 1
  store i64 %t41, ptr %t35
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t42 = load ptr, ptr %t4
  %t43 = zext i1 0 to i64
  %t44 = call i64 @mire_dict_get_i64(ptr %t42, i64 1, i64 2, ptr null, i64 %t43)
  %t45 = icmp ne i64 %t44, 0
  br i1 %t45, label %if_then_6, label %if_else_7
if_then_6:
  %t46 = load i64, ptr %t35
  %t47 = add i64 %t46, 10
  store i64 %t47, ptr %t35
  br label %if_end_8
if_else_7:
  br label %if_end_8
if_end_8:
  %t48 = load ptr, ptr %t4
  %t49 = zext i1 0 to i64
  %t50 = call i64 @mire_dict_get_i64(ptr %t48, i64 1, i64 3, ptr null, i64 %t49)
  %t51 = icmp ne i64 %t50, 0
  br i1 %t51, label %if_then_9, label %if_else_10
if_then_9:
  %t52 = load i64, ptr %t35
  %t53 = add i64 %t52, 100
  store i64 %t53, ptr %t35
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t54 = load ptr, ptr %t4
  %t55 = zext i1 0 to i64
  %t56 = call i64 @mire_dict_get_i64(ptr %t54, i64 1, i64 4, ptr null, i64 %t55)
  %t57 = icmp ne i64 %t56, 0
  br i1 %t57, label %if_then_12, label %if_else_13
if_then_12:
  %t58 = load i64, ptr %t35
  %t59 = add i64 %t58, 1000
  store i64 %t59, ptr %t35
  br label %if_end_14
if_else_13:
  br label %if_end_14
if_end_14:
  %t60 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t61 = load i64, ptr %t35
  %t62 = call ptr @mire_i64_to_string(i64 %t61)
  %t63 = call ptr @mire_string_concat(ptr %t60, ptr %t62)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t63)
  %t64 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t65 = load ptr, ptr %t4
  %t66 = call ptr @mire_dict_to_string(ptr %t65)
  %t67 = call ptr @mire_string_concat(ptr %t64, ptr %t66)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t67)
  %t68 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t69 = load i64, ptr %t0
  %t70 = call ptr @mire_wall_elapsed_ms_str(i64 %t69)
  %t71 = call ptr @mire_string_concat(ptr %t68, ptr %t70)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t71)
  %t72 = getelementptr inbounds [8 x i8], ptr @.str3, i64 0, i64 0
  %t73 = load i64, ptr %t2
  %t74 = call ptr @mire_cpu_elapsed_ms_str(i64 %t73)
  %t75 = call ptr @mire_string_concat(ptr %t72, ptr %t74)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t75)
  %t76 = getelementptr inbounds [16 x i8], ptr @.str4, i64 0, i64 0
  %t77 = load i64, ptr %t2
  %t78 = call i64 @mire_cpu_cycles_est(i64 %t77)
  %t79 = call ptr @mire_i64_to_string(i64 %t78)
  %t80 = call ptr @mire_string_concat(ptr %t76, ptr %t79)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t80)
  %t81 = getelementptr inbounds [13 x i8], ptr @.str5, i64 0, i64 0
  %t82 = call i64 @mire_mem_process_bytes()
  %t83 = call ptr @mire_mem_format(i64 %t82)
  %t84 = call ptr @mire_string_concat(ptr %t81, ptr %t83)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t84)
  ret i32 0
}
