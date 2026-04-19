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
@.str0 = private unnamed_addr constant [6 x i8] c"val1 \00"
@.str1 = private unnamed_addr constant [6 x i8] c"val2 \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t6 = alloca i64
  %t14 = alloca ptr
  %t16 = alloca i64
  %t22 = alloca i64
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
  store ptr %t15, ptr %t14
  %t17 = load ptr, ptr %t4
  %t18 = bitcast ptr %t17 to ptr
  %t19 = mul i64 0, 8
  %t20 = getelementptr inbounds i8, ptr %t18, i64 %t19
  %t21 = load i64, ptr %t20
  store i64 %t21, ptr %t16
  %t23 = load ptr, ptr %t14
  %t24 = bitcast ptr %t23 to ptr
  %t25 = mul i64 0, 8
  %t26 = getelementptr inbounds i8, ptr %t24, i64 %t25
  %t27 = load i64, ptr %t26
  store i64 %t27, ptr %t22
  %t28 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t29 = load i64, ptr %t16
  %t30 = call ptr @mire_i64_to_string(i64 %t29)
  %t31 = call ptr @mire_string_concat(ptr %t28, ptr %t30)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t31)
  %t32 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  %t33 = load i64, ptr %t22
  %t34 = call ptr @mire_i64_to_string(i64 %t33)
  %t35 = call ptr @mire_string_concat(ptr %t32, ptr %t34)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t35)
  %t36 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t37 = load i64, ptr %t0
  %t38 = call ptr @mire_wall_elapsed_ms_str(i64 %t37)
  %t39 = call ptr @mire_string_concat(ptr %t36, ptr %t38)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t39)
  %t40 = getelementptr inbounds [13 x i8], ptr @.str3, i64 0, i64 0
  %t41 = call i64 @mire_mem_process_bytes()
  %t42 = call ptr @mire_mem_format(i64 %t41)
  %t43 = call ptr @mire_string_concat(ptr %t40, ptr %t42)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t43)
  ret i32 0
}
