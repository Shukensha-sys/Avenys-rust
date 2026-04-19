; ModuleID = 'build/release/vec_copy_semantics.ll'
source_filename = "build/release/vec_copy_semantics.ll"

@.str0 = private unnamed_addr constant [6 x i8] c"val1 \00"
@.str1 = private unnamed_addr constant [6 x i8] c"val2 \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.07 = phi ptr [ null, %entry ], [ %t11, %while_body_1 ]
  %t6.06 = phi i64 [ 0, %entry ], [ %t13, %while_body_1 ]
  %t11 = tail call ptr @mire_list_push_i64(ptr %t4.07, i64 %t6.06)
  %t13 = add nuw nsw i64 %t6.06, 1
  %t8 = icmp samesign ult i64 %t6.06, 9999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t21 = load i64, ptr %t11, align 4
  %t30 = tail call ptr @mire_i64_to_string(i64 %t21)
  %t31 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t30)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t31)
  %t34 = tail call ptr @mire_i64_to_string(i64 %t21)
  %t35 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t34)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t35)
  %t38 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t39 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t38)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t39)
  %t41 = tail call i64 @mire_mem_process_bytes()
  %t42 = tail call ptr @mire_mem_format(i64 %t41)
  %t43 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t42)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t43)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
