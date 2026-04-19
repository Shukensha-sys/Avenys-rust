; ModuleID = 'build/release/map_dynamic.ll'
source_filename = "build/release/map_dynamic.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"item\00"
@.str1 = private unnamed_addr constant [12 x i8] c"total_keys \00"
@.str2 = private unnamed_addr constant [14 x i8] c"total_values \00"
@.str3 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str4 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str5 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_keys(ptr) local_unnamed_addr

declare ptr @mire_dict_values(ptr) local_unnamed_addr

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
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t4.050 = phi ptr [ null, %entry ], [ %t23, %while_body_1 ]
  %t6.049 = phi i64 [ 0, %entry ], [ %t25, %while_body_1 ]
  %t12.lhs.trunc = trunc nuw nsw i64 %t6.049 to i16
  %t1248 = urem i16 %t12.lhs.trunc, 100
  %t12.zext = zext nneg i16 %t1248 to i64
  %t13 = tail call ptr @mire_i64_to_string(i64 %t12.zext)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t13)
  %alloc_len.i = add i64 %len_b.i, 5
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 4)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 4
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t13, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 4
  store i8 0, ptr %end.i, align 1
  %t18 = tail call i64 @mire_dict_get_i64(ptr %t4.050, i64 3, i64 0, ptr %new_ptr.i, i64 0)
  %t22 = add i64 %t18, 1
  %t23 = tail call ptr @mire_dict_set_i64(ptr %t4.050, i64 3, i64 1, i64 0, ptr %new_ptr.i, i64 %t22)
  %t25 = add nuw nsw i64 %t6.049, 1
  %t8 = icmp samesign ult i64 %t6.049, 4999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t28 = tail call ptr @mire_dict_keys(ptr %t23)
  %t31 = tail call ptr @mire_dict_values(ptr %t23)
  %t34 = icmp eq ptr %t31, null
  br i1 %t34, label %math_sum_end_6, label %math_sum_cond_4.preheader

math_sum_cond_4.preheader:                        ; preds = %while_end_2
  %t35 = load i64, ptr %t31, align 4
  %t3751 = icmp sgt i64 %t35, 0
  br i1 %t3751, label %math_sum_body_5.lr.ph, label %math_sum_end_6

math_sum_body_5.lr.ph:                            ; preds = %math_sum_cond_4.preheader
  %t38 = getelementptr i8, ptr %t31, i64 8
  br label %math_sum_body_5

math_sum_body_5:                                  ; preds = %math_sum_body_5.lr.ph, %math_sum_body_5
  %t33.053 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t44, %math_sum_body_5 ]
  %t32.052 = phi i64 [ 0, %math_sum_body_5.lr.ph ], [ %t43, %math_sum_body_5 ]
  %t39 = shl i64 %t33.053, 3
  %t40 = getelementptr i8, ptr %t38, i64 %t39
  %t41 = load i64, ptr %t40, align 4
  %t43 = add i64 %t41, %t32.052
  %t44 = add nuw nsw i64 %t33.053, 1
  %t37 = icmp slt i64 %t44, %t35
  br i1 %t37, label %math_sum_body_5, label %math_sum_end_6

math_sum_end_6:                                   ; preds = %math_sum_body_5, %math_sum_cond_4.preheader, %while_end_2
  %t32.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_4.preheader ], [ %t43, %math_sum_body_5 ]
  %t49 = icmp eq ptr %t28, null
  br i1 %t49, label %list_len_end_9, label %list_len_load_8

list_len_load_8:                                  ; preds = %math_sum_end_6
  %t50 = load i64, ptr %t28, align 4
  br label %list_len_end_9

list_len_end_9:                                   ; preds = %math_sum_end_6, %list_len_load_8
  %t52.0 = phi i64 [ %t50, %list_len_load_8 ], [ 0, %math_sum_end_6 ]
  %t53 = tail call ptr @mire_i64_to_string(i64 %t52.0)
  %len_b.i9 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t53)
  %alloc_len.i11 = add i64 %len_b.i9, 12
  %new.i12 = tail call i64 @malloc(i64 %alloc_len.i11)
  %new_ptr.i13 = inttoptr i64 %new.i12 to ptr
  tail call void @memcpy(ptr %new_ptr.i13, ptr nonnull @.str1, i64 11)
  %dest.i14 = getelementptr i8, ptr %new_ptr.i13, i64 11
  tail call void @memcpy(ptr %dest.i14, ptr nonnull %t53, i64 %len_b.i9)
  %1 = getelementptr i8, ptr %new_ptr.i13, i64 %len_b.i9
  %end.i15 = getelementptr i8, ptr %1, i64 11
  store i8 0, ptr %end.i15, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i13)
  %t57 = tail call ptr @mire_i64_to_string(i64 %t32.1)
  %len_b.i17 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t57)
  %alloc_len.i19 = add i64 %len_b.i17, 14
  %new.i20 = tail call i64 @malloc(i64 %alloc_len.i19)
  %new_ptr.i21 = inttoptr i64 %new.i20 to ptr
  tail call void @memcpy(ptr %new_ptr.i21, ptr nonnull @.str2, i64 13)
  %dest.i22 = getelementptr i8, ptr %new_ptr.i21, i64 13
  tail call void @memcpy(ptr %dest.i22, ptr nonnull %t57, i64 %len_b.i17)
  %2 = getelementptr i8, ptr %new_ptr.i21, i64 %len_b.i17
  %end.i23 = getelementptr i8, ptr %2, i64 13
  store i8 0, ptr %end.i23, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i21)
  %t61 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i25 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t61)
  %alloc_len.i27 = add i64 %len_b.i25, 9
  %new.i28 = tail call i64 @malloc(i64 %alloc_len.i27)
  %new_ptr.i29 = inttoptr i64 %new.i28 to ptr
  tail call void @memcpy(ptr %new_ptr.i29, ptr nonnull @.str3, i64 8)
  %dest.i30 = getelementptr i8, ptr %new_ptr.i29, i64 8
  tail call void @memcpy(ptr %dest.i30, ptr nonnull %t61, i64 %len_b.i25)
  %3 = getelementptr i8, ptr %new_ptr.i29, i64 %len_b.i25
  %end.i31 = getelementptr i8, ptr %3, i64 8
  store i8 0, ptr %end.i31, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i29)
  %t65 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i33 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t65)
  %alloc_len.i35 = add i64 %len_b.i33, 8
  %new.i36 = tail call i64 @malloc(i64 %alloc_len.i35)
  %new_ptr.i37 = inttoptr i64 %new.i36 to ptr
  tail call void @memcpy(ptr %new_ptr.i37, ptr nonnull @.str4, i64 7)
  %dest.i38 = getelementptr i8, ptr %new_ptr.i37, i64 7
  tail call void @memcpy(ptr %dest.i38, ptr nonnull %t65, i64 %len_b.i33)
  %4 = getelementptr i8, ptr %new_ptr.i37, i64 %len_b.i33
  %end.i39 = getelementptr i8, ptr %4, i64 7
  store i8 0, ptr %end.i39, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i37)
  %t68 = tail call i64 @mire_mem_process_bytes()
  %t69 = tail call ptr @mire_mem_format(i64 %t68)
  %len_b.i41 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t69)
  %alloc_len.i43 = add i64 %len_b.i41, 13
  %new.i44 = tail call i64 @malloc(i64 %alloc_len.i43)
  %new_ptr.i45 = inttoptr i64 %new.i44 to ptr
  tail call void @memcpy(ptr %new_ptr.i45, ptr nonnull @.str5, i64 12)
  %dest.i46 = getelementptr i8, ptr %new_ptr.i45, i64 12
  tail call void @memcpy(ptr %dest.i46, ptr nonnull %t69, i64 %len_b.i41)
  %5 = getelementptr i8, ptr %new_ptr.i45, i64 %len_b.i41
  %end.i47 = getelementptr i8, ptr %5, i64 12
  store i8 0, ptr %end.i47, align 1
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i45)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
