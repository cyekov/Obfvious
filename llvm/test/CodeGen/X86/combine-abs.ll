; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse2 | FileCheck %s --check-prefixes=CHECK,SSE,SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse4.2 | FileCheck %s --check-prefixes=CHECK,SSE,SSE42
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx2 | FileCheck %s --check-prefixes=CHECK,AVX,AVX2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512f | FileCheck %s --check-prefixes=CHECK,AVX,AVX512,AVX512F
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512f,+avx512vl | FileCheck %s --check-prefixes=CHECK,AVX,AVX512,AVX512VL

; fold (abs c1) -> c2
define <4 x i32> @combine_v4i32_abs_constant() {
; SSE-LABEL: combine_v4i32_abs_constant:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps {{.*#+}} xmm0 = [0,1,3,2147483648]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_v4i32_abs_constant:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps {{.*#+}} xmm0 = [0,1,3,2147483648]
; AVX-NEXT:    retq
  %1 = call <4 x i32> @llvm.abs.v4i32(<4 x i32> <i32 0, i32 -1, i32 3, i32 -2147483648>, i1 false)
  ret <4 x i32> %1
}

define <16 x i16> @combine_v16i16_abs_constant() {
; SSE-LABEL: combine_v16i16_abs_constant:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps {{.*#+}} xmm0 = [0,1,1,3,3,7,7,255]
; SSE-NEXT:    movaps {{.*#+}} xmm1 = [255,4096,4096,32767,32767,32768,32768,0]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_v16i16_abs_constant:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps {{.*#+}} ymm0 = [0,1,1,3,3,7,7,255,255,4096,4096,32767,32767,32768,32768,0]
; AVX-NEXT:    retq
  %1 = call <16 x i16> @llvm.abs.v16i16(<16 x i16> <i16 0, i16 1, i16 -1, i16 3, i16 -3, i16 7, i16 -7, i16 255, i16 -255, i16 4096, i16 -4096, i16 32767, i16 -32767, i16 -32768, i16 32768, i16 65536>, i1 false)
  ret <16 x i16> %1
}

; fold (abs (abs x)) -> (abs x)
define i32 @combine_i32_abs_abs(i32 %a) {
; CHECK-LABEL: combine_i32_abs_abs:
; CHECK:       # %bb.0:
; CHECK-NEXT:    movl %edi, %eax
; CHECK-NEXT:    negl %eax
; CHECK-NEXT:    cmovll %edi, %eax
; CHECK-NEXT:    retq
  %n1 = sub i32 zeroinitializer, %a
  %b1 = icmp slt i32 %a, zeroinitializer
  %a1 = select i1 %b1, i32 %n1, i32 %a
  %n2 = sub i32 zeroinitializer, %a1
  %b2 = icmp sgt i32 %a1, zeroinitializer
  %a2 = select i1 %b2, i32 %a1, i32 %n2
  ret i32 %a2
}

define <8 x i16> @combine_v8i16_abs_abs(<8 x i16> %a) {
; SSE2-LABEL: combine_v8i16_abs_abs:
; SSE2:       # %bb.0:
; SSE2-NEXT:    movdqa %xmm0, %xmm1
; SSE2-NEXT:    psraw $15, %xmm1
; SSE2-NEXT:    paddw %xmm1, %xmm0
; SSE2-NEXT:    pxor %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE42-LABEL: combine_v8i16_abs_abs:
; SSE42:       # %bb.0:
; SSE42-NEXT:    pabsw %xmm0, %xmm0
; SSE42-NEXT:    retq
;
; AVX-LABEL: combine_v8i16_abs_abs:
; AVX:       # %bb.0:
; AVX-NEXT:    vpabsw %xmm0, %xmm0
; AVX-NEXT:    retq
  %a1 = call <8 x i16> @llvm.abs.v8i16(<8 x i16> %a, i1 false)
  %s2 = ashr <8 x i16> %a1, <i16 15, i16 15, i16 15, i16 15, i16 15, i16 15, i16 15, i16 15>
  %a2 = add <8 x i16> %a1, %s2
  %x2 = xor <8 x i16> %a2, %s2
  ret <8 x i16> %x2
}

define <32 x i8> @combine_v32i8_abs_abs(<32 x i8> %a) {
; SSE2-LABEL: combine_v32i8_abs_abs:
; SSE2:       # %bb.0:
; SSE2-NEXT:    pxor %xmm2, %xmm2
; SSE2-NEXT:    pxor %xmm3, %xmm3
; SSE2-NEXT:    pcmpgtb %xmm0, %xmm3
; SSE2-NEXT:    paddb %xmm3, %xmm0
; SSE2-NEXT:    pxor %xmm3, %xmm0
; SSE2-NEXT:    pcmpgtb %xmm1, %xmm2
; SSE2-NEXT:    paddb %xmm2, %xmm1
; SSE2-NEXT:    pxor %xmm2, %xmm1
; SSE2-NEXT:    retq
;
; SSE42-LABEL: combine_v32i8_abs_abs:
; SSE42:       # %bb.0:
; SSE42-NEXT:    pabsb %xmm0, %xmm0
; SSE42-NEXT:    pabsb %xmm1, %xmm1
; SSE42-NEXT:    retq
;
; AVX-LABEL: combine_v32i8_abs_abs:
; AVX:       # %bb.0:
; AVX-NEXT:    vpabsb %ymm0, %ymm0
; AVX-NEXT:    retq
  %n1 = sub <32 x i8> zeroinitializer, %a
  %b1 = icmp slt <32 x i8> %a, zeroinitializer
  %a1 = select <32 x i1> %b1, <32 x i8> %n1, <32 x i8> %a
  %a2 = call <32 x i8> @llvm.abs.v32i8(<32 x i8> %a1, i1 false)
  ret <32 x i8> %a2
}

define <4 x i64> @combine_v4i64_abs_abs(<4 x i64> %a) {
; SSE2-LABEL: combine_v4i64_abs_abs:
; SSE2:       # %bb.0:
; SSE2-NEXT:    movdqa %xmm0, %xmm2
; SSE2-NEXT:    psrad $31, %xmm2
; SSE2-NEXT:    pshufd {{.*#+}} xmm2 = xmm2[1,1,3,3]
; SSE2-NEXT:    paddq %xmm2, %xmm0
; SSE2-NEXT:    pxor %xmm2, %xmm0
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    psrad $31, %xmm2
; SSE2-NEXT:    pshufd {{.*#+}} xmm2 = xmm2[1,1,3,3]
; SSE2-NEXT:    paddq %xmm2, %xmm1
; SSE2-NEXT:    pxor %xmm2, %xmm1
; SSE2-NEXT:    retq
;
; SSE42-LABEL: combine_v4i64_abs_abs:
; SSE42:       # %bb.0:
; SSE42-NEXT:    movdqa %xmm0, %xmm2
; SSE42-NEXT:    pxor %xmm3, %xmm3
; SSE42-NEXT:    pxor %xmm4, %xmm4
; SSE42-NEXT:    psubq %xmm0, %xmm4
; SSE42-NEXT:    blendvpd %xmm0, %xmm4, %xmm2
; SSE42-NEXT:    psubq %xmm1, %xmm3
; SSE42-NEXT:    movdqa %xmm1, %xmm0
; SSE42-NEXT:    blendvpd %xmm0, %xmm3, %xmm1
; SSE42-NEXT:    movapd %xmm2, %xmm0
; SSE42-NEXT:    retq
;
; AVX2-LABEL: combine_v4i64_abs_abs:
; AVX2:       # %bb.0:
; AVX2-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX2-NEXT:    vpsubq %ymm0, %ymm1, %ymm1
; AVX2-NEXT:    vblendvpd %ymm0, %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    retq
;
; AVX512F-LABEL: combine_v4i64_abs_abs:
; AVX512F:       # %bb.0:
; AVX512F-NEXT:    # kill: def $ymm0 killed $ymm0 def $zmm0
; AVX512F-NEXT:    vpabsq %zmm0, %zmm0
; AVX512F-NEXT:    # kill: def $ymm0 killed $ymm0 killed $zmm0
; AVX512F-NEXT:    retq
;
; AVX512VL-LABEL: combine_v4i64_abs_abs:
; AVX512VL:       # %bb.0:
; AVX512VL-NEXT:    vpabsq %ymm0, %ymm0
; AVX512VL-NEXT:    retq
  %n1 = sub <4 x i64> zeroinitializer, %a
  %b1 = icmp slt <4 x i64> %a, zeroinitializer
  %a1 = select <4 x i1> %b1, <4 x i64> %n1, <4 x i64> %a
  %n2 = sub <4 x i64> zeroinitializer, %a1
  %b2 = icmp sgt <4 x i64> %a1, zeroinitializer
  %a2 = select <4 x i1> %b2, <4 x i64> %a1, <4 x i64> %n2
  ret <4 x i64> %a2
}

; fold (abs x) -> x iff not-negative
define <16 x i8> @combine_v16i8_abs_constant(<16 x i8> %a) {
; SSE-LABEL: combine_v16i8_abs_constant:
; SSE:       # %bb.0:
; SSE-NEXT:    andps {{.*}}(%rip), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_v16i8_abs_constant:
; AVX:       # %bb.0:
; AVX-NEXT:    vandps {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = insertelement <16 x i8> undef, i8 15, i32 0
  %2 = shufflevector <16 x i8> %1, <16 x i8> undef, <16 x i32> zeroinitializer
  %3 = and <16 x i8> %a, %2
  %4 = call <16 x i8> @llvm.abs.v16i8(<16 x i8> %3, i1 false)
  ret <16 x i8> %4
}

define <8 x i32> @combine_v8i32_abs_pos(<8 x i32> %a) {
; SSE-LABEL: combine_v8i32_abs_pos:
; SSE:       # %bb.0:
; SSE-NEXT:    psrld $1, %xmm0
; SSE-NEXT:    psrld $1, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_v8i32_abs_pos:
; AVX:       # %bb.0:
; AVX-NEXT:    vpsrld $1, %ymm0, %ymm0
; AVX-NEXT:    retq
  %1 = lshr <8 x i32> %a, <i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
  %2 = call <8 x i32> @llvm.abs.v8i32(<8 x i32> %1, i1 false)
  ret <8 x i32> %2
}

declare <16 x i8> @llvm.abs.v16i8(<16 x i8>, i1) nounwind readnone
declare <4 x i32> @llvm.abs.v4i32(<4 x i32>, i1) nounwind readnone
declare <8 x i16> @llvm.abs.v8i16(<8 x i16>, i1) nounwind readnone

declare <32 x i8> @llvm.abs.v32i8(<32 x i8>, i1) nounwind readnone
declare <8 x i32> @llvm.abs.v8i32(<8 x i32>, i1) nounwind readnone
declare <16 x i16> @llvm.abs.v16i16(<16 x i16>, i1) nounwind readnone
