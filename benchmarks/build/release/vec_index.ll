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
@.str0 = private unnamed_addr constant [5 x i8] c"val \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [5 x i8] c"len \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t14 = alloca i64
  %t20 = alloca i64
  %t26 = alloca i64
  %t51 = alloca i64
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
  %t8 = icmp slt i64 %t7, 10000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t9 = load ptr, ptr %t4
  %t10 = load i64, ptr %t6
  %t11 = call ptr @mire_list_push_i64(ptr %t9, i64 %t10)
  store ptr %t11, ptr %t4
  %t12 = load i64, ptr %t6
  %t13 = add i64 %t12, 1
  store i64 %t13, ptr %t6
  br label %while_cond_0
while_end_2:
  %t15 = load ptr, ptr %t4
  %t16 = bitcast ptr %t15 to ptr
  %t17 = mul i64 5000, 8
  %t18 = getelementptr inbounds i8, ptr %t16, i64 %t17
  %t19 = load i64, ptr %t18
  store i64 %t19, ptr %t14
  %t21 = load ptr, ptr %t4
  %t22 = bitcast ptr %t21 to ptr
  %t23 = mul i64 9999, 8
  %t24 = getelementptr inbounds i8, ptr %t22, i64 %t23
  %t25 = load i64, ptr %t24
  store i64 %t25, ptr %t20
  %t27 = load ptr, ptr %t4
  %t28 = bitcast ptr %t27 to ptr
  %t29 = mul i64 0, 8
  %t30 = getelementptr inbounds i8, ptr %t28, i64 %t29
  %t31 = load i64, ptr %t30
  store i64 %t31, ptr %t26
  %t32 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t33 = load i64, ptr %t14
  %t34 = call ptr @mire_i64_to_string(i64 %t33)
  %t35 = call ptr @mire_string_concat(ptr %t32, ptr %t34)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t35)
  %t36 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t37 = load i64, ptr %t20
  %t38 = call ptr @mire_i64_to_string(i64 %t37)
  %t39 = call ptr @mire_string_concat(ptr %t36, ptr %t38)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t39)
  %t40 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t41 = load i64, ptr %t26
  %t42 = call ptr @mire_i64_to_string(i64 %t41)
  %t43 = call ptr @mire_string_concat(ptr %t40, ptr %t42)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t43)
  %t44 = getelementptr inbounds [5 x i8], ptr @.str3, i64 0, i64 0
  %t45 = load ptr, ptr %t4
  %t46 = load ptr, ptr %t4
  %t47 = getelementptr inbounds i8, ptr %t46, i64 -8
  %t48 = icmp eq ptr %t47, null
  br i1 %t48, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t51
  br label %list_len_end_5
list_len_load_4:
  %t49 = load i64, ptr %t47
  store i64 %t49, ptr %t51
  br label %list_len_end_5
list_len_end_5:
  %t50 = load i64, ptr %t51
  %t52 = call ptr @mire_i64_to_string(i64 %t50)
  %t53 = call ptr @mire_string_concat(ptr %t44, ptr %t52)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t53)
  %t54 = getelementptr inbounds [9 x i8], ptr @.str4, i64 0, i64 0
  %t55 = load i64, ptr %t0
  %t56 = call ptr @mire_wall_elapsed_ms_str(i64 %t55)
  %t57 = call ptr @mire_string_concat(ptr %t54, ptr %t56)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t57)
  %t58 = getelementptr inbounds [8 x i8], ptr @.str5, i64 0, i64 0
  %t59 = load i64, ptr %t2
  %t60 = call ptr @mire_cpu_elapsed_ms_str(i64 %t59)
  %t61 = call ptr @mire_string_concat(ptr %t58, ptr %t60)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t61)
  ret i32 0
}
