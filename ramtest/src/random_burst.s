@ runtime 3s vs. 8s for unoptimized version (for 8 MB)
	.text
	.arm

	.global random_burst

@--------------------------------------
@.func random_generator

@ r3 : input: current random number/seed
@      output: next random number
@ r5 : scratch

@ next value = (xor of bits 0, 1, 4, 6, 31) << 31 | current value >> 1

@random_generator:
@	eor r5, r3, r3, LSR#1
@	eor r5, r5, r3, LSR#4
@	eor r5, r5, r3, LSR#6
@	eor r5, r5, r3, LSR#31
@	rrxs r5, r5        @ shift bit 0 into carry
@	rrx r3, r3         @ shift right and shift carry into bit 31
@	bx lr

@.endfunc

	
@--------------------------------------
.func random_burst

@ r0 : startaddress
@ r1 : end address
@ r2 : seed

@ r3 : random number/seed
@ r4 : loop adr
@ r5 : used by random_generator
@ r6 : burst work 0
@ r7 : burst work 1
@ r8 : burst work 2
@ r9 : burst work 3

random_burst:
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

	@ fill the complete area
	mov	r4, r0				   @ init the loop adr with the start address
	mov	r3, r2				   @ init the loop val with the seed

fill_loop:
	eor r5, r3, r3, LSR#1
	eor r5, r5, r3, LSR#4
	eor r5, r5, r3, LSR#6
	eor r5, r5, r3, LSR#31
	rrxs r5, r5        @ shift bit 0 into carry
	rrx r6, r3         @ shift right and shift carry into bit 31
	
	eor r5, r5, r6, LSR#31
	rrxs r5, r5
	rrx r7, r6
	
	eor r5, r5, r7, LSR#31
	rrxs r5, r5
	rrx r8, r7

	eor r5, r5, r8, LSR#31
	rrxs r5, r5
	rrx r9, r8
	mov r3, r9
	
	stmia	r4!, {r6, r7, r8, r9}
	cmp	r4, r1				@ reached the endaddress
	blo	fill_loop

	@ read back the complete area
	mov	r4, r0				@ init the loop adr with the start address
	mov	r3, r2				@ first random_input is the seed value


readback_loop:
	ldmia	r4!, {r6, r7, r8, r9}  @ read back
	
	eor r5, r3, r3, LSR#1
	eor r5, r5, r3, LSR#4
	eor r5, r5, r3, LSR#6
	eor r5, r5, r3, LSR#31
	rrxs r5, r5        @ shift bit 0 into carry
	rrx r3, r3         @ shift right and shift carry into bit 31
	cmp	r6, r3
	bne	test_failed
	
	eor r5, r5, r3, LSR#31
	rrxs r5, r5
	rrx r3, r3
	cmp	r7, r3
	bne	test_failed

	eor r5, r5, r3, LSR#31
	rrxs r5, r5
	rrx r3, r3
	cmp	r8, r3
	bne	test_failed

	eor r5, r5, r3, LSR#31
	rrxs r5, r5
	rrx r3, r3
	cmp	r9, r3
	bne	test_failed

	cmp	r4, r1				@ reached the endaddress
	blo	readback_loop

	
	@ test ok!
	mov	r0, #0				@ set return value to 0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr


	@ test failed!
test_failed:
	mov	r0, #1				@ set return value to 1
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr

.endfunc

@--------------------------------------

.end

