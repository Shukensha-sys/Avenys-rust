; ModuleID = 'build/release/struct_test.ll'
source_filename = "build/release/struct_test.ll"

@.str0 = private unnamed_addr constant [12 x i8] c"Hello from \00"

; Function Attrs: nofree nounwind
define noundef i64 @mire_main() local_unnamed_addr #0 {
entry:
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str0)
  ret i64 0
}

; Function Attrs: nofree nounwind
define noundef i32 @main() local_unnamed_addr #0 {
entry:
  %puts.i = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str0)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
