// ------------------------------------------------------------
// v7-A Cache and Branch Prediction Maintenance Operations
// ------------------------------------------------------------
	.arm
.section .text, "ax"
.global start

// R_FW_VECT holds the base address of the firmware vector structures.
// R_CPU_ID is the core number (0 or 1)
#define R_FW_VECT  r11
#define R_CPU_ID   r12

// clobbers r0-r4
// Must preserve r11 and r12 which are used by the Rom code.
start:
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
	
	// clear entry vector for A9 rom code and return to the rom code
	add     r0, R_CPU_ID, R_CPU_ID, LSL #1
	add     r0, R_FW_VECT, r0, LSL #3
	mov     r1, #0x11
	mov     r2, #0x22
	mov     r3, #0x33
	mov     r4, #0x44
	stm     r0, {r1-r4}
	ldr     pc, =0x1e4
	.end
	
// ------------------------------------------------------------
// End of v7.s
// ------------------------------------------------------------
