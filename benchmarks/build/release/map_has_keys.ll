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
@.str0 = private unnamed_addr constant [2 x i8] c"a\00"
@.str1 = private unnamed_addr constant [2 x i8] c"b\00"
@.str2 = private unnamed_addr constant [2 x i8] c"c\00"
@.str3 = private unnamed_addr constant [2 x i8] c"d\00"
@.str4 = private unnamed_addr constant [2 x i8] c"e\00"
@.str5 = private unnamed_addr constant [2 x i8] c"a\00"
@.str6 = private unnamed_addr constant [2 x i8] c"z\00"
@.str7 = private unnamed_addr constant [7 x i8] c"val_a \00"
@.str8 = private unnamed_addr constant [7 x i8] c"val_z \00"
@.str9 = private unnamed_addr constant [10 x i8] c"num_keys \00"
@.str10 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str11 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

define i32 @main() {
entry:
  %t0 = alloca i64
  %t2 = alloca i64
  %t4 = alloca ptr
  %t21 = alloca i64
  %t25 = alloca i64
  %t29 = alloca ptr
  %t32 = alloca ptr
  %t49 = alloca i64
  %t1 = call i64 @mire_wall_mark_ns()
  store i64 %t1, ptr %t0
  %t3 = call i64 @mire_cpu_mark_ns()
  store i64 %t3, ptr %t2
  %t5 = inttoptr i64 0 to ptr
  store ptr %t5, ptr %t4
  %t6 = load ptr, ptr %t4
  %t7 = getelementptr inbounds [2 x i8], ptr @.str0, i64 0, i64 0
  %t8 = call ptr @mire_dict_set_i64(ptr %t6, i64 3, i64 1, i64 0, ptr %t7, i64 1)
  store ptr %t8, ptr %t4
  %t9 = load ptr, ptr %t4
  %t10 = getelementptr inbounds [2 x i8], ptr @.str1, i64 0, i64 0
  %t11 = call ptr @mire_dict_set_i64(ptr %t9, i64 3, i64 1, i64 0, ptr %t10, i64 2)
  store ptr %t11, ptr %t4
  %t12 = load ptr, ptr %t4
  %t13 = getelementptr inbounds [2 x i8], ptr @.str2, i64 0, i64 0
  %t14 = call ptr @mire_dict_set_i64(ptr %t12, i64 3, i64 1, i64 0, ptr %t13, i64 3)
  store ptr %t14, ptr %t4
  %t15 = load ptr, ptr %t4
  %t16 = getelementptr inbounds [2 x i8], ptr @.str3, i64 0, i64 0
  %t17 = call ptr @mire_dict_set_i64(ptr %t15, i64 3, i64 1, i64 0, ptr %t16, i64 4)
  store ptr %t17, ptr %t4
  %t18 = load ptr, ptr %t4
  %t19 = getelementptr inbounds [2 x i8], ptr @.str4, i64 0, i64 0
  %t20 = call ptr @mire_dict_set_i64(ptr %t18, i64 3, i64 1, i64 0, ptr %t19, i64 5)
  store ptr %t20, ptr %t4
  %t22 = load ptr, ptr %t4
  %t23 = getelementptr inbounds [2 x i8], ptr @.str5, i64 0, i64 0
  %t24 = call i64 @mire_dict_get_i64(ptr %t22, i64 3, i64 0, ptr %t23, i64 0)
  store i64 %t24, ptr %t21
  %t26 = load ptr, ptr %t4
  %t27 = getelementptr inbounds [2 x i8], ptr @.str6, i64 0, i64 0
  %t28 = call i64 @mire_dict_get_i64(ptr %t26, i64 3, i64 0, ptr %t27, i64 99)
  store i64 %t28, ptr %t25
  %t30 = load ptr, ptr %t4
  %t31 = call ptr @mire_dict_keys(ptr %t30)
  store ptr %t31, ptr %t29
  %t33 = load ptr, ptr %t4
  %t34 = call ptr @mire_dict_values(ptr %t33)
  store ptr %t34, ptr %t32
  %t35 = getelementptr inbounds [7 x i8], ptr @.str7, i64 0, i64 0
  %t36 = load i64, ptr %t21
  %t37 = call ptr @mire_i64_to_string(i64 %t36)
  %t38 = call ptr @concat(ptr %t35, ptr %t37)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t38)
  %t39 = getelementptr inbounds [7 x i8], ptr @.str8, i64 0, i64 0
  %t40 = load i64, ptr %t25
  %t41 = call ptr @mire_i64_to_string(i64 %t40)
  %t42 = call ptr @concat(ptr %t39, ptr %t41)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t42)
  %t43 = getelementptr inbounds [10 x i8], ptr @.str9, i64 0, i64 0
  %t44 = load ptr, ptr %t29
  %t45 = load ptr, ptr %t29
  %t46 = icmp eq ptr %t45, null
  br i1 %t46, label %list_len_null_0, label %list_len_load_1
list_len_null_0:
  store i64 0, ptr %t49
  br label %list_len_end_2
list_len_load_1:
  %t47 = load i64, ptr %t45
  store i64 %t47, ptr %t49
  br label %list_len_end_2
list_len_end_2:
  %t48 = load i64, ptr %t49
  %t50 = call ptr @mire_i64_to_string(i64 %t48)
  %t51 = call ptr @concat(ptr %t43, ptr %t50)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t51)
  %t52 = getelementptr inbounds [9 x i8], ptr @.str10, i64 0, i64 0
  %t53 = load i64, ptr %t0
  %t54 = call ptr @mire_wall_elapsed_ms_str(i64 %t53)
  %t55 = call ptr @concat(ptr %t52, ptr %t54)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t55)
  %t56 = getelementptr inbounds [8 x i8], ptr @.str11, i64 0, i64 0
  %t57 = load i64, ptr %t2
  %t58 = call ptr @mire_cpu_elapsed_ms_str(i64 %t57)
  %t59 = call ptr @concat(ptr %t56, ptr %t58)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t59)
  ret i32 0
}
