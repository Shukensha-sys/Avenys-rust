; ModuleID = 'build/release/simple_vec_test.ll'
source_filename = "build/release/simple_vec_test.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"len \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

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

define noundef i64 @mire_main() local_unnamed_addr {
entry:
  %t9 = tail call ptr @mire_i64_to_string(i64 0)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t9)
  %alloc_len.i = add i64 %len_b.i, 5
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 4)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 4
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t9, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 4
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  ret i64 0
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t9.i = tail call ptr @mire_i64_to_string(i64 0)
  %len_b.i.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t9.i)
  %alloc_len.i.i = add i64 %len_b.i.i, 5
  %new.i.i = tail call i64 @malloc(i64 %alloc_len.i.i)
  %new_ptr.i.i = inttoptr i64 %new.i.i to ptr
  tail call void @memcpy(ptr %new_ptr.i.i, ptr nonnull @.str0, i64 4)
  %dest.i.i = getelementptr i8, ptr %new_ptr.i.i, i64 4
  tail call void @memcpy(ptr %dest.i.i, ptr nonnull %t9.i, i64 %len_b.i.i)
  %0 = getelementptr i8, ptr %new_ptr.i.i, i64 %len_b.i.i
  %end.i.i = getelementptr i8, ptr %0, i64 4
  store i8 0, ptr %end.i.i, align 1
  %puts.i = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i.i)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
