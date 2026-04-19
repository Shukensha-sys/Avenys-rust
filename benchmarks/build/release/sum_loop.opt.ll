; ModuleID = 'build/release/sum_loop.ll'
source_filename = "build/release/sum_loop.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [12 x i8] c"elapsed_ms \00"
@.str2 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t15 = tail call ptr @mire_i64_to_string(i64 499999500000)
  %t16 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t15)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t16)
  %t19 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t20 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t19)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t20)
  %t22 = tail call i64 @mire_mem_process_bytes()
  %t23 = tail call ptr @mire_mem_format(i64 %t22)
  %t24 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t23)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t24)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
