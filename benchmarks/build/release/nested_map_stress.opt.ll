; ModuleID = 'build/release/nested_map_stress.ll'
source_filename = "build/release/nested_map_stress.ll"

@.str12 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str16 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str19 = private unnamed_addr constant [2 x i8] c"x\00"
@.str20 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str22 = private unnamed_addr constant [2 x i8] c"y\00"
@.str23 = private unnamed_addr constant [8 x i8] c"groups \00"
@.str24 = private unnamed_addr constant [7 x i8] c"total \00"
@.str25 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str26 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str27 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str28 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str29 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare ptr @mire_dict_get_ptr(ptr, i64, i64, ptr, ptr) local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_set_ptr(ptr, i64, i64, i64, ptr, ptr) local_unnamed_addr

declare ptr @mire_dict_to_string(ptr) local_unnamed_addr

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
  %t8 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str19, i64 11)
  %t11 = tail call ptr @mire_dict_set_i64(ptr %t8, i64 3, i64 1, i64 0, ptr nonnull @.str22, i64 22)
  %t16 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str19, i64 33)
  %t19 = tail call ptr @mire_dict_set_i64(ptr %t16, i64 3, i64 1, i64 0, ptr nonnull @.str22, i64 44)
  %t24 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str19, i64 55)
  %t27 = tail call ptr @mire_dict_set_i64(ptr %t24, i64 3, i64 1, i64 0, ptr nonnull @.str22, i64 66)
  %t35 = tail call ptr @mire_dict_set_ptr(ptr null, i64 3, i64 4, i64 0, ptr nonnull @.str12, ptr %t11)
  %t39 = tail call ptr @mire_dict_set_ptr(ptr %t35, i64 3, i64 4, i64 0, ptr nonnull @.str16, ptr %t19)
  %t43 = tail call ptr @mire_dict_set_ptr(ptr %t39, i64 3, i64 4, i64 0, ptr nonnull @.str20, ptr %t27)
  %t48 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str16, ptr null)
  %t53 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str12, ptr null)
  %t55 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str19, i64 0)
  %t59 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str12, ptr null)
  %t61 = tail call i64 @mire_dict_get_i64(ptr %t59, i64 3, i64 0, ptr nonnull @.str22, i64 0)
  %t62 = add i64 %t61, %t55
  %t66 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str16, ptr null)
  %t68 = tail call i64 @mire_dict_get_i64(ptr %t66, i64 3, i64 0, ptr nonnull @.str19, i64 0)
  %t69 = add i64 %t62, %t68
  %t73 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str16, ptr null)
  %t75 = tail call i64 @mire_dict_get_i64(ptr %t73, i64 3, i64 0, ptr nonnull @.str22, i64 0)
  %t76 = add i64 %t69, %t75
  %t80 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str20, ptr null)
  %t82 = tail call i64 @mire_dict_get_i64(ptr %t80, i64 3, i64 0, ptr nonnull @.str19, i64 0)
  %t83 = add i64 %t76, %t82
  %t87 = tail call ptr @mire_dict_get_ptr(ptr %t43, i64 3, i64 0, ptr nonnull @.str20, ptr null)
  %t89 = tail call i64 @mire_dict_get_i64(ptr %t87, i64 3, i64 0, ptr nonnull @.str22, i64 0)
  %t90 = add i64 %t83, %t89
  %t94 = tail call i64 @mire_dict_get_i64(ptr %t48, i64 3, i64 0, ptr nonnull @.str22, i64 0)
  %t97 = tail call ptr @mire_dict_to_string(ptr %t43)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t97)
  %alloc_len.i = add i64 %len_b.i, 8
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str23, i64 7)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 7
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t97, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 7
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t101 = tail call ptr @mire_i64_to_string(i64 %t90)
  %len_b.i9 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t101)
  %alloc_len.i11 = add i64 %len_b.i9, 7
  %new.i12 = tail call i64 @malloc(i64 %alloc_len.i11)
  %new_ptr.i13 = inttoptr i64 %new.i12 to ptr
  tail call void @memcpy(ptr %new_ptr.i13, ptr nonnull @.str24, i64 6)
  %dest.i14 = getelementptr i8, ptr %new_ptr.i13, i64 6
  tail call void @memcpy(ptr %dest.i14, ptr nonnull %t101, i64 %len_b.i9)
  %1 = getelementptr i8, ptr %new_ptr.i13, i64 %len_b.i9
  %end.i15 = getelementptr i8, ptr %1, i64 6
  store i8 0, ptr %end.i15, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i13)
  %t105 = tail call ptr @mire_i64_to_string(i64 %t94)
  %len_b.i17 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t105)
  %alloc_len.i19 = add i64 %len_b.i17, 6
  %new.i20 = tail call i64 @malloc(i64 %alloc_len.i19)
  %new_ptr.i21 = inttoptr i64 %new.i20 to ptr
  tail call void @memcpy(ptr %new_ptr.i21, ptr nonnull @.str25, i64 5)
  %dest.i22 = getelementptr i8, ptr %new_ptr.i21, i64 5
  tail call void @memcpy(ptr %dest.i22, ptr nonnull %t105, i64 %len_b.i17)
  %2 = getelementptr i8, ptr %new_ptr.i21, i64 %len_b.i17
  %end.i23 = getelementptr i8, ptr %2, i64 5
  store i8 0, ptr %end.i23, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i21)
  %t109 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i25 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t109)
  %alloc_len.i27 = add i64 %len_b.i25, 9
  %new.i28 = tail call i64 @malloc(i64 %alloc_len.i27)
  %new_ptr.i29 = inttoptr i64 %new.i28 to ptr
  tail call void @memcpy(ptr %new_ptr.i29, ptr nonnull @.str26, i64 8)
  %dest.i30 = getelementptr i8, ptr %new_ptr.i29, i64 8
  tail call void @memcpy(ptr %dest.i30, ptr nonnull %t109, i64 %len_b.i25)
  %3 = getelementptr i8, ptr %new_ptr.i29, i64 %len_b.i25
  %end.i31 = getelementptr i8, ptr %3, i64 8
  store i8 0, ptr %end.i31, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i29)
  %t113 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i33 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t113)
  %alloc_len.i35 = add i64 %len_b.i33, 8
  %new.i36 = tail call i64 @malloc(i64 %alloc_len.i35)
  %new_ptr.i37 = inttoptr i64 %new.i36 to ptr
  tail call void @memcpy(ptr %new_ptr.i37, ptr nonnull @.str27, i64 7)
  %dest.i38 = getelementptr i8, ptr %new_ptr.i37, i64 7
  tail call void @memcpy(ptr %dest.i38, ptr nonnull %t113, i64 %len_b.i33)
  %4 = getelementptr i8, ptr %new_ptr.i37, i64 %len_b.i33
  %end.i39 = getelementptr i8, ptr %4, i64 7
  store i8 0, ptr %end.i39, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i37)
  %t117 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t118 = tail call ptr @mire_i64_to_string(i64 %t117)
  %len_b.i41 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t118)
  %alloc_len.i43 = add i64 %len_b.i41, 16
  %new.i44 = tail call i64 @malloc(i64 %alloc_len.i43)
  %new_ptr.i45 = inttoptr i64 %new.i44 to ptr
  tail call void @memcpy(ptr %new_ptr.i45, ptr nonnull @.str28, i64 15)
  %dest.i46 = getelementptr i8, ptr %new_ptr.i45, i64 15
  tail call void @memcpy(ptr %dest.i46, ptr nonnull %t118, i64 %len_b.i41)
  %5 = getelementptr i8, ptr %new_ptr.i45, i64 %len_b.i41
  %end.i47 = getelementptr i8, ptr %5, i64 15
  store i8 0, ptr %end.i47, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i45)
  %t121 = tail call i64 @mire_mem_process_bytes()
  %t122 = tail call ptr @mire_mem_format(i64 %t121)
  %len_b.i49 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t122)
  %alloc_len.i51 = add i64 %len_b.i49, 13
  %new.i52 = tail call i64 @malloc(i64 %alloc_len.i51)
  %new_ptr.i53 = inttoptr i64 %new.i52 to ptr
  tail call void @memcpy(ptr %new_ptr.i53, ptr nonnull @.str29, i64 12)
  %dest.i54 = getelementptr i8, ptr %new_ptr.i53, i64 12
  tail call void @memcpy(ptr %dest.i54, ptr nonnull %t122, i64 %len_b.i49)
  %6 = getelementptr i8, ptr %new_ptr.i53, i64 %len_b.i49
  %end.i55 = getelementptr i8, ptr %6, i64 12
  store i8 0, ptr %end.i55, align 1
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i53)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
