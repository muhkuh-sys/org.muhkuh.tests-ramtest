
#include "netx_io_areas.S"


	.section .init_code, "ax"

@ The Cortex-M4 in the netX90 is a THUMB-only CPU.
@ All others start in 32 bit mode.
#if ASIC_TYP==ASIC_TYP_NETX90_MPW
        .syntax unified
        .thumb
#else
        .arm
#endif

	.global start
	.extern local_main

#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED
#       define options_parse 0x0411638d
@ #elif ASIC_TYP==ASIC_TYP_NETX4000_FULL_SMALL
@ #       define options_parse 0x04116a75
#endif


@--------------------------------------

    .func start, start
    .type start, STT_FUNC
start:
	@ Save the scratch registers. See chapter 5 in http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042f/IHI0042F_aapcs.pdf for details.
	push    {r0, r1, r2, lr}

	@ Get the parameter.
	ldr     r0, [r0, #4]

	@ Jump to the main routine.
	blx     local_main

	@ Save the result.
	mov     r12, r0

	@ Restore the registers.
	pop     {r0, r1, r2, lr}

	@ Set the result.
	str     r12, [r0]

	@ Go back.
	bx      lr

  .endfunc

  .end

