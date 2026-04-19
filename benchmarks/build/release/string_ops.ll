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
@.str0 = private unnamed_addr constant [12 x i8] c"Hello World\00"
@.str1 = private unnamed_addr constant [1 x i8] c"\00"
@.str2 = private unnamed_addr constant [6 x i8] c"world\00"
@.str3 = private unnamed_addr constant [5 x i8] c"mire\00"
@.str4 = private unnamed_addr constant [8 x i8] c"result \00"
@.str5 = private unnamed_addr constant [5 x i8] c"len \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t7 = alloca ptr
  %t10 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = getelementptr inbounds [12 x i8], ptr @.str0, i64 0, i64 0
  %t6 = call ptr @mire_string_copy(ptr %t5)
  store ptr %t6, ptr %t4
  %t8 = getelementptr inbounds [1 x i8], ptr @.str1, i64 0, i64 0
  %t9 = call ptr @mire_string_copy(ptr %t8)
  store ptr %t9, ptr %t7
  store i64 0, ptr %t10
  br label %while_cond_0
while_cond_0:
  %t11 = load i64, ptr %t10
  %t12 = icmp slt i64 %t11, 10000
  br i1 %t12, label %while_body_1, label %while_end_2
while_body_1:
  %t13 = load ptr, ptr %t4
  %t14 = call ptr @mire_string_to_upper(ptr %t13)
  %t15 = load ptr, ptr %t7
  call void @mire_string_free(ptr %t15)
  store ptr %t14, ptr %t7
  %t16 = load ptr, ptr %t7
  %t17 = call ptr @mire_string_to_lower(ptr %t16)
  %t18 = load ptr, ptr %t7
  call void @mire_string_free(ptr %t18)
  store ptr %t17, ptr %t7
  %t19 = load ptr, ptr %t7
  %t20 = getelementptr inbounds [6 x i8], ptr @.str2, i64 0, i64 0
  %t21 = getelementptr inbounds [5 x i8], ptr @.str3, i64 0, i64 0
  %t22 = call ptr @mire_strings_replace(ptr %t19, ptr %t20, ptr %t21)
  %t23 = load ptr, ptr %t7
  call void @mire_string_free(ptr %t23)
  store ptr %t22, ptr %t7
  %t24 = load i64, ptr %t10
  %t25 = add i64 %t24, 1
  store i64 %t25, ptr %t10
  br label %while_cond_0
while_end_2:
  %t26 = getelementptr inbounds [8 x i8], ptr @.str4, i64 0, i64 0
  %t27 = load ptr, ptr %t7
  %t28 = call ptr @mire_string_concat(ptr %t26, ptr %t27)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t28)
  %t29 = getelementptr inbounds [5 x i8], ptr @.str5, i64 0, i64 0
  %t30 = load ptr, ptr %t7
  %t31 = call i64 @strlen(ptr %t30)
  %t32 = call ptr @mire_i64_to_string(i64 %t31)
  %t33 = call ptr @mire_string_concat(ptr %t29, ptr %t32)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t33)
  %t34 = getelementptr inbounds [9 x i8], ptr @.str6, i64 0, i64 0
  %t35 = load i64, ptr %t0
  %t36 = call ptr @mire_wall_elapsed_ms_str(i64 %t35)
  %t37 = call ptr @mire_string_concat(ptr %t34, ptr %t36)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t37)
  %t38 = getelementptr inbounds [8 x i8], ptr @.str7, i64 0, i64 0
  %t39 = load i64, ptr %t2
  %t40 = call ptr @mire_cpu_elapsed_ms_str(i64 %t39)
  %t41 = call ptr @mire_string_concat(ptr %t38, ptr %t40)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t41)
  %t42 = getelementptr inbounds [13 x i8], ptr @.str8, i64 0, i64 0
  %t43 = call i64 @mire_mem_process_bytes()
  %t44 = call ptr @mire_mem_format(i64 %t43)
  %t45 = call ptr @mire_string_concat(ptr %t42, ptr %t44)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t45)
  ret i32 0
}
