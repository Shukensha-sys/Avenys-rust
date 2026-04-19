; ModuleID = 'build/release/recursion_quicksort.ll'
source_filename = "build/release/recursion_quicksort.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"first \00"
@.str1 = private unnamed_addr constant [6 x i8] c"last \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
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

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

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

define ptr @fn_quicksort(ptr readonly captures(ret: address, provenance) %arg_arr, i64 %arg_len) local_unnamed_addr {
entry:
  %t3 = icmp slt i64 %arg_len, 2
  br i1 %t3, label %common.ret, label %if_end_2

common.ret:                                       ; preds = %entry, %list_len_end_17
  %common.ret.op = phi ptr [ %t71, %list_len_end_17 ], [ %arg_arr, %entry ]
  ret ptr %common.ret.op

if_end_2:                                         ; preds = %entry
  %t7 = getelementptr inbounds nuw i8, ptr %arg_arr, i64 8
  %t10 = load i64, ptr %t7, align 4
  br label %while_body_4

while_body_4:                                     ; preds = %if_end_2, %if_end_11
  %t11.018 = phi ptr [ null, %if_end_2 ], [ %t11.115, %if_end_11 ]
  %t13.017 = phi ptr [ null, %if_end_2 ], [ %t13.1, %if_end_11 ]
  %t15.016 = phi i64 [ 1, %if_end_2 ], [ %t45, %if_end_11 ]
  %t23 = shl i64 %t15.016, 3
  %t24 = getelementptr inbounds i8, ptr %t7, i64 %t23
  %t25 = load i64, ptr %t24, align 4
  %t28 = icmp slt i64 %t25, %t10
  %t30 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t30, align 4
  %t31 = getelementptr i8, ptr %t30, i64 8
  store i64 1, ptr %t31, align 4
  %t33 = getelementptr i8, ptr %t30, i64 16
  store i64 %t25, ptr %t33, align 4
  br i1 %t28, label %if_end_8.thread, label %if_then_9

if_end_8.thread:                                  ; preds = %while_body_4
  %t34 = tail call ptr @mire_list_concat(ptr %t11.018, ptr nonnull %t31)
  br label %if_end_11

if_then_9:                                        ; preds = %while_body_4
  %t43 = tail call ptr @mire_list_concat(ptr %t13.017, ptr nonnull %t31)
  br label %if_end_11

if_end_11:                                        ; preds = %if_end_8.thread, %if_then_9
  %t11.115 = phi ptr [ %t11.018, %if_then_9 ], [ %t34, %if_end_8.thread ]
  %t13.1 = phi ptr [ %t43, %if_then_9 ], [ %t13.017, %if_end_8.thread ]
  %t45 = add nuw nsw i64 %t15.016, 1
  %t18 = icmp slt i64 %t45, %arg_len
  br i1 %t18, label %while_body_4, label %while_end_5

while_end_5:                                      ; preds = %if_end_11
  %t50 = icmp eq ptr %t11.115, null
  br i1 %t50, label %list_len_end_14, label %list_len_load_13.split

list_len_load_13.split:                           ; preds = %while_end_5
  %t51 = load i64, ptr %t11.115, align 4
  %t5410 = tail call ptr @fn_quicksort(ptr nonnull %t11.115, i64 %t51)
  br label %list_len_end_14

list_len_end_14:                                  ; preds = %while_end_5, %list_len_load_13.split
  %phi.call = phi ptr [ %t5410, %list_len_load_13.split ], [ null, %while_end_5 ]
  %t59 = icmp eq ptr %t13.1, null
  br i1 %t59, label %list_len_end_17, label %list_len_load_16.split

list_len_load_16.split:                           ; preds = %list_len_end_14
  %t60 = load i64, ptr %t13.1, align 4
  %t6312 = tail call ptr @fn_quicksort(ptr nonnull %t13.1, i64 %t60)
  br label %list_len_end_17

list_len_end_17:                                  ; preds = %list_len_end_14, %list_len_load_16.split
  %phi.call13 = phi ptr [ %t6312, %list_len_load_16.split ], [ null, %list_len_end_14 ]
  %t65 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t65, align 4
  %t66 = getelementptr i8, ptr %t65, i64 8
  store i64 1, ptr %t66, align 4
  %t68 = getelementptr i8, ptr %t65, i64 16
  store i64 %t10, ptr %t68, align 4
  %t69 = tail call ptr @mire_list_concat(ptr %phi.call, ptr nonnull %t66)
  %t71 = tail call ptr @mire_list_concat(ptr %t69, ptr %phi.call13)
  br label %common.ret
}

define noundef i32 @main() local_unnamed_addr {
list_len_end_23:
  %t73 = tail call i64 @mire_wall_mark_ns()
  %t75 = tail call i64 @mire_cpu_mark_ns()
  %t77 = tail call dereferenceable_or_null(136) ptr @malloc(i64 136)
  store i64 15, ptr %t77, align 4
  %t78 = getelementptr i8, ptr %t77, i64 8
  store i64 15, ptr %t78, align 4
  %t79 = getelementptr i8, ptr %t77, i64 16
  store i64 5, ptr %t79, align 4
  %t80 = getelementptr i8, ptr %t77, i64 24
  store i64 3, ptr %t80, align 4
  %t81 = getelementptr i8, ptr %t77, i64 32
  store i64 8, ptr %t81, align 4
  %t82 = getelementptr i8, ptr %t77, i64 40
  store i64 1, ptr %t82, align 4
  %t83 = getelementptr i8, ptr %t77, i64 48
  store i64 9, ptr %t83, align 4
  %t84 = getelementptr i8, ptr %t77, i64 56
  store i64 2, ptr %t84, align 4
  %t85 = getelementptr i8, ptr %t77, i64 64
  store i64 7, ptr %t85, align 4
  %t86 = getelementptr i8, ptr %t77, i64 72
  store i64 4, ptr %t86, align 4
  %t87 = getelementptr i8, ptr %t77, i64 80
  store i64 6, ptr %t87, align 4
  %t88 = getelementptr i8, ptr %t77, i64 88
  store i64 0, ptr %t88, align 4
  %t89 = getelementptr i8, ptr %t77, i64 96
  store i64 11, ptr %t89, align 4
  %t90 = getelementptr i8, ptr %t77, i64 104
  store i64 13, ptr %t90, align 4
  %t91 = getelementptr i8, ptr %t77, i64 112
  store i64 12, ptr %t91, align 4
  %t92 = getelementptr i8, ptr %t77, i64 120
  store i64 10, ptr %t92, align 4
  %t93 = getelementptr i8, ptr %t77, i64 128
  store i64 14, ptr %t93, align 4
  %t102 = tail call ptr @fn_quicksort(ptr nonnull %t78, i64 15)
  %t105 = getelementptr inbounds nuw i8, ptr %t102, i64 8
  %t108 = load i64, ptr %t105, align 4
  %t114 = load i64, ptr %t102, align 4
  %0 = shl i64 %t114, 3
  %t120 = getelementptr i8, ptr %t102, i64 %0
  %t121 = load i64, ptr %t120, align 4
  %t124 = tail call ptr @mire_i64_to_string(i64 %t108)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t124)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t124, i64 %len_b.i)
  %1 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %1, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t128 = tail call ptr @mire_i64_to_string(i64 %t121)
  %len_b.i5 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t128)
  %alloc_len.i7 = add i64 %len_b.i5, 6
  %new.i8 = tail call i64 @malloc(i64 %alloc_len.i7)
  %new_ptr.i9 = inttoptr i64 %new.i8 to ptr
  tail call void @memcpy(ptr %new_ptr.i9, ptr nonnull @.str1, i64 5)
  %dest.i10 = getelementptr i8, ptr %new_ptr.i9, i64 5
  tail call void @memcpy(ptr %dest.i10, ptr nonnull %t128, i64 %len_b.i5)
  %2 = getelementptr i8, ptr %new_ptr.i9, i64 %len_b.i5
  %end.i11 = getelementptr i8, ptr %2, i64 5
  store i8 0, ptr %end.i11, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i9)
  %t132 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t73)
  %len_b.i13 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t132)
  %alloc_len.i15 = add i64 %len_b.i13, 9
  %new.i16 = tail call i64 @malloc(i64 %alloc_len.i15)
  %new_ptr.i17 = inttoptr i64 %new.i16 to ptr
  tail call void @memcpy(ptr %new_ptr.i17, ptr nonnull @.str2, i64 8)
  %dest.i18 = getelementptr i8, ptr %new_ptr.i17, i64 8
  tail call void @memcpy(ptr %dest.i18, ptr nonnull %t132, i64 %len_b.i13)
  %3 = getelementptr i8, ptr %new_ptr.i17, i64 %len_b.i13
  %end.i19 = getelementptr i8, ptr %3, i64 8
  store i8 0, ptr %end.i19, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i17)
  %t135 = tail call i64 @mire_mem_process_bytes()
  %t136 = tail call ptr @mire_mem_format(i64 %t135)
  %len_b.i21 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t136)
  %alloc_len.i23 = add i64 %len_b.i21, 13
  %new.i24 = tail call i64 @malloc(i64 %alloc_len.i23)
  %new_ptr.i25 = inttoptr i64 %new.i24 to ptr
  tail call void @memcpy(ptr %new_ptr.i25, ptr nonnull @.str3, i64 12)
  %dest.i26 = getelementptr i8, ptr %new_ptr.i25, i64 12
  tail call void @memcpy(ptr %dest.i26, ptr nonnull %t136, i64 %len_b.i21)
  %4 = getelementptr i8, ptr %new_ptr.i25, i64 %len_b.i21
  %end.i27 = getelementptr i8, ptr %4, i64 12
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
