; ModuleID = 'build/release/collections_stress.ll'
source_filename = "build/release/collections_stress.ll"

@.str1 = private unnamed_addr constant [5 x i8] c"seed\00"
@.str2 = private unnamed_addr constant [5 x i8] c"node\00"
@.str3 = private unnamed_addr constant [3 x i8] c"-x\00"
@.str4 = private unnamed_addr constant [7 x i8] c"total \00"
@.str5 = private unnamed_addr constant [7 x i8] c"items \00"
@.str6 = private unnamed_addr constant [10 x i8] c"text_len \00"
@.str7 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str8 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str9 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str10 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str11 = private unnamed_addr constant [5 x i8] c"gpu \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_gpu_snapshot() local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_string_append_owned(ptr, ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_strings_replace(ptr, ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t9 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.014 = phi ptr [ null, %entry ], [ %t14, %while_body_1 ]
  %t6.013 = phi i64 [ 0, %entry ], [ %t24, %while_body_1 ]
  %t7.012 = phi ptr [ %t9, %entry ], [ %t22, %while_body_1 ]
  %t14 = tail call ptr @mire_list_push_i64(ptr %t4.014, i64 %t6.013)
  %t18 = tail call ptr @mire_strings_replace(ptr %t7.012, ptr nonnull @.str1, ptr nonnull @.str2)
  tail call void @mire_string_free(ptr %t7.012)
  %t22 = tail call ptr @mire_string_append_owned(ptr %t18, ptr nonnull @.str3)
  %t24 = add nuw nsw i64 %t6.013, 1
  %t11 = icmp samesign ult i64 %t6.013, 4999
  br i1 %t11, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t29 = icmp eq ptr %t14, null
  br i1 %t29, label %math_sum_end_6, label %math_sum_cond_4.preheader

math_sum_cond_4.preheader:                        ; preds = %while_end_2
  %t30 = load i64, ptr %t14, align 4
  %t3215 = icmp sgt i64 %t30, 0
  br i1 %t3215, label %math_sum_body_5.lr.ph, label %math_sum_end_6

math_sum_body_5.lr.ph:                            ; preds = %math_sum_cond_4.preheader
  %t33 = getelementptr i8, ptr %t14, i64 8
  br label %math_sum_body_5

math_sum_body_5:                                  ; preds = %math_sum_body_5.lr.ph, %math_sum_body_5
  %t28.017 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t39, %math_sum_body_5 ]
  %t27.016 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t38, %math_sum_body_5 ]
  %t34 = shl i64 %t28.017, 3
  %t35 = getelementptr i8, ptr %t33, i64 %t34
  %t36 = load i64, ptr %t35, align 4
  %t38 = add i64 %t36, %t27.016
  %t39 = add nuw nsw i64 %t28.017, 1
  %t32 = icmp slt i64 %t39, %t30
  br i1 %t32, label %math_sum_body_5, label %math_sum_end_6

math_sum_end_6:                                   ; preds = %math_sum_body_5, %math_sum_cond_4.preheader, %while_end_2
  %t27.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_4.preheader ], [ %t38, %math_sum_body_5 ]
  %t42 = tail call ptr @mire_gpu_snapshot()
  %t45 = tail call ptr @mire_i64_to_string(i64 %t27.1)
  %t46 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t45)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t46)
  %t50 = getelementptr inbounds i8, ptr %t14, i64 -8
  %t52 = load i64, ptr %t50, align 4
  %t55 = tail call ptr @mire_i64_to_string(i64 %t52)
  %t56 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t55)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t56)
  %t59 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t22)
  %t60 = tail call ptr @mire_i64_to_string(i64 %t59)
  %t61 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t60)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t61)
  %t64 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t65 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t64)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t65)
  %t68 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t69 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t68)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t69)
  %t72 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t73 = tail call ptr @mire_i64_to_string(i64 %t72)
  %t74 = tail call ptr @mire_string_concat(ptr nonnull @.str9, ptr %t73)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t74)
  %t76 = tail call i64 @mire_mem_process_bytes()
  %t77 = tail call ptr @mire_mem_format(i64 %t76)
  %t78 = tail call ptr @mire_string_concat(ptr nonnull @.str10, ptr %t77)
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t78)
  %t81 = tail call ptr @mire_string_concat(ptr nonnull @.str11, ptr %t42)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t81)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
