; ModuleID = 'build/release/vector_stress.ll'
source_filename = "build/release/vector_stress.ll"

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

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.014 = phi ptr [ null, %entry ], [ %t12, %while_body_1 ]
  %t6.013 = phi i64 [ 0, %entry ], [ %t14, %while_body_1 ]
  %t11 = mul nuw nsw i64 %t6.013, 3
  %t12 = tail call ptr @mire_list_push_i64(ptr %t4.014, i64 %t11)
  %t14 = add nuw nsw i64 %t6.013, 1
  %t8 = icmp samesign ult i64 %t6.013, 14999
  br i1 %t8, label %while_body_1, label %math_sum_cond_4.preheader

math_sum_cond_4.preheader:                        ; preds = %while_body_1
  %t36.pre = load i64, ptr %t12, align 4
  %t2215 = icmp sgt i64 %t36.pre, 0
  br i1 %t2215, label %math_sum_body_5.lr.ph, label %math_sum_end_6

math_sum_body_5.lr.ph:                            ; preds = %math_sum_cond_4.preheader
  %t23 = getelementptr i8, ptr %t12, i64 8
  br label %math_sum_body_5

math_sum_body_5:                                  ; preds = %math_sum_body_5.lr.ph, %math_sum_body_5
  %t17.017 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t28, %math_sum_body_5 ]
  %t18.016 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t29, %math_sum_body_5 ]
  %t24 = shl i64 %t18.016, 3
  %t25 = getelementptr i8, ptr %t23, i64 %t24
  %t26 = load i64, ptr %t25, align 4
  %t28 = add i64 %t26, %t17.017
  %t29 = add nuw nsw i64 %t18.016, 1
  %t22 = icmp slt i64 %t29, %t36.pre
  br i1 %t22, label %math_sum_body_5, label %math_sum_end_6

math_sum_end_6:                                   ; preds = %math_sum_body_5, %math_sum_cond_4.preheader
  %t17.1 = phi i64 [ 0, %math_sum_cond_4.preheader ], [ %t28, %math_sum_body_5 ]
  %t41 = getelementptr inbounds nuw i8, ptr %t12, i64 60000
  %t42 = load i64, ptr %t41, align 4
  %t47 = getelementptr inbounds nuw i8, ptr %t12, i64 119992
  %t48 = load i64, ptr %t47, align 4
  %t51 = tail call ptr @mire_i64_to_string(i64 %t17.1)
  %t52 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t51)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t52)
  %t56 = getelementptr inbounds i8, ptr %t12, i64 -8
  %t58 = load i64, ptr %t56, align 4
  %t61 = tail call ptr @mire_i64_to_string(i64 %t58)
  %t62 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t61)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t62)
  %t65 = tail call ptr @mire_i64_to_string(i64 %t36.pre)
  %t66 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t65)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t66)
  %t69 = tail call ptr @mire_i64_to_string(i64 %t42)
  %t70 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t69)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t70)
  %t73 = tail call ptr @mire_i64_to_string(i64 %t48)
  %t74 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t73)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t74)
  %t77 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t78 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t77)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t78)
  %t81 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t82 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t81)
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t82)
  %t85 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t86 = tail call ptr @mire_i64_to_string(i64 %t85)
  %t87 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t86)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t87)
  %t89 = tail call i64 @mire_mem_process_bytes()
  %t90 = tail call ptr @mire_mem_format(i64 %t89)
  %t91 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t90)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t91)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
