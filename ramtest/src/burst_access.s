
	.text
	.arm

	.global burst_access

@--------------------------------------

    .func burst_access

@ r0 : startaddress
@ r1 : end address
@ r2 : seed
@ r3 : inc

@ r4 : loop adr
@ r5 : loop val
@ r6 : burst work 0
@ r7 : burst work 1
@ r8 : burst work 2
@ r9 : burst work 3

burst_access:
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, lr}

	@ fill the complete area
	mov	r4, r0				@ init the loop adr with the start address
	mov	r5, r2				@ init the loop val with the seed
fill_loop:
	mov	r6, r5
	add	r5, r5, r3
	mov	r7, r5
	add	r5, r5, r3
	mov	r8, r5
	add	r5, r5, r3
	mov	r9, r5
	add	r5, r5, r3
	stmia	r4!, {r6, r7, r8, r9}
	cmp	r4, r1				@ reached the endaddress
	blo	fill_loop

	@ read back the complete area
	mov	r4, r0				@ init the loop adr with the start address
	mov	r5, r2				@ init the loop val with the seed
readback_loop:
	ldmia	r4!, {r6, r7, r8, r9}
	cmp	r6, r5
	bne	test_failed
	add	r5, r5, r3
	cmp	r7, r5
	bne	test_failed
	add	r5, r5, r3
	cmp	r8, r5
	bne	test_failed
	add	r5, r5, r3
	cmp	r9, r5
	bne	test_failed
	add	r5, r5, r3
	cmp	r4, r1				@ reached the endaddress
	blo	readback_loop

	@ test ok!
	mov	r0, #0				@ set return value to 0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, lr}
	bx	lr


	@ test failed!
test_failed:
	mov	r0, #1				@ set return value to 1
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, lr}
	bx	lr

.endfunc

@--------------------------------------

.end

