
#include "netx_io_areas.S"


	.section .init_code, "ax"

@ The Cortex-M4 in the netX90 is a THUMB-only CPU.
@ All others start in 32 bit mode.
#if ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
        .syntax unified
        .thumb
#else
        .arm
#endif

	.global NetxTestParameter_Init
	.global start
	.global stack_top

@--------------------------------------

    .func start, start
    .type start, STT_FUNC
start:
	push    {r1, r2}

	@ Unlock the access key.
	ldr     r1, =HOSTADR(asic_ctrl_access_key)
	ldr     r2, [r1]
	str     r2, [r1]

	@ Write the new hif_io_cfg value.
	ldr     r1, =HOSTADR(hif_io_cfg)
	ldr     r2, [r0, #4]
	str     r2, [r1]

	@ Set the result to 0.
	mov     r1, #0
	str     r1, [r0]

	@ Go back.
	pop     {r1, r2}
	bx	lr

  .endfunc

  .end

