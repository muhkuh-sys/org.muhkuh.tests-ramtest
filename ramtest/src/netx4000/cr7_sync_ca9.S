	.arm
.section .text, "ax"
.global start

#define ADDR_A9_0_FW_VECT 0x0507ffd0
#define ADDR_A9_1_FW_VECT 0x0507ffe8
#define MAGIC1 0x00000011
#define MAGIC2 0x00000022

start:
	
	ldr     r0, =ADDR_A9_0_FW_VECT
	ldm     r0, {r1, r2}
	teq     r1, #MAGIC1
	bne     start
	teq     r2, #MAGIC2
	bne     start
	
	ldr     r0, =ADDR_A9_1_FW_VECT
	ldm     r0, {r1, r2}
	teq     r1, #MAGIC1
	bne     start
	teq     r2, #MAGIC2
	bne     start
	bx      lr
	
	.end
	
