; ModuleID = 'build/release/vec_map_op.ll'
source_filename = "build/release/vec_map_op.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t38 = tail call ptr @mire_list_push_i64(ptr null, i64 100)
  %t38.1 = tail call ptr @mire_list_push_i64(ptr %t38, i64 1)
  %t38.2 = tail call ptr @mire_list_push_i64(ptr %t38.1, i64 4)
  %t38.3 = tail call ptr @mire_list_push_i64(ptr %t38.2, i64 9)
  %t38.4 = tail call ptr @mire_list_push_i64(ptr %t38.3, i64 16)
  %t38.5 = tail call ptr @mire_list_push_i64(ptr %t38.4, i64 25)
  %t38.6 = tail call ptr @mire_list_push_i64(ptr %t38.5, i64 36)
  %t38.7 = tail call ptr @mire_list_push_i64(ptr %t38.6, i64 49)
  %t38.8 = tail call ptr @mire_list_push_i64(ptr %t38.7, i64 64)
  %t38.9 = tail call ptr @mire_list_push_i64(ptr %t38.8, i64 81)
  %t45 = icmp eq ptr %t38.9, null
  br i1 %t45, label %math_sum_end_9, label %math_sum_cond_7.preheader

math_sum_cond_7.preheader:                        ; preds = %entry
  %t46 = load i64, ptr %t38.9, align 4
  %t488 = icmp sgt i64 %t46, 0
  br i1 %t488, label %math_sum_body_8.lr.ph, label %math_sum_end_9

math_sum_body_8.lr.ph:                            ; preds = %math_sum_cond_7.preheader
  %t49 = getelementptr i8, ptr %t38.9, i64 8
  br label %math_sum_body_8

math_sum_body_8:                                  ; preds = %math_sum_body_8.lr.ph, %math_sum_body_8
  %t44.010 = phi i64 [ 0, %math_sum_body_8.lr.ph ], [ %t55, %math_sum_body_8 ]
  %t43.09 = phi i64 [ 0, %math_sum_body_8.lr.ph ], [ %t54, %math_sum_body_8 ]
  %t50 = shl i64 %t44.010, 3
  %t51 = getelementptr i8, ptr %t49, i64 %t50
  %t52 = load i64, ptr %t51, align 4
  %t54 = add i64 %t52, %t43.09
  %t55 = add nuw nsw i64 %t44.010, 1
  %t48 = icmp slt i64 %t55, %t46
  br i1 %t48, label %math_sum_body_8, label %math_sum_end_9

math_sum_end_9:                                   ; preds = %math_sum_body_8, %math_sum_cond_7.preheader, %entry
  %t43.1 = phi i64 [ 0, %entry ], [ 0, %math_sum_cond_7.preheader ], [ %t54, %math_sum_body_8 ]
  %t59 = tail call ptr @mire_i64_to_string(i64 %t43.1)
  %t60 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t59)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t60)
  %t63 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t64 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t63)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t64)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
