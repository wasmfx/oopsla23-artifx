; This file provides common code across AVRs that cannot be implemented directly
; in Go.
; The reset vector is device-specific and is generated by tools/gen-device-avr.py.

; These definitions are necessary because LLVM does not yet know these register
; aliases. See: https://reviews.llvm.org/D96492
#define xl r26
#define xh r27
#define yl r28
#define yh r29
#define zl r30
#define zh r31

; Startup code
.section .text.__vector_RESET
.global  __vector_RESET
__vector_RESET:
    clr  r1          ; r1 is expected to be 0 by the C calling convention

    ; Set up the stack pointer.
    ldi  xl, lo8(_stack_top)
    ldi  xh, hi8(_stack_top)
    out  0x3d, xl; SPL
    out  0x3e, xh; SPH

    ; Subtract one from the stack pointer, so it doesn't point in the .data section.
    push r0

    ; Initialize .data
init_data:
    ldi  xl, lo8(_sdata)
    ldi  xh, hi8(_sdata)
    ldi  yl, lo8(_edata)
    ldi  yh, hi8(_edata)
    ldi  zl, lo8(_sidata)
    ldi  zh, hi8(_sidata)
init_data_loop:
    cp   xl, yl         ; if x == y
    cpc  xh, yh
    breq init_data_end  ; goto main
    lpm  r0, Z+         ; r0 = *(z++)
    st   X+, r0         ; *(x++) = r0
    rjmp init_data_loop ; goto init_data_loop
init_data_end:

    ; main will be placed right after here by the linker script so there's no
    ; need to jump.


; The only thing this WDT handler really does is disable itself, to get out of
; sleep mode.
.section .text.__vector_WDT
.global  __vector_WDT
__vector_WDT:
    push r16

    clr  r16
    wdr            ; Reset watchdog
    out  0x34, r16 ; Clear reset reason (MCUSR)

    ; part 1: set WDCE and WDE to enable editing WDTCSR
    lds  r16, 0x60 ; r16 = WDTCSR
    ori  r16, 0x18 ; r16 |= WDCE | WDE
    sts  0x60, r16 ; WDTCSR = r16

    ; part 2: within 4 clock cycles, set the new value for WDTCSR
    clr  r16
    sts  0x60, r16 ; WDTCSR = 0

    pop  r16
    reti
