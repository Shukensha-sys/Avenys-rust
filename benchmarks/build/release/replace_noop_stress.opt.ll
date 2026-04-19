; ModuleID = 'build/release/replace_noop_stress.ll'
source_filename = "build/release/replace_noop_stress.ll"

@.str1 = private unnamed_addr constant [5 x i8] c"seed\00"
@.str2 = private unnamed_addr constant [5 x i8] c"node\00"
@.str3 = private unnamed_addr constant [6 x i8] c"text \00"
@.str4 = private unnamed_addr constant [8 x i8] c"length \00"
@.str5 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str6 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str7 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str8 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_strings_replace(ptr, ptr, ptr) local_unnamed_addr

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
  %t6 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t7.049 = phi i64 [ 0, %entry ], [ %t16, %while_body_1 ]
  %t4.048 = phi ptr [ %t6, %entry ], [ %t13, %while_body_1 ]
  %t13 = tail call ptr @mire_strings_replace(ptr %t4.048, ptr nonnull @.str1, ptr nonnull @.str2)
  tail call void @mire_string_free(ptr %t4.048)
  %t16 = add nuw nsw i64 %t7.049, 1
  %t9 = icmp samesign ult i64 %t7.049, 19999
  br i1 %t9, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t13)
  %alloc_len.i = add i64 %len_b.i, 6
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str3, i64 5)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 5
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t13, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 5
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t22 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t13)
  %t23 = tail call ptr @mire_i64_to_string(i64 %t22)
  %len_b.i9 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t23)
  %alloc_len.i11 = add i64 %len_b.i9, 8
  %new.i12 = tail call i64 @malloc(i64 %alloc_len.i11)
  %new_ptr.i13 = inttoptr i64 %new.i12 to ptr
  tail call void @memcpy(ptr %new_ptr.i13, ptr nonnull @.str4, i64 7)
  %dest.i14 = getelementptr i8, ptr %new_ptr.i13, i64 7
  tail call void @memcpy(ptr %dest.i14, ptr nonnull %t23, i64 %len_b.i9)
  %1 = getelementptr i8, ptr %new_ptr.i13, i64 %len_b.i9
  %end.i15 = getelementptr i8, ptr %1, i64 7
  store i8 0, ptr %end.i15, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i13)
  %t27 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i17 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t27)
  %alloc_len.i19 = add i64 %len_b.i17, 9
  %new.i20 = tail call i64 @malloc(i64 %alloc_len.i19)
  %new_ptr.i21 = inttoptr i64 %new.i20 to ptr
  tail call void @memcpy(ptr %new_ptr.i21, ptr nonnull @.str5, i64 8)
  %dest.i22 = getelementptr i8, ptr %new_ptr.i21, i64 8
  tail call void @memcpy(ptr %dest.i22, ptr nonnull %t27, i64 %len_b.i17)
  %2 = getelementptr i8, ptr %new_ptr.i21, i64 %len_b.i17
  %end.i23 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i23, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i21)
  %t31 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i25 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t31)
  %alloc_len.i27 = add i64 %len_b.i25, 8
  %new.i28 = tail call i64 @malloc(i64 %alloc_len.i27)
  %new_ptr.i29 = inttoptr i64 %new.i28 to ptr
  tail call void @memcpy(ptr %new_ptr.i29, ptr nonnull @.str6, i64 7)
  %dest.i30 = getelementptr i8, ptr %new_ptr.i29, i64 7
  tail call void @memcpy(ptr %dest.i30, ptr nonnull %t31, i64 %len_b.i25)
  %3 = getelementptr i8, ptr %new_ptr.i29, i64 %len_b.i25
  %end.i31 = getelementptr i8, ptr %3, i64 7
  store i8 0, ptr %end.i31, align 1
  %puts5 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i29)
  %t35 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t36 = tail call ptr @mire_i64_to_string(i64 %t35)
  %len_b.i33 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t36)
  %alloc_len.i35 = add i64 %len_b.i33, 16
  %new.i36 = tail call i64 @malloc(i64 %alloc_len.i35)
  %new_ptr.i37 = inttoptr i64 %new.i36 to ptr
  tail call void @memcpy(ptr %new_ptr.i37, ptr nonnull @.str7, i64 15)
  %dest.i38 = getelementptr i8, ptr %new_ptr.i37, i64 15
  tail call void @memcpy(ptr %dest.i38, ptr nonnull %t36, i64 %len_b.i33)
  %4 = getelementptr i8, ptr %new_ptr.i37, i64 %len_b.i33
  %end.i39 = getelementptr i8, ptr %4, i64 15
  store i8 0, ptr %end.i39, align 1
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i37)
  %t39 = tail call i64 @mire_mem_process_bytes()
  %t40 = tail call ptr @mire_mem_format(i64 %t39)
  %len_b.i41 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t40)
  %alloc_len.i43 = add i64 %len_b.i41, 13
  %new.i44 = tail call i64 @malloc(i64 %alloc_len.i43)
  %new_ptr.i45 = inttoptr i64 %new.i44 to ptr
  tail call void @memcpy(ptr %new_ptr.i45, ptr nonnull @.str8, i64 12)
  %dest.i46 = getelementptr i8, ptr %new_ptr.i45, i64 12
  tail call void @memcpy(ptr %dest.i46, ptr nonnull %t40, i64 %len_b.i41)
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
