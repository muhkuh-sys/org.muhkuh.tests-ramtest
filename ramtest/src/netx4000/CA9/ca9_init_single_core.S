/* 
	define as needed:
	CA9_ENABLE_MMU
	CA9_ENABLE_CACHES
	CA9_NO_L2C_ENABLE 
	
	do not define: 
	darm, 
	SIM_MESSAGES, 
	CA9_DISABLE_BRANCH_PREDICTION 
*/

	// R_FW_VECT holds the base address of the firmware vector structures.
	// R_CPU_ID is the core number (0 or 1)
#define R_FW_VECT  r11
#define R_CPU_ID   r12

	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.extern get_cpu_id
	.extern enable_scu
	.extern join_smp
	.extern enable_maintenance_broadcast
//	.extern init_global_exception_counters
	.extern mmu_table_init
	.global start

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
   @ define entry point for CA9_core0
	.global start_core0
   @ define entry point for CA9_core1
	.global start_core1

@--------------------------------------

  .func start_init_s

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
   @ define entry point for CA9_core0
start_core0:
   @ define entry point for CA9_core1
start_core1:
start:
	
	@ set own stack position
	ldr     r2, =stack_top
	mov     sp, r2
	
	@ save firmware vector address/CPU id
	stmfd   sp!, {R_FW_VECT, R_CPU_ID}
	
	@ save r0/r1
	stmfd   sp!, {r0, r1}

	@ clear .bss section (zero init)
	mov     r2, #0
	ldr     r3, =__bss_start__
	ldr     r4, =__bss_end__
clear_bss:
	cmp     r3, r4
	strlo   r2, [r3], #4
	blo     clear_bss
	
	
//-----------------------------------------------------------------------------
// MMU setup
//-----------------------------------------------------------------------------

#ifndef darm
	// MMU Setup

	// disable MMU in case it has been on
	MRC     p15, 0, r0, c1, c0, 0       // read CP15 register 1
	BIC     r0, r0, #0x1                // clear bit 0
	MCR     p15, 0, r0, c1, c0, 0       // write value back


	// clear icache
	MOV     r0, #0
	MCR     p15, 0, r0, c7, c5, 0     // ICIALLU - Invalidate entire I Cache, and flushes branch target cache


	// clear the branch prediction array
	mov r0, #0x0
	mcr p15, 0, r0, c7, c5, 6     // BPIALL - Invalidate entire branch predictor array

	
#ifdef CA9_ENABLE_CACHES
	// Enable only the icache for now (to speed up init process)
	// but don't enable dcache, because the SCU is not yet on and hasn't been invalidated 
	// (according to R-JK this may be bad)
	// -----------------------
	bl enable_icache
#endif

#ifndef CA9_DISABLE_BRANCH_PREDICTION
	// Branch Prediction Init
	// -----------------------
	bl enable_branch_prediction
#endif


	// invalidate dcache by set/way
	MOV     r0,#0
	MCR     p15,2,r0,c0,c0,0               // cache size selection register, select dcache
	
	// Read cache size from the Cache Size Identification Register
	MRC     p15, 1, r3, c0, c0, 0          // Read current Cache Size Identification Register
	ldr     r1, =0x1ff
	AND     r3, r1, r3, LSR #13            // r3 = (number of sets - 1)
	MOV     r0, #0                         // r0 -> way counter
way_loop:
	MOV     r1, #0                         // r1 -> set counter
set_loop:
	MOV     r2, r0, LSL #30
	ORR     r2, r1, LSL #5                 // r2 -> set/way cache-op format
	MCR     p15, 0, r2, c7, c6, 2          // Invalidate line described by r2
	ADD     r1, r1, #1                     // Increment set counter
	CMP     r1, r3                         // Check if the last set is reached...
	BLE     set_loop                       // ...if not, continue the set_loop...
	ADD     r0, r0, #1                     // ...else, Increment way counter
	CMP     r0, #4                         // Check if the last way is reached...
	BLT     way_loop                       // ...if not, continue the way_loop

#ifdef CA9_ENABLE_MMU
	// Invalidate TLBs
	// ------------------
	mov r0, #0x0
	mcr p15, 0, r0, c8, c7, 0     // TLBIALL - Invalidate entire Unifed TLB

	// Set up Domain Access Control Reg
	// ----------------------------------
	// b00 - No Access (abort)
	// b01 - Client (respect table entry)
	// b10 - RESERVED
	// b11 - Manager (ignore access permissions)
	// Setting D0 to client, all others to No Access
	mov r0, #0x01
	//ldr r0, =0x55555555
	mcr p15, 0, r0, c3, c0, 0


mmu_setup_core0:
	// prepare MMU related data in stack
	ldr r0, =mmu_table
	mov r1, #0
	push {r0, r1}
	
	// Initialize the MMU table
	// get r0 and r1 back from stack
	// r0 has the base address
	// r1 has the core number
	ldm sp, {r0, r1} // keep them on the stack for later use
	dsb
	isb
	bl mmu_table_init

	// barrier to make sure write operations got through
	dsb

mmu_setup_common:
	
	// CA9 supports two translation tables
	// Configure translation table base (TTB) control register cp15,c2
	// to a value of all zeros, indicates we are using TTB register 0.
	mov r0, #0x0
	mcr p15, 0, r0, c2, c0, 2

	// Set location of level 1 page table
	// Note: set TTBCR0 and TTBCR1 just to be sure, normally
	// setting TTBCR0 would be sufficient
	// ------------------------------------
	// 31:x  - Base addr (x=14-TBCCR.N; N=0)
	// x:7   - 0x0
	// 6     - IRGN[0] (used together with C)
	// 5     - NOS 0x0 (Not outer sharable)
	// 4:3   - RGN 0x0 (Outer Noncachable)
	// 2     - P   0x0
	// 1     - S   0x0 (Non-shared)
	// 0     - C   0x0 (Inner Noncachable)
	
	// get r0 and r1 back from stack
	// r0 has the base address
	// r1 has the core number
	ldm sp, {r0, r1} // keep them on the stack for later use
	
	ldr r2, =0xffffc000
	and r2, r0, r2
	ldr r3, =0x00000003 // normal mem, shareable, inner write-back write-allocate, outer non-cacheable
	orr r2, r2, r3
	dsb
	mcr p15, 0, r2, c2, c0, 0
	mcr p15, 0, r2, c2, c0, 1

	dsb
	isb

	// Enable MMU
	// ------------
	// 0     - M, set to enable MMU
	// Leaving the caches disabled until after scatter loading.
	mrc p15, 0, r2, c1, c0, 0     // Read current control reg
	orr r2, r2, #0x01             // Set M bit
	mcr p15, 0, r2, c1, c0, 0     // Write reg back

	dsb
	isb

	#ifdef SIM_MESSAGES
	// sim_asm_message("init.s: MMU is up, sim_messages should work now. Core", disp_data, r1);
	#endif

	// remove now unused values from stack
	pop {r0, r1} // keep them on the stack for later use
#endif //ifdef CA9_ENABLE_MMU
#endif //ifndef darm


// enable asynchronous aborts
#ifndef darm
  // sim_asm_message("init.s: Enabling asynchronous aborts.", disp_only, r1);
  cpsie a
  isb
#endif


//-----------------------------------------------------------------------------
// SMP setup
//-----------------------------------------------------------------------------

#ifndef darm
smp_setup_core0:
	// Note: First invalidate SCU stuff, then enable (ARM example did it the other way around, but 
	// according to ARM TRM ch. 5.3.4 "Multiprocessor bring-up" we should do it this way)
	// Invalidate SCU tag RAM (for both cores)
	// ---------
	mov r1, #0x00ff             // invalidate tag RAMs for both cores
	mrc p15, 4, r2, c15, c0, 0  // Read periph base address
	str r1, [r2, #0x0C]         // Write to SCU Invalidate All in Secure State

	// Enable the SCU
	// ---------------
	bl enable_scu

	dsb
	isb

	// Join SMP
	// ---------
	bl join_smp
	bl enable_maintenance_broadcast
#endif //ifndef darm


//-----------------------------------------------------------------------------
// some additional preliminary initialization
//-----------------------------------------------------------------------------
core0_pre_init:
	#ifdef SIM_MESSAGES
	// sim_asm_message("init.s: Back, PC", disp_data, r15);
	#endif

#ifndef darm
#ifdef CA9_ENABLE_CACHES
#ifndef CA9_NO_L2C_ENABLE
  // sim_asm_message("init.s: Enable L2 cache (PL310).", disp_only, r1);
  ldr   r0, =0xFAF10000 // base address
  mov   r1, #0
  str   r1, [r0, #0x100]  // disable controller
  ldr   r1, [r0, #0x104]  // read aux_control register
  orr   r1, r1,  #1<<30   // enable early bresp feature because CA9 supports it
  str   r1, [r0, #0x104]
  ldr   r1, =0xffff
  str   r1, [r0, #0x77c]  // invalidate all ways
l2c_invalidate:
  ldr   r2, [r0, #0x77c]  // poll invalidate_way register
  tst   r2, r1            // wait until all bits are reset
  bne   l2c_invalidate
  mov   r1, #1
  str   r1, [r0, #0x100]  // enable controller
#endif
#endif
#endif //infndef darm


//-----------------------------------------------------------------------------
// jump to C main function
//-----------------------------------------------------------------------------
prepare_jump_to_main:

#ifdef CA9_ENABLE_CACHES
	// Enable dcache
	// icache has been enabled earlier
	// -----------------------
	#ifdef SIM_MESSAGES
	// sim_asm_message("init.s: Enabling data cache.", disp_only, r1);
	#endif
	bl enable_dcache
    
#ifdef CA9_L1C_ECC
	@ enable ECC for L1 cache
	MRC     p15,0,r0,c1,c0,1               // read Aux Control reg
//	ORR     r0,r0,#1<<6                    // set SMP bit
	ORR     r0,r0,#1<<9                    // enable parity
//	ORR     r0,r0,#1<<2                    // L1 prefetch enable
	MCR     p15,0,r0,c1,c0,1               // write Aux Control reg
#endif
#endif //ifdef CA9_ENABLE_CACHES

	@ restore r0/r1
	ldmfd   sp!, {r0, r1}

	bl      ramtest_main

	bl      clean_invalidate_dcache
	bl      disable_caches
	
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
	
	
	.end
