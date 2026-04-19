; ModuleID = 'build/release/fn_return_vec.ll'
source_filename = "build/release/fn_return_vec.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"len \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #0

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_concat(ptr, ptr) local_unnamed_addr

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define range(i64 0, -1) i64 @fn_map_fn(i64 %arg_x) local_unnamed_addr #1 {
entry:
  %t2 = shl i64 %arg_x, 1
  ret i64 %t2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define i1 @fn_filter_fn(i64 %arg_x) local_unnamed_addr #1 {
entry:
  %t5 = and i64 %arg_x, 1
  %t6 = icmp eq i64 %t5, 0
  ret i1 %t6
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t8 = tail call i64 @mire_wall_mark_ns()
  %t10 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t13.07 = phi i64 [ 0, %entry ], [ %t23, %while_body_1 ]
  %t11.06 = phi ptr [ null, %entry ], [ %t21, %while_body_1 ]
  %t17 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t17, align 4
  %t18 = getelementptr i8, ptr %t17, i64 8
  store i64 1, ptr %t18, align 4
  %t20 = getelementptr i8, ptr %t17, i64 16
  store i64 %t13.07, ptr %t20, align 4
  %t21 = tail call ptr @mire_list_concat(ptr %t11.06, ptr nonnull %t18)
  %t23 = add nuw nsw i64 %t13.07, 1
  %t15 = icmp samesign ult i64 %t13.07, 4999
  br i1 %t15, label %while_body_1, label %list_len_end_5

list_len_end_5:                                   ; preds = %while_body_1
  %t27 = getelementptr inbounds i8, ptr %t21, i64 -8
  %t29 = load i64, ptr %t27, align 4
  %t32 = tail call ptr @mire_i64_to_string(i64 %t29)
  %t33 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t32)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t33)
  %t36 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t8)
  %t37 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t36)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t37)
  %t40 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t10)
  %t41 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t40)
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t41)
  %t43 = tail call i64 @mire_mem_process_bytes()
  %t44 = tail call ptr @mire_mem_format(i64 %t43)
  %t45 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t44)
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t45)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #2

attributes #0 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nofree nounwind }
