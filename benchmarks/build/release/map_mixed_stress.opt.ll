; ModuleID = 'build/release/map_mixed_stress.ll'
source_filename = "build/release/map_mixed_stress.ll"

@.str0 = private unnamed_addr constant [5 x i8] c"item\00"
@.str1 = private unnamed_addr constant [4 x i8] c"cat\00"
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

declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

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
  %t4.041 = phi ptr [ null, %entry ], [ %t38, %while_body_1 ]
  %t6.040 = phi i64 [ 0, %entry ], [ %t40, %while_body_1 ]
  %t12.lhs.trunc = trunc nuw nsw i64 %t6.040 to i16
  %t1238 = urem i16 %t12.lhs.trunc, 1000
  %t12.zext = zext nneg i16 %t1238 to i64
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
  %t1839 = urem i16 %t12.lhs.trunc, 100
  %t18.zext = zext nneg i16 %t1839 to i64
  %t19 = tail call ptr @mire_i64_to_string(i64 %t18.zext)
  %len_b.i7 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t19)
  %alloc_len.i9 = add i64 %len_b.i7, 4
  %new.i10 = tail call i64 @malloc(i64 %alloc_len.i9)
  %new_ptr.i11 = inttoptr i64 %new.i10 to ptr
  tail call void @memcpy(ptr %new_ptr.i11, ptr nonnull @.str1, i64 3)
  %dest.i12 = getelementptr i8, ptr %new_ptr.i11, i64 3
  tail call void @memcpy(ptr %dest.i12, ptr nonnull %t19, i64 %len_b.i7)
  %1 = getelementptr i8, ptr %new_ptr.i11, i64 %len_b.i7
  %end.i13 = getelementptr i8, ptr %1, i64 3
  store i8 0, ptr %end.i13, align 1
  %t24 = tail call i64 @mire_dict_get_i64(ptr %t4.041, i64 3, i64 0, ptr %new_ptr.i, i64 0)
  %t28 = add i64 %t24, 1
  %t29 = tail call ptr @mire_dict_set_i64(ptr %t4.041, i64 3, i64 1, i64 0, ptr %new_ptr.i, i64 %t28)
  %t33 = tail call i64 @mire_dict_get_i64(ptr %t29, i64 3, i64 0, ptr %new_ptr.i11, i64 0)
  %t37 = add i64 %t33, 1
  %t38 = tail call ptr @mire_dict_set_i64(ptr %t29, i64 3, i64 1, i64 0, ptr %new_ptr.i11, i64 %t37)
  %t40 = add nuw nsw i64 %t6.040, 1
  %t8 = icmp samesign ult i64 %t6.040, 29999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t43 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i15 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t43)
  %alloc_len.i17 = add i64 %len_b.i15, 9
  %new.i18 = tail call i64 @malloc(i64 %alloc_len.i17)
  %new_ptr.i19 = inttoptr i64 %new.i18 to ptr
  tail call void @memcpy(ptr %new_ptr.i19, ptr nonnull @.str2, i64 8)
  %dest.i20 = getelementptr i8, ptr %new_ptr.i19, i64 8
  tail call void @memcpy(ptr %dest.i20, ptr nonnull %t43, i64 %len_b.i15)
  %2 = getelementptr i8, ptr %new_ptr.i19, i64 %len_b.i15
  %end.i21 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i21, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i19)
  %t47 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i23 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t47)
  %alloc_len.i25 = add i64 %len_b.i23, 8
  %new.i26 = tail call i64 @malloc(i64 %alloc_len.i25)
  %new_ptr.i27 = inttoptr i64 %new.i26 to ptr
  tail call void @memcpy(ptr %new_ptr.i27, ptr nonnull @.str3, i64 7)
  %dest.i28 = getelementptr i8, ptr %new_ptr.i27, i64 7
  tail call void @memcpy(ptr %dest.i28, ptr nonnull %t47, i64 %len_b.i23)
  %3 = getelementptr i8, ptr %new_ptr.i27, i64 %len_b.i23
  %end.i29 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i29, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i27)
  %t50 = tail call i64 @mire_mem_process_bytes()
  %t51 = tail call ptr @mire_mem_format(i64 %t50)
  %len_b.i31 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t51)
  %alloc_len.i33 = add i64 %len_b.i31, 13
  %new.i34 = tail call i64 @malloc(i64 %alloc_len.i33)
  %new_ptr.i35 = inttoptr i64 %new.i34 to ptr
  tail call void @memcpy(ptr %new_ptr.i35, ptr nonnull @.str4, i64 12)
  %dest.i36 = getelementptr i8, ptr %new_ptr.i35, i64 12
  tail call void @memcpy(ptr %dest.i36, ptr nonnull %t51, i64 %len_b.i31)
  %4 = getelementptr i8, ptr %new_ptr.i35, i64 %len_b.i31
  %end.i37 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i37, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i35)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
