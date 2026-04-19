; ModuleID = 'build/release/fn_vec_param.ll'
source_filename = "build/release/fn_vec_param.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"result \00"
@.str1 = private unnamed_addr constant [5 x i8] c"len \00"
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
define i64 @fn_sum_vec(ptr readonly captures(address_is_null) %arg_xs) local_unnamed_addr #4 {
entry:
  %t4 = icmp eq ptr %arg_xs, null
  br i1 %t4, label %math_sum_end_3, label %math_sum_cond_1.preheader

math_sum_cond_1.preheader:                        ; preds = %entry
  %t5 = load i64, ptr %arg_xs, align 4
  %t72 = icmp sgt i64 %t5, 0
  br i1 %t72, label %math_sum_body_2.lr.ph, label %math_sum_end_3

math_sum_body_2.lr.ph:                            ; preds = %math_sum_cond_1.preheader
  %t8 = getelementptr i8, ptr %arg_xs, i64 8
  br label %math_sum_body_2

math_sum_body_2:                                  ; preds = %math_sum_body_2.lr.ph, %math_sum_body_2
  %t3.04 = phi i64 [ 0, %math_sum_body_2.lr.ph ], [ %t14, %math_sum_body_2 ]
  %t2.03 = phi i64 [ 0, %math_sum_body_2.lr.ph ], [ %t13, %math_sum_body_2 ]
  %t9 = shl i64 %t3.04, 3
  %t10 = getelementptr i8, ptr %t8, i64 %t9
  %t11 = load i64, ptr %t10, align 4
  %t13 = add i64 %t11, %t2.03
  %t14 = add nuw nsw i64 %t3.04, 1
  %t7 = icmp slt i64 %t14, %t5
  br i1 %t7, label %math_sum_body_2, label %math_sum_end_3

math_sum_end_3:                                   ; preds = %math_sum_body_2, %math_sum_cond_1.preheader, %entry
  %t2.1 = phi i64 [ 0, %entry ], [ 0, %math_sum_cond_1.preheader ], [ %t13, %math_sum_body_2 ]
  ret i64 %t2.1
}

define noundef i32 @main() local_unnamed_addr {
entry:
  %t17 = tail call i64 @mire_wall_mark_ns()
  %t19 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_5

while_body_5:                                     ; preds = %entry, %while_body_5
  %t20.040 = phi ptr [ null, %entry ], [ %t27, %while_body_5 ]
  %t22.039 = phi i64 [ 0, %entry ], [ %t29, %while_body_5 ]
  %t27 = tail call ptr @mire_list_push_i64(ptr %t20.040, i64 %t22.039)
  %t29 = add nuw nsw i64 %t22.039, 1
  %t24 = icmp samesign ult i64 %t22.039, 999
  br i1 %t24, label %while_body_5, label %while_end_6

while_end_6:                                      ; preds = %while_body_5
  %t4.i = icmp eq ptr %t27, null
  br i1 %t4.i, label %fn_sum_vec.exit, label %math_sum_cond_1.preheader.i

math_sum_cond_1.preheader.i:                      ; preds = %while_end_6
  %t5.i = load i64, ptr %t27, align 4
  %t72.i = icmp sgt i64 %t5.i, 0
  br i1 %t72.i, label %math_sum_body_2.lr.ph.i, label %fn_sum_vec.exit

math_sum_body_2.lr.ph.i:                          ; preds = %math_sum_cond_1.preheader.i
  %t8.i = getelementptr i8, ptr %t27, i64 8
  br label %math_sum_body_2.i

math_sum_body_2.i:                                ; preds = %math_sum_body_2.i, %math_sum_body_2.lr.ph.i
  %t3.04.i = phi i64 [ 0, %math_sum_body_2.lr.ph.i ], [ %t14.i, %math_sum_body_2.i ]
  %t2.03.i = phi i64 [ 0, %math_sum_body_2.lr.ph.i ], [ %t13.i, %math_sum_body_2.i ]
  %t9.i = shl i64 %t3.04.i, 3
  %t10.i = getelementptr i8, ptr %t8.i, i64 %t9.i
  %t11.i = load i64, ptr %t10.i, align 4
  %t13.i = add i64 %t11.i, %t2.03.i
  %t14.i = add nuw nsw i64 %t3.04.i, 1
  %t7.i = icmp slt i64 %t14.i, %t5.i
  br i1 %t7.i, label %math_sum_body_2.i, label %fn_sum_vec.exit

fn_sum_vec.exit:                                  ; preds = %math_sum_body_2.i, %while_end_6, %math_sum_cond_1.preheader.i
  %t2.1.i = phi i64 [ 0, %while_end_6 ], [ 0, %math_sum_cond_1.preheader.i ], [ %t13.i, %math_sum_body_2.i ]
  %t35 = tail call ptr @mire_i64_to_string(i64 %t2.1.i)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t35)
  %alloc_len.i = add i64 %len_b.i, 8
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 7)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 7
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t35, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 7
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  br i1 %t4.i, label %list_len_end_9, label %list_len_load_8

list_len_load_8:                                  ; preds = %fn_sum_vec.exit
  %t41 = load i64, ptr %t27, align 4
  br label %list_len_end_9

list_len_end_9:                                   ; preds = %fn_sum_vec.exit, %list_len_load_8
  %t43.0 = phi i64 [ %t41, %list_len_load_8 ], [ 0, %fn_sum_vec.exit ]
  %t44 = tail call ptr @mire_i64_to_string(i64 %t43.0)
  %len_b.i8 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t44)
  %alloc_len.i10 = add i64 %len_b.i8, 5
  %new.i11 = tail call i64 @malloc(i64 %alloc_len.i10)
  %new_ptr.i12 = inttoptr i64 %new.i11 to ptr
  tail call void @memcpy(ptr %new_ptr.i12, ptr nonnull @.str1, i64 4)
  %dest.i13 = getelementptr i8, ptr %new_ptr.i12, i64 4
  tail call void @memcpy(ptr %dest.i13, ptr nonnull %t44, i64 %len_b.i8)
  %1 = getelementptr i8, ptr %new_ptr.i12, i64 %len_b.i8
  %end.i14 = getelementptr i8, ptr %1, i64 4
  store i8 0, ptr %end.i14, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i12)
  %t48 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t17)
  %len_b.i16 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t48)
  %alloc_len.i18 = add i64 %len_b.i16, 9
  %new.i19 = tail call i64 @malloc(i64 %alloc_len.i18)
  %new_ptr.i20 = inttoptr i64 %new.i19 to ptr
  tail call void @memcpy(ptr %new_ptr.i20, ptr nonnull @.str2, i64 8)
  %dest.i21 = getelementptr i8, ptr %new_ptr.i20, i64 8
  tail call void @memcpy(ptr %dest.i21, ptr nonnull %t48, i64 %len_b.i16)
  %2 = getelementptr i8, ptr %new_ptr.i20, i64 %len_b.i16
  %end.i22 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i22, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i20)
  %t52 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t19)
  %len_b.i24 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t52)
  %alloc_len.i26 = add i64 %len_b.i24, 8
  %new.i27 = tail call i64 @malloc(i64 %alloc_len.i26)
  %new_ptr.i28 = inttoptr i64 %new.i27 to ptr
  tail call void @memcpy(ptr %new_ptr.i28, ptr nonnull @.str3, i64 7)
  %dest.i29 = getelementptr i8, ptr %new_ptr.i28, i64 7
  tail call void @memcpy(ptr %dest.i29, ptr nonnull %t52, i64 %len_b.i24)
  %3 = getelementptr i8, ptr %new_ptr.i28, i64 %len_b.i24
  %end.i30 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i30, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i28)
  %t55 = tail call i64 @mire_mem_process_bytes()
  %t56 = tail call ptr @mire_mem_format(i64 %t55)
  %len_b.i32 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t56)
  %alloc_len.i34 = add i64 %len_b.i32, 13
  %new.i35 = tail call i64 @malloc(i64 %alloc_len.i34)
  %new_ptr.i36 = inttoptr i64 %new.i35 to ptr
  tail call void @memcpy(ptr %new_ptr.i36, ptr nonnull @.str4, i64 12)
  %dest.i37 = getelementptr i8, ptr %new_ptr.i36, i64 12
  tail call void @memcpy(ptr %dest.i37, ptr nonnull %t56, i64 %len_b.i32)
  %4 = getelementptr i8, ptr %new_ptr.i36, i64 %len_b.i32
  %end.i38 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i38, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i36)
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
