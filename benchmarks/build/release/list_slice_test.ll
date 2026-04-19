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
@.str0 = private unnamed_addr constant [7 x i8] c"first \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [12 x i8] c"sliced_len \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca ptr
  %t4 = alloca i64
  %t12 = alloca i64
  %t18 = alloca i64
  %t24 = alloca ptr
  %t42 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = inttoptr i64 0 to ptr
  store ptr %t3, ptr %t2
  store i64 0, ptr %t4
  br label %while_cond_0
while_cond_0:
  %t5 = load i64, ptr %t4
  %t6 = icmp slt i64 %t5, 10000
  br i1 %t6, label %while_body_1, label %while_end_2
while_body_1:
  %t7 = load ptr, ptr %t2
  %t8 = load i64, ptr %t4
  %t9 = call ptr @mire_list_push_i64(ptr %t7, i64 %t8)
  store ptr %t9, ptr %t2
  %t10 = load i64, ptr %t4
  %t11 = add i64 %t10, 1
  store i64 %t11, ptr %t4
  br label %while_cond_0
while_end_2:
  %t13 = load ptr, ptr %t2
  %t14 = bitcast ptr %t13 to ptr
  %t15 = mul i64 0, 8
  %t16 = getelementptr inbounds i8, ptr %t14, i64 %t15
  %t17 = load i64, ptr %t16
  store i64 %t17, ptr %t12
  %t19 = load ptr, ptr %t2
  %t20 = bitcast ptr %t19 to ptr
  %t21 = mul i64 9999, 8
  %t22 = getelementptr inbounds i8, ptr %t20, i64 %t21
  %t23 = load i64, ptr %t22
  store i64 %t23, ptr %t18
  %t25 = load ptr, ptr %t2
  %t26 = call ptr @mire_list_slice(ptr %t25, i64 100, i64 200)
  store ptr %t26, ptr %t24
  %t27 = getelementptr inbounds [7 x i8], ptr @.str0, i64 0, i64 0
  %t28 = load i64, ptr %t12
  %t29 = call ptr @mire_i64_to_string(i64 %t28)
  %t30 = call ptr @mire_string_concat(ptr %t27, ptr %t29)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t30)
  %t31 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t32 = load i64, ptr %t18
  %t33 = call ptr @mire_i64_to_string(i64 %t32)
  %t34 = call ptr @mire_string_concat(ptr %t31, ptr %t33)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t34)
  %t35 = getelementptr inbounds [12 x i8], ptr @.str2, i64 0, i64 0
  %t36 = load ptr, ptr %t24
  %t37 = load ptr, ptr %t24
  %t38 = getelementptr inbounds i8, ptr %t37, i64 -8
  %t39 = icmp eq ptr %t38, null
  br i1 %t39, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t42
  br label %list_len_end_5
list_len_load_4:
  %t40 = load i64, ptr %t38
  store i64 %t40, ptr %t42
  br label %list_len_end_5
list_len_end_5:
  %t41 = load i64, ptr %t42
  %t43 = call ptr @mire_i64_to_string(i64 %t41)
  %t44 = call ptr @mire_string_concat(ptr %t35, ptr %t43)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t44)
  %t45 = getelementptr inbounds [9 x i8], ptr @.str3, i64 0, i64 0
  %t46 = load i64, ptr %t0
  %t47 = call ptr @mire_wall_elapsed_ms_str(i64 %t46)
  %t48 = call ptr @mire_string_concat(ptr %t45, ptr %t47)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t48)
  ret i32 0
}
