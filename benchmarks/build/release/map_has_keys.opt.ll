; ModuleID = 'build/release/map_has_keys.ll'
source_filename = "build/release/map_has_keys.ll"

@.str1 = private unnamed_addr constant [2 x i8] c"b\00"
@.str2 = private unnamed_addr constant [2 x i8] c"c\00"
@.str3 = private unnamed_addr constant [2 x i8] c"d\00"
@.str4 = private unnamed_addr constant [2 x i8] c"e\00"
@.str5 = private unnamed_addr constant [2 x i8] c"a\00"
@.str6 = private unnamed_addr constant [2 x i8] c"z\00"
@.str7 = private unnamed_addr constant [7 x i8] c"val_a \00"
@.str8 = private unnamed_addr constant [7 x i8] c"val_z \00"
@.str9 = private unnamed_addr constant [10 x i8] c"num_keys \00"
@.str10 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str11 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"

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
  %t8 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str5, i64 1)
  %t11 = tail call ptr @mire_dict_set_i64(ptr %t8, i64 3, i64 1, i64 0, ptr nonnull @.str1, i64 2)
  %t14 = tail call ptr @mire_dict_set_i64(ptr %t11, i64 3, i64 1, i64 0, ptr nonnull @.str2, i64 3)
  %t17 = tail call ptr @mire_dict_set_i64(ptr %t14, i64 3, i64 1, i64 0, ptr nonnull @.str3, i64 4)
  %t20 = tail call ptr @mire_dict_set_i64(ptr %t17, i64 3, i64 1, i64 0, ptr nonnull @.str4, i64 5)
  %t24 = tail call i64 @mire_dict_get_i64(ptr %t20, i64 3, i64 0, ptr nonnull @.str5, i64 0)
  %t28 = tail call i64 @mire_dict_get_i64(ptr %t20, i64 3, i64 0, ptr nonnull @.str6, i64 99)
  %t31 = tail call ptr @mire_dict_keys(ptr %t20)
  %t34 = tail call ptr @mire_dict_values(ptr %t20)
  %t37 = tail call ptr @mire_i64_to_string(i64 %t24)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t37)
  %alloc_len.i = add i64 %len_b.i, 7
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str7, i64 6)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 6
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t37, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 6
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t41 = tail call ptr @mire_i64_to_string(i64 %t28)
  %len_b.i6 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t41)
  %alloc_len.i8 = add i64 %len_b.i6, 7
  %new.i9 = tail call i64 @malloc(i64 %alloc_len.i8)
  %new_ptr.i10 = inttoptr i64 %new.i9 to ptr
  tail call void @memcpy(ptr %new_ptr.i10, ptr nonnull @.str8, i64 6)
  %dest.i11 = getelementptr i8, ptr %new_ptr.i10, i64 6
  tail call void @memcpy(ptr %dest.i11, ptr nonnull %t41, i64 %len_b.i6)
  %1 = getelementptr i8, ptr %new_ptr.i10, i64 %len_b.i6
  %end.i12 = getelementptr i8, ptr %1, i64 6
  store i8 0, ptr %end.i12, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i10)
  %t46 = icmp eq ptr %t31, null
  br i1 %t46, label %list_len_end_2, label %list_len_load_1

list_len_load_1:                                  ; preds = %entry
  %t47 = load i64, ptr %t31, align 4
  br label %list_len_end_2

list_len_end_2:                                   ; preds = %entry, %list_len_load_1
  %t49.0 = phi i64 [ %t47, %list_len_load_1 ], [ 0, %entry ]
  %t50 = tail call ptr @mire_i64_to_string(i64 %t49.0)
  %len_b.i14 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t50)
  %alloc_len.i16 = add i64 %len_b.i14, 10
  %new.i17 = tail call i64 @malloc(i64 %alloc_len.i16)
  %new_ptr.i18 = inttoptr i64 %new.i17 to ptr
  tail call void @memcpy(ptr %new_ptr.i18, ptr nonnull @.str9, i64 9)
  %dest.i19 = getelementptr i8, ptr %new_ptr.i18, i64 9
  tail call void @memcpy(ptr %dest.i19, ptr nonnull %t50, i64 %len_b.i14)
  %2 = getelementptr i8, ptr %new_ptr.i18, i64 %len_b.i14
  %end.i20 = getelementptr i8, ptr %2, i64 9
  store i8 0, ptr %end.i20, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i18)
  %t54 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i22 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t54)
  %alloc_len.i24 = add i64 %len_b.i22, 9
  %new.i25 = tail call i64 @malloc(i64 %alloc_len.i24)
  %new_ptr.i26 = inttoptr i64 %new.i25 to ptr
  tail call void @memcpy(ptr %new_ptr.i26, ptr nonnull @.str10, i64 8)
  %dest.i27 = getelementptr i8, ptr %new_ptr.i26, i64 8
  tail call void @memcpy(ptr %dest.i27, ptr nonnull %t54, i64 %len_b.i22)
  %3 = getelementptr i8, ptr %new_ptr.i26, i64 %len_b.i22
  %end.i28 = getelementptr i8, ptr %3, i64 8
  store i8 0, ptr %end.i28, align 1
  %puts3 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i26)
  %t58 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %len_b.i30 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t58)
  %alloc_len.i32 = add i64 %len_b.i30, 8
  %new.i33 = tail call i64 @malloc(i64 %alloc_len.i32)
  %new_ptr.i34 = inttoptr i64 %new.i33 to ptr
  tail call void @memcpy(ptr %new_ptr.i34, ptr nonnull @.str11, i64 7)
  %dest.i35 = getelementptr i8, ptr %new_ptr.i34, i64 7
  tail call void @memcpy(ptr %dest.i35, ptr nonnull %t58, i64 %len_b.i30)
  %4 = getelementptr i8, ptr %new_ptr.i34, i64 %len_b.i30
  %end.i36 = getelementptr i8, ptr %4, i64 7
  store i8 0, ptr %end.i36, align 1
  %puts4 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i34)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
