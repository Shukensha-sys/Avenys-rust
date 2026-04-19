; ModuleID = 'build/release/vec_index.ll'
source_filename = "build/release/vec_index.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"val \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [7 x i8] c"first \00"
@.str3 = private unnamed_addr constant [5 x i8] c"len \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.09 = phi ptr [ null, %entry ], [ %t11, %while_body_1 ]
  %t6.08 = phi i64 [ 0, %entry ], [ %t13, %while_body_1 ]
  %t11 = tail call ptr @mire_list_push_i64(ptr %t4.09, i64 %t6.08)
  %t13 = add nuw nsw i64 %t6.08, 1
  %t8 = icmp samesign ult i64 %t6.08, 9999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t18 = getelementptr inbounds nuw i8, ptr %t11, i64 40000
  %t19 = load i64, ptr %t18, align 4
  %t24 = getelementptr inbounds nuw i8, ptr %t11, i64 79992
  %t25 = load i64, ptr %t24, align 4
  %t31 = load i64, ptr %t11, align 4
  %t34 = tail call ptr @mire_i64_to_string(i64 %t19)
  %t35 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t34)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t35)
  %t38 = tail call ptr @mire_i64_to_string(i64 %t25)
  %t39 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t38)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t39)
  %t42 = tail call ptr @mire_i64_to_string(i64 %t31)
  %t43 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t42)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t43)
  %t47 = getelementptr inbounds i8, ptr %t11, i64 -8
  %t49 = load i64, ptr %t47, align 4
  %t52 = tail call ptr @mire_i64_to_string(i64 %t49)
  %t53 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t52)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t53)
  %t56 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t57 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t56)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t57)
  %t60 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t61 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t60)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t61)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
