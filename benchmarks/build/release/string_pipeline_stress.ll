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
@.str1 = private unnamed_addr constant [15 x i8] c" pending_item \00"
@.str2 = private unnamed_addr constant [9 x i8] c"out_len \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t1 = alloca ptr
  %t6 = alloca ptr
  store i64 0, ptr %t0
  %t2 = getelementptr inbounds [1 x i8], ptr @.str0, i64 0, i64 0
  %t3 = call ptr @mire_string_copy(ptr %t2)
  store ptr %t3, ptr %t1
  br label %while_cond_0
while_cond_0:
  %t4 = load i64, ptr %t0
  %t5 = icmp slt i64 %t4, 8000
  br i1 %t5, label %while_body_1, label %while_end_2
while_body_1:
  %t7 = getelementptr inbounds [15 x i8], ptr @.str1, i64 0, i64 0
  %t8 = call ptr @mire_string_copy(ptr %t7)
  store ptr %t8, ptr %t6
  %t9 = load ptr, ptr %t6
  %t10 = call ptr @mire_string_to_upper(ptr %t9)
  %t11 = load ptr, ptr %t6
  call void @mire_string_free(ptr %t11)
  store ptr %t10, ptr %t6
  %t12 = load ptr, ptr %t6
  %t13 = call ptr @mire_strings_trim(ptr %t12)
  %t14 = load ptr, ptr %t6
  call void @mire_string_free(ptr %t14)
  store ptr %t13, ptr %t6
  %t15 = load ptr, ptr %t6
  %t16 = load ptr, ptr %t1
  %t17 = call ptr @mire_string_append_owned(ptr %t16, ptr %t15)
  store ptr %t17, ptr %t1
  %t18 = load i64, ptr %t0
  %t19 = add i64 %t18, 1
  store i64 %t19, ptr %t0
  br label %while_cond_0
while_end_2:
  %t20 = getelementptr inbounds [9 x i8], ptr @.str2, i64 0, i64 0
  %t21 = load ptr, ptr %t1
  %t22 = call i64 @strlen(ptr %t21)
  %t23 = call ptr @mire_i64_to_string(i64 %t22)
  %t24 = call ptr @mire_string_concat(ptr %t20, ptr %t23)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t24)
  ret i32 0
}
