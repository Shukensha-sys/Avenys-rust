; ModuleID = 'build/release/list_growth.ll'
source_filename = "build/release/list_growth.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str4 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str5 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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
  %t4.011 = phi ptr [ null, %entry ], [ %t11, %while_body_1 ]
  %t6.010 = phi i64 [ 0, %entry ], [ %t13, %while_body_1 ]
  %t11 = tail call ptr @mire_list_push_i64(ptr %t4.011, i64 %t6.010)
  %t13 = add nuw nsw i64 %t6.010, 1
  %t8 = icmp samesign ult i64 %t6.010, 19999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t18 = icmp eq ptr %t11, null
  br i1 %t18, label %math_sum_end_6, label %math_sum_cond_4.preheader

math_sum_cond_4.preheader:                        ; preds = %while_end_2
  %t19 = load i64, ptr %t11, align 4
  %t2112 = icmp sgt i64 %t19, 0
  br i1 %t2112, label %math_sum_body_5.lr.ph, label %math_sum_end_6

math_sum_body_5.lr.ph:                            ; preds = %math_sum_cond_4.preheader
  %t22 = getelementptr i8, ptr %t11, i64 8
  br label %math_sum_body_5

math_sum_body_5:                                  ; preds = %math_sum_body_5.lr.ph, %math_sum_body_5
  %t17.014 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t28, %math_sum_body_5 ]
  %t16.013 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t27, %math_sum_body_5 ]
  %t23 = shl i64 %t17.014, 3
  %t24 = getelementptr i8, ptr %t22, i64 %t23
  %t25 = load i64, ptr %t24, align 4
  %t27 = add i64 %t25, %t16.013
  %t28 = add nuw nsw i64 %t17.014, 1
  %t21 = icmp slt i64 %t28, %t19
  br i1 %t21, label %math_sum_body_5, label %math_sum_end_6

math_sum_end_6:                                   ; preds = %math_sum_body_5, %math_sum_cond_4.preheader, %while_end_2
  %t16.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_4.preheader ], [ %t27, %math_sum_body_5 ]
  %t32 = tail call ptr @mire_i64_to_string(i64 %t16.1)
  %t33 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t32)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t33)
  %t37 = getelementptr inbounds i8, ptr %t11, i64 -8
  %t39 = load i64, ptr %t37, align 4
  %t42 = tail call ptr @mire_i64_to_string(i64 %t39)
  %t43 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t42)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t43)
  %t46 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t47 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t46)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t47)
  %t50 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t51 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t50)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t51)
  %t54 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t55 = tail call ptr @mire_i64_to_string(i64 %t54)
  %t56 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t55)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t56)
  %t58 = tail call i64 @mire_mem_process_bytes()
  %t59 = tail call ptr @mire_mem_format(i64 %t58)
  %t60 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t59)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t60)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
