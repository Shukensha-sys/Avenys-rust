; ModuleID = 'build/release/task_queue_sim.ll'
source_filename = "build/release/task_queue_sim.ll"

@.str0 = private unnamed_addr constant [1 x i8] zeroinitializer
@.str1 = private unnamed_addr constant [5 x i8] c"tAsk\00"
@.str2 = private unnamed_addr constant [7 x i8] c"total \00"
@.str3 = private unnamed_addr constant [7 x i8] c"items \00"
@.str4 = private unnamed_addr constant [12 x i8] c"digest_len \00"

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #0

declare ptr @mire_i64_to_string(i64) local_unnamed_addr

declare ptr @mire_string_copy(ptr) local_unnamed_addr

declare ptr @mire_string_concat(ptr, ptr) local_unnamed_addr

declare ptr @mire_string_append_owned(ptr, ptr) local_unnamed_addr

declare ptr @mire_list_push_i64(ptr, i64) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
entry:
  %t5 = tail call ptr @mire_string_copy(ptr nonnull @.str0)
  br label %while_body_1

while_body_1:                                     ; preds = %entry, %if_end_5
  %t0.013 = phi ptr [ null, %entry ], [ %t16, %if_end_5 ]
  %t6.012 = phi i64 [ 0, %entry ], [ %t27, %if_end_5 ]
  %t3.011 = phi ptr [ %t5, %entry ], [ %t3.1, %if_end_5 ]
  %t2.010 = phi i64 [ 0, %entry ], [ %t19, %if_end_5 ]
  %0 = trunc nuw nsw i64 %t6.012 to i32
  %1 = mul nuw nsw i32 %0, 7
  %t13.lhs.trunc = add nuw nsw i32 %1, 3
  %t138 = urem i32 %t13.lhs.trunc, 11
  %t13.zext = zext nneg i32 %t138 to i64
  %t16 = tail call ptr @mire_list_push_i64(ptr %t0.013, i64 %t13.zext)
  %t19 = add i64 %t2.010, %t13.zext
  %t21.lhs.trunc = trunc nuw nsw i32 %t138 to i8
  %t219 = urem i8 %t21.lhs.trunc, 3
  %t22 = icmp eq i8 %t219, 0
  br i1 %t22, label %if_then_3, label %if_end_5

if_then_3:                                        ; preds = %while_body_1
  %t25 = tail call ptr @mire_string_append_owned(ptr %t3.011, ptr nonnull @.str1)
  br label %if_end_5

if_end_5:                                         ; preds = %while_body_1, %if_then_3
  %t3.1 = phi ptr [ %t25, %if_then_3 ], [ %t3.011, %while_body_1 ]
  %t27 = add nuw nsw i64 %t6.012, 1
  %t8 = icmp samesign ult i64 %t6.012, 11999
  br i1 %t8, label %while_body_1, label %while_end_2

while_end_2:                                      ; preds = %if_end_5
  %t30 = tail call ptr @mire_i64_to_string(i64 %t19)
  %t31 = tail call ptr @mire_string_concat(ptr nonnull @.str2, ptr %t30)
  %puts = tail call i32 @puts(ptr nonnull dereferenceable(1) %t31)
  %t35 = getelementptr inbounds i8, ptr %t16, i64 -8
  %t37 = load i64, ptr %t35, align 4
  %t40 = tail call ptr @mire_i64_to_string(i64 %t37)
  %t41 = tail call ptr @mire_string_concat(ptr nonnull @.str3, ptr %t40)
  %puts6 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t41)
  %t44 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %t3.1)
  %t45 = tail call ptr @mire_i64_to_string(i64 %t44)
  %t46 = tail call ptr @mire_string_concat(ptr nonnull @.str4, ptr %t45)
  %puts7 = tail call i32 @puts(ptr nonnull dereferenceable(1) %t46)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr noundef readonly captures(none)) local_unnamed_addr #1

attributes #0 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) }
attributes #1 = { nofree nounwind }
