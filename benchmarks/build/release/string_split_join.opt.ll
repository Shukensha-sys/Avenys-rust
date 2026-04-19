; ModuleID = 'build/release/string_split_join.ll'
source_filename = "build/release/string_split_join.ll"

@.str0 = private unnamed_addr constant [18 x i8] c"hello world world\00"
@.str1 = private unnamed_addr constant [6 x i8] c"world\00"
@.str2 = private unnamed_addr constant [5 x i8] c"mire\00"
@.str3 = private unnamed_addr constant [2 x i8] c" \00"
@.str4 = private unnamed_addr constant [10 x i8] c"original \00"
@.str5 = private unnamed_addr constant [7 x i8] c"parts \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_strings_replace(ptr, ptr, ptr) local_unnamed_addr

declare ptr @mire_strings_split(ptr, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t6 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  %t10 = tail call ptr @mire_strings_replace(ptr %t6, ptr nonnull @.str1, ptr nonnull @.str2)
  tail call void @mire_string_free(ptr %t6)
  %t15 = tail call ptr @mire_strings_split(ptr %t10, ptr nonnull @.str3)
  %t18 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t10)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t18)
  %t21 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t15)
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t21)
  %t24 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t25 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t24)
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t25)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
