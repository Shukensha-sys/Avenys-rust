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
@.str1 = private unnamed_addr constant [10 x i8] c"checksum \00"
@.str2 = private unnamed_addr constant [9 x i8] c"tag_len \00"
@.str3 = private unnamed_addr constant [19 x i8] c"avenys-flow-stress\00"

define i64 @fn_weight(i64 %arg_x, i64 %arg_y) {
entry:
  %t0 = alloca i64
  %t1 = alloca i64
  %t2 = alloca i64
  %t8 = alloca i64
  %t11 = alloca i64
  store i64 %arg_x, ptr %t0
  store i64 %arg_y, ptr %t1
  %t3 = load i64, ptr %t0
  %t4 = mul i64 %t3, 17
  %t5 = load i64, ptr %t1
  %t6 = mul i64 %t5, 23
  %t7 = add i64 %t4, %t6
  store i64 %t7, ptr %t2
  %t9 = load i64, ptr %t2
  %t10 = udiv i64 %t9, 2
  %t12 = load i64, ptr %t2
  %t13 = urem i64 %t12, 2
  %t14 = icmp eq i64 %t13, 0
  br i1 %t14, label %ifexpr_then_0, label %ifexpr_else_1
ifexpr_then_0:
  store i64 %t10, ptr %t11
  br label %ifexpr_end_2
ifexpr_else_1:
  %t15 = load i64, ptr %t2
  %t16 = mul i64 %t15, 3
  %t17 = sub i64 %t16, 1
  store i64 %t17, ptr %t11
  br label %ifexpr_end_2
ifexpr_end_2:
  %t18 = load i64, ptr %t11
  store i64 %t18, ptr %t8
  %t19 = load i64, ptr %t8
  %t20 = urem i64 %t19, 997
  ret i64 %t20
}
define i64 @mire_main() {
entry:
  %t21 = alloca i64
  %t22 = alloca i64
  %t23 = alloca i64
  %t26 = alloca i64
  %t31 = alloca i1
  %t35 = alloca i64
  %t59 = alloca i64
  store i64 0, ptr %t21
  store i64 0, ptr %t22
  store i64 0, ptr %t23
  br label %while_cond_3
while_cond_3:
  %t24 = load i64, ptr %t21
  %t25 = icmp slt i64 %t24, 18000
  br i1 %t25, label %while_body_4, label %while_end_5
while_body_4:
  store i64 0, ptr %t26
  br label %for_cond_6
for_cond_6:
  %t27 = icmp sgt i64 1, 0
  %t28 = load i64, ptr %t26
  br i1 %t27, label %for_positive_9, label %for_negative_10
for_positive_9:
  %t29 = icmp slt i64 %t28, 64
  store i1 %t29, ptr %t31
  br label %for_cond_merge_11
for_negative_10:
  %t30 = icmp sgt i64 %t28, 64
  store i1 %t30, ptr %t31
  br label %for_cond_merge_11
for_cond_merge_11:
  %t32 = load i1, ptr %t31
  br i1 %t32, label %for_body_7, label %for_end_12
for_body_7:
  %t33 = load i64, ptr %t26
  %t34 = icmp eq i64 %t33, 7
  br i1 %t34, label %if_then_13, label %if_else_14
if_then_13:
  br label %for_continue_8
  br label %if_end_15
if_else_14:
  br label %if_end_15
if_end_15:
  %t36 = load i64, ptr %t21
  %t37 = load i64, ptr %t26
  %t38 = call i64 @fn_weight(i64 %t36, i64 %t37)
  store i64 %t38, ptr %t35
  %t39 = load i64, ptr %t22
  %t40 = load i64, ptr %t35
  %t41 = add i64 %t39, %t40
  store i64 %t41, ptr %t22
  %t42 = load i64, ptr %t35
  %t43 = urem i64 %t42, 11
  %t44 = icmp eq i64 %t43, 0
  br i1 %t44, label %if_then_16, label %if_else_17
if_then_16:
  %t45 = load i64, ptr %t23
  %t46 = load i64, ptr %t35
  %t47 = udiv i64 %t46, 11
  %t48 = add i64 %t45, %t47
  store i64 %t48, ptr %t23
  br label %if_end_18
if_else_17:
  br label %if_end_18
if_end_18:
  %t49 = load i64, ptr %t26
  %t50 = icmp eq i64 %t49, 61
  %t51 = load i64, ptr %t21
  %t52 = urem i64 %t51, 97
  %t53 = icmp eq i64 %t52, 0
  %t54 = and i1 %t50, %t53
  br i1 %t54, label %if_then_19, label %if_else_20
if_then_19:
  br label %for_end_12
  br label %if_end_21
if_else_20:
  br label %if_end_21
if_end_21:
  br label %for_continue_8
for_continue_8:
  %t55 = load i64, ptr %t26
  %t56 = add i64 %t55, 1
  store i64 %t56, ptr %t26
  br label %for_cond_6
for_end_12:
  %t57 = load i64, ptr %t21
  %t58 = add i64 %t57, 1
  store i64 %t58, ptr %t21
  br label %while_cond_3
while_end_5:
  store i64 0, ptr %t59
  br label %dowhile_body_22
dowhile_body_22:
  %t60 = load i64, ptr %t59
  %t61 = add i64 %t60, 1
  store i64 %t61, ptr %t59
  %t62 = load i64, ptr %t23
  %t63 = load i64, ptr %t59
  %t64 = add i64 %t62, %t63
  store i64 %t64, ptr %t23
  br label %dowhile_cond_23
dowhile_cond_23:
  %t65 = load i64, ptr %t59
  %t66 = icmp ne i64 %t65, 128
  br i1 %t66, label %dowhile_body_22, label %dowhile_end_24
dowhile_end_24:
  %t67 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t68 = load i64, ptr %t22
  %t69 = call ptr @mire_i64_to_string(i64 %t68)
  %t70 = call ptr @mire_string_concat(ptr %t67, ptr %t69)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t70)
  %t71 = getelementptr inbounds [10 x i8], ptr @.str1, i64 0, i64 0
  %t72 = load i64, ptr %t23
  %t73 = call ptr @mire_i64_to_string(i64 %t72)
  %t74 = call ptr @mire_string_concat(ptr %t71, ptr %t73)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t74)
  %t75 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t76 = getelementptr inbounds [19 x i8], ptr @.str3, i64 0, i64 0
  %t77 = call i64 @strlen(ptr %t76)
  %t78 = call ptr @mire_i64_to_string(i64 %t77)
  %t79 = call ptr @mire_string_concat(ptr %t75, ptr %t78)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t79)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
