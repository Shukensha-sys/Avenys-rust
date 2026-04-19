; ModuleID = 'build/release/string_pipeline_stress.ll'
source_filename = "build/release/string_pipeline_stress.ll"

@.str0 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str1 = private unnamed_addr constant [15 x i8] c" pending_item \00"
@.str2 = private unnamed_addr constant [9 x i8] c"out_len \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_string_append_owned(ptr, ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_string_to_upper(ptr) local_unnamed_addr

declare ptr @mire_strings_trim(ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t3 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t0.03 = phi i64 [ 0, %entry ], [ %t19, %while_body_1 ]
  %t1.02 = phi ptr [ %t3, %entry ], [ %t17, %while_body_1 ]
  %t8 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  %t10 = tail call ptr @mire_string_to_upper(ptr %t8)
  tail call void @mire_string_free(ptr %t8)
  %t13 = tail call ptr @mire_strings_trim(ptr %t10)
  tail call void @mire_string_free(ptr %t10)
  %t17 = tail call ptr @mire_string_append_owned(ptr %t1.02, ptr %t13)
  %t19 = add nuw nsw i64 %t0.03, 1
  %t5 = icmp samesign ult i64 %t0.03, 7999
  br i1 %t5, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t22 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t17)
  %t23 = tail call ptr @mire_i64_to_string(i64 %t22)
  %t24 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t23)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t24)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
