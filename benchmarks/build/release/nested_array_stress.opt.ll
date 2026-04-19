; ModuleID = 'build/release/nested_array_stress.ll'
source_filename = "build/release/nested_array_stress.ll"

@.str0 = private unnamed_addr constant [6 x i8] c"rows \00"
@.str1 = private unnamed_addr constant [6 x i8] c"cols \00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [6 x i8] c"edge \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str5 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str6 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str7 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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
list_len_end_5:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t159 = tail call ptr @mire_i64_to_string(i64 3)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t159)
  %alloc_len.i = add i64 %len_b.i, 6
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str0, i64 5)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 5
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t159, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 5
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t163 = tail call ptr @mire_i64_to_string(i64 4)
  %len_b.i22 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t163)
  %alloc_len.i24 = add i64 %len_b.i22, 6
  %new.i25 = tail call i64 @malloc(i64 %alloc_len.i24)
  %new_ptr.i26 = inttoptr i64 %new.i25 to ptr
  tail call void @memcpy(ptr %new_ptr.i26, ptr nonnull @.str1, i64 5)
  %dest.i27 = getelementptr i8, ptr %new_ptr.i26, i64 5
  tail call void @memcpy(ptr %dest.i27, ptr nonnull %t163, i64 %len_b.i22)
  %1 = getelementptr i8, ptr %new_ptr.i26, i64 %len_b.i22
  %end.i28 = getelementptr i8, ptr %1, i64 5
  store i8 0, ptr %end.i28, align 1
  %puts14 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i26)
  %t167 = tail call ptr @mire_i64_to_string(i64 78)
  %len_b.i30 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t167)
  %alloc_len.i32 = add i64 %len_b.i30, 7
  %new.i33 = tail call i64 @malloc(i64 %alloc_len.i32)
  %new_ptr.i34 = inttoptr i64 %new.i33 to ptr
  tail call void @memcpy(ptr %new_ptr.i34, ptr nonnull @.str2, i64 6)
  %dest.i35 = getelementptr i8, ptr %new_ptr.i34, i64 6
  tail call void @memcpy(ptr %dest.i35, ptr nonnull %t167, i64 %len_b.i30)
  %2 = getelementptr i8, ptr %new_ptr.i34, i64 %len_b.i30
  %end.i36 = getelementptr i8, ptr %2, i64 6
  store i8 0, ptr %end.i36, align 1
  %puts15 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i34)
  %t171 = tail call ptr @mire_i64_to_string(i64 12)
  %len_b.i38 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t171)
  %alloc_len.i40 = add i64 %len_b.i38, 6
  %new.i41 = tail call i64 @malloc(i64 %alloc_len.i40)
  %new_ptr.i42 = inttoptr i64 %new.i41 to ptr
  tail call void @memcpy(ptr %new_ptr.i42, ptr nonnull @.str3, i64 5)
  %dest.i43 = getelementptr i8, ptr %new_ptr.i42, i64 5
  tail call void @memcpy(ptr %dest.i43, ptr nonnull %t171, i64 %len_b.i38)
  %3 = getelementptr i8, ptr %new_ptr.i42, i64 %len_b.i38
  %end.i44 = getelementptr i8, ptr %3, i64 5
  store i8 0, ptr %end.i44, align 1
  %puts16 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i42)
  %t175 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i46 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t175)
  %alloc_len.i48 = add i64 %len_b.i46, 9
  %new.i49 = tail call i64 @malloc(i64 %alloc_len.i48)
  %new_ptr.i50 = inttoptr i64 %new.i49 to ptr
  tail call void @memcpy(ptr %new_ptr.i50, ptr nonnull @.str4, i64 8)
  %dest.i51 = getelementptr i8, ptr %new_ptr.i50, i64 8
  tail call void @memcpy(ptr %dest.i51, ptr nonnull %t175, i64 %len_b.i46)
  %4 = getelementptr i8, ptr %new_ptr.i50, i64 %len_b.i46
  %end.i52 = getelementptr i8, ptr %4, i64 8
  store i8 0, ptr %end.i52, align 1
  %puts17 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i50)
  %t179 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i54 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t179)
  %alloc_len.i56 = add i64 %len_b.i54, 8
  %new.i57 = tail call i64 @malloc(i64 %alloc_len.i56)
  %new_ptr.i58 = inttoptr i64 %new.i57 to ptr
  tail call void @memcpy(ptr %new_ptr.i58, ptr nonnull @.str5, i64 7)
  %dest.i59 = getelementptr i8, ptr %new_ptr.i58, i64 7
  tail call void @memcpy(ptr %dest.i59, ptr nonnull %t179, i64 %len_b.i54)
  %5 = getelementptr i8, ptr %new_ptr.i58, i64 %len_b.i54
  %end.i60 = getelementptr i8, ptr %5, i64 7
  store i8 0, ptr %end.i60, align 1
  %puts18 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i58)
  %t183 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t184 = tail call ptr @mire_i64_to_string(i64 %t183)
  %len_b.i62 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t184)
  %alloc_len.i64 = add i64 %len_b.i62, 16
  %new.i65 = tail call i64 @malloc(i64 %alloc_len.i64)
  %new_ptr.i66 = inttoptr i64 %new.i65 to ptr
  tail call void @memcpy(ptr %new_ptr.i66, ptr nonnull @.str6, i64 15)
  %dest.i67 = getelementptr i8, ptr %new_ptr.i66, i64 15
  tail call void @memcpy(ptr %dest.i67, ptr nonnull %t184, i64 %len_b.i62)
  %6 = getelementptr i8, ptr %new_ptr.i66, i64 %len_b.i62
  %end.i68 = getelementptr i8, ptr %6, i64 15
  store i8 0, ptr %end.i68, align 1
  %puts19 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i66)
  %t187 = tail call i64 @mire_mem_process_bytes()
  %t188 = tail call ptr @mire_mem_format(i64 %t187)
  %len_b.i70 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t188)
  %alloc_len.i72 = add i64 %len_b.i70, 13
  %new.i73 = tail call i64 @malloc(i64 %alloc_len.i72)
  %new_ptr.i74 = inttoptr i64 %new.i73 to ptr
  tail call void @memcpy(ptr %new_ptr.i74, ptr nonnull @.str7, i64 12)
  %dest.i75 = getelementptr i8, ptr %new_ptr.i74, i64 12
  tail call void @memcpy(ptr %dest.i75, ptr nonnull %t188, i64 %len_b.i70)
  %7 = getelementptr i8, ptr %new_ptr.i74, i64 %len_b.i70
  %end.i76 = getelementptr i8, ptr %7, i64 12
  store i8 0, ptr %end.i76, align 1
  %puts20 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i74)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
