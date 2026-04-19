; ModuleID = 'build/release/vec_slice.ll'
source_filename = "build/release/vec_slice.ll"

@.str0 = private unnamed_addr constant [9 x i8] c"sum_all \00"
@.str1 = private unnamed_addr constant [12 x i8] c"sum_sliced \00"
@.str2 = private unnamed_addr constant [12 x i8] c"sliced_len \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str4 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

declare ptr @mire_list_slice(ptr, i64, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.011 = phi ptr [ null, %entry ], [ %t11, %while_body_1 ]
  %t6.010 = phi i64 [ 0, %entry ], [ %t13, %while_body_1 ]
  %t11 = tail call ptr @mire_list_push_i64(ptr %t4.011, i64 %t6.010)
  %t13 = add nuw nsw i64 %t6.010, 1
  %t8 = icmp samesign ult i64 %t6.010, 4999
  br i1 %t8, label %while_body_1, label %list_len_end_5

list_len_end_5:                                   ; preds = %while_body_1
  %t17 = getelementptr inbounds i8, ptr %t11, i64 -8
  %t19 = load i64, ptr %t17, align 4
  %t225 = lshr i64 %t19, 1
  %t26 = tail call ptr @mire_list_slice(ptr %t11, i64 0, i64 %t225)
  %t32 = load i64, ptr %t11, align 4
  %t3412 = icmp sgt i64 %t32, 0
  br i1 %t3412, label %math_sum_body_8.lr.ph, label %math_sum_end_9

math_sum_body_8.lr.ph:                            ; preds = %list_len_end_5
  %t35 = getelementptr i8, ptr %t11, i64 8
  br label %math_sum_body_8

math_sum_body_8:                                  ; preds = %math_sum_body_8.lr.ph, %math_sum_body_8
  %t30.014 = phi i64 [ 0, %math_sum_body_8.lr.ph ], [ %t41, %math_sum_body_8 ]
  %t29.013 = phi i64 [ 0, %math_sum_body_8.lr.ph ], [ %t40, %math_sum_body_8 ]
  %t36 = shl i64 %t30.014, 3
  %t37 = getelementptr i8, ptr %t35, i64 %t36
  %t38 = load i64, ptr %t37, align 4
  %t40 = add i64 %t38, %t29.013
  %t41 = add nuw nsw i64 %t30.014, 1
  %t34 = icmp slt i64 %t41, %t32
  br i1 %t34, label %math_sum_body_8, label %math_sum_end_9

math_sum_end_9:                                   ; preds = %math_sum_body_8, %list_len_end_5
  %t29.0.lcssa = phi i64 [ 0, %list_len_end_5 ], [ %t40, %math_sum_body_8 ]
  %t47 = icmp eq ptr %t26, null
  br i1 %t47, label %math_sum_end_13, label %math_sum_cond_11.preheader

math_sum_cond_11.preheader:                       ; preds = %math_sum_end_9
  %t48 = load i64, ptr %t26, align 4
  %t5015 = icmp sgt i64 %t48, 0
  br i1 %t5015, label %math_sum_body_12.lr.ph, label %math_sum_end_13

math_sum_body_12.lr.ph:                           ; preds = %math_sum_cond_11.preheader
  %t51 = getelementptr i8, ptr %t26, i64 8
  br label %math_sum_body_12

math_sum_body_12:                                 ; preds = %math_sum_body_12.lr.ph, %math_sum_body_12
  %t46.017 = phi i64 [ 0, %math_sum_body_12.lr.ph ], [ %t57, %math_sum_body_12 ]
  %t45.016 = phi i64 [ 0, %math_sum_body_12.lr.ph ], [ %t56, %math_sum_body_12 ]
  %t52 = shl i64 %t46.017, 3
  %t53 = getelementptr i8, ptr %t51, i64 %t52
  %t54 = load i64, ptr %t53, align 4
  %t56 = add i64 %t54, %t45.016
  %t57 = add nuw nsw i64 %t46.017, 1
  %t50 = icmp slt i64 %t57, %t48
  br i1 %t50, label %math_sum_body_12, label %math_sum_end_13

math_sum_end_13:                                  ; preds = %math_sum_body_12, %math_sum_cond_11.preheader, %math_sum_end_9
  %t45.1 = phi i64 [ 0, %math_sum_end_9 ], [ 0, %math_sum_cond_11.preheader ], [ %t56, %math_sum_body_12 ]
  %t61 = tail call ptr @mire_i64_to_string(i64 %t29.0.lcssa)
  %t62 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t61)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t62)
  %t65 = tail call ptr @mire_i64_to_string(i64 %t45.1)
  %t66 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t65)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t66)
  %t70 = getelementptr inbounds i8, ptr %t26, i64 -8
  %t72 = load i64, ptr %t70, align 4
  %t75 = tail call ptr @mire_i64_to_string(i64 %t72)
  %t76 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t75)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t76)
  %t79 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t80 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t79)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t80)
  %t83 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t84 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t83)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t84)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
