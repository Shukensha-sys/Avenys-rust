; ModuleID = 'build/release/map_keys_values.ll'
source_filename = "build/release/map_keys_values.ll"

@.str0 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str1 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str2 = private unnamed_addr constant [6 x i8] c"keys \00"
@.str3 = private unnamed_addr constant [8 x i8] c"values \00"
@.str4 = private unnamed_addr constant [9 x i8] c"wall_ms \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare ptr @memcpy(ptr noalias returned writeonly, ptr noalias readonly captures(none), i64) local_unnamed_addr #2

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_to_string(ptr) local_unnamed_addr

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
  %t8 = tail call ptr @mire_dict_set_i64(ptr null, i64 3, i64 1, i64 0, ptr nonnull @.str0, i64 100)
  %t11 = tail call ptr @mire_dict_set_i64(ptr %t8, i64 3, i64 1, i64 0, ptr nonnull @.str1, i64 200)
  %t14 = tail call ptr @mire_dict_keys(ptr %t11)
  %t17 = tail call ptr @mire_dict_values(ptr %t11)
  %t20 = tail call ptr @mire_dict_to_string(ptr %t14)
  %len_b.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t20)
  %alloc_len.i = add i64 %len_b.i, 6
  %new.i = tail call i64 @malloc(i64 %alloc_len.i)
  %new_ptr.i = inttoptr i64 %new.i to ptr
  tail call void @memcpy(ptr %new_ptr.i, ptr nonnull @.str2, i64 5)
  %dest.i = getelementptr i8, ptr %new_ptr.i, i64 5
  tail call void @memcpy(ptr %dest.i, ptr nonnull %t20, i64 %len_b.i)
  %0 = getelementptr i8, ptr %new_ptr.i, i64 %len_b.i
  %end.i = getelementptr i8, ptr %0, i64 5
  store i8 0, ptr %end.i, align 1
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i)
  %t24 = tail call ptr @mire_dict_to_string(ptr %t17)
  %len_b.i4 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t24)
  %alloc_len.i6 = add i64 %len_b.i4, 8
  %new.i7 = tail call i64 @malloc(i64 %alloc_len.i6)
  %new_ptr.i8 = inttoptr i64 %new.i7 to ptr
  tail call void @memcpy(ptr %new_ptr.i8, ptr nonnull @.str3, i64 7)
  %dest.i9 = getelementptr i8, ptr %new_ptr.i8, i64 7
  tail call void @memcpy(ptr %dest.i9, ptr nonnull %t24, i64 %len_b.i4)
  %1 = getelementptr i8, ptr %new_ptr.i8, i64 %len_b.i4
  %end.i10 = getelementptr i8, ptr %1, i64 7
  store i8 0, ptr %end.i10, align 1
  %puts1 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i8)
  %t28 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %len_b.i12 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t28)
  %alloc_len.i14 = add i64 %len_b.i12, 9
  %new.i15 = tail call i64 @malloc(i64 %alloc_len.i14)
  %new_ptr.i16 = inttoptr i64 %new.i15 to ptr
  tail call void @memcpy(ptr %new_ptr.i16, ptr nonnull @.str4, i64 8)
  %dest.i17 = getelementptr i8, ptr %new_ptr.i16, i64 8
  tail call void @memcpy(ptr %dest.i17, ptr nonnull %t28, i64 %len_b.i12)
  %2 = getelementptr i8, ptr %new_ptr.i16, i64 %len_b.i12
  %end.i18 = getelementptr i8, ptr %2, i64 8
  store i8 0, ptr %end.i18, align 1
  %puts2 = tail call i32 @puts(ptr nonnull dereferenceable(1) %new_ptr.i16)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #4

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(readwrite, target_mem0: none, target_mem1: none) }
attributes #4 = { nofree nounwind }
