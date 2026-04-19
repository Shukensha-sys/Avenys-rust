; ModuleID = 'build/release/array_index_stress.ll'
source_filename = "build/release/array_index_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str3 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t79 = tail call ptr @mire_i64_to_string(i64 4410000)
  %t80 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t79)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t80)
  %t83 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t84 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t83)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t84)
  %t87 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t88 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t87)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t88)
  %t91 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t92 = tail call ptr @mire_i64_to_string(i64 %t91)
  %t93 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t92)
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t93)
  %t95 = tail call i64 @mire_mem_process_bytes()
  %t96 = tail call ptr @mire_mem_format(i64 %t95)
  %t97 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t96)
  %puts14 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t97)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
