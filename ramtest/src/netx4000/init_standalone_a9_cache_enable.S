#include "netx_io_areas.S"

	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.global start

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED
   @ define entry point for CA9_core0
	.global start_core0
   @ define entry point for CA9_core1
	.global start_core1
#endif

@--------------------------------------

  .func start_init_s

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED
   @ define entry point for CA9_core0
start_core0:
   @ define entry point for CA9_core1
start_core1:
#endif 

start:
	push    {r0, r1}
// ------------------------------------------------------------
// v7-A Cache and Branch Prediction Maintenance Operations
// ------------------------------------------------------------

// R_FW_VECT holds the base address of the firmware vector structures.
// R_CPU_ID is the core number (0 or 1)
#define R_FW_VECT  r11
#define R_CPU_ID   r12

// clobbers r0-r4
// Must preserve r11 and r12 which are used by the Rom code.
	// disable MMU in case it has been on
	MRC     p15, 0, r0, c1, c0, 0         // read CP15 register 1
	BIC     r0, r0, #0x1                  // clear bit 0
	MCR     p15, 0, r0, c1, c0, 0         // write value back

	// clear icache
	MOV     r0, #0
	MCR     p15, 0, r0, c7, c5, 0         // ICIALLU - Invalidate entire I Cache, and flushes branch target cache

	// clear the branch prediction array
	mov     r0, #0x0
	mcr     p15, 0, r0, c7, c5, 6             // BPIALL - Invalidate entire branch predictor array

	// Enable only the icache for now (to speed up init process)
	// but don't enable dcache, because the SCU is not yet on and hasn't been invalidated 
	// (according to R-JK this may be bad)
	MRC     p15, 0, r0, c1, c0, 0         // Read System Control Register configuration data
	ORR     r0, r0, #(1 << 12)            // Set I bit
	MCR     p15, 0, r0, c1, c0, 0         // Write System Control Register configuration data

	// Branch Prediction Init
	MRC     p15, 0, r0, c1, c0, 0         // Read SCTLR
	ORR     r0, r0, #(1 << 11)            // Set the Z bit (bit 11)
	MCR     p15, 0,r0, c1, c0, 0          // Write SCTLR

	// invalidate dcache by set/way
	MOV     r0,#0
	// mcr: Crashes Lauterbach 2014.02
	MCR     p15,2,r0,c0,c0,0              // cache size selection register, select dcache
	
	// Read cache size from the Cache Size Identification Register
	MRC     p15, 1, r3, c0, c0, 0         // Read current Cache Size Identification Register
	ldr     r1, =0x1ff
	AND     r3, r1, r3, LSR #13           // r3 = (number of sets - 1)
	MOV     r0, #0                        // r0 -> way counter

way_loop:
	MOV     r1, #0                         // r1 -> set counter
set_loop:
	MOV     r2, r0, LSL #30
	ORR     r2, r1, LSL #5                 // r2 -> set/way cache-op format
	MCR     p15, 0, r2, c7, c6, 2          // Invalidate line described by r2
	ADD     r1, r1, #1                     // Increment set counter
	CMP     r1, r3                         // Check if the last set is reached...
	// ble: Emulation debug port fail in Lauterbach 2014.02
	BLE     set_loop                       // ...if not, continue the set_loop...
	ADD     r0, r0, #1                     // ...else, Increment way counter
	CMP     r0, #4                         // Check if the last way is reached...
	// blt: Emulation debug port fail in Lauterbach 2014.02
	BLT     way_loop                       // ...if not, continue the way_loop
	
	// enable data cache
	MRC     p15, 0, r0, c1, c0, 0         // Read System Control Register configuration data
	ORR     r0, r0, #(1 << 2)             // Set C bit
	MCR     p15, 0, r0, c1, c0, 0         // Write System Control Register configuration data
	
	pop     {r0, r1}
	
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

	// no provisions for returning into rom code 
  .endfunc

@--------------------------------------

  .end

