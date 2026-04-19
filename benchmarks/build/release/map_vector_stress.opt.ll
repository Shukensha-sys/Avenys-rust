; ModuleID = 'build/release/map_vector_stress.ll'
source_filename = "build/release/map_vector_stress.ll"

@.str2 = private unnamed_addr constant [6 x i8] c"right\00"
@.str5 = private unnamed_addr constant [5 x i8] c"left\00"
@.str6 = private unnamed_addr constant [7 x i8] c"total \00"
@.str7 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str8 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str9 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str10 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str11 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

declare ptr @mire_dict_get_ptr(ptr, i64, i64, ptr, ptr) local_unnamed_addr

declare ptr @mire_dict_set_ptr(ptr, i64, i64, i64, ptr, ptr) local_unnamed_addr

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
  %t7 = tail call ptr @mire_list_push_i64(ptr null, i64 2)
  %t9 = tail call ptr @mire_list_push_i64(ptr %t7, i64 4)
  %t11 = tail call ptr @mire_list_push_i64(ptr %t9, i64 6)
  %t15 = tail call ptr @mire_list_push_i64(ptr null, i64 3)
  %t17 = tail call ptr @mire_list_push_i64(ptr %t15, i64 5)
  %t19 = tail call ptr @mire_list_push_i64(ptr %t17, i64 7)
  %t27 = tail call ptr @mire_dict_set_ptr(ptr null, i64 3, i64 5, i64 0, ptr nonnull @.str5, ptr %t11)
  %t31 = tail call ptr @mire_dict_set_ptr(ptr %t27, i64 3, i64 5, i64 0, ptr nonnull @.str2, ptr %t19)
  %t36 = tail call ptr @mire_dict_get_ptr(ptr %t31, i64 3, i64 0, ptr nonnull @.str2, ptr null)
  %t41 = tail call ptr @mire_dict_get_ptr(ptr %t31, i64 3, i64 0, ptr nonnull @.str5, ptr null)
  %t42 = getelementptr inbounds nuw i8, ptr %t41, i64 8
  %t45 = load i64, ptr %t42, align 4
  %t49 = tail call ptr @mire_dict_get_ptr(ptr %t31, i64 3, i64 0, ptr nonnull @.str5, ptr null)
  %t52 = getelementptr inbounds nuw i8, ptr %t49, i64 16
  %t53 = load i64, ptr %t52, align 4
  %t54 = add i64 %t53, %t45
  %t58 = tail call ptr @mire_dict_get_ptr(ptr %t31, i64 3, i64 0, ptr nonnull @.str5, ptr null)
  %t61 = getelementptr inbounds nuw i8, ptr %t58, i64 24
  %t62 = load i64, ptr %t61, align 4
  %t63 = add i64 %t54, %t62
  %t65 = getelementptr inbounds nuw i8, ptr %t36, i64 8
  %t68 = load i64, ptr %t65, align 4
  %t69 = add i64 %t63, %t68
  %t73 = getelementptr inbounds nuw i8, ptr %t36, i64 16
  %t74 = load i64, ptr %t73, align 4
  %t75 = add i64 %t69, %t74
  %t79 = getelementptr inbounds nuw i8, ptr %t36, i64 24
  %t80 = load i64, ptr %t79, align 4
  %t81 = add i64 %t75, %t80
  %t90 = tail call ptr @mire_i64_to_string(i64 %t81)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t90)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str6, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t90, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t94 = tail call ptr @mire_i64_to_string(i64 %t80)
  %len_b.i8 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t94)
  %alloc_len.i10 = add i64 %len_b.i8, 6
  %new.i11 = tail call i64 @malloc(i64 %alloc_len.i10)
  %new_ptr.i12 = inttoptr i64 %new.i11 to ptr
  tail call void @memcpy(ptr %new_ptr.i12, ptr nonnull @.str7, i64 5)
  %dest.i13 = getelementptr i8, ptr %new_ptr.i12, i64 5
  tail call void @memcpy(ptr %dest.i13, ptr nonnull %t94, i64 %len_b.i8)
  %1 = getelementptr i8, ptr %new_ptr.i12, i64 %len_b.i8
  %end.i14 = getelementptr i8, ptr %1, i64 5
  store i8 0, ptr %end.i14, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i12)
  %t98 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i16 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t98)
  %alloc_len.i18 = add i64 %len_b.i16, 9
  %new.i19 = tail call i64 @malloc(i64 %alloc_len.i18)
  %new_ptr.i20 = inttoptr i64 %new.i19 to ptr
  tail call void @memcpy(ptr %new_ptr.i20, ptr nonnull @.str8, i64 8)
  %dest.i21 = getelementptr i8, ptr %new_ptr.i20, i64 8
  tail call void @memcpy(ptr %dest.i21, ptr nonnull %t98, i64 %len_b.i16)
  %2 = getelementptr i8, ptr %new_ptr.i20, i64 %len_b.i16
  %end.i22 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i22, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i20)
  %t102 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i24 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t102)
  %alloc_len.i26 = add i64 %len_b.i24, 8
  %new.i27 = tail call i64 @malloc(i64 %alloc_len.i26)
  %new_ptr.i28 = inttoptr i64 %new.i27 to ptr
  tail call void @memcpy(ptr %new_ptr.i28, ptr nonnull @.str9, i64 7)
  %dest.i29 = getelementptr i8, ptr %new_ptr.i28, i64 7
  tail call void @memcpy(ptr %dest.i29, ptr nonnull %t102, i64 %len_b.i24)
  %3 = getelementptr i8, ptr %new_ptr.i28, i64 %len_b.i24
  %end.i30 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i30, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i28)
  %t106 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t107 = tail call ptr @mire_i64_to_string(i64 %t106)
  %len_b.i32 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t107)
  %alloc_len.i34 = add i64 %len_b.i32, 16
  %new.i35 = tail call i64 @malloc(i64 %alloc_len.i34)
  %new_ptr.i36 = inttoptr i64 %new.i35 to ptr
  tail call void @memcpy(ptr %new_ptr.i36, ptr nonnull @.str10, i64 15)
  %dest.i37 = getelementptr i8, ptr %new_ptr.i36, i64 15
  tail call void @memcpy(ptr %dest.i37, ptr nonnull %t107, i64 %len_b.i32)
  %4 = getelementptr i8, ptr %new_ptr.i36, i64 %len_b.i32
  %end.i38 = getelementptr i8, ptr %4, i64 15
  store i8 0, ptr %end.i38, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i36)
  %t110 = tail call i64 @mire_mem_process_bytes()
  %t111 = tail call ptr @mire_mem_format(i64 %t110)
  %len_b.i40 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t111)
  %alloc_len.i42 = add i64 %len_b.i40, 13
  %new.i43 = tail call i64 @malloc(i64 %alloc_len.i42)
  %new_ptr.i44 = inttoptr i64 %new.i43 to ptr
  tail call void @memcpy(ptr %new_ptr.i44, ptr nonnull @.str11, i64 12)
  %dest.i45 = getelementptr i8, ptr %new_ptr.i44, i64 12
  tail call void @memcpy(ptr %dest.i45, ptr nonnull %t111, i64 %len_b.i40)
  %5 = getelementptr i8, ptr %new_ptr.i44, i64 %len_b.i40
  %end.i46 = getelementptr i8, ptr %5, i64 12
  store i8 0, ptr %end.i46, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i44)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
