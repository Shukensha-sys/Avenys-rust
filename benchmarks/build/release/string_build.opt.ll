; ModuleID = 'build/release/string_build.ll'
source_filename = "build/release/string_build.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"seed\00"
@.str1 = private unnamed_addr constant [3 x i8] c"-x\00"
@.str2 = private unnamed_addr constant [8 x i8] c"length \00"
@.str3 = private unnamed_addr constant [12 x i8] c"elapsed_ms \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

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
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t6 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.029 = phi ptr [ %t6, %entry ], [ %new_ptr.i, %while_body_1 ]
  %t3.028 = phi i64 [ 0, %entry ], [ %t15, %while_body_1 ]
  %len_a.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t4.029)
  %alloc_len.i = add i64 %len_a.i, 3
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull %t4.029, i64 %len_a.i)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 %len_a.i
  tail call void @memcpy(ptr %dest.i, ptr nonnull @.str1, i64 2)
  %end.i = getelementptr i8, ptr %dest.i, i64 2
  store i8 0, ptr %end.i, align 1
  tail call void @mire_string_free(ptr nonnull %t4.029)
  %t15 = add nuw nsw i64 %t3.028, 1
  %t9 = icmp samesign ult i64 %t3.028, 19999
  br i1 %t9, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t18 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %new_ptr.i)
  %t19 = tail call ptr @mire_i64_to_string(i64 %t18)
  %len_b.i5 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t19)
  %alloc_len.i7 = add i64 %len_b.i5, 8
  %new.i8 = tail call i64 @malloc(i64 %alloc_len.i7)
  %new_ptr.i9 = inttoptr i64 %new.i8 to ptr
  tail call void @memcpy(ptr %new_ptr.i9, ptr nonnull @.str2, i64 7)
  %dest.i10 = getelementptr i8, ptr %new_ptr.i9, i64 7
  tail call void @memcpy(ptr %dest.i10, ptr nonnull %t19, i64 %len_b.i5)
  %0 = getelementptr i8, ptr %new_ptr.i9, i64 %len_b.i5
  %end.i11 = getelementptr i8, ptr %0, i64 7
  store i8 0, ptr %end.i11, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i9)
  %t23 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i13 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t23)
  %alloc_len.i15 = add i64 %len_b.i13, 12
  %new.i16 = tail call i64 @malloc(i64 %alloc_len.i15)
  %new_ptr.i17 = inttoptr i64 %new.i16 to ptr
  tail call void @memcpy(ptr %new_ptr.i17, ptr nonnull @.str3, i64 11)
  %dest.i18 = getelementptr i8, ptr %new_ptr.i17, i64 11
  tail call void @memcpy(ptr %dest.i18, ptr nonnull %t23, i64 %len_b.i13)
  %1 = getelementptr i8, ptr %new_ptr.i17, i64 %len_b.i13
  %end.i19 = getelementptr i8, ptr %1, i64 11
  store i8 0, ptr %end.i19, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i17)
  %t26 = tail call i64 @mire_mem_process_bytes()
  %t27 = tail call ptr @mire_mem_format(i64 %t26)
  %len_b.i21 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t27)
  %alloc_len.i23 = add i64 %len_b.i21, 13
  %new.i24 = tail call i64 @malloc(i64 %alloc_len.i23)
  %new_ptr.i25 = inttoptr i64 %new.i24 to ptr
  tail call void @memcpy(ptr %new_ptr.i25, ptr nonnull @.str4, i64 12)
  %dest.i26 = getelementptr i8, ptr %new_ptr.i25, i64 12
  tail call void @memcpy(ptr %dest.i26, ptr nonnull %t27, i64 %len_b.i21)
  %2 = getelementptr i8, ptr %new_ptr.i25, i64 %len_b.i21
  %end.i27 = getelementptr i8, ptr %2, i64 12
  store i8 0, ptr %end.i27, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i25)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
