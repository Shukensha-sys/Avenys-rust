; ModuleID = 'build/release/list_slice_test.ll'
source_filename = "build/release/list_slice_test.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"first \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [12 x i8] c"sliced_len \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

declare ptr @mire_list_slice(ptr, i64, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t2.07 = phi ptr [ null, %entry ], [ %t9, %while_body_1 ]
  %t4.06 = phi i64 [ 0, %entry ], [ %t11, %while_body_1 ]
  %t9 = tail call ptr @mire_list_push_i64(ptr %t2.07, i64 %t4.06)
  %t11 = add nuw nsw i64 %t4.06, 1
  %t6 = icmp samesign ult i64 %t4.06, 9999
  br i1 %t6, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t17 = load i64, ptr %t9, align 4
  %t22 = getelementptr inbounds nuw i8, ptr %t9, i64 79992
  %t23 = load i64, ptr %t22, align 4
  %t26 = tail call ptr @mire_list_slice(ptr nonnull %t9, i64 100, i64 200)
  %t29 = tail call ptr @mire_i64_to_string(i64 %t17)
  %t30 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t29)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t30)
  %t33 = tail call ptr @mire_i64_to_string(i64 %t23)
  %t34 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t33)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t34)
  %t38 = getelementptr inbounds i8, ptr %t26, i64 -8
  %t40 = load i64, ptr %t38, align 4
  %t43 = tail call ptr @mire_i64_to_string(i64 %t40)
  %t44 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t43)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t44)
  %t47 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t48 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t47)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t48)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
