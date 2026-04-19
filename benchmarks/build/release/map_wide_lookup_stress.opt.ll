; ModuleID = 'build/release/map_wide_lookup_stress.ll'
source_filename = "build/release/map_wide_lookup_stress.ll"

@.str16 = private unnamed_addr constant [4 x i8] c"k00\00"
@.str17 = private unnamed_addr constant [4 x i8] c"k01\00"
@.str18 = private unnamed_addr constant [4 x i8] c"k02\00"
@.str19 = private unnamed_addr constant [4 x i8] c"k03\00"
@.str20 = private unnamed_addr constant [4 x i8] c"k04\00"
@.str21 = private unnamed_addr constant [4 x i8] c"k05\00"
@.str22 = private unnamed_addr constant [4 x i8] c"k06\00"
@.str23 = private unnamed_addr constant [4 x i8] c"k07\00"
@.str24 = private unnamed_addr constant [4 x i8] c"k08\00"
@.str25 = private unnamed_addr constant [4 x i8] c"k09\00"
@.str26 = private unnamed_addr constant [4 x i8] c"k10\00"
@.str27 = private unnamed_addr constant [4 x i8] c"k11\00"
@.str28 = private unnamed_addr constant [4 x i8] c"k12\00"
@.str29 = private unnamed_addr constant [4 x i8] c"k13\00"
@.str30 = private unnamed_addr constant [4 x i8] c"k14\00"
@.str31 = private unnamed_addr constant [4 x i8] c"k15\00"
@.str32 = private unnamed_addr constant [7 x i8] c"total \00"
@.str33 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str34 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str35 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str36 = private unnamed_addr constant [13 x i8] c"process_ram \00"

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
  %t8 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str16, i64 1)
  %t11 = tail call ptr @mire_dict_set_i64(ptr %t8, i64 3, i64 1, i64 0, ptr nonnull @.str17, i64 2)
  %t14 = tail call ptr @mire_dict_set_i64(ptr %t11, i64 3, i64 1, i64 0, ptr nonnull @.str18, i64 3)
  %t17 = tail call ptr @mire_dict_set_i64(ptr %t14, i64 3, i64 1, i64 0, ptr nonnull @.str19, i64 4)
  %t20 = tail call ptr @mire_dict_set_i64(ptr %t17, i64 3, i64 1, i64 0, ptr nonnull @.str20, i64 5)
  %t23 = tail call ptr @mire_dict_set_i64(ptr %t20, i64 3, i64 1, i64 0, ptr nonnull @.str21, i64 6)
  %t26 = tail call ptr @mire_dict_set_i64(ptr %t23, i64 3, i64 1, i64 0, ptr nonnull @.str22, i64 7)
  %t29 = tail call ptr @mire_dict_set_i64(ptr %t26, i64 3, i64 1, i64 0, ptr nonnull @.str23, i64 8)
  %t32 = tail call ptr @mire_dict_set_i64(ptr %t29, i64 3, i64 1, i64 0, ptr nonnull @.str24, i64 9)
  %t35 = tail call ptr @mire_dict_set_i64(ptr %t32, i64 3, i64 1, i64 0, ptr nonnull @.str25, i64 10)
  %t38 = tail call ptr @mire_dict_set_i64(ptr %t35, i64 3, i64 1, i64 0, ptr nonnull @.str26, i64 11)
  %t41 = tail call ptr @mire_dict_set_i64(ptr %t38, i64 3, i64 1, i64 0, ptr nonnull @.str27, i64 12)
  %t44 = tail call ptr @mire_dict_set_i64(ptr %t41, i64 3, i64 1, i64 0, ptr nonnull @.str28, i64 13)
  %t47 = tail call ptr @mire_dict_set_i64(ptr %t44, i64 3, i64 1, i64 0, ptr nonnull @.str29, i64 14)
  %t50 = tail call ptr @mire_dict_set_i64(ptr %t47, i64 3, i64 1, i64 0, ptr nonnull @.str30, i64 15)
  %t53 = tail call ptr @mire_dict_set_i64(ptr %t50, i64 3, i64 1, i64 0, ptr nonnull @.str31, i64 16)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t55.056 = phi i64 [ 0, %entry ], [ %t137, %while_body_1 ]
  %t54.055 = phi i64 [ 0, %entry ], [ %t139, %while_body_1 ]
  %t61 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str16, i64 0)
  %t62 = add i64 %t61, %t55.056
  %t66 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str17, i64 0)
  %t67 = add i64 %t62, %t66
  %t71 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str18, i64 0)
  %t72 = add i64 %t67, %t71
  %t76 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str19, i64 0)
  %t77 = add i64 %t72, %t76
  %t81 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str20, i64 0)
  %t82 = add i64 %t77, %t81
  %t86 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str21, i64 0)
  %t87 = add i64 %t82, %t86
  %t91 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str22, i64 0)
  %t92 = add i64 %t87, %t91
  %t96 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str23, i64 0)
  %t97 = add i64 %t92, %t96
  %t101 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str24, i64 0)
  %t102 = add i64 %t97, %t101
  %t106 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str25, i64 0)
  %t107 = add i64 %t102, %t106
  %t111 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str26, i64 0)
  %t112 = add i64 %t107, %t111
  %t116 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str27, i64 0)
  %t117 = add i64 %t112, %t116
  %t121 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str28, i64 0)
  %t122 = add i64 %t117, %t121
  %t126 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str29, i64 0)
  %t127 = add i64 %t122, %t126
  %t131 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str30, i64 0)
  %t132 = add i64 %t127, %t131
  %t136 = tail call i64 @mire_dict_get_i64(ptr %t53, i64 3, i64 0, ptr nonnull @.str31, i64 0)
  %t137 = add i64 %t132, %t136
  %t139 = add nuw nsw i64 %t54.055, 1
  %t57 = icmp samesign ult i64 %t54.055, 19999
  br i1 %t57, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t142 = tail call ptr @mire_i64_to_string(i64 %t137)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t142)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str32, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t142, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t146 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i24 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t146)
  %alloc_len.i26 = add i64 %len_b.i24, 9
  %new.i27 = tail call i64 @malloc(i64 %alloc_len.i26)
  %new_ptr.i28 = inttoptr i64 %new.i27 to ptr
  tail call void @memcpy(ptr %new_ptr.i28, ptr nonnull @.str33, i64 8)
  %dest.i29 = getelementptr i8, ptr %new_ptr.i28, i64 8
  tail call void @memcpy(ptr %dest.i29, ptr nonnull %t146, i64 %len_b.i24)
  %1 = getelementptr i8, ptr %new_ptr.i28, i64 %len_b.i24
  %end.i30 = getelementptr i8, ptr %1, i64 8
  store i8 0, ptr %end.i30, align 1
  %puts19 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i28)
  %t150 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i32 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t150)
  %alloc_len.i34 = add i64 %len_b.i32, 8
  %new.i35 = tail call i64 @malloc(i64 %alloc_len.i34)
  %new_ptr.i36 = inttoptr i64 %new.i35 to ptr
  tail call void @memcpy(ptr %new_ptr.i36, ptr nonnull @.str34, i64 7)
  %dest.i37 = getelementptr i8, ptr %new_ptr.i36, i64 7
  tail call void @memcpy(ptr %dest.i37, ptr nonnull %t150, i64 %len_b.i32)
  %2 = getelementptr i8, ptr %new_ptr.i36, i64 %len_b.i32
  %end.i38 = getelementptr i8, ptr %2, i64 7
  store i8 0, ptr %end.i38, align 1
  %puts20 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i36)
  %t154 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t155 = tail call ptr @mire_i64_to_string(i64 %t154)
  %len_b.i40 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t155)
  %alloc_len.i42 = add i64 %len_b.i40, 16
  %new.i43 = tail call i64 @malloc(i64 %alloc_len.i42)
  %new_ptr.i44 = inttoptr i64 %new.i43 to ptr
  tail call void @memcpy(ptr %new_ptr.i44, ptr nonnull @.str35, i64 15)
  %dest.i45 = getelementptr i8, ptr %new_ptr.i44, i64 15
  tail call void @memcpy(ptr %dest.i45, ptr nonnull %t155, i64 %len_b.i40)
  %3 = getelementptr i8, ptr %new_ptr.i44, i64 %len_b.i40
  %end.i46 = getelementptr i8, ptr %3, i64 15
  store i8 0, ptr %end.i46, align 1
  %puts21 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i44)
  %t158 = tail call i64 @mire_mem_process_bytes()
  %t159 = tail call ptr @mire_mem_format(i64 %t158)
  %len_b.i48 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t159)
  %alloc_len.i50 = add i64 %len_b.i48, 13
  %new.i51 = tail call i64 @malloc(i64 %alloc_len.i50)
  %new_ptr.i52 = inttoptr i64 %new.i51 to ptr
  tail call void @memcpy(ptr %new_ptr.i52, ptr nonnull @.str36, i64 12)
  %dest.i53 = getelementptr i8, ptr %new_ptr.i52, i64 12
  tail call void @memcpy(ptr %dest.i53, ptr nonnull %t159, i64 %len_b.i48)
  %4 = getelementptr i8, ptr %new_ptr.i52, i64 %len_b.i48
  %end.i54 = getelementptr i8, ptr %4, i64 12
  store i8 0, ptr %end.i54, align 1
  %puts22 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i52)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
