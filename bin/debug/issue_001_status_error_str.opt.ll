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
declare void @mire_runtime_panic(ptr)
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
@.str0 = private unnamed_addr constant [3 x i8] c"ok\00"
@.str1 = private unnamed_addr constant [6 x i8] c"error\00"
@.str2 = private unnamed_addr constant [1 x i8] c"\00"

define i64 @mire_main() {
entry:
  %t0 = alloca ptr
  %t3 = alloca ptr
  %t5 = alloca ptr
  %t1 = alloca { i32, [1 x i64] }
  %t2 = getelementptr inbounds { i32, [1 x i64] }, ptr %t1, i32 0, i32 0
  store i32 1, ptr %t2
  store ptr %t1, ptr %t0
  %t4 = load ptr, ptr %t0
  %t6 = getelementptr inbounds { i32, [1 x i64] }, ptr %t4, i32 0, i32 0
  %t7 = load i32, ptr %t6
  %t8 = icmp eq i32 %t7, 0
  br i1 %t8, label %match_expr_body_0_3, label %match_expr_next_0_4
match_expr_body_0_3:
  %t9 = getelementptr inbounds [3 x i8], ptr @.str0, i64 0, i64 0
  store ptr %t9, ptr %t5
  br label %match_expr_end_0
match_expr_next_0_4:
  %t10 = getelementptr inbounds { i32, [1 x i64] }, ptr %t4, i32 0, i32 0
  %t11 = load i32, ptr %t10
  %t12 = icmp eq i32 %t11, 1
  br i1 %t12, label %match_expr_body_1_5, label %match_expr_default_1
match_expr_body_1_5:
  %t13 = getelementptr inbounds [6 x i8], ptr @.str1, i64 0, i64 0
  store ptr %t13, ptr %t5
  br label %match_expr_end_0
match_expr_default_1:
  %t14 = getelementptr inbounds [1 x i8], ptr @.str2, i64 0, i64 0
  store ptr %t14, ptr %t5
  br label %match_expr_end_0
match_expr_end_0:
  %t15 = load ptr, ptr %t5
  %t16 = call ptr @mire_string_copy(ptr %t15)
  store ptr %t16, ptr %t3
  %t17 = load ptr, ptr %t3
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t17)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
