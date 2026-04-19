; ModuleID = 'build/release/vec_plus_vec.ll'
source_filename = "build/release/vec_plus_vec.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"len \00"
@.str1 = private unnamed_addr constant [13 x i8] c"process_ram \00"

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #0

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_concat(ptr, ptr) local_unnamed_addr

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t2.05 = phi i64 [ 0, %entry ], [ %t12, %while_body_1 ]
  %t0.04 = phi ptr [ null, %entry ], [ %t10, %while_body_1 ]
  %t6 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t6, align 4
  %t7 = getelementptr i8, ptr %t6, i64 8
  store i64 1, ptr %t7, align 4
  %t9 = getelementptr i8, ptr %t6, i64 16
  store i64 %t2.05, ptr %t9, align 4
  %t10 = tail call ptr @mire_list_concat(ptr %t0.04, ptr nonnull %t7)
  %t12 = add nuw nsw i64 %t2.05, 1
  %t4 = icmp samesign ult i64 %t2.05, 99
  br i1 %t4, label %while_body_1, label %list_len_end_5

list_len_end_5:                                   ; preds = %while_body_1
  %t16 = getelementptr inbounds i8, ptr %t10, i64 -8
  %t18 = load i64, ptr %t16, align 4
  %t21 = tail call ptr @mire_i64_to_string(i64 %t18)
  %t22 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t21)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t22)
  %t24 = tail call i64 @mire_mem_process_bytes()
  %t25 = tail call ptr @mire_mem_format(i64 %t24)
  %t26 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t25)
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t26)
  ret i64 0
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %call_main = tail call i64 @mire_main()
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #1 = { nofree nounwind }
