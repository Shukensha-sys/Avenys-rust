; ModuleID = 'build/release/higher_order_filter.ll'
source_filename = "build/release/higher_order_filter.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define ptr @fn_filter_even(ptr readonly captures(none) %arg_xs) local_unnamed_addr {
entry:
  %t7 = getelementptr inbounds i8, ptr %arg_xs, i64 -8
  %t94 = load i64, ptr %t7, align 4
  %t125 = icmp sgt i64 %t94, 0
  br i1 %t125, label %while_body_1, label %while_end_2

while_body_1:                                     ; preds = %entry, %if_end_8
  %t98 = phi i64 [ %t9, %if_end_8 ], [ %t94, %entry ]
  %t1.07 = phi ptr [ %t1.1, %if_end_8 ], [ null, %entry ]
  %t3.06 = phi i64 [ %t27, %if_end_8 ], [ 0, %entry ]
  %t17 = shl i64 %t3.06, 3
  %t18 = getelementptr inbounds i8, ptr %arg_xs, i64 %t17
  %t19 = load i64, ptr %t18, align 4
  %t21 = and i64 %t19, 1
  %t22 = icmp eq i64 %t21, 0
  br i1 %t22, label %if_then_6, label %if_end_8

if_then_6:                                        ; preds = %while_body_1
  %t25 = tail call ptr @mire_list_push_i64(ptr %t1.07, i64 %t19)
  %t9.pre = load i64, ptr %t7, align 4
  br label %if_end_8

if_end_8:                                         ; preds = %while_body_1, %if_then_6
  %t9 = phi i64 [ %t9.pre, %if_then_6 ], [ %t98, %while_body_1 ]
  %t1.1 = phi ptr [ %t25, %if_then_6 ], [ %t1.07, %while_body_1 ]
  %t27 = add nuw nsw i64 %t3.06, 1
  %t12 = icmp slt i64 %t27, %t9
  br i1 %t12, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %if_end_8, %entry
  %t1.0.lcssa = phi ptr [ null, %entry ], [ %t1.1, %if_end_8 ]
  ret ptr %t1.0.lcssa
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t30 = tail call i64 @mire_wall_mark_ns()
  %t32 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_10

while_body_10:                                    ; preds = %entry, %while_body_10
  %t33.06 = phi ptr [ null, %entry ], [ %t40, %while_body_10 ]
  %t35.05 = phi i64 [ 0, %entry ], [ %t42, %while_body_10 ]
  %t40 = tail call ptr @mire_list_push_i64(ptr %t33.06, i64 %t35.05)
  %t42 = add nuw nsw i64 %t35.05, 1
  %t37 = icmp samesign ult i64 %t35.05, 9999
  br i1 %t37, label %while_body_10, label %while_end_11

while_end_11:                                     ; preds = %while_body_10
  %t7.i = getelementptr inbounds i8, ptr %t40, i64 -8
  %t94.i = load i64, ptr %t7.i, align 4
  %t125.i = icmp sgt i64 %t94.i, 0
  tail call void @llvm.assume(i1 %t125.i)
  br label %while_body_1.i

while_body_1.i:                                   ; preds = %while_end_11, %if_end_8.i
  %t98.i = phi i64 [ %t9.i, %if_end_8.i ], [ %t94.i, %while_end_11 ]
  %t1.07.i = phi ptr [ %t1.1.i, %if_end_8.i ], [ null, %while_end_11 ]
  %t3.06.i = phi i64 [ %t27.i, %if_end_8.i ], [ 0, %while_end_11 ]
  %t17.i = shl i64 %t3.06.i, 3
  %t18.i = getelementptr inbounds i8, ptr %t40, i64 %t17.i
  %t19.i = load i64, ptr %t18.i, align 4
  %t21.i = and i64 %t19.i, 1
  %t22.i = icmp eq i64 %t21.i, 0
  br i1 %t22.i, label %if_then_6.i, label %if_end_8.i

if_then_6.i:                                      ; preds = %while_body_1.i
  %t25.i = tail call ptr @mire_list_push_i64(ptr %t1.07.i, i64 %t19.i)
  %t9.pre.i = load i64, ptr %t7.i, align 4
  br label %if_end_8.i

if_end_8.i:                                       ; preds = %if_then_6.i, %while_body_1.i
  %t9.i = phi i64 [ %t9.pre.i, %if_then_6.i ], [ %t98.i, %while_body_1.i ]
  %t1.1.i = phi ptr [ %t25.i, %if_then_6.i ], [ %t1.07.i, %while_body_1.i ]
  %t27.i = add nuw nsw i64 %t3.06.i, 1
  %t12.i = icmp slt i64 %t27.i, %t9.i
  br i1 %t12.i, label %while_body_1.i, label %fn_filter_even.exit

fn_filter_even.exit:                              ; preds = %if_end_8.i
  %t49 = getelementptr inbounds i8, ptr %t1.1.i, i64 -8
  %t51 = load i64, ptr %t49, align 4
  %t56 = tail call ptr @mire_i64_to_string(i64 %t51)
  %t57 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t56)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t57)
  %t60 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t30)
  %t61 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t60)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t61)
  %t64 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t32)
  %t65 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t64)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t65)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

attributes #0 = { nofree nounwind }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
