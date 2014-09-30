
#include "netx_io_areas.S"


	.section .init_code, "ax"
	.arm

	.extern test_main

	.global NetxTestParameter_Init
	.global start
	.global stack_top

@--------------------------------------

  .func start_init_s

start:
	stmfd   sp!, {r1, r2, lr}

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
	bx	lr

  .endfunc

  .end

