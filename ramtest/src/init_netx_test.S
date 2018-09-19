#include "asic_types.h"

	.section .init_code, "ax"

@ The Cortex-M4 in the netX90 is a THUMB-only CPU.
@ All others start in 32 bit mode.
#if ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
        .syntax unified
        .thumb
#else
        .arm
#endif


	.extern test_main

	.global start
	.global stack_top

	@ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
	@ define entry point for CA9_core0
	.global start_core0
	@ define entry point for CA9_core1
	.global start_core1
#endif

@--------------------------------------

	@ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
	@ define entry point for CA9_core0
start_core0:
	@ define entry point for CA9_core1
start_core1:
#endif 

    .func start, start
    .type start, STT_FUNC
start:
	push    {r1, r2, lr}

	@ Save the stack position of the ROM.
	mov     r1, sp

	@ Set own stack position
	ldr     r2, =stack_top
	mov     sp, r2

	@ Save the ROM stack position and some additional registers.
	push    {r0, r1, r3}

	@ Clear the .bss section.
	mov     r1, #0
	ldr     r2, =__bss_start__
	ldr     r3, =__bss_end__
clear_bss:
	str     r1, [r2], #4
	cmp     r2, r3
	bmi     clear_bss

	@ Jump to the main routine.
	blx     test_main

	@ Move the result to r2.
	mov     r2, r0

	@ Restore the ROM stack position.
	pop     {r0, r1, r3}
	mov     sp, r1

	@ Store the result in the structure.
	str     r2, [r0, #0]

	@ Restore the rest of the registers.
	pop     {r1, r2, lr}
	bx      lr

  .endfunc

@--------------------------------------

  .end

