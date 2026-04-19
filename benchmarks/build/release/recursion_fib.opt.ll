; ModuleID = 'build/release/recursion_fib.ll'
source_filename = "build/release/recursion_fib.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str3 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

; Function Attrs: nofree nosync nounwind memory(none)
define i64 @fn_fib(i64 %arg_n) local_unnamed_addr #4 {
entry:
  %t24 = icmp slt i64 %arg_n, 2
  br i1 %t24, label %common.ret, label %if_end_2

common.ret:                                       ; preds = %if_end_2, %entry
  %accumulator.tr.lcssa = phi i64 [ 0, %entry ], [ %t10, %if_end_2 ]
  %arg_n.tr.lcssa = phi i64 [ %arg_n, %entry ], [ %t8, %if_end_2 ]
  %accumulator.ret.tr = add i64 %arg_n.tr.lcssa, %accumulator.tr.lcssa
  ret i64 %accumulator.ret.tr

if_end_2:                                         ; preds = %entry, %if_end_2
  %arg_n.tr6 = phi i64 [ %t8, %if_end_2 ], [ %arg_n, %entry ]
  %accumulator.tr5 = phi i64 [ %t10, %if_end_2 ], [ 0, %entry ]
  %t5 = add nsw i64 %arg_n.tr6, -1
  %t6 = tail call i64 @fn_fib(i64 %t5)
  %t8 = add nsw i64 %arg_n.tr6, -2
  %t10 = add i64 %t6, %accumulator.tr5
  %t2 = icmp samesign ult i64 %arg_n.tr6, 4
  br i1 %t2, label %common.ret, label %if_end_2
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t12 = tail call i64 @mire_wall_mark_ns()
  %t14 = tail call i64 @mire_cpu_mark_ns()
  %t16 = tail call i64 @fn_fib(i64 20)
  %t19 = tail call ptr @mire_i64_to_string(i64 %t16)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t19)
  %alloc_len.i = add i64 %len_b.i, 8
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 7)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 7
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t19, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 7
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t23 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t12)
  %len_b.i5 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t23)
  %alloc_len.i7 = add i64 %len_b.i5, 9
  %new.i8 = tail call i64 @malloc(i64 %alloc_len.i7)
  %new_ptr.i9 = inttoptr i64 %new.i8 to ptr
  tail call void @memcpy(ptr %new_ptr.i9, ptr nonnull @.str1, i64 8)
  %dest.i10 = getelementptr i8, ptr %new_ptr.i9, i64 8
  tail call void @memcpy(ptr %dest.i10, ptr nonnull %t23, i64 %len_b.i5)
  %1 = getelementptr i8, ptr %new_ptr.i9, i64 %len_b.i5
  %end.i11 = getelementptr i8, ptr %1, i64 8
  store i8 0, ptr %end.i11, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i9)
  %t27 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t14)
  %len_b.i13 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t27)
  %alloc_len.i15 = add i64 %len_b.i13, 8
  %new.i16 = tail call i64 @malloc(i64 %alloc_len.i15)
  %new_ptr.i17 = inttoptr i64 %new.i16 to ptr
  tail call void @memcpy(ptr %new_ptr.i17, ptr nonnull @.str2, i64 7)
  %dest.i18 = getelementptr i8, ptr %new_ptr.i17, i64 7
  tail call void @memcpy(ptr %dest.i18, ptr nonnull %t27, i64 %len_b.i13)
  %2 = getelementptr i8, ptr %new_ptr.i17, i64 %len_b.i13
  %end.i19 = getelementptr i8, ptr %2, i64 7
  store i8 0, ptr %end.i19, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i17)
  %t30 = tail call i64 @mire_mem_process_bytes()
  %t31 = tail call ptr @mire_mem_format(i64 %t30)
  %len_b.i21 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t31)
  %alloc_len.i23 = add i64 %len_b.i21, 13
  %new.i24 = tail call i64 @malloc(i64 %alloc_len.i23)
  %new_ptr.i25 = inttoptr i64 %new.i24 to ptr
  tail call void @memcpy(ptr %new_ptr.i25, ptr nonnull @.str3, i64 12)
  %dest.i26 = getelementptr i8, ptr %new_ptr.i25, i64 12
  tail call void @memcpy(ptr %dest.i26, ptr nonnull %t31, i64 %len_b.i21)
  %3 = getelementptr i8, ptr %new_ptr.i25, i64 %len_b.i21
  %end.i27 = getelementptr i8, ptr %3, i64 12
  store i8 0, ptr %end.i27, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i25)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #5

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nosync nounwind memory(none) }
attributes #5 = { nofree nounwind }
