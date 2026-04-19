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
@.str0 = private unnamed_addr constant [5 x i8] c"len \00"
@.str1 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i64 @mire_main() {
entry:
  %t0 = alloca ptr
  %t2 = alloca i64
  %t20 = alloca i64
  %t1 = inttoptr i64 0 to ptr
  store ptr %t1, ptr %t0
  store i64 0, ptr %t2
  br label %while_cond_0
while_cond_0:
  %t3 = load i64, ptr %t2
  %t4 = icmp slt i64 %t3, 100
  br i1 %t4, label %while_body_1, label %while_end_2
while_body_1:
  %t5 = load ptr, ptr %t0
  %t6 = call i8* @malloc(i64 24)
  store i64 1, ptr %t6
  %t7 = getelementptr i8, ptr %t6, i64 8
  store i64 1, ptr %t7
  %t8 = load i64, ptr %t2
  %t9 = getelementptr i8, ptr %t7, i64 8
  store i64 %t8, ptr %t9
  %t10 = call ptr @mire_list_concat(ptr %t5, ptr %t7)
  store ptr %t10, ptr %t0
  %t11 = load i64, ptr %t2
  %t12 = add i64 %t11, 1
  store i64 %t12, ptr %t2
  br label %while_cond_0
while_end_2:
  %t13 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t14 = load ptr, ptr %t0
  %t15 = load ptr, ptr %t0
  %t16 = getelementptr inbounds i8, ptr %t15, i64 -8
  %t17 = icmp eq ptr %t16, null
  br i1 %t17, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t20
  br label %list_len_end_5
list_len_load_4:
  %t18 = load i64, ptr %t16
  store i64 %t18, ptr %t20
  br label %list_len_end_5
list_len_end_5:
  %t19 = load i64, ptr %t20
  %t21 = call ptr @mire_i64_to_string(i64 %t19)
  %t22 = call ptr @mire_string_concat(ptr %t13, ptr %t21)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t22)
  %t23 = getelementptr inbounds [13 x i8], ptr @.str1, i64 0, i64 0
  %t24 = call i64 @mire_mem_process_bytes()
  %t25 = call ptr @mire_mem_format(i64 %t24)
  %t26 = call ptr @mire_string_concat(ptr %t23, ptr %t25)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t26)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
