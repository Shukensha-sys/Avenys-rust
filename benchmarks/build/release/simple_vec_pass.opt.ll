; ModuleID = 'build/release/simple_vec_pass.ll'
source_filename = "build/release/simple_vec_pass.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"len \00"
@.str1 = private unnamed_addr constant [7 x i8] c"first \00"
@.str2 = private unnamed_addr constant [8 x i8] c"second \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_list_concat(ptr, ptr) local_unnamed_addr

; Function Attrs: mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none)
define ptr @concat(ptr captures(none) %a, ptr captures(none) %b) local_unnamed_addr #3 {
  %len_a = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %a)
  %len_b = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %b)
  %len = add i64 %len_b, %len_a
  %alloc_len = add i64 %len, 1
  %new = tail call i64 @malloc(i64 %alloc_len)
  %new_ptr = inttoptr i64 %new to ptr
  tail call void @memcpy(ptr %new_ptr, ptr nonnull %a, i64 %len_a)
  %dest = getelementptr i8, ptr %new_ptr, i64 %len_a
  tail call void @memcpy(ptr %dest, ptr nonnull %b, i64 %len_b)
  %end = getelementptr i8, ptr %new_ptr, i64 %len
  store i8 0, ptr %end, align 1
  ret ptr %new_ptr
}

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  %t3 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t3, align 4
  %t4 = getelementptr i8, ptr %t3, i64 8
  store i64 1, ptr %t4, align 4
  %t5 = getelementptr i8, ptr %t3, i64 16
  store i64 1, ptr %t5, align 4
  %t6 = tail call ptr @mire_list_concat(ptr null, ptr nonnull %t4)
  %t8 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t8, align 4
  %t9 = getelementptr i8, ptr %t8, i64 8
  store i64 1, ptr %t9, align 4
  %t10 = getelementptr i8, ptr %t8, i64 16
  store i64 2, ptr %t10, align 4
  %t11 = tail call ptr @mire_list_concat(ptr %t6, ptr nonnull %t9)
  %t15 = icmp eq ptr %t11, null
  br i1 %t15, label %list_len_end_2, label %list_len_load_1

list_len_load_1:                                  ; preds = %entry
  %t16 = load i64, ptr %t11, align 4
  br label %list_len_end_2

list_len_end_2:                                   ; preds = %entry, %list_len_load_1
  %t18.0 = phi i64 [ %t16, %list_len_load_1 ], [ 0, %entry ]
  %t21 = tail call ptr @mire_i64_to_string(i64 %t18.0)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t21)
  %alloc_len.i = add i64 %len_b.i, 5
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 4)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 4
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t21, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 4
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t25 = getelementptr inbounds nuw i8, ptr %t11, i64 8
  %t28 = load i64, ptr %t25, align 4
  %t29 = tail call ptr @mire_i64_to_string(i64 %t28)
  %len_b.i4 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t29)
  %alloc_len.i6 = add i64 %len_b.i4, 7
  %new.i7 = tail call i64 @malloc(i64 %alloc_len.i6)
  %new_ptr.i8 = inttoptr i64 %new.i7 to ptr
  tail call void @memcpy(ptr %new_ptr.i8, ptr nonnull @.str1, i64 6)
  %dest.i9 = getelementptr i8, ptr %new_ptr.i8, i64 6
  tail call void @memcpy(ptr %dest.i9, ptr nonnull %t29, i64 %len_b.i4)
  %1 = getelementptr i8, ptr %new_ptr.i8, i64 %len_b.i4
  %end.i10 = getelementptr i8, ptr %1, i64 6
  store i8 0, ptr %end.i10, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i8)
  %t35 = getelementptr inbounds nuw i8, ptr %t11, i64 16
  %t36 = load i64, ptr %t35, align 4
  %t37 = tail call ptr @mire_i64_to_string(i64 %t36)
  %len_b.i12 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t37)
  %alloc_len.i14 = add i64 %len_b.i12, 8
  %new.i15 = tail call i64 @malloc(i64 %alloc_len.i14)
  %new_ptr.i16 = inttoptr i64 %new.i15 to ptr
  tail call void @memcpy(ptr %new_ptr.i16, ptr nonnull @.str2, i64 7)
  %dest.i17 = getelementptr i8, ptr %new_ptr.i16, i64 7
  tail call void @memcpy(ptr %dest.i17, ptr nonnull %t37, i64 %len_b.i12)
  %2 = getelementptr i8, ptr %new_ptr.i16, i64 %len_b.i12
  %end.i18 = getelementptr i8, ptr %2, i64 7
  store i8 0, ptr %end.i18, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i16)
  ret i64 0
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %call_main = tail call i64 @mire_main()
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
