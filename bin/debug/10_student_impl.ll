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
declare ptr @mire_list_create(i64, i64)
declare ptr @mire_list_push_i64(ptr, i64)
declare ptr @mire_list_new()
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
@.str0 = private unnamed_addr constant [6 x i8] c"Alice\00"
@.str1 = private unnamed_addr constant [4 x i8] c"Bob\00"
@.str2 = private unnamed_addr constant [14 x i8] c"Alice grade: \00"
@.str3 = private unnamed_addr constant [12 x i8] c"Bob grade: \00"

define ptr @fn_Student_new(ptr %arg_name, i64 %arg_grade) {
entry:
  %t0 = alloca ptr
  %t1 = alloca i64
  store ptr %arg_name, ptr %t0
  store i64 %arg_grade, ptr %t1
  %t2 = call ptr @malloc(i64 16)
  %t3 = load ptr, ptr %t0
  %t4 = getelementptr inbounds { ptr, i64 }, ptr %t2, i32 0, i32 0
  store ptr %t3, ptr %t4
  %t5 = load i64, ptr %t1
  %t6 = getelementptr inbounds { ptr, i64 }, ptr %t2, i32 0, i32 1
  store i64 %t5, ptr %t6
  ret ptr %t2
}
define i64 @fn_Student_promote(ptr %arg_self) {
entry:
  %t7 = alloca ptr
  store ptr %arg_self, ptr %t7
  %t8 = load ptr, ptr %t7
  %t9 = getelementptr inbounds { ptr, i64 }, ptr %t8, i32 0, i32 1
  %t10 = load ptr, ptr %t7
  %t11 = getelementptr inbounds { ptr, i64 }, ptr %t10, i32 0, i32 1
  %t12 = load i64, ptr %t11
  %t13 = add i64 %t12, 1
  store i64 %t13, ptr %t9
  ret i64 0
}
define i64 @fn_Student_get_grade(ptr %arg_self) {
entry:
  %t14 = alloca ptr
  store ptr %arg_self, ptr %t14
  %t15 = load ptr, ptr %t14
  %t16 = getelementptr inbounds { ptr, i64 }, ptr %t15, i32 0, i32 1
  %t17 = load i64, ptr %t16
  ret i64 %t17
}
define i64 @mire_main() {
entry:
  %t18 = alloca ptr
  %t21 = alloca ptr
  %t30 = alloca i64
  %t33 = alloca i64
  %t19 = getelementptr inbounds [6 x i8], ptr @.str0, i64 0, i64 0
  %t20 = call ptr @fn_Student_new(ptr %t19, i64 90)
  store ptr %t20, ptr %t18
  %t22 = getelementptr inbounds [4 x i8], ptr @.str1, i64 0, i64 0
  %t23 = call ptr @fn_Student_new(ptr %t22, i64 85)
  store ptr %t23, ptr %t21
  %t24 = load ptr, ptr %t18
  %t25 = call i64 @fn_Student_promote(ptr %t24)
  %t26 = load ptr, ptr %t21
  %t27 = call i64 @fn_Student_promote(ptr %t26)
  %t28 = load ptr, ptr %t21
  %t29 = call i64 @fn_Student_promote(ptr %t28)
  %t31 = load ptr, ptr %t18
  %t32 = call i64 @fn_Student_get_grade(ptr %t31)
  store i64 %t32, ptr %t30
  %t34 = load ptr, ptr %t21
  %t35 = call i64 @fn_Student_get_grade(ptr %t34)
  store i64 %t35, ptr %t33
  %t36 = getelementptr inbounds [14 x i8], ptr @.str2, i64 0, i64 0
  %t37 = load i64, ptr %t30
  %t38 = call ptr @mire_i64_to_string(i64 %t37)
  %t39 = call ptr @mire_string_concat(ptr %t36, ptr %t38)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t39)
  %t40 = getelementptr inbounds [12 x i8], ptr @.str3, i64 0, i64 0
  %t41 = load i64, ptr %t33
  %t42 = call ptr @mire_i64_to_string(i64 %t41)
  %t43 = call ptr @mire_string_concat(ptr %t40, ptr %t42)
  call i32 (ptr, ...) @printf(ptr @.fmt_str, ptr %t43)
  ret i64 0
}

define i32 @main() {
entry:
  %call_main = call i64 @mire_main()
  ret i32 0
}
