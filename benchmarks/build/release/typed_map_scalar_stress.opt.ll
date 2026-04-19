; ModuleID = 'build/release/typed_map_scalar_stress.ll'
source_filename = "build/release/typed_map_scalar_stress.ll"

@.str0 = private unnamed_addr constant [7 x i8] c"score \00"
@.str1 = private unnamed_addr constant [7 x i8] c"flags \00"
@.str2 = private unnamed_addr constant [9 x i8] c"wall_ms \00"
@.str3 = private unnamed_addr constant [8 x i8] c"cpu_ms \00"
@.str4 = private unnamed_addr constant [16 x i8] c"cpu_cycles_est \00"
@.str5 = private unnamed_addr constant [13 x i8] c"process_ram \00"

declare i64 @mire_wall_mark_ns() local_unnamed_addr

declare ptr @mire_wall_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_mark_ns() local_unnamed_addr

declare ptr @mire_cpu_elapsed_ms_str(i64) local_unnamed_addr

declare i64 @mire_cpu_cycles_est(i64) local_unnamed_addr

declare i64 @mire_mem_process_bytes() local_unnamed_addr

declare ptr @mire_mem_format(i64) local_unnamed_addr

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare i64 @mire_dict_get_i64(ptr, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_set_i64(ptr, i64, i64, i64, ptr, i64) local_unnamed_addr

declare ptr @mire_dict_to_string(ptr) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t1 = tail call i64 @mire_wall_mark_ns()
  %t3 = tail call i64 @mire_cpu_mark_ns()
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %while_body_1
  %t6.020 = phi i64 [ 0, %entry ], [ %t34, %while_body_1 ]
  %t4.019 = phi ptr [ null, %entry ], [ %t31, %while_body_1 ]
  %t11 = and i64 %t6.020, 1
  %t14 = xor i64 %t11, 1
  %t13 = tail call ptr @mire_dict_set_i64(ptr %t4.019, i64 1, i64 2, i64 1, ptr null, i64 %t14)
  %t17.lhs.trunc = trunc nuw nsw i64 %t6.020 to i16
  %t1716 = urem i16 %t17.lhs.trunc, 3
  %t18 = icmp eq i16 %t1716, 0
  %t20 = zext i1 %t18 to i64
  %t19 = tail call ptr @mire_dict_set_i64(ptr %t13, i64 1, i64 2, i64 2, ptr null, i64 %t20)
  %t2317 = urem i16 %t17.lhs.trunc, 5
  %t24 = icmp eq i16 %t2317, 0
  %t26 = zext i1 %t24 to i64
  %t25 = tail call ptr @mire_dict_set_i64(ptr %t19, i64 1, i64 2, i64 3, ptr null, i64 %t26)
  %t2918 = urem i16 %t17.lhs.trunc, 7
  %t30 = icmp eq i16 %t2918, 0
  %t32 = zext i1 %t30 to i64
  %t31 = tail call ptr @mire_dict_set_i64(ptr %t25, i64 1, i64 2, i64 4, ptr null, i64 %t32)
  %t34 = add nuw nsw i64 %t6.020, 1
  %t8 = icmp samesign ult i64 %t6.020, 19999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %while_body_1
  %t38 = tail call i64 @mire_dict_get_i64(ptr %t31, i64 1, i64 1, ptr null, i64 0)
  %t39.not = icmp ne i64 %t38, 0
  %spec.select = zext i1 %t39.not to i64
  %t44 = tail call i64 @mire_dict_get_i64(ptr %t31, i64 1, i64 2, ptr null, i64 0)
  %t45.not = icmp eq i64 %t44, 0
  %t47 = or disjoint i64 %spec.select, 10
  %t35.1 = select i1 %t45.not, i64 %spec.select, i64 %t47
  %t50 = tail call i64 @mire_dict_get_i64(ptr %t31, i64 1, i64 3, ptr null, i64 0)
  %t51.not = icmp eq i64 %t50, 0
  %t53 = or disjoint i64 %t35.1, 100
  %t35.2 = select i1 %t51.not, i64 %t35.1, i64 %t53
  %t56 = tail call i64 @mire_dict_get_i64(ptr %t31, i64 1, i64 4, ptr null, i64 0)
  %t57.not = icmp eq i64 %t56, 0
  %t59 = add nuw nsw i64 %t35.2, 1000
  %t35.3 = select i1 %t57.not, i64 %t35.2, i64 %t59
  %t62 = tail call ptr @mire_i64_to_string(i64 %t35.3)
  %t63 = tail call ptr @mire_string_concat(ptr nonnull @.str0, ptr %t62)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t63)
  %t66 = tail call ptr @mire_dict_to_string(ptr %t31)
  %t67 = tail call ptr @mire_string_concat(ptr nonnull @.str1, ptr %t66)
  %puts11 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t67)
  %t70 = tail call ptr @mire_wall_elapsed_ms_str(i64 %t1)
  %t71 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t70)
  %puts12 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t71)
  %t74 = tail call ptr @mire_cpu_elapsed_ms_str(i64 %t3)
  %t75 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t74)
  %puts13 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t75)
  %t78 = tail call i64 @mire_cpu_cycles_est(i64 %t3)
  %t79 = tail call ptr @mire_i64_to_string(i64 %t78)
  %t80 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t79)
  %puts14 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t80)
  %t82 = tail call i64 @mire_mem_process_bytes()
  %t83 = tail call ptr @mire_mem_format(i64 %t82)
  %t84 = tail call ptr @mire_string_concat(ptr nonnull @.str5, ptr %t83)
  %puts15 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t84)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #0

attributes #0 = { nofree nounwind }
