; ModuleID = 'build/release/list_string_ops.ll'
source_filename = "build/release/list_string_ops.ll"

@.str0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str1 = private unnamed_addr constant [6 x i8] c"world\00"
@.str2 = private unnamed_addr constant [5 x i8] c"test\00"
@.str3 = private unnamed_addr constant [7 x i8] c"first \00"
@.str4 = private unnamed_addr constant [8 x i8] c"second \00"
@.str5 = private unnamed_addr constant [6 x i8] c"last \00"
@.str6 = private unnamed_addr constant [5 x i8] c"len \00"
@.str7 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_list_push_ptr(ptr, ptr) local_unnamed_addr

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

define noundef i32 @main() local_unnamed_addr {
list_len_end_2:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t8 = tail call ptr @mire_list_push_ptr(ptr null, ptr nonnull @.str0)
  %t11 = tail call ptr @mire_list_push_ptr(ptr %t8, ptr nonnull @.str1)
  %t14 = tail call ptr @mire_list_push_ptr(ptr %t11, ptr nonnull @.str2)
  %t17 = getelementptr inbounds nuw i8, ptr %t14, i64 8
  %t20 = load ptr, ptr %t17, align 8
  %t21 = tail call ptr @mire_string_copy(ptr %t20)
  %t26 = getelementptr inbounds nuw i8, ptr %t14, i64 16
  %t27 = load ptr, ptr %t26, align 8
  %t28 = tail call ptr @mire_string_copy(ptr %t27)
  %t33 = getelementptr inbounds nuw i8, ptr %t14, i64 24
  %t34 = load ptr, ptr %t33, align 8
  %t35 = tail call ptr @mire_string_copy(ptr %t34)
  %t40 = load i64, ptr %t14, align 8
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t21)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str3, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t21, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %len_b.i6 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t28)
  %alloc_len.i8 = add i64 %len_b.i6, 8
  %new.i9 = tail call i64 @malloc(i64 %alloc_len.i8)
  %new_ptr.i10 = inttoptr i64 %new.i9 to ptr
  tail call void @memcpy(ptr %new_ptr.i10, ptr nonnull @.str4, i64 7)
  %dest.i11 = getelementptr i8, ptr %new_ptr.i10, i64 7
  tail call void @memcpy(ptr %dest.i11, ptr nonnull %t28, i64 %len_b.i6)
  %1 = getelementptr i8, ptr %new_ptr.i10, i64 %len_b.i6
  %end.i12 = getelementptr i8, ptr %1, i64 7
  store i8 0, ptr %end.i12, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i10)
  %len_b.i14 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t35)
  %alloc_len.i16 = add i64 %len_b.i14, 6
  %new.i17 = tail call i64 @malloc(i64 %alloc_len.i16)
  %new_ptr.i18 = inttoptr i64 %new.i17 to ptr
  tail call void @memcpy(ptr %new_ptr.i18, ptr nonnull @.str5, i64 5)
  %dest.i19 = getelementptr i8, ptr %new_ptr.i18, i64 5
  tail call void @memcpy(ptr %dest.i19, ptr nonnull %t35, i64 %len_b.i14)
  %2 = getelementptr i8, ptr %new_ptr.i18, i64 %len_b.i14
  %end.i20 = getelementptr i8, ptr %2, i64 5
  store i8 0, ptr %end.i20, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i18)
  %t54 = tail call ptr @mire_i64_to_string(i64 %t40)
  %len_b.i22 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t54)
  %alloc_len.i24 = add i64 %len_b.i22, 5
  %new.i25 = tail call i64 @malloc(i64 %alloc_len.i24)
  %new_ptr.i26 = inttoptr i64 %new.i25 to ptr
  tail call void @memcpy(ptr %new_ptr.i26, ptr nonnull @.str6, i64 4)
  %dest.i27 = getelementptr i8, ptr %new_ptr.i26, i64 4
  tail call void @memcpy(ptr %dest.i27, ptr nonnull %t54, i64 %len_b.i22)
  %3 = getelementptr i8, ptr %new_ptr.i26, i64 %len_b.i22
  %end.i28 = getelementptr i8, ptr %3, i64 4
  store i8 0, ptr %end.i28, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i26)
  %t58 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i30 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t58)
  %alloc_len.i32 = add i64 %len_b.i30, 9
  %new.i33 = tail call i64 @malloc(i64 %alloc_len.i32)
  %new_ptr.i34 = inttoptr i64 %new.i33 to ptr
  tail call void @memcpy(ptr %new_ptr.i34, ptr nonnull @.str7, i64 8)
  %dest.i35 = getelementptr i8, ptr %new_ptr.i34, i64 8
  tail call void @memcpy(ptr %dest.i35, ptr nonnull %t58, i64 %len_b.i30)
  %4 = getelementptr i8, ptr %new_ptr.i34, i64 %len_b.i30
  %end.i36 = getelementptr i8, ptr %4, i64 8
  store i8 0, ptr %end.i36, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i34)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
