; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -gvn -S | FileCheck %s

define void @loadpre_opportunity(i32** %arg, i1 %arg1, i1 %arg2, i1 %arg3) {
; CHECK-LABEL: @loadpre_opportunity(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    br label [[BB9:%.*]]
; CHECK:       bb6:
; CHECK-NEXT:    br label [[BB9]]
; CHECK:       bb9:
; CHECK-NEXT:    br i1 [[ARG1:%.*]], label [[BB6:%.*]], label [[BB10:%.*]]
; CHECK:       bb10:
; CHECK-NEXT:    call void @somecall()
; CHECK-NEXT:    br i1 [[ARG2:%.*]], label [[BB12:%.*]], label [[BB15:%.*]]
; CHECK:       bb12:
; CHECK-NEXT:    br label [[BB13:%.*]]
; CHECK:       bb13:
; CHECK-NEXT:    br i1 [[ARG3:%.*]], label [[BB14:%.*]], label [[BB13]]
; CHECK:       bb14:
; CHECK-NEXT:    br label [[BB15]]
; CHECK:       bb15:
; CHECK-NEXT:    br label [[BB6]]
;
bb:
  %i = load i32*, i32** %arg, align 8
  %i4 = getelementptr inbounds i32, i32* %i, i64 0
  br label %bb5

bb5:
  br label %bb9

bb6:
  %i7 = load i32*, i32** %arg, align 8
  %i8 = getelementptr inbounds i32, i32* %i7, i64 0
  br label %bb9

bb9:
  br i1 %arg1, label %bb6, label %bb10

bb10:
  call void @somecall()
  br i1 %arg2, label %bb12, label %bb15

bb12:
  br label %bb13

bb13:
  br i1 %arg3, label %bb14, label %bb13

bb14:
  br label %bb15

bb15:
  br label %bb6
}

declare void @somecall()
