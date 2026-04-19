; ModuleID = 'build/release/recursion_factorial.ll'
source_filename = "build/release/recursion_factorial.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

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

; Function Attrs: nofree norecurse nosync nounwind memory(none)
define i64 @fn_factorial(i64 %arg_n) local_unnamed_addr #4 {
entry:
  %t23 = icmp slt i64 %arg_n, 2
  br i1 %t23, label %common.ret, label %if_end_2

common.ret:                                       ; preds = %if_end_2, %entry
  %accumulator.tr.lcssa = phi i64 [ 1, %entry ], [ %t7, %if_end_2 ]
  ret i64 %accumulator.tr.lcssa

if_end_2:                                         ; preds = %entry, %if_end_2
  %arg_n.tr5 = phi i64 [ %t5, %if_end_2 ], [ %arg_n, %entry ]
  %accumulator.tr4 = phi i64 [ %t7, %if_end_2 ], [ 1, %entry ]
  %t5 = add nsw i64 %arg_n.tr5, -1
  %t7 = mul i64 %arg_n.tr5, %accumulator.tr4
  %t2 = icmp samesign ult i64 %arg_n.tr5, 3
  br i1 %t2, label %common.ret, label %if_end_2
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t9 = tail call i64 @mire_wall_mark_ns()
  %t11 = tail call i64 @mire_cpu_mark_ns()
  %t16 = tail call ptr @mire_i64_to_string(i64 479001600)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t16)
  %alloc_len.i = add i64 %len_b.i, 8
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 7)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 7
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t16, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 7
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t20 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t9)
  %len_b.i4 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t20)
  %alloc_len.i6 = add i64 %len_b.i4, 9
  %new.i7 = tail call i64 @malloc(i64 %alloc_len.i6)
  %new_ptr.i8 = inttoptr i64 %new.i7 to ptr
  tail call void @memcpy(ptr %new_ptr.i8, ptr nonnull @.str1, i64 8)
  %dest.i9 = getelementptr i8, ptr %new_ptr.i8, i64 8
  tail call void @memcpy(ptr %dest.i9, ptr nonnull %t20, i64 %len_b.i4)
  %1 = getelementptr i8, ptr %new_ptr.i8, i64 %len_b.i4
  %end.i10 = getelementptr i8, ptr %1, i64 8
  store i8 0, ptr %end.i10, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i8)
  %t24 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t11)
  %len_b.i12 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t24)
  %alloc_len.i14 = add i64 %len_b.i12, 8
  %new.i15 = tail call i64 @malloc(i64 %alloc_len.i14)
  %new_ptr.i16 = inttoptr i64 %new.i15 to ptr
  tail call void @memcpy(ptr %new_ptr.i16, ptr nonnull @.str2, i64 7)
  %dest.i17 = getelementptr i8, ptr %new_ptr.i16, i64 7
  tail call void @memcpy(ptr %dest.i17, ptr nonnull %t24, i64 %len_b.i12)
  %2 = getelementptr i8, ptr %new_ptr.i16, i64 %len_b.i12
  %end.i18 = getelementptr i8, ptr %2, i64 7
  store i8 0, ptr %end.i18, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i16)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #5

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree norecurse nosync nounwind memory(none) }
attributes #5 = { nofree nounwind }
