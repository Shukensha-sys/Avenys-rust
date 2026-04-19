; ModuleID = 'build/release/matrix_2d_stress.ll'
source_filename = "build/release/matrix_2d_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"total \00"
@.str1 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str2 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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
  br label %while_cond_3.preheader

while_cond_3.preheader:                           ; preds = %entry, %while_end_5
  %t2.031 = phi ptr [ null, %entry ], [ %t30, %while_end_5 ]
  %t4.030 = phi i64 [ 0, %entry ], [ %t32, %while_end_5 ]
  %t14 = mul nuw nsw i64 %t4.030, 100
  br label %while_body_4

while_cond_6.preheader:                           ; preds = %while_end_5
  %t43 = getelementptr inbounds nuw i8, ptr %t30, i64 8
  br label %while_cond_9.preheader

while_body_4:                                     ; preds = %while_cond_3.preheader, %while_body_4
  %t9.029 = phi i64 [ 0, %while_cond_3.preheader ], [ %t24, %while_body_4 ]
  %t7.028 = phi ptr [ null, %while_cond_3.preheader ], [ %t22, %while_body_4 ]
  %t16 = add nuw nsw i64 %t9.029, %t14
  %t18 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t18, align 4
  %t19 = getelementptr i8, ptr %t18, i64 8
  store i64 1, ptr %t19, align 4
  %t21 = getelementptr i8, ptr %t18, i64 16
  store i64 %t16, ptr %t21, align 4
  %t22 = tail call ptr @mire_list_concat(ptr %t7.028, ptr nonnull %t19)
  %t24 = add nuw nsw i64 %t9.029, 1
  %t11 = icmp samesign ult i64 %t9.029, 99
  br i1 %t11, label %while_body_4, label %while_end_5

while_end_5:                                      ; preds = %while_body_4
  %t26 = tail call dereferenceable_or_null(24) ptr @malloc(i64 24)
  store i64 1, ptr %t26, align 4
  %t27 = getelementptr i8, ptr %t26, i64 8
  store i64 1, ptr %t27, align 4
  %t29 = getelementptr i8, ptr %t26, i64 16
  store ptr %t22, ptr %t29, align 8
  %t30 = tail call ptr @mire_list_concat(ptr %t2.031, ptr nonnull %t27)
  %t32 = add nuw nsw i64 %t4.030, 1
  %t6 = icmp samesign ult i64 %t4.030, 99
  br i1 %t6, label %while_cond_3.preheader, label %while_cond_6.preheader

while_cond_9.preheader:                           ; preds = %while_cond_6.preheader, %while_end_11
  %t34.035 = phi i64 [ 0, %while_cond_6.preheader ], [ %t56, %while_end_11 ]
  %t33.034 = phi i64 [ 0, %while_cond_6.preheader ], [ %t52, %while_end_11 ]
  %t44 = shl nuw nsw i64 %t34.035, 3
  %t45 = getelementptr inbounds nuw i8, ptr %t43, i64 %t44
  %t46 = load ptr, ptr %t45, align 8
  %t48 = getelementptr inbounds nuw i8, ptr %t46, i64 8
  br label %while_body_10

while_body_10:                                    ; preds = %while_cond_9.preheader, %while_body_10
  %t37.033 = phi i64 [ 0, %while_cond_9.preheader ], [ %t54, %while_body_10 ]
  %t33.132 = phi i64 [ %t33.034, %while_cond_9.preheader ], [ %t52, %while_body_10 ]
  %t49 = shl nuw nsw i64 %t37.033, 3
  %t50 = getelementptr inbounds nuw i8, ptr %t48, i64 %t49
  %t51 = load i64, ptr %t50, align 4
  %t52 = add i64 %t51, %t33.132
  %t54 = add nuw nsw i64 %t37.033, 1
  %t39 = icmp samesign ult i64 %t37.033, 99
  br i1 %t39, label %while_body_10, label %while_end_11

while_end_11:                                     ; preds = %while_body_10
  %t56 = add nuw nsw i64 %t34.035, 1
  %t36 = icmp samesign ult i64 %t34.035, 99
  br i1 %t36, label %while_cond_9.preheader, label %while_end_8

while_end_8:                                      ; preds = %while_end_11
  %t59 = tail call ptr @mire_i64_to_string(i64 %t52)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t59)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t59, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t63 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i13 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t63)
  %alloc_len.i15 = add i64 %len_b.i13, 9
  %new.i16 = tail call i64 @malloc(i64 %alloc_len.i15)
  %new_ptr.i17 = inttoptr i64 %new.i16 to ptr
  tail call void @memcpy(ptr %new_ptr.i17, ptr nonnull @.str1, i64 8)
  %dest.i18 = getelementptr i8, ptr %new_ptr.i17, i64 8
  tail call void @memcpy(ptr %dest.i18, ptr nonnull %t63, i64 %len_b.i13)
  %1 = getelementptr i8, ptr %new_ptr.i17, i64 %len_b.i13
  %end.i19 = getelementptr i8, ptr %1, i64 8
  store i8 0, ptr %end.i19, align 1
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i17)
  %t66 = tail call i64 @mire_mem_process_bytes()
  %t67 = tail call ptr @mire_mem_format(i64 %t66)
  %len_b.i21 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t67)
  %alloc_len.i23 = add i64 %len_b.i21, 13
  %new.i24 = tail call i64 @malloc(i64 %alloc_len.i23)
  %new_ptr.i25 = inttoptr i64 %new.i24 to ptr
  tail call void @memcpy(ptr %new_ptr.i25, ptr nonnull @.str2, i64 12)
  %dest.i26 = getelementptr i8, ptr %new_ptr.i25, i64 12
  tail call void @memcpy(ptr %dest.i26, ptr nonnull %t67, i64 %len_b.i21)
  %2 = getelementptr i8, ptr %new_ptr.i25, i64 %len_b.i21
  %end.i27 = getelementptr i8, ptr %2, i64 12
  store i8 0, ptr %end.i27, align 1
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i25)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
