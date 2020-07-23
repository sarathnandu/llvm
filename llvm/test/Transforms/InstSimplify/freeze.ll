; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instsimplify -S | FileCheck %s

define i32 @fold(i32 %x) {
; CHECK-LABEL: @fold(
; CHECK-NEXT:    [[Y:%.*]] = freeze i32 [[X:%.*]]
; CHECK-NEXT:    ret i32 [[Y]]
;
  %y = freeze i32 %x
  %z = freeze i32 %y
  ret i32 %z
}

define i32 @make_const() {
; CHECK-LABEL: @make_const(
; CHECK-NEXT:    ret i32 10
;
  %x = freeze i32 10
  ret i32 %x
}

define float @make_const2() {
; CHECK-LABEL: @make_const2(
; CHECK-NEXT:    ret float 1.000000e+01
;
  %x = freeze float 10.0
  ret float %x
}

@glb = constant i32 0

define i32* @make_const_glb() {
; CHECK-LABEL: @make_const_glb(
; CHECK-NEXT:    ret i32* @glb
;
  %k = freeze i32* @glb
  ret i32* %k
}

define i32()* @make_const_fn() {
; CHECK-LABEL: @make_const_fn(
; CHECK-NEXT:    ret i32 ()* @make_const
;
  %k = freeze i32()* @make_const
  ret i32()* %k
}

define i32* @make_const_null() {
; CHECK-LABEL: @make_const_null(
; CHECK-NEXT:    ret i32* null
;
  %k = freeze i32* null
  ret i32* %k
}

define <2 x i32> @constvector() {
; CHECK-LABEL: @constvector(
; CHECK-NEXT:    ret <2 x i32> <i32 0, i32 1>
;
  %x = freeze <2 x i32> <i32 0, i32 1>
  ret <2 x i32> %x
}

define <3 x i5> @constvector_weird() {
; CHECK-LABEL: @constvector_weird(
; CHECK-NEXT:    ret <3 x i5> <i5 0, i5 1, i5 10>
;
  %x = freeze <3 x i5> <i5 0, i5 1, i5 42>
  ret <3 x i5> %x
}

define <2 x float> @constvector_FP() {
; CHECK-LABEL: @constvector_FP(
; CHECK-NEXT:    ret <2 x float> <float 0.000000e+00, float 1.000000e+00>
;
  %x = freeze <2 x float> <float 0.0, float 1.0>
  ret <2 x float> %x
}

; Negative test

define <2 x i32> @constvector_noopt() {
; CHECK-LABEL: @constvector_noopt(
; CHECK-NEXT:    [[X:%.*]] = freeze <2 x i32> <i32 0, i32 undef>
; CHECK-NEXT:    ret <2 x i32> [[X]]
;
  %x = freeze <2 x i32> <i32 0, i32 undef>
  ret <2 x i32> %x
}

; Negative test

define <3 x i5> @constvector_weird_noopt() {
; CHECK-LABEL: @constvector_weird_noopt(
; CHECK-NEXT:    [[X:%.*]] = freeze <3 x i5> <i5 0, i5 undef, i5 10>
; CHECK-NEXT:    ret <3 x i5> [[X]]
;
  %x = freeze <3 x i5> <i5 0, i5 undef, i5 42>
  ret <3 x i5> %x
}

; Negative test

define <2 x float> @constvector_FP_noopt() {
; CHECK-LABEL: @constvector_FP_noopt(
; CHECK-NEXT:    [[X:%.*]] = freeze <2 x float> <float 0.000000e+00, float undef>
; CHECK-NEXT:    ret <2 x float> [[X]]
;
  %x = freeze <2 x float> <float 0.0, float undef>
  ret <2 x float> %x
}

@g = external global i16, align 1

; Negative test

define float @constant_expr() {
; CHECK-LABEL: @constant_expr(
; CHECK-NEXT:    ret float bitcast (i32 ptrtoint (i16* @g to i32) to float)
;
  %r = freeze float bitcast (i32 ptrtoint (i16* @g to i32) to float)
  ret float %r
}

define i8* @constant_expr2() {
; CHECK-LABEL: @constant_expr2(
; CHECK-NEXT:    ret i8* bitcast (i16* @g to i8*)
;
  %r = freeze i8* bitcast (i16* @g to i8*)
  ret i8* %r
}

define i32* @constant_expr3() {
; CHECK-LABEL: @constant_expr3(
; CHECK-NEXT:    ret i32* getelementptr (i32, i32* @glb, i64 3)
;
  %r = freeze i32* getelementptr (i32, i32* @glb, i64 3)
  ret i32* %r
}

; Negative test

define <2 x i31> @vector_element_constant_expr() {
; CHECK-LABEL: @vector_element_constant_expr(
; CHECK-NEXT:    [[R:%.*]] = freeze <2 x i31> <i31 34, i31 ptrtoint (i16* @g to i31)>
; CHECK-NEXT:    ret <2 x i31> [[R]]
;
  %r = freeze <2 x i31> <i31 34, i31 ptrtoint (i16* @g to i31)>
  ret <2 x i31> %r
}

define void @alloca() {
; CHECK-LABEL: @alloca(
; CHECK-NEXT:    [[P:%.*]] = alloca i8, align 1
; CHECK-NEXT:    call void @f3(i8* [[P]])
; CHECK-NEXT:    ret void
;
  %p = alloca i8
  %y = freeze i8* %p
  call void @f3(i8* %y)
  ret void
}

define i8* @gep() {
; CHECK-LABEL: @gep(
; CHECK-NEXT:    [[P:%.*]] = alloca [4 x i8], align 1
; CHECK-NEXT:    [[Q:%.*]] = getelementptr [4 x i8], [4 x i8]* [[P]], i32 0, i32 6
; CHECK-NEXT:    ret i8* [[Q]]
;
  %p = alloca [4 x i8]
  %q = getelementptr [4 x i8], [4 x i8]* %p, i32 0, i32 6
  %q2 = freeze i8* %q
  ret i8* %q2
}

define i8* @gep_noopt(i32 %arg) {
; CHECK-LABEL: @gep_noopt(
; CHECK-NEXT:    [[Q:%.*]] = getelementptr [4 x i8], [4 x i8]* null, i32 0, i32 [[ARG:%.*]]
; CHECK-NEXT:    [[Q2:%.*]] = freeze i8* [[Q]]
; CHECK-NEXT:    ret i8* [[Q2]]
;
  %q = getelementptr [4 x i8], [4 x i8]* null, i32 0, i32 %arg
  %q2 = freeze i8* %q
  ret i8* %q2
}

define i8* @gep_inbounds() {
; CHECK-LABEL: @gep_inbounds(
; CHECK-NEXT:    [[P:%.*]] = alloca [4 x i8], align 1
; CHECK-NEXT:    [[Q:%.*]] = getelementptr inbounds [4 x i8], [4 x i8]* [[P]], i32 0, i32 0
; CHECK-NEXT:    ret i8* [[Q]]
;
  %p = alloca [4 x i8]
  %q = getelementptr inbounds [4 x i8], [4 x i8]* %p, i32 0, i32 0
  %q2 = freeze i8* %q
  ret i8* %q2
}

define i8* @gep_inbounds_noopt(i32 %arg) {
; CHECK-LABEL: @gep_inbounds_noopt(
; CHECK-NEXT:    [[P:%.*]] = alloca [4 x i8], align 1
; CHECK-NEXT:    [[Q:%.*]] = getelementptr inbounds [4 x i8], [4 x i8]* [[P]], i32 0, i32 [[ARG:%.*]]
; CHECK-NEXT:    [[Q2:%.*]] = freeze i8* [[Q]]
; CHECK-NEXT:    ret i8* [[Q2]]
;
  %p = alloca [4 x i8]
  %q = getelementptr inbounds [4 x i8], [4 x i8]* %p, i32 0, i32 %arg
  %q2 = freeze i8* %q
  ret i8* %q2
}

define i32* @gep_inbounds_null() {
; CHECK-LABEL: @gep_inbounds_null(
; CHECK-NEXT:    ret i32* null
;
  %p = getelementptr inbounds i32, i32* null, i32 0
  %k = freeze i32* %p
  ret i32* %k
}

define i32* @gep_inbounds_null_noopt(i32* %p) {
; CHECK-LABEL: @gep_inbounds_null_noopt(
; CHECK-NEXT:    [[K:%.*]] = freeze i32* [[P:%.*]]
; CHECK-NEXT:    ret i32* [[K]]
;
  %q = getelementptr inbounds i32, i32* %p, i32 0
  %k = freeze i32* %q
  ret i32* %k
}

define i1 @icmp(i32 %a, i32 %b) {
; CHECK-LABEL: @icmp(
; CHECK-NEXT:    [[A_FR:%.*]] = freeze i32 [[A:%.*]]
; CHECK-NEXT:    [[B_FR:%.*]] = freeze i32 [[B:%.*]]
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[A_FR]], [[B_FR]]
; CHECK-NEXT:    ret i1 [[C]]
;
  %a.fr = freeze i32 %a
  %b.fr = freeze i32 %b
  %c = icmp eq i32 %a.fr, %b.fr
  %c.fr = freeze i1 %c
  ret i1 %c.fr
}

define i1 @icmp_noopt(i32 %a, i32 %b) {
; CHECK-LABEL: @icmp_noopt(
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[C_FR:%.*]] = freeze i1 [[C]]
; CHECK-NEXT:    ret i1 [[C_FR]]
;
  %c = icmp eq i32 %a, %b
  %c.fr = freeze i1 %c
  ret i1 %c.fr
}

define i1 @fcmp(float %x, float %y) {
; CHECK-LABEL: @fcmp(
; CHECK-NEXT:    [[FX:%.*]] = freeze float [[X:%.*]]
; CHECK-NEXT:    [[FY:%.*]] = freeze float [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = fcmp oeq float [[FX]], [[FY]]
; CHECK-NEXT:    ret i1 [[C]]
;
  %fx = freeze float %x
  %fy = freeze float %y
  %c = fcmp oeq float %fx, %fy
  %fc = freeze i1 %c
  ret i1 %fc
}

define i1 @fcmp_noopt(float %x, float %y) {
; CHECK-LABEL: @fcmp_noopt(
; CHECK-NEXT:    [[FX:%.*]] = freeze float [[X:%.*]]
; CHECK-NEXT:    [[FY:%.*]] = freeze float [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = fcmp nnan oeq float [[FX]], [[FY]]
; CHECK-NEXT:    [[FC:%.*]] = freeze i1 [[C]]
; CHECK-NEXT:    ret i1 [[FC]]
;
  %fx = freeze float %x
  %fy = freeze float %y
  %c = fcmp nnan oeq float %fx, %fy
  %fc = freeze i1 %c
  ret i1 %fc
}

define i1 @brcond(i1 %c, i1 %c2) {
; CHECK-LABEL: @brcond(
; CHECK-NEXT:    br i1 [[C:%.*]], label [[A:%.*]], label [[B:%.*]]
; CHECK:       A:
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[A2:%.*]], label [[B]]
; CHECK:       A2:
; CHECK-NEXT:    ret i1 [[C]]
; CHECK:       B:
; CHECK-NEXT:    ret i1 [[C]]
;
  br i1 %c, label %A, label %B
A:
  br i1 %c2, label %A2, label %B
A2:
  %f1 = freeze i1 %c
  ret i1 %f1
B:
  %f2 = freeze i1 %c
  ret i1 %f2
}

define i32 @phi(i1 %cond, i1 %cond2, i32 %a0, i32 %a1) {
; CHECK-LABEL: @phi(
; CHECK-NEXT:  ENTRY:
; CHECK-NEXT:    [[A0_FR:%.*]] = freeze i32 [[A0:%.*]]
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       BB1:
; CHECK-NEXT:    [[A1_FR:%.*]] = freeze i32 [[A1:%.*]]
; CHECK-NEXT:    br i1 [[COND2:%.*]], label [[BB2]], label [[EXIT:%.*]]
; CHECK:       BB2:
; CHECK-NEXT:    [[PHI1:%.*]] = phi i32 [ [[A0_FR]], [[ENTRY:%.*]] ], [ [[A1_FR]], [[BB1]] ]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       EXIT:
; CHECK-NEXT:    [[PHI2:%.*]] = phi i32 [ [[A0_FR]], [[BB1]] ], [ [[PHI1]], [[BB2]] ]
; CHECK-NEXT:    ret i32 [[PHI2]]
;
ENTRY:
  %a0.fr = freeze i32 %a0
  br i1 %cond, label %BB1, label %BB2
BB1:
  %a1.fr = freeze i32 %a1
  br i1 %cond2, label %BB2, label %EXIT
BB2:
  %phi1 = phi i32 [%a0.fr, %ENTRY], [%a1.fr, %BB1]
  br label %EXIT
EXIT:
  %phi2 = phi i32 [%a0.fr, %BB1], [%phi1, %BB2]
  %phi2.fr = freeze i32 %phi2
  ret i32 %phi2.fr
}

define i32 @phi_noopt(i1 %cond, i1 %cond2, i32 %a0, i32 %a1) {
; CHECK-LABEL: @phi_noopt(
; CHECK-NEXT:  ENTRY:
; CHECK-NEXT:    [[A0_FR:%.*]] = freeze i32 [[A0:%.*]]
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       BB1:
; CHECK-NEXT:    br i1 [[COND2:%.*]], label [[BB2]], label [[EXIT:%.*]]
; CHECK:       BB2:
; CHECK-NEXT:    [[PHI1:%.*]] = phi i32 [ [[A0_FR]], [[ENTRY:%.*]] ], [ [[A1:%.*]], [[BB1]] ]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       EXIT:
; CHECK-NEXT:    [[PHI2:%.*]] = phi i32 [ [[A0_FR]], [[BB1]] ], [ [[PHI1]], [[BB2]] ]
; CHECK-NEXT:    [[PHI2_FR:%.*]] = freeze i32 [[PHI2]]
; CHECK-NEXT:    ret i32 [[PHI2_FR]]
;
ENTRY:
  %a0.fr = freeze i32 %a0
  br i1 %cond, label %BB1, label %BB2
BB1:
  br i1 %cond2, label %BB2, label %EXIT
BB2:
  %phi1 = phi i32 [%a0.fr, %ENTRY], [%a1, %BB1]
  br label %EXIT
EXIT:
  %phi2 = phi i32 [%a0.fr, %BB1], [%phi1, %BB2]
  %phi2.fr = freeze i32 %phi2
  ret i32 %phi2.fr
}

define i32 @brcond_switch(i32 %x) {
; CHECK-LABEL: @brcond_switch(
; CHECK-NEXT:    switch i32 [[X:%.*]], label [[EXIT:%.*]] [
; CHECK-NEXT:    i32 0, label [[A:%.*]]
; CHECK-NEXT:    ]
; CHECK:       A:
; CHECK-NEXT:    ret i32 [[X]]
; CHECK:       EXIT:
; CHECK-NEXT:    ret i32 [[X]]
;
  switch i32 %x, label %EXIT [ i32 0, label %A ]
A:
  %fr1 = freeze i32 %x
  ret i32 %fr1
EXIT:
  %fr2 = freeze i32 %x
  ret i32 %fr2
}

declare i32 @any_num()

define i32 @brcond_call() {
; CHECK-LABEL: @brcond_call(
; CHECK-NEXT:    [[X:%.*]] = call i32 @any_num()
; CHECK-NEXT:    switch i32 [[X]], label [[EXIT:%.*]] [
; CHECK-NEXT:    ]
; CHECK:       EXIT:
; CHECK-NEXT:    ret i32 [[X]]
;
  %x = call i32 @any_num()
  switch i32 %x, label %EXIT []
EXIT:
  %y = freeze i32 %x
  ret i32 %y
}

define i1 @brcond_noopt(i1 %c, i1 %c2) {
; CHECK-LABEL: @brcond_noopt(
; CHECK-NEXT:    [[F:%.*]] = freeze i1 [[C:%.*]]
; CHECK-NEXT:    call void @f1(i1 [[F]])
; CHECK-NEXT:    call void @f2()
; CHECK-NEXT:    br i1 [[C]], label [[A:%.*]], label [[B:%.*]]
; CHECK:       A:
; CHECK-NEXT:    ret i1 false
; CHECK:       B:
; CHECK-NEXT:    ret i1 true
;
  %f = freeze i1 %c
  call void @f1(i1 %f) ; cannot optimize i1 %f to %c
  call void @f2()      ; .. because if f2() exits, `br %c` cannot be reached
  br i1 %c, label %A, label %B
A:
  ret i1 0
B:
  ret i1 1
}
declare void @f1(i1)
declare void @f2()
declare void @f3(i8*)
