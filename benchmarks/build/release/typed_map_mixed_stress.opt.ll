; ModuleID = 'build/release/typed_map_mixed_stress.ll'
source_filename = "build/release/typed_map_mixed_stress.ll"

@.str0 = private unnamed_addr constant [8 x i8] c"enabled\00"
@.str1 = private unnamed_addr constant [9 x i8] c"disabled\00"
@.str3 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str4 = private unnamed_addr constant [7 x i8] c"total \00"
@.str5 = private unnamed_addr constant [8 x i8] c"labels \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str9 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_dict_get_ptr(ptr, i64, i64, ptr, ptr) local_unnamed_addr

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
  %t9 = tail call ptr @mire_dict_set_ptr(ptr null, i64 2, i64 3, i64 1, ptr null, ptr nonnull @.str0)
  %t13 = tail call ptr @mire_dict_set_ptr(ptr %t9, i64 2, i64 3, i64 0, ptr null, ptr nonnull @.str1)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t14.051 = phi i64 [ 0, %entry ], [ %t37, %while_body_1 ]
  %t15.050 = phi i64 [ 0, %entry ], [ %t39, %while_body_1 ]
  %t22 = tail call ptr @mire_dict_get_ptr(ptr %t13, i64 2, i64 1, ptr null, ptr nonnull @.str3)
  %t23 = tail call ptr @mire_string_copy(ptr %t22)
  %t28 = tail call ptr @mire_dict_get_ptr(ptr %t13, i64 2, i64 0, ptr null, ptr nonnull @.str3)
  %t29 = tail call ptr @mire_string_copy(ptr %t28)
  %t32 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t23)
  %t33 = add i64 %t32, %t14.051
  %t36 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t29)
  %t37 = add i64 %t33, %t36
  %t39 = add nuw nsw i64 %t15.050, 1
  %t17 = icmp samesign ult i64 %t15.050, 39999
  br i1 %t17, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t42 = tail call ptr @mire_i64_to_string(i64 %t37)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t42)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str4, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t42, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t46 = tail call ptr @mire_dict_to_string(ptr %t13)
  %len_b.i11 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t46)
  %alloc_len.i13 = add i64 %len_b.i11, 8
  %new.i14 = tail call i64 @malloc(i64 %alloc_len.i13)
  %new_ptr.i15 = inttoptr i64 %new.i14 to ptr
  tail call void @memcpy(ptr %new_ptr.i15, ptr nonnull @.str5, i64 7)
  %dest.i16 = getelementptr i8, ptr %new_ptr.i15, i64 7
  tail call void @memcpy(ptr %dest.i16, ptr nonnull %t46, i64 %len_b.i11)
  %1 = getelementptr i8, ptr %new_ptr.i15, i64 %len_b.i11
  %end.i17 = getelementptr i8, ptr %1, i64 7
  store i8 0, ptr %end.i17, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i15)
  %t50 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i19 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t50)
  %alloc_len.i21 = add i64 %len_b.i19, 9
  %new.i22 = tail call i64 @malloc(i64 %alloc_len.i21)
  %new_ptr.i23 = inttoptr i64 %new.i22 to ptr
  tail call void @memcpy(ptr %new_ptr.i23, ptr nonnull @.str6, i64 8)
  %dest.i24 = getelementptr i8, ptr %new_ptr.i23, i64 8
  tail call void @memcpy(ptr %dest.i24, ptr nonnull %t50, i64 %len_b.i19)
  %2 = getelementptr i8, ptr %new_ptr.i23, i64 %len_b.i19
  %end.i25 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i25, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i23)
  %t54 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i27 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t54)
  %alloc_len.i29 = add i64 %len_b.i27, 8
  %new.i30 = tail call i64 @malloc(i64 %alloc_len.i29)
  %new_ptr.i31 = inttoptr i64 %new.i30 to ptr
  tail call void @memcpy(ptr %new_ptr.i31, ptr nonnull @.str7, i64 7)
  %dest.i32 = getelementptr i8, ptr %new_ptr.i31, i64 7
  tail call void @memcpy(ptr %dest.i32, ptr nonnull %t54, i64 %len_b.i27)
  %3 = getelementptr i8, ptr %new_ptr.i31, i64 %len_b.i27
  %end.i33 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i33, align 1
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i31)
  %t58 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t59 = tail call ptr @mire_i64_to_string(i64 %t58)
  %len_b.i35 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t59)
  %alloc_len.i37 = add i64 %len_b.i35, 16
  %new.i38 = tail call i64 @malloc(i64 %alloc_len.i37)
  %new_ptr.i39 = inttoptr i64 %new.i38 to ptr
  tail call void @memcpy(ptr %new_ptr.i39, ptr nonnull @.str8, i64 15)
  %dest.i40 = getelementptr i8, ptr %new_ptr.i39, i64 15
  tail call void @memcpy(ptr %dest.i40, ptr nonnull %t59, i64 %len_b.i35)
  %4 = getelementptr i8, ptr %new_ptr.i39, i64 %len_b.i35
  %end.i41 = getelementptr i8, ptr %4, i64 15
  store i8 0, ptr %end.i41, align 1
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i39)
  %t62 = tail call i64 @mire_mem_process_bytes()
  %t63 = tail call ptr @mire_mem_format(i64 %t62)
  %len_b.i43 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t63)
  %alloc_len.i45 = add i64 %len_b.i43, 13
  %new.i46 = tail call i64 @malloc(i64 %alloc_len.i45)
  %new_ptr.i47 = inttoptr i64 %new.i46 to ptr
  tail call void @memcpy(ptr %new_ptr.i47, ptr nonnull @.str9, i64 12)
  %dest.i48 = getelementptr i8, ptr %new_ptr.i47, i64 12
  tail call void @memcpy(ptr %dest.i48, ptr nonnull %t63, i64 %len_b.i43)
  %5 = getelementptr i8, ptr %new_ptr.i47, i64 %len_b.i43
  %end.i49 = getelementptr i8, ptr %5, i64 12
  store i8 0, ptr %end.i49, align 1
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i47)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
