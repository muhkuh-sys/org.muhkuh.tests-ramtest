
	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.global start


@--------------------------------------

  .func start

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

	ldr     r0, =aulBootBlock
	bl      ramtest_main

  .endfunc


aulBootBlock:
	.word 0x00000000    @ 0
	.word 0x00000000    @ 1
	.word 0x00000000    @ 2
	.word 0x00000000    @ 3
	.word 0x00000000    @ 4
	.word 0x00000000    @ 5
	.word 0x00000000    @ 6
	.word 0x030C0011    @ 7
	.word 0x03C23251    @ 8
	.word 0x00000000    @ 9
	.word 0x00000000    @ a
	.word 0x00000000    @ b
	.word 0x00000000    @ c
	.word 0x80000000    @ d
	.word 0x00000000    @ e
	.word 0x00000000    @ f

@--------------------------------------

  .end

