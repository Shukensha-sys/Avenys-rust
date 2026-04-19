; ModuleID = 'build/release/typed_vector_i32_stress.ll'
source_filename = "build/release/typed_vector_i32_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [5 x i8] c"mid \00"
@.str4 = private unnamed_addr constant [6 x i8] c"last \00"
@.str5 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str6 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str7 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str8 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_scalar(ptr, i64, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.014 = phi ptr [ null, %entry ], [ %t11, %while_body_1 ]
  %t6.013 = phi i64 [ 0, %entry ], [ %t13, %while_body_1 ]
  %t11 = tail call ptr @mire_list_push_scalar(ptr %t4.014, i64 %t6.013, i64 4)
  %t13 = add nuw nsw i64 %t6.013, 1
  %t8 = icmp samesign ult i64 %t6.013, 29999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t18 = icmp eq ptr %t11, null
  br i1 %t18, label %math_sum_end_6, label %math_sum_cond_4.preheader

math_sum_cond_4.preheader:                        ; preds = %while_end_2
  %t19 = load i64, ptr %t11, align 4
  %t2115 = icmp sgt i64 %t19, 0
  %0 = trunc i64 %t19 to i32
  br i1 %t2115, label %math_sum_body_5.lr.ph, label %math_sum_end_6

math_sum_body_5.lr.ph:                            ; preds = %math_sum_cond_4.preheader
  %t22 = getelementptr i8, ptr %t11, i64 8
  br label %math_sum_body_5

math_sum_body_5:                                  ; preds = %math_sum_body_5.lr.ph, %math_sum_body_5
  %t16.017 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t27, %math_sum_body_5 ]
  %t17.016 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t28, %math_sum_body_5 ]
  %t23 = shl i64 %t17.016, 2
  %t24 = getelementptr i8, ptr %t22, i64 %t23
  %t29 = load i32, ptr %t24, align 4
  %t25 = sext i32 %t29 to i64
  %t27 = add i64 %t16.017, %t25
  %t28 = add nuw nsw i64 %t17.016, 1
  %t21 = icmp slt i64 %t28, %t19
  br i1 %t21, label %math_sum_body_5, label %math_sum_end_6

math_sum_end_6:                                   ; preds = %math_sum_body_5, %while_end_2, %math_sum_cond_4.preheader
  %t36 = phi i32 [ undef, %while_end_2 ], [ %0, %math_sum_cond_4.preheader ], [ %0, %math_sum_body_5 ]
  %t16.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_4.preheader ], [ %t27, %math_sum_body_5 ]
  %t42 = getelementptr inbounds nuw i8, ptr %t11, i64 60000
  %t43 = load i32, ptr %t42, align 4
  %t49 = getelementptr inbounds nuw i8, ptr %t11, i64 119996
  %t50 = load i32, ptr %t49, align 4
  %t54 = tail call ptr @mire_i64_to_string(i64 %t16.1)
  %t55 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t54)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t55)
  %t59 = getelementptr inbounds i8, ptr %t11, i64 -8
  %t61 = load i64, ptr %t59, align 4
  %t51 = sext i32 %t50 to i64
  %t44 = sext i32 %t43 to i64
  %t37 = sext i32 %t36 to i64
  %t64 = tail call ptr @mire_i64_to_string(i64 %t61)
  %t65 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t64)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t65)
  %t68 = tail call ptr @mire_i64_to_string(i64 %t37)
  %t69 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t68)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t69)
  %t72 = tail call ptr @mire_i64_to_string(i64 %t44)
  %t73 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t72)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t73)
  %t76 = tail call ptr @mire_i64_to_string(i64 %t51)
  %t77 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t76)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t77)
  %t80 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t81 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t80)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t81)
  %t84 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t85 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t84)
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t85)
  %t88 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t89 = tail call ptr @mire_i64_to_string(i64 %t88)
  %t90 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t89)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t90)
  %t92 = tail call i64 @mire_mem_process_bytes()
  %t93 = tail call ptr @mire_mem_format(i64 %t92)
  %t94 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t93)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t94)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
