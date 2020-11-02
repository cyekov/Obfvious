; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv64 -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefix=RV64I %s
; RUN: llc -mtriple=riscv64 -mattr=+f -target-abi lp64f \
; RUN:    -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefix=RV64I %s
; RUN: llc -mtriple=riscv64 -mattr=+d -target-abi lp64d \
; RUN:    -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefix=RV64I %s

; This file contains tests that should have identical output for the lp64,
; lp64f, and lp64d ABIs. i.e. where no arguments are passed according to
; the floating point ABI. It doesn't check codegen when frame pointer
; elimination is disabled, as there is sufficient coverage for this case in
; other files.

; Check that on RV64, i128 is passed in a pair of registers. Unlike
; the convention for varargs, this need not be an aligned pair.

define i64 @callee_i128_in_regs(i64 %a, i128 %b) nounwind {
; RV64I-LABEL: callee_i128_in_regs:
; RV64I:       # %bb.0:
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    ret
  %b_trunc = trunc i128 %b to i64
  %1 = add i64 %a, %b_trunc
  ret i64 %1
}

define i64 @caller_i128_in_regs() nounwind {
; RV64I-LABEL: caller_i128_in_regs:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp)
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    mv a2, zero
; RV64I-NEXT:    call callee_i128_in_regs
; RV64I-NEXT:    ld ra, 8(sp)
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
  %1 = call i64 @callee_i128_in_regs(i64 1, i128 2)
  ret i64 %1
}

; Check that the stack is used once the GPRs are exhausted

define i32 @callee_many_scalars(i8 %a, i16 %b, i32 %c, i128 %d, i32 %e, i32 %f, i128 %g, i32 %h) nounwind {
; RV64I-LABEL: callee_many_scalars:
; RV64I:       # %bb.0:
; RV64I-NEXT:    lw t0, 8(sp)
; RV64I-NEXT:    ld t1, 0(sp)
; RV64I-NEXT:    andi t2, a0, 255
; RV64I-NEXT:    lui a0, 16
; RV64I-NEXT:    addiw a0, a0, -1
; RV64I-NEXT:    and a0, a1, a0
; RV64I-NEXT:    add a0, t2, a0
; RV64I-NEXT:    add a0, a0, a2
; RV64I-NEXT:    xor a1, a4, t1
; RV64I-NEXT:    xor a2, a3, a7
; RV64I-NEXT:    or a1, a2, a1
; RV64I-NEXT:    seqz a1, a1
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    add a0, a0, a5
; RV64I-NEXT:    add a0, a0, a6
; RV64I-NEXT:    addw a0, a0, t0
; RV64I-NEXT:    ret
  %a_ext = zext i8 %a to i32
  %b_ext = zext i16 %b to i32
  %1 = add i32 %a_ext, %b_ext
  %2 = add i32 %1, %c
  %3 = icmp eq i128 %d, %g
  %4 = zext i1 %3 to i32
  %5 = add i32 %4, %2
  %6 = add i32 %5, %e
  %7 = add i32 %6, %f
  %8 = add i32 %7, %h
  ret i32 %8
}

define i32 @caller_many_scalars() nounwind {
; RV64I-LABEL: caller_many_scalars:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -32
; RV64I-NEXT:    sd ra, 24(sp)
; RV64I-NEXT:    addi a0, zero, 8
; RV64I-NEXT:    sd a0, 8(sp)
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    addi a2, zero, 3
; RV64I-NEXT:    addi a3, zero, 4
; RV64I-NEXT:    addi a5, zero, 5
; RV64I-NEXT:    addi a6, zero, 6
; RV64I-NEXT:    addi a7, zero, 7
; RV64I-NEXT:    sd zero, 0(sp)
; RV64I-NEXT:    mv a4, zero
; RV64I-NEXT:    call callee_many_scalars
; RV64I-NEXT:    ld ra, 24(sp)
; RV64I-NEXT:    addi sp, sp, 32
; RV64I-NEXT:    ret
  %1 = call i32 @callee_many_scalars(i8 1, i16 2, i32 3, i128 4, i32 5, i32 6, i128 7, i32 8)
  ret i32 %1
}

; Check that i256 is passed indirectly.

define i64 @callee_large_scalars(i256 %a, i256 %b) nounwind {
; RV64I-LABEL: callee_large_scalars:
; RV64I:       # %bb.0:
; RV64I-NEXT:    ld a6, 0(a1)
; RV64I-NEXT:    ld a7, 0(a0)
; RV64I-NEXT:    ld a4, 8(a1)
; RV64I-NEXT:    ld a5, 24(a1)
; RV64I-NEXT:    ld a2, 24(a0)
; RV64I-NEXT:    ld a3, 8(a0)
; RV64I-NEXT:    ld a1, 16(a1)
; RV64I-NEXT:    ld a0, 16(a0)
; RV64I-NEXT:    xor a2, a2, a5
; RV64I-NEXT:    xor a3, a3, a4
; RV64I-NEXT:    or a2, a3, a2
; RV64I-NEXT:    xor a0, a0, a1
; RV64I-NEXT:    xor a1, a7, a6
; RV64I-NEXT:    or a0, a1, a0
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    seqz a0, a0
; RV64I-NEXT:    ret
  %1 = icmp eq i256 %a, %b
  %2 = zext i1 %1 to i64
  ret i64 %2
}

define i64 @caller_large_scalars() nounwind {
; RV64I-LABEL: caller_large_scalars:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -80
; RV64I-NEXT:    sd ra, 72(sp)
; RV64I-NEXT:    sd zero, 24(sp)
; RV64I-NEXT:    sd zero, 16(sp)
; RV64I-NEXT:    sd zero, 8(sp)
; RV64I-NEXT:    addi a0, zero, 2
; RV64I-NEXT:    sd a0, 0(sp)
; RV64I-NEXT:    sd zero, 56(sp)
; RV64I-NEXT:    sd zero, 48(sp)
; RV64I-NEXT:    sd zero, 40(sp)
; RV64I-NEXT:    addi a2, zero, 1
; RV64I-NEXT:    addi a0, sp, 32
; RV64I-NEXT:    mv a1, sp
; RV64I-NEXT:    sd a2, 32(sp)
; RV64I-NEXT:    call callee_large_scalars
; RV64I-NEXT:    ld ra, 72(sp)
; RV64I-NEXT:    addi sp, sp, 80
; RV64I-NEXT:    ret
  %1 = call i64 @callee_large_scalars(i256 1, i256 2)
  ret i64 %1
}

; Check that arguments larger than 2*xlen are handled correctly when their
; address is passed on the stack rather than in memory

; Must keep define on a single line due to an update_llc_test_checks.py limitation
define i64 @callee_large_scalars_exhausted_regs(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i256 %h, i64 %i, i256 %j) nounwind {
; RV64I-LABEL: callee_large_scalars_exhausted_regs:
; RV64I:       # %bb.0:
; RV64I-NEXT:    ld a0, 8(sp)
; RV64I-NEXT:    ld a6, 0(a0)
; RV64I-NEXT:    ld t0, 0(a7)
; RV64I-NEXT:    ld a3, 8(a0)
; RV64I-NEXT:    ld a4, 24(a0)
; RV64I-NEXT:    ld a5, 24(a7)
; RV64I-NEXT:    ld a1, 8(a7)
; RV64I-NEXT:    ld a0, 16(a0)
; RV64I-NEXT:    ld a2, 16(a7)
; RV64I-NEXT:    xor a4, a5, a4
; RV64I-NEXT:    xor a1, a1, a3
; RV64I-NEXT:    or a1, a1, a4
; RV64I-NEXT:    xor a0, a2, a0
; RV64I-NEXT:    xor a2, t0, a6
; RV64I-NEXT:    or a0, a2, a0
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    seqz a0, a0
; RV64I-NEXT:    ret
  %1 = icmp eq i256 %h, %j
  %2 = zext i1 %1 to i64
  ret i64 %2
}

define i64 @caller_large_scalars_exhausted_regs() nounwind {
; RV64I-LABEL: caller_large_scalars_exhausted_regs:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -96
; RV64I-NEXT:    sd ra, 88(sp)
; RV64I-NEXT:    addi a0, sp, 16
; RV64I-NEXT:    sd a0, 8(sp)
; RV64I-NEXT:    addi a0, zero, 9
; RV64I-NEXT:    sd a0, 0(sp)
; RV64I-NEXT:    sd zero, 40(sp)
; RV64I-NEXT:    sd zero, 32(sp)
; RV64I-NEXT:    sd zero, 24(sp)
; RV64I-NEXT:    addi a0, zero, 10
; RV64I-NEXT:    sd a0, 16(sp)
; RV64I-NEXT:    sd zero, 72(sp)
; RV64I-NEXT:    sd zero, 64(sp)
; RV64I-NEXT:    sd zero, 56(sp)
; RV64I-NEXT:    addi t0, zero, 8
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    addi a2, zero, 3
; RV64I-NEXT:    addi a3, zero, 4
; RV64I-NEXT:    addi a4, zero, 5
; RV64I-NEXT:    addi a5, zero, 6
; RV64I-NEXT:    addi a6, zero, 7
; RV64I-NEXT:    addi a7, sp, 48
; RV64I-NEXT:    sd t0, 48(sp)
; RV64I-NEXT:    call callee_large_scalars_exhausted_regs
; RV64I-NEXT:    ld ra, 88(sp)
; RV64I-NEXT:    addi sp, sp, 96
; RV64I-NEXT:    ret
  %1 = call i64 @callee_large_scalars_exhausted_regs(
      i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i256 8, i64 9,
      i256 10)
  ret i64 %1
}

; Ensure that libcalls generated in the middle-end obey the calling convention

define i64 @caller_mixed_scalar_libcalls(i64 %a) nounwind {
; RV64I-LABEL: caller_mixed_scalar_libcalls:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp)
; RV64I-NEXT:    call __floatditf
; RV64I-NEXT:    ld ra, 8(sp)
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
  %1 = sitofp i64 %a to fp128
  %2 = bitcast fp128 %1 to i128
  %3 = trunc i128 %2 to i64
  ret i64 %3
}

; Check passing of coerced integer arrays

%struct.small = type { i64, i64* }

define i64 @callee_small_coerced_struct([2 x i64] %a.coerce) nounwind {
; RV64I-LABEL: callee_small_coerced_struct:
; RV64I:       # %bb.0:
; RV64I-NEXT:    xor a0, a0, a1
; RV64I-NEXT:    seqz a0, a0
; RV64I-NEXT:    ret
  %1 = extractvalue [2 x i64] %a.coerce, 0
  %2 = extractvalue [2 x i64] %a.coerce, 1
  %3 = icmp eq i64 %1, %2
  %4 = zext i1 %3 to i64
  ret i64 %4
}

define i64 @caller_small_coerced_struct() nounwind {
; RV64I-LABEL: caller_small_coerced_struct:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp)
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    call callee_small_coerced_struct
; RV64I-NEXT:    ld ra, 8(sp)
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
  %1 = call i64 @callee_small_coerced_struct([2 x i64] [i64 1, i64 2])
  ret i64 %1
}

; Check large struct arguments, which are passed byval

%struct.large = type { i64, i64, i64, i64 }

define i64 @callee_large_struct(%struct.large* byval align 8 %a) nounwind {
; RV64I-LABEL: callee_large_struct:
; RV64I:       # %bb.0:
; RV64I-NEXT:    ld a1, 0(a0)
; RV64I-NEXT:    ld a0, 24(a0)
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    ret
  %1 = getelementptr inbounds %struct.large, %struct.large* %a, i64 0, i32 0
  %2 = getelementptr inbounds %struct.large, %struct.large* %a, i64 0, i32 3
  %3 = load i64, i64* %1
  %4 = load i64, i64* %2
  %5 = add i64 %3, %4
  ret i64 %5
}

define i64 @caller_large_struct() nounwind {
; RV64I-LABEL: caller_large_struct:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -80
; RV64I-NEXT:    sd ra, 72(sp)
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    sd a0, 40(sp)
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    sd a1, 48(sp)
; RV64I-NEXT:    addi a2, zero, 3
; RV64I-NEXT:    sd a2, 56(sp)
; RV64I-NEXT:    addi a3, zero, 4
; RV64I-NEXT:    sd a3, 64(sp)
; RV64I-NEXT:    sd a0, 8(sp)
; RV64I-NEXT:    sd a1, 16(sp)
; RV64I-NEXT:    sd a2, 24(sp)
; RV64I-NEXT:    sd a3, 32(sp)
; RV64I-NEXT:    addi a0, sp, 8
; RV64I-NEXT:    call callee_large_struct
; RV64I-NEXT:    ld ra, 72(sp)
; RV64I-NEXT:    addi sp, sp, 80
; RV64I-NEXT:    ret
  %ls = alloca %struct.large, align 8
  %1 = bitcast %struct.large* %ls to i8*
  %a = getelementptr inbounds %struct.large, %struct.large* %ls, i64 0, i32 0
  store i64 1, i64* %a
  %b = getelementptr inbounds %struct.large, %struct.large* %ls, i64 0, i32 1
  store i64 2, i64* %b
  %c = getelementptr inbounds %struct.large, %struct.large* %ls, i64 0, i32 2
  store i64 3, i64* %c
  %d = getelementptr inbounds %struct.large, %struct.large* %ls, i64 0, i32 3
  store i64 4, i64* %d
  %2 = call i64 @callee_large_struct(%struct.large* byval align 8 %ls)
  ret i64 %2
}

; Check 2x*xlen values are aligned appropriately when passed on the stack
; Must keep define on a single line due to an update_llc_test_checks.py limitation
define i64 @callee_aligned_stack(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i128 %f, i64 %g, i64 %h, i128 %i, i64 %j, [2 x i64] %k) nounwind {
; The i128 should be 16-byte aligned on the stack, but the two-element array
; should only be 8-byte aligned
; RV64I-LABEL: callee_aligned_stack:
; RV64I:       # %bb.0:
; RV64I-NEXT:    ld a0, 40(sp)
; RV64I-NEXT:    ld a1, 0(sp)
; RV64I-NEXT:    ld a2, 16(sp)
; RV64I-NEXT:    ld a3, 32(sp)
; RV64I-NEXT:    add a4, a5, a7
; RV64I-NEXT:    add a1, a4, a1
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    add a1, a1, a3
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    ret
  %f_trunc = trunc i128 %f to i64
  %1 = add i64 %f_trunc, %g
  %2 = add i64 %1, %h
  %3 = trunc i128 %i to i64
  %4 = add i64 %2, %3
  %5 = add i64 %4, %j
  %6 = extractvalue [2 x i64] %k, 0
  %7 = add i64 %5, %6
  ret i64 %7
}

define void @caller_aligned_stack() nounwind {
; The i128 should be 16-byte aligned on the stack, but the two-element array
; should only be 8-byte aligned
; RV64I-LABEL: caller_aligned_stack:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -64
; RV64I-NEXT:    sd ra, 56(sp)
; RV64I-NEXT:    addi a0, zero, 12
; RV64I-NEXT:    sd a0, 48(sp)
; RV64I-NEXT:    addi a0, zero, 11
; RV64I-NEXT:    sd a0, 40(sp)
; RV64I-NEXT:    addi a0, zero, 10
; RV64I-NEXT:    sd a0, 32(sp)
; RV64I-NEXT:    sd zero, 24(sp)
; RV64I-NEXT:    addi a0, zero, 9
; RV64I-NEXT:    sd a0, 16(sp)
; RV64I-NEXT:    addi a6, zero, 8
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    addi a2, zero, 3
; RV64I-NEXT:    addi a3, zero, 4
; RV64I-NEXT:    addi a4, zero, 5
; RV64I-NEXT:    addi a5, zero, 6
; RV64I-NEXT:    addi a7, zero, 7
; RV64I-NEXT:    sd a6, 0(sp)
; RV64I-NEXT:    mv a6, zero
; RV64I-NEXT:    call callee_aligned_stack
; RV64I-NEXT:    ld ra, 56(sp)
; RV64I-NEXT:    addi sp, sp, 64
; RV64I-NEXT:    ret
  %1 = call i64 @callee_aligned_stack(i64 1, i64 2, i64 3, i64 4, i64 5,
    i128 6, i64 7, i64 8, i128 9, i64 10, [2 x i64] [i64 11, i64 12])
  ret void
}

; Check return of 2x xlen scalars

define i128 @callee_small_scalar_ret() nounwind {
; RV64I-LABEL: callee_small_scalar_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi a0, zero, -1
; RV64I-NEXT:    addi a1, zero, -1
; RV64I-NEXT:    ret
  ret i128 -1
}

define i64 @caller_small_scalar_ret() nounwind {
; RV64I-LABEL: caller_small_scalar_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp)
; RV64I-NEXT:    call callee_small_scalar_ret
; RV64I-NEXT:    not a1, a1
; RV64I-NEXT:    xori a0, a0, -2
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    seqz a0, a0
; RV64I-NEXT:    ld ra, 8(sp)
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
  %1 = call i128 @callee_small_scalar_ret()
  %2 = icmp eq i128 -2, %1
  %3 = zext i1 %2 to i64
  ret i64 %3
}

; Check return of 2x xlen structs

define %struct.small @callee_small_struct_ret() nounwind {
; RV64I-LABEL: callee_small_struct_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi a0, zero, 1
; RV64I-NEXT:    mv a1, zero
; RV64I-NEXT:    ret
  ret %struct.small { i64 1, i64* null }
}

define i64 @caller_small_struct_ret() nounwind {
; RV64I-LABEL: caller_small_struct_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp)
; RV64I-NEXT:    call callee_small_struct_ret
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    ld ra, 8(sp)
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
  %1 = call %struct.small @callee_small_struct_ret()
  %2 = extractvalue %struct.small %1, 0
  %3 = extractvalue %struct.small %1, 1
  %4 = ptrtoint i64* %3 to i64
  %5 = add i64 %2, %4
  ret i64 %5
}

; Check return of >2x xlen scalars

define i256 @callee_large_scalar_ret() nounwind {
; RV64I-LABEL: callee_large_scalar_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi a1, zero, -1
; RV64I-NEXT:    sd a1, 24(a0)
; RV64I-NEXT:    sd a1, 16(a0)
; RV64I-NEXT:    sd a1, 8(a0)
; RV64I-NEXT:    lui a1, 1018435
; RV64I-NEXT:    addiw a1, a1, 747
; RV64I-NEXT:    sd a1, 0(a0)
; RV64I-NEXT:    ret
  ret i256 -123456789
}

define void @caller_large_scalar_ret() nounwind {
; RV64I-LABEL: caller_large_scalar_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -48
; RV64I-NEXT:    sd ra, 40(sp)
; RV64I-NEXT:    mv a0, sp
; RV64I-NEXT:    call callee_large_scalar_ret
; RV64I-NEXT:    ld ra, 40(sp)
; RV64I-NEXT:    addi sp, sp, 48
; RV64I-NEXT:    ret
  %1 = call i256 @callee_large_scalar_ret()
  ret void
}

; Check return of >2x xlen structs

define void @callee_large_struct_ret(%struct.large* noalias sret %agg.result) nounwind {
; RV64I-LABEL: callee_large_struct_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    sw zero, 4(a0)
; RV64I-NEXT:    addi a1, zero, 1
; RV64I-NEXT:    sw a1, 0(a0)
; RV64I-NEXT:    sw zero, 12(a0)
; RV64I-NEXT:    addi a1, zero, 2
; RV64I-NEXT:    sw a1, 8(a0)
; RV64I-NEXT:    sw zero, 20(a0)
; RV64I-NEXT:    addi a1, zero, 3
; RV64I-NEXT:    sw a1, 16(a0)
; RV64I-NEXT:    sw zero, 28(a0)
; RV64I-NEXT:    addi a1, zero, 4
; RV64I-NEXT:    sw a1, 24(a0)
; RV64I-NEXT:    ret
  %a = getelementptr inbounds %struct.large, %struct.large* %agg.result, i64 0, i32 0
  store i64 1, i64* %a, align 4
  %b = getelementptr inbounds %struct.large, %struct.large* %agg.result, i64 0, i32 1
  store i64 2, i64* %b, align 4
  %c = getelementptr inbounds %struct.large, %struct.large* %agg.result, i64 0, i32 2
  store i64 3, i64* %c, align 4
  %d = getelementptr inbounds %struct.large, %struct.large* %agg.result, i64 0, i32 3
  store i64 4, i64* %d, align 4
  ret void
}

define i64 @caller_large_struct_ret() nounwind {
; RV64I-LABEL: caller_large_struct_ret:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addi sp, sp, -48
; RV64I-NEXT:    sd ra, 40(sp)
; RV64I-NEXT:    addi a0, sp, 8
; RV64I-NEXT:    call callee_large_struct_ret
; RV64I-NEXT:    ld a0, 8(sp)
; RV64I-NEXT:    ld a1, 32(sp)
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    ld ra, 40(sp)
; RV64I-NEXT:    addi sp, sp, 48
; RV64I-NEXT:    ret
  %1 = alloca %struct.large
  call void @callee_large_struct_ret(%struct.large* sret %1)
  %2 = getelementptr inbounds %struct.large, %struct.large* %1, i64 0, i32 0
  %3 = load i64, i64* %2
  %4 = getelementptr inbounds %struct.large, %struct.large* %1, i64 0, i32 3
  %5 = load i64, i64* %4
  %6 = add i64 %3, %5
  ret i64 %6
}
