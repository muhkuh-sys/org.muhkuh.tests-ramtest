#include "netx_io_areas.S"

#include "cr7.S"
  .section .init_code, "ax"
  .arm

  .extern ramtest_main
  .extern stack_top

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
  stmfd   sp!, {r0, r1, r2, r3, r4, lr}

  push {r0, r1}
  
@ =====================================================================
@
@ Disable MPU and cache in case it was left enabled from an earlier run.
@
@ =====================================================================
	/* Read the system control register. */
	mrc     p15, 0, r0, c1, c0, 0

	/* Disable all stuff. */
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_M
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_C
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_Z
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_I
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_V
	bic     r0, r0, #MSK_CR7_CP15_SCTRL_EE

	/* Ensure all previous loads/stores have completed */
	dsb

	mcr     p15, 0, r0, c1, c0, 0
	
	/* Ensure subsequent insts execute wrt new MPU settings. */
	isb


	@ Invalidate the complete branch predictor array.
	mcr     p15, 0, r1, c7, c5, 6



@ =====================================================================
@
@ Setup MPU
@
@ =====================================================================


	// region  0: this is the base region. It is device type to ensure that all accesses are ordered by default.
	MACRO_MPU_REGION  0, 1, 0x00000000, "ffffffff", MPU_MT_Device_NonShareable,          MPU_AP_RW_RW
	
	// region  1: ROM POR, ITCM and DTCM mirror.
	MACRO_MPU_REGION  1, 1, HOSTADDR(CR7_ITCM), "0003ffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RW_RW
	
	// region  2: LLRAM
	MACRO_MPU_REGION  2, 1, HOSTADDR(CR7_llram), "03ffffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RW_RW
	
	// region  3: ROM
	MACRO_MPU_REGION  3, 1, HOSTADDR(CR7_rom), "0001ffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RO_RO
	
	// region  4: SQIROM0 and SQIROM1
	MACRO_MPU_REGION  4, 1, HOSTADDR(NX2RAP_SQIROM0), "07ffffff", MPU_MT_Device_NonShareable,          MPU_AP_RO_RO
	
	// region  5: HIF SDRAM and EXT SDRAM
	MACRO_MPU_REGION  5, 1, HOSTADDR(hif_sdram), "1fffffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RW_RW
	
	// region  6: DDR Lo
	MACRO_MPU_REGION  6, 1, HOSTADDR(NX2RAP_ddr_lo), "3fffffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RW_RW
	
	// region  7: DDR Hi
	MACRO_MPU_REGION  7, 1, HOSTADDR(NX2RAP_ddr_hi), "3fffffff", MPU_MT_Normal_Buffered_NonShareable, MPU_AP_RW_RW
	
	// region  8: off
	MACRO_MPU_REGION  8, 0, 0,                             0,    0,                                   0
	
	// region  9: off
	MACRO_MPU_REGION  9, 0, 0,                             0,    0,                                   0
	
	// region 10: off
	MACRO_MPU_REGION 10, 0, 0,                             0,    0,                                   0
	
	// region 11: off
	MACRO_MPU_REGION 11, 0, 0,                             0,    0,                                   0
	
	// region 12: off
	MACRO_MPU_REGION 12, 0, 0,                             0,    0,                                   0
	
	// region 13: off
	MACRO_MPU_REGION 13, 0, 0,                             0,    0,                                   0
	
	// region 14: off
	MACRO_MPU_REGION 14, 0, 0,                             0,    0,                                   0
	
	// region 15: off
	MACRO_MPU_REGION 15, 0, 0,                             0,    0,                                   0
	
	
	

@ =====================================================================
@
@ Enable the MPU.
@
@ =====================================================================
	/* Enable the MPU and branch prediction.
	 * NOTE: enable I and D caches later.
	 */
	mrc     p15, 0, r0, c1, c0, 0
	orr     r0, r0, #MSK_CR7_CP15_SCTRL_M
	orr     r0, r0, #MSK_CR7_CP15_SCTRL_Z

	/* Ensure all previous loads/stores have completed */
	dsb

	mcr     p15, 0, r0, c1, c0, 0
	isb

	
// ------------------------------------------------------------
// Cache Maintenance
// ------------------------------------------------------------
  
  @ Invalidate icache
  MOV     r0, #0
  MCR     p15, 0, r0, c7, c5, 0   // ICIALLU - Invalidate entire I Cache, and flushes branch target cache
  
  @ Enable icache
  MRC     p15, 0, r0, c1, c0, 0   // Read System Control Register configuration data
  ORR     r0, r0, #(1 << 12)      // Set I bit
  MCR     p15, 0, r0, c1, c0, 0   // Write System Control Register configuration data
  
  @ Enable program flow prediction
  MCR p15, 0, R1, c7, c5, 6  // Invalidating branch predictor array

  MRC p15, 0, R1, c1, c0, 0  // read CP15 register 1
  ORR R1, R1, #(1<<11)       // enable Z bit, Enabling program flow prediction
  DSB
  MCR p15, 0, R1, c1, c0, 0  // write CP15 reg
  ISB
  
  @ Invalidate data cache
  @
  @ Based on code example given in section B2.2.4/11.2.4 of ARM DDI 0406B
  @
  MRC     p15, 1, r0, c0, c0, 1     // Read CLIDR
  ANDS    r3, r0, #0x7000000
  MOV     r3, r3, LSR #23           // Cache level value (naturally aligned)
  BEQ     invalidate_dcache_finished
  MOV     r10, #0

invalidate_dcache_loop1:
  ADD     r8, r10, r10, LSR #1      // Work out 3xcachelevel
  MOV     r1, r0, LSR r8            // bottom 3 bits are the Cache type for this level
  AND     r1, r1, #7                // get those 3 bits alone
  CMP     r1, #2
  BLT     invalidate_dcache_skip    // no cache or only instruction cache at this level
  MCR     p15, 2, r10, c0, c0, 0    // write the Cache Size selection register
  ISB                               // ISB to sync the change to the CacheSizeID reg
  MRC     p15, 1, r1, c0, c0, 0     // reads current Cache Size ID register
  AND     r8, r1, #0x7              // extract the line length field
  ADD     r8, r8, #4                // add 4 for the line length offset (log2 16 bytes)
  LDR     r4, =0x3FF
  ANDS    r4, r4, r1, LSR #3        // R4 is the max number on the way size (right aligned)
  CLZ     r5, r4                    // R5 is the bit position of the way size increment
  
// differs from example in DDI 0406C  
  LDR     r7, =0x00007FFF
  ANDS    r7, r7, r1, LSR #13       // R7 is the max number of the index size (right aligned)

invalidate_dcache_loop2:
  MOV     r9, R4                    // R9 working copy of the max way size (right aligned)

invalidate_dcache_loop3:
  ORR     r11, r10, r9, LSL r5      // factor in the way number and cache number into R11
  ORR     r11, r11, r7, LSL r8      // factor in the index number
  MCR     p15, 0, r11, c7, c6, 2    // DCISW - invalidate by set/way
  SUBS    r9, r9, #1                // decrement the way number
  BGE     invalidate_dcache_loop3

  SUBS    r7, r7, #1                // decrement the index
  BGE     invalidate_dcache_loop2

invalidate_dcache_skip:
  ADD     r10, r10, #2              // increment the cache number
  CMP     r3, r10
  BGT     invalidate_dcache_loop1
  DSB                             // *SL
invalidate_dcache_finished:

  @ Enable dcache
  MRC     p15, 0, r0, c1, c0, 0   // Read System Control Register configuration data
  ORR     r0, r0, #(1 << 2)       // Set C bit
	DSB                             // *SL
  MCR     p15, 0, r0, c1, c0, 0   // Write System Control Register configuration data
  
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

  .endfunc

@--------------------------------------

  .end


  
  
