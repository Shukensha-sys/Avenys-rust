; ModuleID = 'build/release/map_stress.ll'
source_filename = "build/release/map_stress.ll"

@.str8 = private unnamed_addr constant [7 x i8] c"alpha \00"
@.str9 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str10 = private unnamed_addr constant [6 x i8] c"beta \00"
@.str11 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str12 = private unnamed_addr constant [7 x i8] c"gamma \00"
@.str13 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str14 = private unnamed_addr constant [7 x i8] c"delta \00"
@.str15 = private unnamed_addr constant [6 x i8] c"delta\00"
@.str16 = private unnamed_addr constant [7 x i8] c"total \00"
@.str17 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str18 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str19 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str20 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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

while_body_1:                                     ; preds = %entry, %if_end_14
  %t4.090 = phi ptr [ null, %entry ], [ %t40, %if_end_14 ]
  %t6.089 = phi i64 [ 0, %entry ], [ %t74, %if_end_14 ]
  %trunc = trunc i64 %t6.089 to i2
  switch i2 %trunc, label %if_then_12 [
    i2 0, label %if_end_14
    i2 1, label %if_then_6
    i2 -2, label %if_then_9
  ]

if_then_6:                                        ; preds = %while_body_1
  br label %if_end_14

if_then_9:                                        ; preds = %while_body_1
  br label %if_end_14

if_then_12:                                       ; preds = %while_body_1
  br label %if_end_14

if_end_14:                                        ; preds = %while_body_1, %if_then_6, %if_then_9, %if_then_12
  %.str1.sink = phi ptr [ @.str11, %if_then_6 ], [ @.str15, %if_then_12 ], [ @.str13, %if_then_9 ], [ @.str9, %while_body_1 ]
  %t30 = tail call ptr @mire_string_copy(ptr nonnull %.str1.sink)
  %t34 = tail call i64 @mire_dict_get_i64(ptr %t4.090, i64 3, i64 0, ptr %t30, i64 0)
  %t39 = add i64 %t34, %t6.089
  %t40 = tail call ptr @mire_dict_set_i64(ptr %t4.090, i64 3, i64 1, i64 0, ptr %t30, i64 %t39)
  %t74 = add nuw nsw i64 %t6.089, 1
  %t8 = icmp samesign ult i64 %t6.089, 11999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %if_end_14
  %t78 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str9, i64 0)
  %t81 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str11, i64 0)
  %t82 = add i64 %t81, %t78
  %t85 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str13, i64 0)
  %t86 = add i64 %t82, %t85
  %t89 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str15, i64 0)
  %t90 = add i64 %t86, %t89
  %t94 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str9, i64 0)
  %t95 = tail call ptr @mire_i64_to_string(i64 %t94)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t95)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str8, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t95, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t100 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str11, i64 0)
  %t101 = tail call ptr @mire_i64_to_string(i64 %t100)
  %len_b.i20 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t101)
  %alloc_len.i22 = add i64 %len_b.i20, 6
  %new.i23 = tail call i64 @malloc(i64 %alloc_len.i22)
  %new_ptr.i24 = inttoptr i64 %new.i23 to ptr
  tail call void @memcpy(ptr %new_ptr.i24, ptr nonnull @.str10, i64 5)
  %dest.i25 = getelementptr i8, ptr %new_ptr.i24, i64 5
  tail call void @memcpy(ptr %dest.i25, ptr nonnull %t101, i64 %len_b.i20)
  %1 = getelementptr i8, ptr %new_ptr.i24, i64 %len_b.i20
  %end.i26 = getelementptr i8, ptr %1, i64 5
  store i8 0, ptr %end.i26, align 1
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i24)
  %t106 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str13, i64 0)
  %t107 = tail call ptr @mire_i64_to_string(i64 %t106)
  %len_b.i28 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t107)
  %alloc_len.i30 = add i64 %len_b.i28, 7
  %new.i31 = tail call i64 @malloc(i64 %alloc_len.i30)
  %new_ptr.i32 = inttoptr i64 %new.i31 to ptr
  tail call void @memcpy(ptr %new_ptr.i32, ptr nonnull @.str12, i64 6)
  %dest.i33 = getelementptr i8, ptr %new_ptr.i32, i64 6
  tail call void @memcpy(ptr %dest.i33, ptr nonnull %t107, i64 %len_b.i28)
  %2 = getelementptr i8, ptr %new_ptr.i32, i64 %len_b.i28
  %end.i34 = getelementptr i8, ptr %2, i64 6
  store i8 0, ptr %end.i34, align 1
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i32)
  %t112 = tail call i64 @mire_dict_get_i64(ptr %t40, i64 3, i64 0, ptr nonnull @.str15, i64 0)
  %t113 = tail call ptr @mire_i64_to_string(i64 %t112)
  %len_b.i36 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t113)
  %alloc_len.i38 = add i64 %len_b.i36, 7
  %new.i39 = tail call i64 @malloc(i64 %alloc_len.i38)
  %new_ptr.i40 = inttoptr i64 %new.i39 to ptr
  tail call void @memcpy(ptr %new_ptr.i40, ptr nonnull @.str14, i64 6)
  %dest.i41 = getelementptr i8, ptr %new_ptr.i40, i64 6
  tail call void @memcpy(ptr %dest.i41, ptr nonnull %t113, i64 %len_b.i36)
  %3 = getelementptr i8, ptr %new_ptr.i40, i64 %len_b.i36
  %end.i42 = getelementptr i8, ptr %3, i64 6
  store i8 0, ptr %end.i42, align 1
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i40)
  %t117 = tail call ptr @mire_i64_to_string(i64 %t90)
  %len_b.i44 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t117)
  %alloc_len.i46 = add i64 %len_b.i44, 7
  %new.i47 = tail call i64 @malloc(i64 %alloc_len.i46)
  %new_ptr.i48 = inttoptr i64 %new.i47 to ptr
  tail call void @memcpy(ptr %new_ptr.i48, ptr nonnull @.str16, i64 6)
  %dest.i49 = getelementptr i8, ptr %new_ptr.i48, i64 6
  tail call void @memcpy(ptr %dest.i49, ptr nonnull %t117, i64 %len_b.i44)
  %4 = getelementptr i8, ptr %new_ptr.i48, i64 %len_b.i44
  %end.i50 = getelementptr i8, ptr %4, i64 6
  store i8 0, ptr %end.i50, align 1
  %puts14 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i48)
  %t121 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i52 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t121)
  %alloc_len.i54 = add i64 %len_b.i52, 9
  %new.i55 = tail call i64 @malloc(i64 %alloc_len.i54)
  %new_ptr.i56 = inttoptr i64 %new.i55 to ptr
  tail call void @memcpy(ptr %new_ptr.i56, ptr nonnull @.str17, i64 8)
  %dest.i57 = getelementptr i8, ptr %new_ptr.i56, i64 8
  tail call void @memcpy(ptr %dest.i57, ptr nonnull %t121, i64 %len_b.i52)
  %5 = getelementptr i8, ptr %new_ptr.i56, i64 %len_b.i52
  %end.i58 = getelementptr i8, ptr %5, i64 8
  store i8 0, ptr %end.i58, align 1
  %puts15 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i56)
  %t125 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i60 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t125)
  %alloc_len.i62 = add i64 %len_b.i60, 8
  %new.i63 = tail call i64 @malloc(i64 %alloc_len.i62)
  %new_ptr.i64 = inttoptr i64 %new.i63 to ptr
  tail call void @memcpy(ptr %new_ptr.i64, ptr nonnull @.str18, i64 7)
  %dest.i65 = getelementptr i8, ptr %new_ptr.i64, i64 7
  tail call void @memcpy(ptr %dest.i65, ptr nonnull %t125, i64 %len_b.i60)
  %6 = getelementptr i8, ptr %new_ptr.i64, i64 %len_b.i60
  %end.i66 = getelementptr i8, ptr %6, i64 7
  store i8 0, ptr %end.i66, align 1
  %puts16 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i64)
  %t129 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t130 = tail call ptr @mire_i64_to_string(i64 %t129)
  %len_b.i68 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t130)
  %alloc_len.i70 = add i64 %len_b.i68, 16
  %new.i71 = tail call i64 @malloc(i64 %alloc_len.i70)
  %new_ptr.i72 = inttoptr i64 %new.i71 to ptr
  tail call void @memcpy(ptr %new_ptr.i72, ptr nonnull @.str19, i64 15)
  %dest.i73 = getelementptr i8, ptr %new_ptr.i72, i64 15
  tail call void @memcpy(ptr %dest.i73, ptr nonnull %t130, i64 %len_b.i68)
  %7 = getelementptr i8, ptr %new_ptr.i72, i64 %len_b.i68
  %end.i74 = getelementptr i8, ptr %7, i64 15
  store i8 0, ptr %end.i74, align 1
  %puts17 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i72)
  %t133 = tail call i64 @mire_mem_process_bytes()
  %t134 = tail call ptr @mire_mem_format(i64 %t133)
  %len_b.i76 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t134)
  %alloc_len.i78 = add i64 %len_b.i76, 13
  %new.i79 = tail call i64 @malloc(i64 %alloc_len.i78)
  %new_ptr.i80 = inttoptr i64 %new.i79 to ptr
  tail call void @memcpy(ptr %new_ptr.i80, ptr nonnull @.str20, i64 12)
  %dest.i81 = getelementptr i8, ptr %new_ptr.i80, i64 12
  tail call void @memcpy(ptr %dest.i81, ptr nonnull %t134, i64 %len_b.i76)
  %8 = getelementptr i8, ptr %new_ptr.i80, i64 %len_b.i76
  %end.i82 = getelementptr i8, ptr %8, i64 12
  store i8 0, ptr %end.i82, align 1
  %puts18 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i80)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
