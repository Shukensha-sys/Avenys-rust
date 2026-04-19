; ModuleID = 'build/release/higher_order_manual.ll'
source_filename = "build/release/higher_order_manual.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #0

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define i1 @fn_is_even(i64 %arg_n) local_unnamed_addr #1 {
entry:
  %t2 = and i64 %arg_n, 1
  %t3 = icmp eq i64 %t2, 0
  ret i1 %t3
}

define noundef i32 @main() local_unnamed_addr {
while_body_1.preheader:
  %t5 = tail call i64 @mire_wall_mark_ns()
  %t7 = tail call dereferenceable_or_null(96) ptr @malloc(i64 96)
  store i64 10, ptr %t7, align 4
  %t8 = getelementptr i8, ptr %t7, i64 8
  store i64 10, ptr %t8, align 4
  %t9 = getelementptr i8, ptr %t7, i64 16
  store i64 1, ptr %t9, align 4
  %t10 = getelementptr i8, ptr %t7, i64 24
  store i64 2, ptr %t10, align 4
  %t11 = getelementptr i8, ptr %t7, i64 32
  store i64 3, ptr %t11, align 4
  %t12 = getelementptr i8, ptr %t7, i64 40
  store i64 4, ptr %t12, align 4
  %t13 = getelementptr i8, ptr %t7, i64 48
  store i64 5, ptr %t13, align 4
  %t14 = getelementptr i8, ptr %t7, i64 56
  store i64 6, ptr %t14, align 4
  %t15 = getelementptr i8, ptr %t7, i64 64
  store i64 7, ptr %t15, align 4
  %t16 = getelementptr i8, ptr %t7, i64 72
  store i64 8, ptr %t16, align 4
  %t17 = getelementptr i8, ptr %t7, i64 80
  store i64 9, ptr %t17, align 4
  %t18 = getelementptr i8, ptr %t7, i64 88
  store i64 10, ptr %t18, align 4
  br label %while_body_1

while_body_1:                                     ; preds = %while_body_1.preheader, %if_end_8
  %t2715 = phi i64 [ %t27, %if_end_8 ], [ 10, %while_body_1.preheader ]
  %t19.010 = phi ptr [ %t19.1, %if_end_8 ], [ null, %while_body_1.preheader ]
  %t21.09 = phi i64 [ %t44, %if_end_8 ], [ 0, %while_body_1.preheader ]
  %t35 = shl i64 %t21.09, 3
  %t36 = getelementptr inbounds i8, ptr %t8, i64 %t35
  %t37 = load i64, ptr %t36, align 4
  %t2.i = and i64 %t37, 1
  %t3.i = icmp eq i64 %t2.i, 0
  br i1 %t3.i, label %if_then_6, label %if_end_8

if_then_6:                                        ; preds = %while_body_1
  %t42 = tail call ptr @mire_list_push_i64(ptr %t19.010, i64 %t37)
  %t27.pre = load i64, ptr %t7, align 4
  br label %if_end_8

if_end_8:                                         ; preds = %while_body_1, %if_then_6
  %t27 = phi i64 [ %t27.pre, %if_then_6 ], [ %t2715, %while_body_1 ]
  %t19.1 = phi ptr [ %t42, %if_then_6 ], [ %t19.010, %while_body_1 ]
  %t44 = add nuw nsw i64 %t21.09, 1
  %t30 = icmp slt i64 %t44, %t27
  br i1 %t30, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %if_end_8
  %t49 = icmp eq ptr %t19.1, null
  br i1 %t49, label %math_sum_end_12, label %math_sum_cond_10.preheader

math_sum_cond_10.preheader:                       ; preds = %while_end_2
  %t50 = load i64, ptr %t19.1, align 4
  %t5211 = icmp sgt i64 %t50, 0
  br i1 %t5211, label %math_sum_body_11.lr.ph, label %math_sum_end_12

math_sum_body_11.lr.ph:                           ; preds = %math_sum_cond_10.preheader
  %t53 = getelementptr i8, ptr %t19.1, i64 8
  br label %math_sum_body_11

math_sum_body_11:                                 ; preds = %math_sum_body_11.lr.ph, %math_sum_body_11
  %t48.013 = phi i64 [ 0, %math_sum_body_11.lr.ph ], [ %t59, %math_sum_body_11 ]
  %t47.012 = phi i64 [ 0, %math_sum_body_11.lr.ph ], [ %t58, %math_sum_body_11 ]
  %t54 = shl i64 %t48.013, 3
  %t55 = getelementptr i8, ptr %t53, i64 %t54
  %t56 = load i64, ptr %t55, align 4
  %t58 = add i64 %t56, %t47.012
  %t59 = add nuw nsw i64 %t48.013, 1
  %t52 = icmp slt i64 %t59, %t50
  br i1 %t52, label %math_sum_body_11, label %math_sum_end_12

math_sum_end_12:                                  ; preds = %math_sum_body_11, %math_sum_cond_10.preheader, %while_end_2
  %t47.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_10.preheader ], [ %t58, %math_sum_body_11 ]
  %t63 = tail call ptr @mire_i64_to_string(i64 %t47.1)
  %t64 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t63)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t64)
  %t68 = getelementptr inbounds i8, ptr %t19.1, i64 -8
  %t70 = load i64, ptr %t68, align 4
  %t73 = tail call ptr @mire_i64_to_string(i64 %t70)
  %t74 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t73)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t74)
  %t77 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t5)
  %t78 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t77)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t78)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #2

attributes #0 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nofree nounwind }
