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
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [6 x i8] c"last \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str6 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str7 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t17 = alloca i64
  %t18 = alloca i64
  %t26 = alloca i64
  %t50 = alloca i64
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
  %t13 = call ptr @mire_list_push_scalar(ptr %t9, i64 %t14, i64 1)
  store ptr %t13, ptr %t4
  %t15 = load i64, ptr %t6
  %t16 = add i64 %t15, 1
  store i64 %t16, ptr %t6
  br label %while_cond_0
while_end_2:
  store i64 0, ptr %t17
  store i64 0, ptr %t18
  br label %while_cond_3
while_cond_3:
  %t19 = load i64, ptr %t18
  %t20 = load ptr, ptr %t4
  %t21 = load ptr, ptr %t4
  %t22 = getelementptr inbounds i8, ptr %t21, i64 -8
  %t23 = icmp eq ptr %t22, null
  br i1 %t23, label %list_len_null_6, label %list_len_load_7
list_len_null_6:
  store i64 0, ptr %t26
  br label %list_len_end_8
list_len_load_7:
  %t24 = load i64, ptr %t22
  store i64 %t24, ptr %t26
  br label %list_len_end_8
list_len_end_8:
  %t25 = load i64, ptr %t26
  %t27 = icmp slt i64 %t19, %t25
  br i1 %t27, label %while_body_4, label %while_end_5
while_body_4:
  %t28 = load ptr, ptr %t4
  %t29 = load i64, ptr %t18
  %t30 = bitcast ptr %t28 to ptr
  %t31 = mul i64 %t29, 1
  %t32 = getelementptr inbounds i8, ptr %t30, i64 %t31
  %t33 = load i8, ptr %t32
  %t34 = icmp ne i8 %t33, 0
  br i1 %t34, label %if_then_9, label %if_else_10
if_then_9:
  %t35 = load i64, ptr %t17
  %t36 = add i64 %t35, 1
  store i64 %t36, ptr %t17
  br label %if_end_11
if_else_10:
  br label %if_end_11
if_end_11:
  %t37 = load i64, ptr %t18
  %t38 = add i64 %t37, 1
  store i64 %t38, ptr %t18
  br label %while_cond_3
while_end_5:
  %t39 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t40 = load i64, ptr %t17
  %t41 = call ptr @mire_i64_to_string(i64 %t40)
  %t42 = call ptr @mire_string_concat(ptr %t39, ptr %t41)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t42)
  %t43 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t44 = load ptr, ptr %t4
  %t45 = load ptr, ptr %t4
  %t46 = getelementptr inbounds i8, ptr %t45, i64 -8
  %t47 = icmp eq ptr %t46, null
  br i1 %t47, label %list_len_null_12, label %list_len_load_13
list_len_null_12:
  store i64 0, ptr %t50
  br label %list_len_end_14
list_len_load_13:
  %t48 = load i64, ptr %t46
  store i64 %t48, ptr %t50
  br label %list_len_end_14
list_len_end_14:
  %t49 = load i64, ptr %t50
  %t51 = call ptr @mire_i64_to_string(i64 %t49)
  %t52 = call ptr @mire_string_concat(ptr %t43, ptr %t51)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t52)
  %t53 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t54 = load ptr, ptr %t4
  %t55 = bitcast ptr %t54 to ptr
  %t56 = mul i64 0, 1
  %t57 = getelementptr inbounds i8, ptr %t55, i64 %t56
  %t58 = load i8, ptr %t57
  %t59 = icmp ne i8 %t58, 0
  %t60 = zext i1 %t59 to i64
  %t61 = call ptr @mire_bool_to_string(i64 %t60)
  %t62 = call ptr @mire_string_concat(ptr %t53, ptr %t61)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t62)
  %t63 = getelementptr inbounds [6 x i8], ptr @.str3, i64 0, i64 0
  %t64 = load ptr, ptr %t4
  %t65 = bitcast ptr %t64 to ptr
  %t66 = mul i64 19999, 1
  %t67 = getelementptr inbounds i8, ptr %t65, i64 %t66
  %t68 = load i8, ptr %t67
  %t69 = icmp ne i8 %t68, 0
  %t70 = zext i1 %t69 to i64
  %t71 = call ptr @mire_bool_to_string(i64 %t70)
  %t72 = call ptr @mire_string_concat(ptr %t63, ptr %t71)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t72)
  %t73 = getelementptr inbounds [9 x i8], ptr @.str4, i64 0, i64 0
  %t74 = load i64, ptr %t0
  %t75 = call ptr @mire_wall_elapsed_ms_str(i64 %t74)
  %t76 = call ptr @mire_string_concat(ptr %t73, ptr %t75)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t76)
  %t77 = getelementptr inbounds [8 x i8], ptr @.str5, i64 0, i64 0
  %t78 = load i64, ptr %t2
  %t79 = call ptr @mire_cpu_elapsed_ms_str(i64 %t78)
  %t80 = call ptr @mire_string_concat(ptr %t77, ptr %t79)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t80)
  %t81 = getelementptr inbounds [16 x i8], ptr @.str6, i64 0, i64 0
  %t82 = load i64, ptr %t2
  %t83 = call i64 @mire_cpu_cycles_est(i64 %t82)
  %t84 = call ptr @mire_i64_to_string(i64 %t83)
  %t85 = call ptr @mire_string_concat(ptr %t81, ptr %t84)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t85)
  %t86 = getelementptr inbounds [13 x i8], ptr @.str7, i64 0, i64 0
  %t87 = call i64 @mire_mem_process_bytes()
  %t88 = call ptr @mire_mem_format(i64 %t87)
  %t89 = call ptr @mire_string_concat(ptr %t86, ptr %t88)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t89)
  ret i32 0
}
