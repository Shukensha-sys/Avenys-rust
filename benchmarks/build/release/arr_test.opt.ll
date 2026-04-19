; ModuleID = 'build/release/arr_test.ll'
source_filename = "build/release/arr_test.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"x_at_0 \00"
@.str1 = private unnamed_addr constant [10 x i8] c"y_at - 0 \00"

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  %t16 = tail call ptr @mire_i64_to_string(i64 2)
  %t17 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t16)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t17)
  %t24 = tail call ptr @mire_i64_to_string(i64 2)
  %t25 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t24)
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t25)
  ret i64 0
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t16.i = tail call ptr @mire_i64_to_string(i64 2)
  %t17.i = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t16.i)
  %puts.i = tail call i32 @puts(ptr nonnull dereferenceable(1) %t17.i)
  %t24.i = tail call ptr @mire_i64_to_string(i64 2)
  %t25.i = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t24.i)
  %puts1.i = tail call i32 @puts(ptr nonnull dereferenceable(1) %t25.i)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
