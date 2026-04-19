; ModuleID = 'build/release/fn_multi_args.ll'
source_filename = "build/release/fn_multi_args.ll"

@.str0 = private unnamed_addr constant [3 x i8] c"p \00"

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define i64 @fn_pair(i64 %arg_x, i64 %arg_y) local_unnamed_addr #0 {
entry:
  %t4 = add i64 %arg_y, %arg_x
  ret i64 %t4
}

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  %t9 = tail call ptr @mire_i64_to_string(i64 7)
  %t10 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t9)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t10)
  ret i64 0
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t9.i = tail call ptr @mire_i64_to_string(i64 7)
  %t10.i = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t9.i)
  %puts.i = tail call i32 @puts(ptr nonnull dereferenceable(1) %t10.i)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nofree nounwind }
