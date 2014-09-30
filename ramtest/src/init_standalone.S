
	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.global start


@--------------------------------------

  .func start_init_s

start:
	stmfd   sp!, {r0, r1, r2, r3, r4, lr}

	@ set own stack position
	ldr     r2, =stack_top
	mov     sp, r2

	@ clear .bss section (zero init)
	mov     r2, #0
	ldr     r3, =__bss_start__
	ldr     r4, =__bss_end__
clear_bss:
	cmp     r3, r4
	strlo   r2, [r3], #4
	blo     clear_bss

	bl      ramtest_main

  .endfunc

@--------------------------------------

  .end

