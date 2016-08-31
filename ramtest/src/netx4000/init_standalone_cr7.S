	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.global start

@--------------------------------------

  .func start_init_s
start:
	stmfd   sp!, {r0-r12, lr}

	@ save romcode stack position
	mov     r0, sp
	ldr     r1, =sp_save
	str     r0, [r1]
 
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

	@ restore romcode stack
	ldr     r1, =sp_save
	ldr     r0, [r1]
	mov     sp, r0

	ldmfd   sp!, {r0-r12, lr}
	bx      lr 
	
  .endfunc

@--------------------------------------
	.align 4

sp_save:
	.word 0 
  .end

