; ModuleID = 'build/release/analytics_pass.ll'
source_filename = "build/release/analytics_pass.ll"

@.str0 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str2 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str3 = private unnamed_addr constant [6 x i8] c"gamma\00"
@.str4 = private unnamed_addr constant [5 x i8] c"beta\00"
@.str5 = private unnamed_addr constant [2 x i8] c"a\00"
@.str6 = private unnamed_addr constant [2 x i8] c"A\00"
@.str7 = private unnamed_addr constant [8 x i8] c"counts \00"
@.str8 = private unnamed_addr constant [6 x i8] c"sums \00"
@.str9 = private unnamed_addr constant [12 x i8] c"report_len \00"
@.str10 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str11 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str12 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str13 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str14 = private unnamed_addr constant [5 x i8] c"gpu \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i32 @strcmp(ptr captures(none), ptr captures(none)) local_unnamed_addr #0

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_gpu_snapshot() local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_string_append_owned(ptr, ptr) local_unnamed_addr

declare void @mire_string_free(ptr) local_unnamed_addr

declare ptr @mire_strings_replace(ptr, ptr, ptr) local_unnamed_addr

declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_to_string(ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t10 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %if_end_11
  %t4.020 = phi ptr [ null, %entry ], [ %t44, %if_end_11 ]
  %t6.019 = phi ptr [ null, %entry ], [ %t56, %if_end_11 ]
  %t8.018 = phi ptr [ %t10, %entry ], [ %t8.1, %if_end_11 ]
  %t11.017 = phi i64 [ 0, %entry ], [ %t67, %if_end_11 ]
  %t16 = tail call ptr @mire_string_copy(ptr nonnull @.str3)
  %t18.lhs.trunc = trunc nuw nsw i64 %t11.017 to i16
  %t1814 = urem i16 %t18.lhs.trunc, 7
  %t19 = icmp eq i16 %t1814, 0
  br i1 %t19, label %if_then_3, label %if_end_5

if_then_3:                                        ; preds = %while_body_1
  tail call void @mire_string_free(ptr %t16)
  %t22 = tail call ptr @mire_string_copy(ptr nonnull @.str2)
  br label %if_end_5

if_end_5:                                         ; preds = %while_body_1, %if_then_3
  %t14.0 = phi ptr [ %t22, %if_then_3 ], [ %t16, %while_body_1 ]
  %t26 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %t14.0, ptr noundef nonnull dereferenceable(6) @.str3)
  %t25 = icmp eq i32 %t26, 0
  %t2815 = urem i16 %t18.lhs.trunc, 5
  %t29 = icmp eq i16 %t2815, 0
  %t30 = and i1 %t29, %t25
  br i1 %t30, label %if_then_6, label %if_end_8

if_then_6:                                        ; preds = %if_end_5
  tail call void @mire_string_free(ptr nonnull %t14.0)
  %t33 = tail call ptr @mire_string_copy(ptr nonnull @.str4)
  br label %if_end_8

if_end_8:                                         ; preds = %if_end_5, %if_then_6
  %t14.1 = phi ptr [ %t33, %if_then_6 ], [ %t14.0, %if_end_5 ]
  %t37 = tail call i64 @mire_dict_get_i64(ptr %t4.020, i64 3, i64 0, ptr %t14.1, i64 0)
  %t40 = add i64 %t37, 1
  %t44 = tail call ptr @mire_dict_set_i64(ptr %t4.020, i64 3, i64 1, i64 0, ptr %t14.1, i64 %t40)
  %t48 = tail call i64 @mire_dict_get_i64(ptr %t6.019, i64 3, i64 0, ptr %t14.1, i64 0)
  %t52 = add i64 %t48, %t11.017
  %t56 = tail call ptr @mire_dict_set_i64(ptr %t6.019, i64 3, i64 1, i64 0, ptr %t14.1, i64 %t52)
  %t5816 = urem i16 %t18.lhs.trunc, 1000
  %t59 = icmp eq i16 %t5816, 0
  br i1 %t59, label %if_then_9, label %if_end_11

if_then_9:                                        ; preds = %if_end_8
  %t63 = tail call ptr @mire_strings_replace(ptr %t14.1, ptr nonnull @.str5, ptr nonnull @.str6)
  %t65 = tail call ptr @mire_string_append_owned(ptr %t8.018, ptr %t63)
  br label %if_end_11

if_end_11:                                        ; preds = %if_end_8, %if_then_9
  %t8.1 = phi ptr [ %t65, %if_then_9 ], [ %t8.018, %if_end_8 ]
  %t67 = add nuw nsw i64 %t11.017, 1
  %t13 = icmp samesign ult i64 %t11.017, 19999
  br i1 %t13, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %if_end_11
  %t70 = tail call ptr @mire_dict_to_string(ptr %t44)
  %t71 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t70)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t71)
  %t74 = tail call ptr @mire_dict_to_string(ptr %t56)
  %t75 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t74)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t75)
  %t78 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t8.1)
  %t79 = tail call ptr @mire_i64_to_string(i64 %t78)
  %t80 = tail call ptr @mire_string_concat(ptr nonnull @.str9, ptr %t79)
  %puts8 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t80)
  %t83 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t84 = tail call ptr @mire_string_concat(ptr nonnull @.str10, ptr %t83)
  %puts9 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t84)
  %t87 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t88 = tail call ptr @mire_string_concat(ptr nonnull @.str11, ptr %t87)
  %puts10 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t88)
  %t91 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t92 = tail call ptr @mire_i64_to_string(i64 %t91)
  %t93 = tail call ptr @mire_string_concat(ptr nonnull @.str12, ptr %t92)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t93)
  %t95 = tail call i64 @mire_mem_process_bytes()
  %t96 = tail call ptr @mire_mem_format(i64 %t95)
  %t97 = tail call ptr @mire_string_concat(ptr nonnull @.str13, ptr %t96)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t97)
  %t99 = tail call ptr @mire_gpu_snapshot()
  %t100 = tail call ptr @mire_string_concat(ptr nonnull @.str14, ptr %t99)
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t100)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
