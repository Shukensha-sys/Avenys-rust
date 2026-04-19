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
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

define i64 @fn_map_fn(i64 %arg_x) {
entry:
  %t0 = alloca i64
  store i64 %arg_x, ptr %t0
  %t1 = load i64, ptr %t0
  %t2 = mul i64 %t1, 2
  ret i64 %t2
}
define i1 @fn_filter_fn(i64 %arg_x) {
entry:
  %t3 = alloca i64
  store i64 %arg_x, ptr %t3
  %t4 = load i64, ptr %t3
  %t5 = urem i64 %t4, 2
  %t6 = icmp eq i64 %t5, 0
  ret i1 %t6
}

define i32 @main() {
entry:
  %t7 = alloca i64
  %t9 = alloca i64
  %t11 = alloca ptr
  %t13 = alloca i64
  %t31 = alloca i64
  %t8 = call i64 @mire_wall_mark_ns()
  store i64 %t8, ptr %t7
  %t10 = call i64 @mire_cpu_mark_ns()
  store i64 %t10, ptr %t9
  %t12 = inttoptr i64 0 to ptr
  store ptr %t12, ptr %t11
  store i64 0, ptr %t13
  br label %while_cond_0
while_cond_0:
  %t14 = load i64, ptr %t13
  %t15 = icmp slt i64 %t14, 5000
  br i1 %t15, label %while_body_1, label %while_end_2
while_body_1:
  %t16 = load ptr, ptr %t11
  %t17 = call i8* @malloc(i64 24)
  store i64 1, ptr %t17
  %t18 = getelementptr i8, ptr %t17, i64 8
  store i64 1, ptr %t18
  %t19 = load i64, ptr %t13
  %t20 = getelementptr i8, ptr %t18, i64 8
  store i64 %t19, ptr %t20
  %t21 = call ptr @mire_list_concat(ptr %t16, ptr %t18)
  store ptr %t21, ptr %t11
  %t22 = load i64, ptr %t13
  %t23 = add i64 %t22, 1
  store i64 %t23, ptr %t13
  br label %while_cond_0
while_end_2:
  %t24 = getelementptr inbounds [5 x i8], ptr @.str0, i64 0, i64 0
  %t25 = load ptr, ptr %t11
  %t26 = load ptr, ptr %t11
  %t27 = getelementptr inbounds i8, ptr %t26, i64 -8
  %t28 = icmp eq ptr %t27, null
  br i1 %t28, label %list_len_null_3, label %list_len_load_4
list_len_null_3:
  store i64 0, ptr %t31
  br label %list_len_end_5
list_len_load_4:
  %t29 = load i64, ptr %t27
  store i64 %t29, ptr %t31
  br label %list_len_end_5
list_len_end_5:
  %t30 = load i64, ptr %t31
  %t32 = call ptr @mire_i64_to_string(i64 %t30)
  %t33 = call ptr @mire_string_concat(ptr %t24, ptr %t32)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t33)
  %t34 = getelementptr inbounds [9 x i8], ptr @.str1, i64 0, i64 0
  %t35 = load i64, ptr %t7
  %t36 = call ptr @mire_wall_elapsed_ms_str(i64 %t35)
  %t37 = call ptr @mire_string_concat(ptr %t34, ptr %t36)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t37)
  %t38 = getelementptr inbounds [8 x i8], ptr @.str2, i64 0, i64 0
  %t39 = load i64, ptr %t9
  %t40 = call ptr @mire_cpu_elapsed_ms_str(i64 %t39)
  %t41 = call ptr @mire_string_concat(ptr %t38, ptr %t40)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t41)
  %t42 = getelementptr inbounds [13 x i8], ptr @.str3, i64 0, i64 0
  %t43 = call i64 @mire_mem_process_bytes()
  %t44 = call ptr @mire_mem_format(i64 %t43)
  %t45 = call ptr @mire_string_concat(ptr %t42, ptr %t44)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t45)
  ret i32 0
}
