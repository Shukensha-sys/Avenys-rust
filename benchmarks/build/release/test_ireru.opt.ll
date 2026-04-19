; ModuleID = 'benchmarks/build/release/test_ireru.ll'
source_filename = "benchmarks/build/release/test_ireru.ll"

@.scanf_str = private unnamed_addr constant [3 x i8] c"%s\00"
@.str0 = private unnamed_addr constant [25 x i8] c"Hola como te     llamas:\00"
@.str1 = private unnamed_addr constant [5 x i8] c"Hola\00"

; Function Attrs: nofree nounwind
declare noundef i32 @scanf(ptr noundef readonly captures(none), ...) local_unnamed_addr #0

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none)
define ptr @concat(ptr captures(none) %a, ptr captures(none) %b) local_unnamed_addr #4 {
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

; Function Attrs: nofree nounwind
define noundef i64 @mire_main() local_unnamed_addr #0 {
entry:
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str0)
  %t1 = tail call i64 @malloc(i64 256)
  %t2 = inttoptr i64 %t1 to ptr
  %t3 = tail call i32 (ptr, ...) @scanf(ptr nonnull @.scanf_str, ptr %t2)
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t2)
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str1)
  ret i64 0
}

; Function Attrs: nofree nounwind
define noundef i32 @main() local_unnamed_addr #0 {
entry:
  %puts.i = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str0)
  %t1.i = tail call i64 @malloc(i64 256)
  %t2.i = inttoptr i64 %t1.i to ptr
  %t3.i = tail call i32 (ptr, ...) @scanf(ptr nonnull @.scanf_str, ptr %t2.i)
  %puts1.i = tail call i32 @puts(ptr nonnull dereferenceable(1) %t2.i)
  %puts2.i = tail call i32 @puts(ptr nonnull dereferenceable(1) @.str1)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
attributes #1 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
