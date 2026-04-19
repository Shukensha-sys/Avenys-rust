; ModuleID = 'build/release/typed_vector_bool_stress.ll'
source_filename = "build/release/typed_vector_bool_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [7 x i8] c"items \00"
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [6 x i8] c"last \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str6 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str7 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_bool_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_scalar(ptr, i64, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_cond_3.preheader:                           ; preds = %while_body_1
  %t22 = getelementptr inbounds i8, ptr %t13, i64 -8
  %t24 = load i64, ptr %t22, align 4
  %t2716 = icmp sgt i64 %t24, 0
  br i1 %t2716, label %while_body_4, label %while_end_5

while_body_1:                                     ; preds = %entry, %while_body_1
  %t6.015 = phi i64 [ 0, %entry ], [ %t16, %while_body_1 ]
  %t4.014 = phi ptr [ null, %entry ], [ %t13, %while_body_1 ]
  %t11 = and i64 %t6.015, 1
  %t14 = xor i64 %t11, 1
  %t13 = tail call ptr @mire_list_push_scalar(ptr %t4.014, i64 %t14, i64 1)
  %t16 = add nuw nsw i64 %t6.015, 1
  %t8 = icmp samesign ult i64 %t6.015, 19999
  br i1 %t8, label %while_body_1, label %while_cond_3.preheader

while_body_4:                                     ; preds = %while_cond_3.preheader, %while_body_4
  %t18.018 = phi i64 [ %t38, %while_body_4 ], [ 0, %while_cond_3.preheader ]
  %t17.017 = phi i64 [ %spec.select, %while_body_4 ], [ 0, %while_cond_3.preheader ]
  %t32 = getelementptr inbounds nuw i8, ptr %t13, i64 %t18.018
  %t33 = load i8, ptr %t32, align 1
  %t34.not = icmp ne i8 %t33, 0
  %t36 = zext i1 %t34.not to i64
  %spec.select = add i64 %t17.017, %t36
  %t38 = add nuw nsw i64 %t18.018, 1
  %t27 = icmp slt i64 %t38, %t24
  br i1 %t27, label %while_body_4, label %while_end_5

while_end_5:                                      ; preds = %while_body_4, %while_cond_3.preheader
  %t17.0.lcssa = phi i64 [ 0, %while_cond_3.preheader ], [ %spec.select, %while_body_4 ]
  %t41 = tail call ptr @mire_i64_to_string(i64 %t17.0.lcssa)
  %t42 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t41)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t42)
  %t48 = load i64, ptr %t22, align 4
  %t51 = tail call ptr @mire_i64_to_string(i64 %t48)
  %t52 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t51)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t52)
  %t58 = load i8, ptr %t13, align 4
  %t59 = icmp ne i8 %t58, 0
  %t60 = zext i1 %t59 to i64
  %t61 = tail call ptr @mire_bool_to_string(i64 %t60)
  %t62 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t61)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t62)
  %t67 = getelementptr inbounds nuw i8, ptr %t13, i64 19999
  %t68 = load i8, ptr %t67, align 1
  %t69 = icmp ne i8 %t68, 0
  %t70 = zext i1 %t69 to i64
  %t71 = tail call ptr @mire_bool_to_string(i64 %t70)
  %t72 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t71)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t72)
  %t75 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t76 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t75)
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t76)
  %t79 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t80 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t79)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t80)
  %t83 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t84 = tail call ptr @mire_i64_to_string(i64 %t83)
  %t85 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t84)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t85)
  %t87 = tail call i64 @mire_mem_process_bytes()
  %t88 = tail call ptr @mire_mem_format(i64 %t87)
  %t89 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t88)
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t89)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
