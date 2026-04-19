; ModuleID = 'build/release/nested_vec.ll'
source_filename = "build/release/nested_vec.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [6 x i8] c"rows \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
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

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

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

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_cond_3.preheader

while_cond_3.preheader:                           ; preds = %entry, %while_end_5
  %t4.049 = phi ptr [ null, %entry ], [ %t30, %while_end_5 ]
  %t6.048 = phi i64 [ 0, %entry ], [ %t32, %while_end_5 ]
  %t18 = mul nuw nsw i64 %t6.048, 100
  br label %while_body_4

while_cond_6.preheader:                           ; preds = %while_end_5
  %t54 = tail call ptr @mire_i64_to_string(i64 49995000)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t54)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t54, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t59 = icmp eq ptr %t30, null
  br i1 %t59, label %list_len_end_14, label %list_len_load_13

while_body_4:                                     ; preds = %while_cond_3.preheader, %while_body_4
  %t11.047 = phi i64 [ 0, %while_cond_3.preheader ], [ %t24, %while_body_4 ]
  %t9.046 = phi ptr [ null, %while_cond_3.preheader ], [ %t22, %while_body_4 ]
  %t15 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t15, align 4
  %t16 = getelementptr i8, ptr %t15, i64 8
  store i64 1, ptr %t16, align 4
  %t20 = add nuw nsw i64 %t11.047, %t18
  %t21 = getelementptr i8, ptr %t15, i64 16
  store i64 %t20, ptr %t21, align 4
  %t22 = tail call ptr @mire_list_concat(ptr %t9.046, ptr nonnull %t16)
  %t24 = add nuw nsw i64 %t11.047, 1
  %t13 = icmp samesign ult i64 %t11.047, 99
  br i1 %t13, label %while_body_4, label %while_end_5

while_end_5:                                      ; preds = %while_body_4
  %t26 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t26, align 4
  %t27 = getelementptr i8, ptr %t26, i64 8
  store i64 1, ptr %t27, align 4
  %t29 = getelementptr i8, ptr %t26, i64 16
  store ptr %t22, ptr %t29, align 8
  %t30 = tail call ptr @mire_list_concat(ptr %t4.049, ptr nonnull %t27)
  %t32 = add nuw nsw i64 %t6.048, 1
  %t8 = icmp samesign ult i64 %t6.048, 99
  br i1 %t8, label %while_cond_3.preheader, label %while_cond_6.preheader

list_len_load_13:                                 ; preds = %while_cond_6.preheader
  %t60 = load i64, ptr %t30, align 4
  br label %list_len_end_14

list_len_end_14:                                  ; preds = %while_cond_6.preheader, %list_len_load_13
  %t62.0 = phi i64 [ %t60, %list_len_load_13 ], [ 0, %while_cond_6.preheader ]
  %t63 = tail call ptr @mire_i64_to_string(i64 %t62.0)
  %len_b.i15 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t63)
  %alloc_len.i17 = add i64 %len_b.i15, 6
  %new.i18 = tail call i64 @malloc(i64 %alloc_len.i17)
  %new_ptr.i19 = inttoptr i64 %new.i18 to ptr
  tail call void @memcpy(ptr %new_ptr.i19, ptr nonnull @.str1, i64 5)
  %dest.i20 = getelementptr i8, ptr %new_ptr.i19, i64 5
  tail call void @memcpy(ptr %dest.i20, ptr nonnull %t63, i64 %len_b.i15)
  %1 = getelementptr i8, ptr %new_ptr.i19, i64 %len_b.i15
  %end.i21 = getelementptr i8, ptr %1, i64 5
  store i8 0, ptr %end.i21, align 1
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i19)
  %t67 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i23 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t67)
  %alloc_len.i25 = add i64 %len_b.i23, 9
  %new.i26 = tail call i64 @malloc(i64 %alloc_len.i25)
  %new_ptr.i27 = inttoptr i64 %new.i26 to ptr
  tail call void @memcpy(ptr %new_ptr.i27, ptr nonnull @.str2, i64 8)
  %dest.i28 = getelementptr i8, ptr %new_ptr.i27, i64 8
  tail call void @memcpy(ptr %dest.i28, ptr nonnull %t67, i64 %len_b.i23)
  %2 = getelementptr i8, ptr %new_ptr.i27, i64 %len_b.i23
  %end.i29 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i29, align 1
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i27)
  %t71 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i31 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t71)
  %alloc_len.i33 = add i64 %len_b.i31, 8
  %new.i34 = tail call i64 @malloc(i64 %alloc_len.i33)
  %new_ptr.i35 = inttoptr i64 %new.i34 to ptr
  tail call void @memcpy(ptr %new_ptr.i35, ptr nonnull @.str3, i64 7)
  %dest.i36 = getelementptr i8, ptr %new_ptr.i35, i64 7
  tail call void @memcpy(ptr %dest.i36, ptr nonnull %t71, i64 %len_b.i31)
  %3 = getelementptr i8, ptr %new_ptr.i35, i64 %len_b.i31
  %end.i37 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i37, align 1
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i35)
  %t74 = tail call i64 @mire_mem_process_bytes()
  %t75 = tail call ptr @mire_mem_format(i64 %t74)
  %len_b.i39 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t75)
  %alloc_len.i41 = add i64 %len_b.i39, 13
  %new.i42 = tail call i64 @malloc(i64 %alloc_len.i41)
  %new_ptr.i43 = inttoptr i64 %new.i42 to ptr
  tail call void @memcpy(ptr %new_ptr.i43, ptr nonnull @.str4, i64 12)
  %dest.i44 = getelementptr i8, ptr %new_ptr.i43, i64 12
  tail call void @memcpy(ptr %dest.i44, ptr nonnull %t75, i64 %len_b.i39)
  %4 = getelementptr i8, ptr %new_ptr.i43, i64 %len_b.i39
  %end.i45 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i45, align 1
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i43)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
