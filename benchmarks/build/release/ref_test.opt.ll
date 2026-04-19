; ModuleID = 'build/release/ref_test.ll'
source_filename = "build/release/ref_test.ll"

@.str0 = private unnamed_addr constant [3 x i8] c"x \00"
@.str1 = private unnamed_addr constant [3 x i8] c"y \00"
@.str2 = private unnamed_addr constant [10 x i8] c"x_plus_y \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str4 = private unnamed_addr constant [13 x i8] c"process_ram \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

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
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t8 = tail call ptr @mire_i64_to_string(i64 10)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t8)
  %alloc_len.i = add i64 %len_b.i, 3
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 2)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 2
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t8, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 2
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t12 = tail call ptr @mire_i64_to_string(i64 20)
  %len_b.i8 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t12)
  %alloc_len.i10 = add i64 %len_b.i8, 3
  %new.i11 = tail call i64 @malloc(i64 %alloc_len.i10)
  %new_ptr.i12 = inttoptr i64 %new.i11 to ptr
  tail call void @memcpy(ptr %new_ptr.i12, ptr nonnull @.str1, i64 2)
  %dest.i13 = getelementptr i8, ptr %new_ptr.i12, i64 2
  tail call void @memcpy(ptr %dest.i13, ptr nonnull %t12, i64 %len_b.i8)
  %1 = getelementptr i8, ptr %new_ptr.i12, i64 %len_b.i8
  %end.i14 = getelementptr i8, ptr %1, i64 2
  store i8 0, ptr %end.i14, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i12)
  %t18 = tail call ptr @mire_i64_to_string(i64 30)
  %len_b.i16 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t18)
  %alloc_len.i18 = add i64 %len_b.i16, 10
  %new.i19 = tail call i64 @malloc(i64 %alloc_len.i18)
  %new_ptr.i20 = inttoptr i64 %new.i19 to ptr
  tail call void @memcpy(ptr %new_ptr.i20, ptr nonnull @.str2, i64 9)
  %dest.i21 = getelementptr i8, ptr %new_ptr.i20, i64 9
  tail call void @memcpy(ptr %dest.i21, ptr nonnull %t18, i64 %len_b.i16)
  %2 = getelementptr i8, ptr %new_ptr.i20, i64 %len_b.i16
  %end.i22 = getelementptr i8, ptr %2, i64 9
  store i8 0, ptr %end.i22, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i20)
  %t22 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i24 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t22)
  %alloc_len.i26 = add i64 %len_b.i24, 9
  %new.i27 = tail call i64 @malloc(i64 %alloc_len.i26)
  %new_ptr.i28 = inttoptr i64 %new.i27 to ptr
  tail call void @memcpy(ptr %new_ptr.i28, ptr nonnull @.str3, i64 8)
  %dest.i29 = getelementptr i8, ptr %new_ptr.i28, i64 8
  tail call void @memcpy(ptr %dest.i29, ptr nonnull %t22, i64 %len_b.i24)
  %3 = getelementptr i8, ptr %new_ptr.i28, i64 %len_b.i24
  %end.i30 = getelementptr i8, ptr %3, i64 8
  store i8 0, ptr %end.i30, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i28)
  %t25 = tail call i64 @mire_mem_process_bytes()
  %t26 = tail call ptr @mire_mem_format(i64 %t25)
  %len_b.i32 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t26)
  %alloc_len.i34 = add i64 %len_b.i32, 13
  %new.i35 = tail call i64 @malloc(i64 %alloc_len.i34)
  %new_ptr.i36 = inttoptr i64 %new.i35 to ptr
  tail call void @memcpy(ptr %new_ptr.i36, ptr nonnull @.str4, i64 12)
  %dest.i37 = getelementptr i8, ptr %new_ptr.i36, i64 12
  tail call void @memcpy(ptr %dest.i37, ptr nonnull %t26, i64 %len_b.i32)
  %4 = getelementptr i8, ptr %new_ptr.i36, i64 %len_b.i32
  %end.i38 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i38, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i36)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
