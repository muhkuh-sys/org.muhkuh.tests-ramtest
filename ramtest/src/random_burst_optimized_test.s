@ test whether the optimized version generates the same sequence
@ fill the memory with the optimized routine, check with the original one

	.text
	.arm

	.global random_burst

	.func random_generator


		@ r3 : input
			   @first random number will be generated from seed
			   @following numbers generated from last generated random nr

		@ r5 : output which is random number

random_generator:


		lsr r12, r3, #31     @ shift seed 31 to the right and store in r12
		lsr r11, r3, #6      @ shift seed 6  to the right and store in r11
		eor r10, r11, r12    @ row 1 and 2 saved in r10
		lsr r12, r3, #4
		lsr r11, r3, #1
		eor r12, r12, r11
		eor r10, r12, r10    @ rows 1-4 in r10
		eor r10, r10, r3     @ row 5
		and r10, r10, #1
		lsl r10, r10, #31
		lsr r11, r3, #1
		orr r5, r10, r11

		bx lr


.endfunc
	
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
	bl random_generator     @ generate first random number and store it into r5

readback_loop:
	ldmia	r4!, {r6, r7, r8, r9}  @ save
	cmp	r6, r5
	bne	test_failed
	mov r3, r6
	bl random_generator
	cmp	r7, r5
	bne	test_failed
	mov r3, r7
	bl random_generator
	cmp	r8, r5
	bne	test_failed
	mov r3, r8
	bl random_generator
	cmp	r9, r5
	bne	test_failed
	mov r3, r9
	bl random_generator
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

