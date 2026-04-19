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
define ptr @concat(ptr %a, ptr %b) {
  %len_a = call i64 @strlen(ptr %a)
  %len_b = call i64 @strlen(ptr %b)
  %len = add i64 %len_a, %len_b
  %alloc_len = add i64 %len, 1
  %new = call i64 @malloc(i64 %alloc_len)
  %new_ptr = inttoptr i64 %new to ptr
  call void @memcpy(ptr %new_ptr, ptr %a, i64 %len_a)
  %dest = getelementptr i8, ptr %new_ptr, i64 %len_a
  call void @memcpy(ptr %dest, ptr %b, i64 %len_b)
  %end = getelementptr i8, ptr %new_ptr, i64 %len
  store i8 0, ptr %end
  ret ptr %new_ptr
}
@.fmt_i64 = private unnamed_addr constant [5 x i8] c"%ld\0A\00"
@.fmt_str = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.fmt_float = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@.fmt_bool_true = private unnamed_addr constant [5 x i8] c"true\00"
@.fmt_bool_false = private unnamed_addr constant [6 x i8] c"false\00"
@.fmt_i32 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.scanf_str = private unnamed_addr constant [3 x i8] c"%s\00"
@.str0 = private unnamed_addr constant [5 x i8] c"len \00"
@.str1 = private unnamed_addr constant [7 x i8] c"first \00"
@.str2 = private unnamed_addr constant [8 x i8] c"second \00"

define i64 @mire_main() {
entry:
  %t0 = alloca ptr
  %t12 = alloca i64
  %t18 = alloca i64
  %t1 = inttoptr i64 0 to ptr
  store ptr %t1, ptr %t0
  %t2 = load ptr, ptr %t0
  %t3 = call i8* @malloc(i64 24)
  store i64 1, ptr %t3
  %t4 = getelementptr i8, ptr %t3, i64 8
  store i64 1, ptr %t4
  %t5 = getelementptr i8, ptr %t4, i64 8
  store i64 1, ptr %t5
  %t6 = call ptr @mire_list_concat(ptr %t2, ptr %t4)
  store ptr %t6, ptr %t0
  %t7 = load ptr, ptr %t0
  %t8 = call i8* @malloc(i64 24)
  store i64 1, ptr %t8
  %t9 = getelementptr i8, ptr %t8, i64 8
  store i64 1, ptr %t9
  %t10 = getelementptr i8, ptr %t9, i64 8
  store i64 2, ptr %t10
  %t11 = call ptr @mire_list_concat(ptr %t7, ptr %t9)
  store ptr %t11, ptr %t0
  %t13 = load ptr, ptr %t0
  %t14 = load ptr, ptr %t0
  %t15 = icmp eq ptr %t14, null
  br i1 %t15, label %list_len_null_0, label %list_len_load_1
list_len_null_0:
  store i64 0, ptr %t18
  br label %list_len_end_2
list_len_load_1:
  %t16 = load i64, ptr %t14
  store i64 %t16, ptr %t18
  br label %list_len_end_2
list_len_end_2:
  %t17 = load i64, ptr %t18
  store i64 %t17, ptr %t12
  %t19 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t20 = load i64, ptr %t12
  %t21 = call ptr @mire_i64_to_string(i64 %t20)
  %t22 = call ptr @concat(ptr %t19, ptr %t21)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t22)
  %t23 = getelementptr inbounds [7 x i8], ptr @.str1, i64 0, i64 0
  %t24 = load ptr, ptr %t0
  %t25 = getelementptr inbounds i8, ptr %t24, i64 8
  %t26 = mul i64 0, 8
  %t27 = getelementptr inbounds i8, ptr %t25, i64 %t26
  %t28 = load i64, ptr %t27
  %t29 = call ptr @mire_i64_to_string(i64 %t28)
  %t30 = call ptr @concat(ptr %t23, ptr %t29)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t30)
  %t31 = getelementptr inbounds [8 x i8], ptr @.str2, i64 0, i64 0
  %t32 = load ptr, ptr %t0
  %t33 = getelementptr inbounds i8, ptr %t32, i64 8
  %t34 = mul i64 1, 8
  %t35 = getelementptr inbounds i8, ptr %t33, i64 %t34
  %t36 = load i64, ptr %t35
  %t37 = call ptr @mire_i64_to_string(i64 %t36)
  %t38 = call ptr @concat(ptr %t31, ptr %t37)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t38)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
