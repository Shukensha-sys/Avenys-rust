; ModuleID = 'build/release/flow_stress.ll'
source_filename = "build/release/flow_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [10 x i8] c"checksum \00"
@.str2 = private unnamed_addr constant [9 x i8] c"tag_len \00"

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define range(i64 0, 997) i64 @fn_weight(i64 %arg_x, i64 %arg_y) local_unnamed_addr #0 {
entry:
  %t4 = mul i64 %arg_x, 17
  %t6 = mul i64 %arg_y, 23
  %t7 = add i64 %t6, %t4
  %t13 = and i64 %t7, 1
  %t14 = icmp eq i64 %t13, 0
  %t103 = lshr i64 %t7, 1
  %t16 = mul i64 %t7, 3
  %t17 = add nsw i64 %t16, -1
  %t11.0 = select i1 %t14, i64 %t103, i64 %t17
  %t20 = urem i64 %t11.0, 997
  ret i64 %t20
}

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  br label %for_cond_6.preheader

for_cond_6.preheader:                             ; preds = %entry, %for_end_12
  %t21.025 = phi i64 [ 0, %entry ], [ %t58, %for_end_12 ]
  %t23.024 = phi i64 [ 0, %entry ], [ %.us-phi22, %for_end_12 ]
  %t22.023 = phi i64 [ 0, %entry ], [ %.us-phi, %for_end_12 ]
  %t4.i = mul nuw nsw i64 %t21.025, 17
  %t52.lhs.trunc = trunc i64 %t21.025 to i16
  %t5228 = urem i16 %t52.lhs.trunc, 97
  %t53 = icmp eq i16 %t5228, 0
  br i1 %t53, label %for_body_7, label %for_body_7.us

for_body_7.us:                                    ; preds = %for_cond_6.preheader, %for_continue_8.us
  %t26.021.us = phi i64 [ %t56.us, %for_continue_8.us ], [ 0, %for_cond_6.preheader ]
  %t23.120.us = phi i64 [ %t23.3.us, %for_continue_8.us ], [ %t23.024, %for_cond_6.preheader ]
  %t22.119.us = phi i64 [ %t22.3.us, %for_continue_8.us ], [ %t22.023, %for_cond_6.preheader ]
  %t34.us = icmp eq i64 %t26.021.us, 7
  br i1 %t34.us, label %for_continue_8.us, label %if_end_15.us

if_end_15.us:                                     ; preds = %for_body_7.us
  %t6.i.us = mul nuw nsw i64 %t26.021.us, 23
  %t7.i.us = add nuw nsw i64 %t6.i.us, %t4.i
  %t13.i.us = and i64 %t7.i.us, 1
  %t14.i.us = icmp eq i64 %t13.i.us, 0
  %t103.i.us = lshr i64 %t7.i.us, 1
  %t16.i.us = mul nuw nsw i64 %t7.i.us, 3
  %t17.i.us = add nsw i64 %t16.i.us, -1
  %t11.0.i.us = select i1 %t14.i.us, i64 %t103.i.us, i64 %t17.i.us
  %t20.i.us = urem i64 %t11.0.i.us, 997
  %t41.us = add i64 %t20.i.us, %t22.119.us
  %t43.lhs.trunc.us = trunc nuw nsw i64 %t20.i.us to i16
  %t43.lhs.trunc.us.frozen = freeze i16 %t43.lhs.trunc.us
  %t4718.us = udiv i16 %t43.lhs.trunc.us.frozen, 11
  %0 = mul i16 %t4718.us, 11
  %t4317.us.decomposed = sub i16 %t43.lhs.trunc.us.frozen, %0
  %t44.us = icmp eq i16 %t4317.us.decomposed, 0
  br i1 %t44.us, label %if_then_16.us, label %for_continue_8.us

if_then_16.us:                                    ; preds = %if_end_15.us
  %t47.zext.us = zext nneg i16 %t4718.us to i64
  %t48.us = add i64 %t23.120.us, %t47.zext.us
  br label %for_continue_8.us

for_continue_8.us:                                ; preds = %if_end_15.us, %if_then_16.us, %for_body_7.us
  %t22.3.us = phi i64 [ %t22.119.us, %for_body_7.us ], [ %t41.us, %if_then_16.us ], [ %t41.us, %if_end_15.us ]
  %t23.3.us = phi i64 [ %t23.120.us, %for_body_7.us ], [ %t48.us, %if_then_16.us ], [ %t23.120.us, %if_end_15.us ]
  %t56.us = add nuw nsw i64 %t26.021.us, 1
  %t29.us = icmp samesign ult i64 %t26.021.us, 63
  br i1 %t29.us, label %for_body_7.us, label %for_end_12

dowhile_body_22.preheader:                        ; preds = %for_end_12
  %1 = add i64 %.us-phi22, 8256
  %t69 = tail call ptr @mire_i64_to_string(i64 %.us-phi)
  %t70 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t69)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t70)
  %t73 = tail call ptr @mire_i64_to_string(i64 %1)
  %t74 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t73)
  %puts15 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t74)
  %t78 = tail call ptr @mire_i64_to_string(i64 18)
  %t79 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t78)
  %puts16 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t79)
  ret i64 0

for_body_7:                                       ; preds = %for_cond_6.preheader, %for_continue_8
  %t26.021 = phi i64 [ %t56, %for_continue_8 ], [ 0, %for_cond_6.preheader ]
  %t23.120 = phi i64 [ %t23.3, %for_continue_8 ], [ %t23.024, %for_cond_6.preheader ]
  %t22.119 = phi i64 [ %t22.3, %for_continue_8 ], [ %t22.023, %for_cond_6.preheader ]
  %t34 = icmp eq i64 %t26.021, 7
  br i1 %t34, label %for_continue_8, label %if_end_15

if_end_15:                                        ; preds = %for_body_7
  %t6.i = mul nuw nsw i64 %t26.021, 23
  %t7.i = add nuw nsw i64 %t6.i, %t4.i
  %t13.i = and i64 %t7.i, 1
  %t14.i = icmp eq i64 %t13.i, 0
  %t103.i = lshr i64 %t7.i, 1
  %t16.i = mul nuw nsw i64 %t7.i, 3
  %t17.i = add nsw i64 %t16.i, -1
  %t11.0.i = select i1 %t14.i, i64 %t103.i, i64 %t17.i
  %t20.i = urem i64 %t11.0.i, 997
  %t41 = add i64 %t20.i, %t22.119
  %t43.lhs.trunc = trunc nuw nsw i64 %t20.i to i16
  %t43.lhs.trunc.frozen = freeze i16 %t43.lhs.trunc
  %t4718 = udiv i16 %t43.lhs.trunc.frozen, 11
  %2 = mul i16 %t4718, 11
  %t4317.decomposed = sub i16 %t43.lhs.trunc.frozen, %2
  %t44 = icmp eq i16 %t4317.decomposed, 0
  %t47.zext = zext nneg i16 %t4718 to i64
  %t48 = add i64 %t23.120, %t47.zext
  %t23.4 = select i1 %t44, i64 %t48, i64 %t23.120
  %t50 = icmp eq i64 %t26.021, 61
  br i1 %t50, label %for_end_12, label %for_continue_8

for_continue_8:                                   ; preds = %if_end_15, %for_body_7
  %t22.3 = phi i64 [ %t22.119, %for_body_7 ], [ %t41, %if_end_15 ]
  %t23.3 = phi i64 [ %t23.120, %for_body_7 ], [ %t23.4, %if_end_15 ]
  %t56 = add nuw nsw i64 %t26.021, 1
  %t29 = icmp samesign ult i64 %t26.021, 63
  br i1 %t29, label %for_body_7, label %for_end_12

for_end_12:                                       ; preds = %for_continue_8.us, %for_continue_8, %if_end_15
  %.us-phi = phi i64 [ %t41, %if_end_15 ], [ %t22.3, %for_continue_8 ], [ %t22.3.us, %for_continue_8.us ]
  %.us-phi22 = phi i64 [ %t23.4, %if_end_15 ], [ %t23.3, %for_continue_8 ], [ %t23.3.us, %for_continue_8.us ]
  %t58 = add nuw nsw i64 %t21.025, 1
  %t25 = icmp samesign ult i64 %t21.025, 17999
  br i1 %t25, label %for_cond_6.preheader, label %dowhile_body_22.preheader
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %call_main = tail call i64 @mire_main()
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nofree nounwind }
