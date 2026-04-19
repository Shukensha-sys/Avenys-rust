; ModuleID = 'build/release/string_ops.ll'
source_filename = "build/release/string_ops.ll"

@.str0 = private unnamed_addr constant [12 x i8] c"Hello World\00"
@.str1 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str2 = private unnamed_addr constant [6 x i8] c"world\00"
@.str3 = private unnamed_addr constant [5 x i8] c"mire\00"
@.str4 = private unnamed_addr constant [8 x i8] c"result \00"
@.str5 = private unnamed_addr constant [5 x i8] c"len \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [13 x i8] c"process_ram \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_string_to_upper(ptr) local_unnamed_addr

declare ptr @mire_string_to_lower(ptr) local_unnamed_addr

declare ptr @mire_strings_replace(ptr, ptr, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t6 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  %t9 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t10.07 = phi i64 [ 0, %entry ], [ %t25, %while_body_1 ]
  %t7.06 = phi ptr [ %t9, %entry ], [ %t22, %while_body_1 ]
  %t14 = tail call ptr @mire_string_to_upper(ptr %t6)
  tail call void @mire_string_free(ptr %t7.06)
  %t17 = tail call ptr @mire_string_to_lower(ptr %t14)
  tail call void @mire_string_free(ptr %t14)
  %t22 = tail call ptr @mire_strings_replace(ptr %t17, ptr nonnull @.str2, ptr nonnull @.str3)
  tail call void @mire_string_free(ptr %t17)
  %t25 = add nuw nsw i64 %t10.07, 1
  %t12 = icmp samesign ult i64 %t10.07, 9999
  br i1 %t12, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t28 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t22)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t28)
  %t31 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t22)
  %t32 = tail call ptr @mire_i64_to_string(i64 %t31)
  %t33 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t32)
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t33)
  %t36 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t37 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t36)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t37)
  %t40 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t41 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t40)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t41)
  %t43 = tail call i64 @mire_mem_process_bytes()
  %t44 = tail call ptr @mire_mem_format(i64 %t43)
  %t45 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t44)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t45)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
