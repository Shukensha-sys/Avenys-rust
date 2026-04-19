; ModuleID = 'build/release/branchy_workload.ll'
source_filename = "build/release/branchy_workload.ll"

@.str0 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str1 = private unnamed_addr constant [5 x i8] c"n0de\00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [11 x i8] c"sum_check \00"
@.str4 = private unnamed_addr constant [7 x i8] c"items \00"
@.str5 = private unnamed_addr constant [11 x i8] c"trace_len \00"
@.str6 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str7 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str8 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str9 = private unnamed_addr constant [13 x i8] c"process_ram \00"
@.str10 = private unnamed_addr constant [5 x i8] c"gpu \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

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

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  %t8 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  br label %while_cond_3.preheader

while_cond_3.preheader:                           ; preds = %entry, %if_end_17
  %t4.033 = phi ptr [ null, %entry ], [ %t47, %if_end_17 ]
  %t6.032 = phi ptr [ %t8, %entry ], [ %t6.1, %if_end_17 ]
  %t9.031 = phi i64 [ 0, %entry ], [ %t61, %if_end_17 ]
  %t10.030 = phi i64 [ 0, %entry ], [ %t50, %if_end_17 ]
  %t19 = mul nuw nsw i64 %t9.031, 3
  br label %while_body_4

while_body_4:                                     ; preds = %while_cond_3.preheader, %while_body_4
  %t14.029 = phi i64 [ 0, %while_cond_3.preheader ], [ %t14.3, %while_body_4 ]
  %t13.028 = phi i64 [ 0, %while_cond_3.preheader ], [ %t44, %while_body_4 ]
  %t21 = mul nuw nsw i64 %t13.028, 7
  %t22 = add nuw nsw i64 %t21, %t19
  %t23.lhs.trunc = trunc i64 %t22 to i16
  %t2337 = urem i16 %t23.lhs.trunc, 11
  %t23.zext = zext nneg i16 %t2337 to i64
  %t25 = and i64 %t23.zext, 1
  %t26 = icmp eq i64 %t25, 0
  %t30 = add nuw nsw i64 %t9.031, %t23.zext
  %t31 = select i1 %t26, i64 %t30, i64 0
  %t14.1 = add i64 %t31, %t14.029
  %t33.lhs.trunc = trunc nuw nsw i16 %t2337 to i8
  %0 = insertelement <2 x i8> poison, i8 %t33.lhs.trunc, i64 0
  %1 = shufflevector <2 x i8> %0, <2 x i8> poison, <2 x i32> zeroinitializer
  %2 = urem <2 x i8> %1, <i8 5, i8 3>
  %3 = icmp eq <2 x i8> %2, zeroinitializer
  %4 = extractelement <2 x i1> %3, i64 1
  %t37 = select i1 %4, i64 %t13.028, i64 0
  %t14.2 = add i64 %t14.1, %t37
  %5 = extractelement <2 x i1> %3, i64 0
  %t42 = sext i1 %5 to i64
  %t14.3 = add i64 %t14.2, %t42
  %t44 = add nuw nsw i64 %t13.028, 1
  %t16 = icmp samesign ult i64 %t13.028, 31
  br i1 %t16, label %while_body_4, label %while_end_5

while_end_5:                                      ; preds = %while_body_4
  %t47 = tail call ptr @mire_list_push_i64(ptr %t4.033, i64 %t14.3)
  %t50 = add i64 %t14.3, %t10.030
  %t52 = urem i64 %t9.031, 250
  %t53 = icmp eq i64 %t52, 0
  br i1 %t53, label %if_then_15, label %if_end_17

if_then_15:                                       ; preds = %while_end_5
  %t56 = tail call ptr @mire_string_copy(ptr nonnull @.str1)
  %t59 = tail call ptr @mire_string_append_owned(ptr %t6.032, ptr %t56)
  br label %if_end_17

if_end_17:                                        ; preds = %while_end_5, %if_then_15
  %t6.1 = phi ptr [ %t59, %if_then_15 ], [ %t6.032, %while_end_5 ]
  %t61 = add nuw nsw i64 %t9.031, 1
  %t12 = icmp samesign ult i64 %t9.031, 2999
  br i1 %t12, label %while_cond_3.preheader, label %while_end_2

while_end_2:                                      ; preds = %if_end_17
  %t66 = icmp eq ptr %t47, null
  br i1 %t66, label %math_sum_end_21, label %math_sum_cond_19.preheader

math_sum_cond_19.preheader:                       ; preds = %while_end_2
  %t67 = load i64, ptr %t47, align 4
  %t6934 = icmp sgt i64 %t67, 0
  br i1 %t6934, label %math_sum_body_20.lr.ph, label %math_sum_end_21

math_sum_body_20.lr.ph:                           ; preds = %math_sum_cond_19.preheader
  %t70 = getelementptr i8, ptr %t47, i64 8
  br label %math_sum_body_20

math_sum_body_20:                                 ; preds = %math_sum_body_20.lr.ph, %math_sum_body_20
  %t65.036 = phi i64 [ 0, %math_sum_body_20.lr.ph ], [ %t76, %math_sum_body_20 ]
  %t64.035 = phi i64 [ 0, %math_sum_body_20.lr.ph ], [ %t75, %math_sum_body_20 ]
  %t71 = shl i64 %t65.036, 3
  %t72 = getelementptr i8, ptr %t70, i64 %t71
  %t73 = load i64, ptr %t72, align 4
  %t75 = add i64 %t73, %t64.035
  %t76 = add nuw nsw i64 %t65.036, 1
  %t69 = icmp slt i64 %t76, %t67
  br i1 %t69, label %math_sum_body_20, label %math_sum_end_21

math_sum_end_21:                                  ; preds = %math_sum_body_20, %math_sum_cond_19.preheader, %while_end_2
  %t64.1 = phi i64 [ 0, %while_end_2 ], [ 0, %math_sum_cond_19.preheader ], [ %t75, %math_sum_body_20 ]
  %t80 = tail call ptr @mire_i64_to_string(i64 %t50)
  %t81 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t80)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t81)
  %t84 = tail call ptr @mire_i64_to_string(i64 %t64.1)
  %t85 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t84)
  %puts18 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t85)
  %t89 = getelementptr inbounds i8, ptr %t47, i64 -8
  %t91 = load i64, ptr %t89, align 4
  %t94 = tail call ptr @mire_i64_to_string(i64 %t91)
  %t95 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t94)
  %puts19 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t95)
  %t98 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t6.1)
  %t99 = tail call ptr @mire_i64_to_string(i64 %t98)
  %t100 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t99)
  %puts20 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t100)
  %t103 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t104 = tail call ptr @mire_string_concat(ptr nonnull @.str6, ptr %t103)
  %puts21 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t104)
  %t107 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t108 = tail call ptr @mire_string_concat(ptr nonnull @.str7, ptr %t107)
  %puts22 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t108)
  %t111 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t112 = tail call ptr @mire_i64_to_string(i64 %t111)
  %t113 = tail call ptr @mire_string_concat(ptr nonnull @.str8, ptr %t112)
  %puts23 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t113)
  %t115 = tail call i64 @mire_mem_process_bytes()
  %t116 = tail call ptr @mire_mem_format(i64 %t115)
  %t117 = tail call ptr @mire_string_concat(ptr nonnull @.str9, ptr %t116)
  %puts24 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t117)
  %t119 = tail call ptr @mire_gpu_snapshot()
  %t120 = tail call ptr @mire_string_concat(ptr nonnull @.str10, ptr %t119)
  %puts25 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t120)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
