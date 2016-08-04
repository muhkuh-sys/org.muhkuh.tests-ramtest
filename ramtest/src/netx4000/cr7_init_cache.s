// ------------------------------------------------------------
// based on "v7-A Cache and Branch Prediction Maintenance Operations"
// sripped down to cache operations only for v7-R
// ------------------------------------------------------------
.section .text, "ax"
.arm
.global start
start:
.global init_caches_and_branch_prediction
init_caches_and_branch_prediction:
	stmfd   sp!, {r0-r12, lr} 
	//push {r0-r12, lr}
	bl invalidate_and_enable_icache
	bl enable_program_flow_prediction
	bl invalidate_and_enable_dcache
	ldmfd   sp!, {r0-r12, lr}
	//pop {r0-r12, lr}
	bx lr
 	
// ------------------------------------------------------------
// Cache Maintenance
// ------------------------------------------------------------


// ------------------------------------------------------------
.global invalidate_and_enable_icache
// ------------------------------------------------------------
  // void invalidate_and_enable_icache(void);
invalidate_and_enable_icache:
  // prepare the caches before use
  MOV     r0, #0
  MCR     p15, 0, r0, c7, c5, 0   // ICIALLU - Invalidate entire I Cache, and flushes branch target cache

  MRC     p15, 0, r0, c1, c0, 0   // Read System Control Register configuration data
  ORR     r0, r0, #(1 << 12)      // Set I bit
  MCR     p15, 0, r0, c1, c0, 0   // Write System Control Register configuration data
  BX      lr
// ------------------------------------------------------------



// ------------------------------------------------------------
.global invalidate_and_enable_dcache
// ------------------------------------------------------------
  // void invalidate_and_enable_dcache(void);
invalidate_and_enable_dcache:
  PUSH    {r4-r12,lr}
  
  //
  // Based on code example given in section B2.2.4/11.2.4 of ARM DDI 0406B
  //

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
	
// Abweichung zu DDI 0406C	
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

invalidate_dcache_finished:
enable_dcache:
  MRC     p15, 0, r0, c1, c0, 0   // Read System Control Register configuration data
  ORR     r0, r0, #(1 << 2)       // Set C bit
  MCR     p15, 0, r0, c1, c0, 0   // Write System Control Register configuration data

  POP     {r4-r12,lr}
  BX      lr
// ------------------------------------------------------------


// ------------------------------------------------------------
.global enable_program_flow_prediction
// ------------------------------------------------------------
  // void enable_program_flow_prediction(void);
enable_program_flow_prediction:
  // uses only R1, no stack rescue
  MCR p15, 0, R1, c7, c5, 6  // Invalidating branch predictor array

  MRC p15, 0, R1, c1, c0, 0  // read CP15 register 1
  ORR R1, R1, #(1<<11)       // enable Z bit, Enabling program flow prediction
  DSB
  MCR p15, 0, R1, c1, c0, 0  // write CP15 reg
  ISB

  BX      lr
// ------------------------------------------------------------

  .end

// ------------------------------------------------------------
// End of v7.s
// ------------------------------------------------------------
