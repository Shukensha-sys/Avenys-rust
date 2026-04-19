; ModuleID = 'build/release/string_join_test.ll'
source_filename = "build/release/string_join_test.ll"

@.str0 = private unnamed_addr constant [17 x i8] c"hello world test\00"
@.str1 = private unnamed_addr constant [2 x i8] c"-\00"
@.str2 = private unnamed_addr constant [8 x i8] c"joined \00"

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_strings_join(ptr, i64, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t2 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  %t6 = tail call ptr @mire_strings_join(ptr %t2, i64 0, ptr nonnull @.str1)
  %t9 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t6)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t9)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
