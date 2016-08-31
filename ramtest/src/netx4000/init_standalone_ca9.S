	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

// R_FW_VECT holds the base address of the firmware vector structures.
// R_CPU_ID is the core number (0 or 1)
#define R_FW_VECT  r11
#define R_CPU_ID   r12

	.global start

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==4000
   @ define entry point for CA9_core0
	.global start_core0
   @ define entry point for CA9_core1
	.global start_core1
#endif

@--------------------------------------

  .func start_init_s

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==4000
   @ define entry point for CA9_core0
start_core0:
   @ define entry point for CA9_core1
start_core1:
#endif 
start:
	
	@ set own stack position
	ldr     r2, =stack_top
	mov     sp, r2

	@ save firmware vector address/CPU id
	stmfd   sp!, {R_FW_VECT, R_CPU_ID}
	
	@ clear .bss section (zero init)
	mov     r2, #0
	ldr     r3, =__bss_start__
	ldr     r4, =__bss_end__
clear_bss:
	cmp     r3, r4
	strlo   r2, [r3], #4
	blo     clear_bss

	bl      ramtest_main
	
	@ restore firmware vector address/CPU id
	ldmfd   sp!, {R_FW_VECT, R_CPU_ID}
	
	// clear entry vector for A9 firmware and return to the rom code
	add     r0, R_CPU_ID, R_CPU_ID, LSL #1
	add     r0, R_FW_VECT, r0, LSL #3
	mov     r1, #0x11
	mov     r2, #0x22
	mov     r3, #0x33
	mov     r4, #0x44
	stm     r0, {r1-r4}
	ldr     pc, =0x1e4
	
  .endfunc

@--------------------------------------

  .end

