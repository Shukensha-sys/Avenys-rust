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
@.str1 = private unnamed_addr constant [5 x i8] c"tAsk\00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [7 x i8] c"items \00"
@.str4 = private unnamed_addr constant [12 x i8] c"digest_len \00"

define i32 @main() {
entry:
  %t0 = alloca ptr
  %t2 = alloca i64
  %t3 = alloca ptr
  %t6 = alloca i64
  %t9 = alloca i64
  %t39 = alloca i64
  %t1 = inttoptr i64 0 to ptr
  store ptr %t1, ptr %t0
  store i64 0, ptr %t2
  %t4 = getelementptr inbounds [1 x i8], ptr @.str0, i64 0, i64 0
  %t5 = call ptr @mire_string_copy(ptr %t4)
  store ptr %t5, ptr %t3
  store i64 0, ptr %t6
  br label %while_cond_0
while_cond_0:
  %t7 = load i64, ptr %t6
  %t8 = icmp slt i64 %t7, 12000
  br i1 %t8, label %while_body_1, label %while_end_2
while_body_1:
  %t10 = load i64, ptr %t6
  %t11 = mul i64 %t10, 7
  %t12 = add i64 %t11, 3
  %t13 = urem i64 %t12, 11
  store i64 %t13, ptr %t9
  %t14 = load ptr, ptr %t0
  %t15 = load i64, ptr %t9
  %t16 = call ptr @mire_list_push_i64(ptr %t14, i64 %t15)
  store ptr %t16, ptr %t0
  %t17 = load i64, ptr %t2
  %t18 = load i64, ptr %t9
  %t19 = add i64 %t17, %t18
  store i64 %t19, ptr %t2
  %t20 = load i64, ptr %t9
  %t21 = urem i64 %t20, 3
  %t22 = icmp eq i64 %t21, 0
  br i1 %t22, label %if_then_3, label %if_else_4
if_then_3:
  %t23 = getelementptr inbounds [5 x i8], ptr @.str1, i64 0, i64 0
  %t24 = load ptr, ptr %t3
  %t25 = call ptr @mire_string_append_owned(ptr %t24, ptr %t23)
  store ptr %t25, ptr %t3
  br label %if_end_5
if_else_4:
  br label %if_end_5
if_end_5:
  %t26 = load i64, ptr %t6
  %t27 = add i64 %t26, 1
  store i64 %t27, ptr %t6
  br label %while_cond_0
while_end_2:
  %t28 = getelementptr inbounds [7 x i8], ptr @.str2, i64 0, i64 0
  %t29 = load i64, ptr %t2
  %t30 = call ptr @mire_i64_to_string(i64 %t29)
  %t31 = call ptr @mire_string_concat(ptr %t28, ptr %t30)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t31)
  %t32 = getelementptr inbounds [7 x i8], ptr @.str3, i64 0, i64 0
  %t33 = load ptr, ptr %t0
  %t34 = load ptr, ptr %t0
  %t35 = getelementptr inbounds i8, ptr %t34, i64 -8
  %t36 = icmp eq ptr %t35, null
  br i1 %t36, label %list_len_null_6, label %list_len_load_7
list_len_null_6:
  store i64 0, ptr %t39
  br label %list_len_end_8
list_len_load_7:
  %t37 = load i64, ptr %t35
  store i64 %t37, ptr %t39
  br label %list_len_end_8
list_len_end_8:
  %t38 = load i64, ptr %t39
  %t40 = call ptr @mire_i64_to_string(i64 %t38)
  %t41 = call ptr @mire_string_concat(ptr %t32, ptr %t40)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t41)
  %t42 = getelementptr inbounds [12 x i8], ptr @.str4, i64 0, i64 0
  %t43 = load ptr, ptr %t3
  %t44 = call i64 @strlen(ptr %t43)
  %t45 = call ptr @mire_i64_to_string(i64 %t44)
  %t46 = call ptr @mire_string_concat(ptr %t42, ptr %t45)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t46)
  ret i32 0
}
