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
@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [12 x i8] c"elapsed_ms \00"
@.str2 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t3 = alloca i64
  %t4 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  store i64 1000000, ptr %t2
  store i64 0, ptr %t3
  store i64 0, ptr %t4
  br label %while_cond_0
while_cond_0:
  %t5 = load i64, ptr %t3
  %t6 = load i64, ptr %t2
  %t7 = icmp slt i64 %t5, %t6
  br i1 %t7, label %while_body_1, label %while_end_2
while_body_1:
  %t8 = load i64, ptr %t4
  %t9 = load i64, ptr %t3
  %t10 = add i64 %t8, %t9
  store i64 %t10, ptr %t4
  %t11 = load i64, ptr %t3
  %t12 = add i64 %t11, 1
  store i64 %t12, ptr %t3
  br label %while_cond_0
while_end_2:
  %t13 = getelementptr inbounds [8 x i8], ptr @.str0, i64 0, i64 0
  %t14 = load i64, ptr %t4
  %t15 = call ptr @mire_i64_to_string(i64 %t14)
  %t16 = call ptr @mire_string_concat(ptr %t13, ptr %t15)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t16)
  %t17 = getelementptr inbounds [12 x i8], ptr @.str1, i64 0, i64 0
  %t18 = load i64, ptr %t0
  %t19 = call ptr @mire_wall_elapsed_ms_str(i64 %t18)
  %t20 = call ptr @mire_string_concat(ptr %t17, ptr %t19)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t20)
  %t21 = getelementptr inbounds [13 x i8], ptr @.str2, i64 0, i64 0
  %t22 = call i64 @mire_mem_process_bytes()
  %t23 = call ptr @mire_mem_format(i64 %t22)
  %t24 = call ptr @mire_string_concat(ptr %t21, ptr %t23)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t24)
  ret i32 0
}
