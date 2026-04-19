; ModuleID = 'build/release/string_trim_test.ll'
source_filename = "build/release/string_trim_test.ll"

@.str0 = private unnamed_addr constant [16 x i8] c"  hello world  \00"
@.str1 = private unnamed_addr constant [9 x i8] c"trimmed \00"

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_strings_trim(ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t2 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  %t5 = tail call ptr @mire_strings_trim(ptr %t2)
  %t8 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t5)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t8)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
