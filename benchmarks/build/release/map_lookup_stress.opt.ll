; ModuleID = 'build/release/map_lookup_stress.ll'
source_filename = "build/release/map_lookup_stress.ll"

@.str4 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str5 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str6 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str7 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str8 = private unnamed_addr constant [7 x i8] c"total \00"
@.str9 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str10 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str11 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str12 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

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
  %t8 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str4, i64 11)
  %t11 = tail call ptr @mire_dict_set_i64(ptr %t8, i64 3, i64 1, i64 0, ptr nonnull @.str5, i64 22)
  %t14 = tail call ptr @mire_dict_set_i64(ptr %t11, i64 3, i64 1, i64 0, ptr nonnull @.str6, i64 33)
  %t17 = tail call ptr @mire_dict_set_i64(ptr %t14, i64 3, i64 1, i64 0, ptr nonnull @.str7, i64 44)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t19.044 = phi i64 [ 0, %entry ], [ %t41, %while_body_1 ]
  %t18.043 = phi i64 [ 0, %entry ], [ %t43, %while_body_1 ]
  %t25 = tail call i64 @mire_dict_get_i64(ptr %t17, i64 3, i64 0, ptr nonnull @.str4, i64 0)
  %t26 = add i64 %t25, %t19.044
  %t30 = tail call i64 @mire_dict_get_i64(ptr %t17, i64 3, i64 0, ptr nonnull @.str5, i64 0)
  %t31 = add i64 %t26, %t30
  %t35 = tail call i64 @mire_dict_get_i64(ptr %t17, i64 3, i64 0, ptr nonnull @.str6, i64 0)
  %t36 = add i64 %t31, %t35
  %t40 = tail call i64 @mire_dict_get_i64(ptr %t17, i64 3, i64 0, ptr nonnull @.str7, i64 0)
  %t41 = add i64 %t36, %t40
  %t43 = add nuw nsw i64 %t18.043, 1
  %t21 = icmp samesign ult i64 %t18.043, 39999
  br i1 %t21, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t46 = tail call ptr @mire_i64_to_string(i64 %t41)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t46)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str8, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t46, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t50 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i12 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t50)
  %alloc_len.i14 = add i64 %len_b.i12, 9
  %new.i15 = tail call i64 @malloc(i64 %alloc_len.i14)
  %new_ptr.i16 = inttoptr i64 %new.i15 to ptr
  tail call void @memcpy(ptr %new_ptr.i16, ptr nonnull @.str9, i64 8)
  %dest.i17 = getelementptr i8, ptr %new_ptr.i16, i64 8
  tail call void @memcpy(ptr %dest.i17, ptr nonnull %t50, i64 %len_b.i12)
  %1 = getelementptr i8, ptr %new_ptr.i16, i64 %len_b.i12
  %end.i18 = getelementptr i8, ptr %1, i64 8
  store i8 0, ptr %end.i18, align 1
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i16)
  %t54 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i20 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t54)
  %alloc_len.i22 = add i64 %len_b.i20, 8
  %new.i23 = tail call i64 @malloc(i64 %alloc_len.i22)
  %new_ptr.i24 = inttoptr i64 %new.i23 to ptr
  tail call void @memcpy(ptr %new_ptr.i24, ptr nonnull @.str10, i64 7)
  %dest.i25 = getelementptr i8, ptr %new_ptr.i24, i64 7
  tail call void @memcpy(ptr %dest.i25, ptr nonnull %t54, i64 %len_b.i20)
  %2 = getelementptr i8, ptr %new_ptr.i24, i64 %len_b.i20
  %end.i26 = getelementptr i8, ptr %2, i64 7
  store i8 0, ptr %end.i26, align 1
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i24)
  %t58 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t59 = tail call ptr @mire_i64_to_string(i64 %t58)
  %len_b.i28 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t59)
  %alloc_len.i30 = add i64 %len_b.i28, 16
  %new.i31 = tail call i64 @malloc(i64 %alloc_len.i30)
  %new_ptr.i32 = inttoptr i64 %new.i31 to ptr
  tail call void @memcpy(ptr %new_ptr.i32, ptr nonnull @.str11, i64 15)
  %dest.i33 = getelementptr i8, ptr %new_ptr.i32, i64 15
  tail call void @memcpy(ptr %dest.i33, ptr nonnull %t59, i64 %len_b.i28)
  %3 = getelementptr i8, ptr %new_ptr.i32, i64 %len_b.i28
  %end.i34 = getelementptr i8, ptr %3, i64 15
  store i8 0, ptr %end.i34, align 1
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i32)
  %t62 = tail call i64 @mire_mem_process_bytes()
  %t63 = tail call ptr @mire_mem_format(i64 %t62)
  %len_b.i36 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t63)
  %alloc_len.i38 = add i64 %len_b.i36, 13
  %new.i39 = tail call i64 @malloc(i64 %alloc_len.i38)
  %new_ptr.i40 = inttoptr i64 %new.i39 to ptr
  tail call void @memcpy(ptr %new_ptr.i40, ptr nonnull @.str12, i64 12)
  %dest.i41 = getelementptr i8, ptr %new_ptr.i40, i64 12
  tail call void @memcpy(ptr %dest.i41, ptr nonnull %t63, i64 %len_b.i36)
  %4 = getelementptr i8, ptr %new_ptr.i40, i64 %len_b.i36
  %end.i42 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i42, align 1
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i40)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
