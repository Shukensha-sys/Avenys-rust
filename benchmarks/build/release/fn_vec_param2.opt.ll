; ModuleID = 'build/release/fn_vec_param2.ll'
source_filename = "build/release/fn_vec_param2.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [9 x i8] c"result2 \00"
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

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

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

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read)
define i64 @fn_sum_all(ptr readonly captures(address_is_null) %arg_xs) local_unnamed_addr #4 {
entry:
  %t6 = icmp eq ptr %arg_xs, null
  br i1 %t6, label %while_end_2, label %list_len_load_4.lr.ph

list_len_load_4.lr.ph:                            ; preds = %entry
  %t7 = load i64, ptr %arg_xs, align 4
  %t14 = getelementptr inbounds nuw i8, ptr %arg_xs, i64 8
  %0 = icmp sgt i64 %t7, 0
  br i1 %0, label %while_body_1, label %while_end_2

while_body_1:                                     ; preds = %list_len_load_4.lr.ph, %while_body_1
  %t1.049 = phi i64 [ %t18, %while_body_1 ], [ 0, %list_len_load_4.lr.ph ]
  %t2.058 = phi i64 [ %t20, %while_body_1 ], [ 0, %list_len_load_4.lr.ph ]
  %t15 = shl i64 %t2.058, 3
  %t16 = getelementptr inbounds i8, ptr %t14, i64 %t15
  %t17 = load i64, ptr %t16, align 4
  %t18 = add i64 %t17, %t1.049
  %t20 = add nuw nsw i64 %t2.058, 1
  %1 = icmp slt i64 %t20, %t7
  br i1 %1, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1, %list_len_load_4.lr.ph, %entry
  %t1.0.lcssa = phi i64 [ 0, %entry ], [ 0, %list_len_load_4.lr.ph ], [ %t18, %while_body_1 ]
  ret i64 %t1.0.lcssa
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t23 = tail call i64 @mire_wall_mark_ns()
  %t25 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_7

while_body_7:                                     ; preds = %entry, %while_body_7
  %t26.051 = phi ptr [ null, %entry ], [ %t33, %while_body_7 ]
  %t28.050 = phi i64 [ 0, %entry ], [ %t35, %while_body_7 ]
  %t33 = tail call ptr @mire_list_push_i64(ptr %t26.051, i64 %t28.050)
  %t35 = add nuw nsw i64 %t28.050, 1
  %t30 = icmp samesign ult i64 %t28.050, 4999
  br i1 %t30, label %while_body_7, label %while_end_8

while_end_8:                                      ; preds = %while_body_7
  %t6.i = icmp eq ptr %t33, null
  br i1 %t6.i, label %fn_sum_all.exit19, label %list_len_load_4.lr.ph.i

list_len_load_4.lr.ph.i:                          ; preds = %while_end_8
  %t7.i = load i64, ptr %t33, align 4
  %t14.i = getelementptr inbounds nuw i8, ptr %t33, i64 8
  %0 = icmp sgt i64 %t7.i, 0
  br i1 %0, label %while_body_1.i, label %fn_sum_all.exit19

while_body_1.i:                                   ; preds = %list_len_load_4.lr.ph.i, %while_body_1.i
  %t1.049.i = phi i64 [ %t18.i, %while_body_1.i ], [ 0, %list_len_load_4.lr.ph.i ]
  %t2.058.i = phi i64 [ %t20.i, %while_body_1.i ], [ 0, %list_len_load_4.lr.ph.i ]
  %t15.i = shl i64 %t2.058.i, 3
  %t16.i = getelementptr inbounds i8, ptr %t14.i, i64 %t15.i
  %t17.i = load i64, ptr %t16.i, align 4
  %t18.i = add i64 %t17.i, %t1.049.i
  %t20.i = add nuw nsw i64 %t2.058.i, 1
  %1 = icmp slt i64 %t20.i, %t7.i
  br i1 %1, label %while_body_1.i, label %while_body_1.i11

while_body_1.i11:                                 ; preds = %while_body_1.i, %while_body_1.i11
  %t1.049.i12 = phi i64 [ %t18.i17, %while_body_1.i11 ], [ 0, %while_body_1.i ]
  %t2.058.i13 = phi i64 [ %t20.i18, %while_body_1.i11 ], [ 0, %while_body_1.i ]
  %t15.i14 = shl i64 %t2.058.i13, 3
  %t16.i15 = getelementptr inbounds i8, ptr %t14.i, i64 %t15.i14
  %t17.i16 = load i64, ptr %t16.i15, align 4
  %t18.i17 = add i64 %t17.i16, %t1.049.i12
  %t20.i18 = add nuw nsw i64 %t2.058.i13, 1
  %2 = icmp slt i64 %t20.i18, %t7.i
  br i1 %2, label %while_body_1.i11, label %fn_sum_all.exit19

fn_sum_all.exit19:                                ; preds = %while_body_1.i11, %list_len_load_4.lr.ph.i, %while_end_8
  %t1.0.lcssa.i46 = phi i64 [ 0, %list_len_load_4.lr.ph.i ], [ 0, %while_end_8 ], [ %t18.i, %while_body_1.i11 ]
  %t1.0.lcssa.i10 = phi i64 [ 0, %list_len_load_4.lr.ph.i ], [ 0, %while_end_8 ], [ %t18.i17, %while_body_1.i11 ]
  %t44 = tail call ptr @mire_i64_to_string(i64 %t1.0.lcssa.i46)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t44)
  %alloc_len.i = add i64 %len_b.i, 8
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 7)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 7
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t44, i64 %len_b.i)
  %3 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t48 = tail call ptr @mire_i64_to_string(i64 %t1.0.lcssa.i10)
  %len_b.i21 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t48)
  %alloc_len.i23 = add i64 %len_b.i21, 9
  %new.i24 = tail call i64 @malloc(i64 %alloc_len.i23)
  %new_ptr.i25 = inttoptr i64 %new.i24 to ptr
  tail call void @memcpy(ptr %new_ptr.i25, ptr nonnull @.str1, i64 8)
  %dest.i26 = getelementptr i8, ptr %new_ptr.i25, i64 8
  tail call void @memcpy(ptr %dest.i26, ptr nonnull %t48, i64 %len_b.i21)
  %4 = getelementptr i8, ptr %new_ptr.i25, i64 %len_b.i21
  %end.i27 = getelementptr i8, ptr %4, i64 8
  store i8 0, ptr %end.i27, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i25)
  %t52 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t23)
  %len_b.i29 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t52)
  %alloc_len.i31 = add i64 %len_b.i29, 9
  %new.i32 = tail call i64 @malloc(i64 %alloc_len.i31)
  %new_ptr.i33 = inttoptr i64 %new.i32 to ptr
  tail call void @memcpy(ptr %new_ptr.i33, ptr nonnull @.str2, i64 8)
  %dest.i34 = getelementptr i8, ptr %new_ptr.i33, i64 8
  tail call void @memcpy(ptr %dest.i34, ptr nonnull %t52, i64 %len_b.i29)
  %5 = getelementptr i8, ptr %new_ptr.i33, i64 %len_b.i29
  %end.i35 = getelementptr i8, ptr %5, i64 8
  store i8 0, ptr %end.i35, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i33)
  %t55 = tail call i64 @mire_mem_process_bytes()
  %t56 = tail call ptr @mire_mem_format(i64 %t55)
  %len_b.i37 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t56)
  %alloc_len.i39 = add i64 %len_b.i37, 13
  %new.i40 = tail call i64 @malloc(i64 %alloc_len.i39)
  %new_ptr.i41 = inttoptr i64 %new.i40 to ptr
  tail call void @memcpy(ptr %new_ptr.i41, ptr nonnull @.str3, i64 12)
  %dest.i42 = getelementptr i8, ptr %new_ptr.i41, i64 12
  tail call void @memcpy(ptr %dest.i42, ptr nonnull %t56, i64 %len_b.i37)
  %6 = getelementptr i8, ptr %new_ptr.i41, i64 %len_b.i37
  %end.i43 = getelementptr i8, ptr %6, i64 12
  store i8 0, ptr %end.i43, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i41)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #5

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree norecurse nosync nounwind memory(argmem: read) }
attributes #5 = { nofree nounwind }
