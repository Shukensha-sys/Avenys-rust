; ModuleID = 'build/release/string_case_ops.ll'
source_filename = "build/release/string_case_ops.ll"

@.str0 = private unnamed_addr constant [6 x i8] c"HELLO\00"
@.str1 = private unnamed_addr constant [6 x i8] c"world\00"
@.str2 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str3 = private unnamed_addr constant [7 x i8] c"upper \00"
@.str4 = private unnamed_addr constant [7 x i8] c"lower \00"
@.str5 = private unnamed_addr constant [9 x i8] c"trimmed \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t4 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  %t7 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  %t10 = tail call ptr @mire_string_copy(ptr nonnull @.str2)
  %t13 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t4)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t13)
  %t16 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t7)
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t16)
  %t19 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t10)
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t19)
  %t22 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t23 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t22)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t23)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
