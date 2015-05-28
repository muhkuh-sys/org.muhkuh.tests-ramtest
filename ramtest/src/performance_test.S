@ Core routines for RAM performance test
@ SL Apr 30, 2015

/*
	Initialization
	Currently, no explicit initialization is taking place.
	The performance test is run via the romcode and the muhkuh framework.
	On the netX 500, the cache is off. On the other netX types, there are no caches.
	On the netX 50, the SDRAM fix is performed by the plugin.
*/

#include "netx_io_areas.S"

	.text
	.arm
	.altmacro

.global ram_perftest_seq_R8   
.global ram_perftest_seq_R16  
.global ram_perftest_seq_R32  
.global ram_perftest_seq_R256
.global ram_perftest_seq_W8  
.global ram_perftest_seq_W16  
.global ram_perftest_seq_W32  
.global ram_perftest_seq_W256
.global ram_perftest_seq_RW8  
.global ram_perftest_seq_RW16 
.global ram_perftest_seq_RW32 
.global ram_perftest_seq_RW256
.global ram_perftest_row_R8   
.global ram_perftest_row_R16  
.global ram_perftest_row_R32  
.global ram_perftest_row_R256
.global ram_perftest_row_W8   
.global ram_perftest_row_W16  
.global ram_perftest_row_W32  
.global ram_perftest_row_W256 
.global ram_perftest_row_RW8  
.global ram_perftest_row_RW16 
.global ram_perftest_row_RW32 
.global ram_perftest_row_RW256  
.global ram_perftest_seq_nop
.global ram_perftest_row_jump

.global ram_perftest_get_row_size
.global ram_perftest_get_refresh_time
.global ram_perftest_init_netx

ram_perftest_init_netx:
#if ASIC_TYP==500 || ASIC_TYP==100
Mode_SVC            = 0x13        
I_Bit               = 0x80 @ when I bit is set, IRQ is disabled
F_Bit               = 0x40 @ when F bit is set, FIQ is disabled
Adr_vic_int_enclear = 0x001FF014 @ Adr_NX500_vic_vic_int_enclear
Adr_dTCM_base       = 0x10000000 @ Adr_NX500_dTCM_base

	stmfd	sp!, {r0, r1, r2}
	
@ ################## configure all relevant ARM Coprocessor register  #####################################
	MOV     ip, #I_Bit | F_Bit | Mode_SVC   @ go to supervisor mode and keep interrupts disabled
	MSR     cpsr_c, ip
	
	MOV     ip, #0
	MCR     p15, 0, ip, c7, c7, 0           @ invalidate Instruction and Data caches
	MCR     p15, 0, ip, c7, c10, 4          @ drain the Write buffer, to be sure not to have data in pipe
	MCR     p15, 0, ip, c8, c7, 0           @ invalidate Instruction and Data Translation Lookaside Buffers
	MRC     p15, 0, ip, c1, c0, 0           @ get the ctrl register
	BIC     ip, ip, #0x0007                 @ .............cam   disable MMU, disable Alignment checking, disable D-Cache
	BIC     ip, ip, #0x1100                 @ ...i...s........   disable System Protection, disable I-Cache
	MCR     p15, 0, ip, c1, c0, 0           @ write ctrl register

@ ################## clear all pending interrupts  #####################################
	LDR     r1, =Adr_vic_int_enclear        @ clear all interrupts first
	LDR     r2, =0xFFFFFFFF                 @ load the interrupt mask
	STR     r2, [r1]
@ ################## enable the tighly coupled memory now #####################################
	LDR     r0, =Adr_dTCM_base              @ load the Tighly coupled Memory base address
	ORR     r0, r0, #1                      @ add the enable bit to the base address
	MCR     p15, 0, r0, c9, c1, 0           @ Enable the tightly coupled memory
	
	ldmfd   sp!, {r0, r1, r2}
	bx      lr
	
#elif ASIC_TYP==50
	
#elif ASIC_TYP==10
		
#elif ASIC_TYP==56

#define SR_Mode_SVC  0x13
#define SR_Irq       0x80
#define SR_Fiq       0x40
	stmfd	sp!, {r0, r1}
	
	@ enable svc mode and disable irq and fiq
	msr     cpsr_c, #SR_Irq|SR_Fiq|SR_Mode_SVC

	@ clear data pipe
	mcr     p15,    0, r1, c7, c10, 4

	@ set the ctrl register to ...
	@ TBIT enable (#15 = 0)
	@ disable ITCM (#12 = 0)
	@ little endianess (#7 = 0)
	@ enable buffered writes in bufferable areas (#3 = 1)
	@ disable DTCM (#2 = 0)
	@ disable alignment check (#1 = 0)
	ldr     r0,     =0x0f78
	mcr     p15,    0, r0, c1, c0, 0

	@ NOTE: r1 must be 0 here
	ldr     r1,     =0
	
	@ Disable intram parity check.
	ldr     r0,     =HOSTADDR(parity)
	str     r1,     [r0, #HOSTREL(parity_enable)]
	str     r1,     [r0, #HOSTREL(parity_abort_enable)]

	ldr     r0,     =HOSTADDR(vic)
	@ init vic registers
	mvn     r1,     r1
	@ disable all irqs
	str     r1,     [r0, #HOSTREL(vic_int_enclear)]
	str     r1,     [r0, #HOSTREL(vic_softint_clear)]

	ldmfd	sp!, {r0, r1}
	bx      lr
#endif



@--------------------------------------
@ Get the time for a complete refresh based on the current SDRAM controller settings.
@ Note: This assumes the MEM SDRAM controller and does not work if the test 
@       is to be run on HIF SDRAM.
@
@ Return value:
@ r0: time in clock cycles in r0 (100 MHz)
@
@ Uses r0, r1, r2
@
@ refresh time = #rows * #banks * t_refi
@ Worst case:    64k     8        32 microseconds = 2^(16+3+5) = 2^24 microseconds = 16s

ram_perftest_get_refresh_time:
	stmfd	sp!, {r1, r2}
	
	ldr r1, =HOSTADDR(ext_sdram_ctrl)
	mov r0, #100 /* r0 = 100 clock cycles (= 1 microsecond) */
	
	@ t_REFI
	ldr r2, [r1, #HOSTREL(sdram_timing_ctrl)]
	and r2, r2, #HOSTMSK(sdram_timing_ctrl_t_REFI)
	lsr r2, r2, #HOSTSRT(sdram_timing_ctrl_t_REFI)
	add r2, r2, #2 /* 0 = 3.9 microseconds */
	lsl r0, r2 /* r0 = r0 * microseconds per refresh */
	
	@ number of rows
	ldr r2, [r1, #HOSTREL(sdram_general_ctrl)]
	and r2, r2, #HOSTMSK(sdram_general_ctrl_rows)
	lsr r2, r2, #HOSTSRT(sdram_general_ctrl_rows)
	add r2, r2, #11 /* 0 = 2048 rows */
	lsl r0, r2 /* r0 = r0 * rows/bank */
	
	@ number of banks
	ldr r2, [r1, #HOSTREL(sdram_general_ctrl)]
	and r2, r2, #HOSTMSK(sdram_general_ctrl_banks)
	lsr r2, r2, #HOSTSRT(sdram_general_ctrl_banks)
	add r2, r2, #1 /* 0 = 2 banks */
	lsl r0, r2 /* r0 = r0 * number of banks */
	
	ldmfd	sp!, {r1, r2}
	bx lr

	
@--------------------------------------
@ Get the row size in bytes based on the current SDRAM controller settings.
@ Note: This assumes the MEM SDRAM controller and does not work if the test 
@       is to be run on HIF SDRAM.
@
@ Return value:
@  r0 : row size
@
@ Uses r0, r1

@ row length = number of columns * bus width (1/2/4 bytes)

ram_perftest_get_row_size:
	stmfd	sp!, {r1}
	
	@ r1 = sdram_general_ctrl
	ldr r1, =HOSTADDR(ext_sdram_ctrl)
	ldr r1, [r1, #HOSTREL(sdram_general_ctrl)]
	
	@ r0 = number of columns
	@ ((sdram_general_ctrl_columns+1) * 256)
	and r0, r1, #HOSTMSK(sdram_general_ctrl_columns)
	lsr r0, r0, #HOSTSRT(sdram_general_ctrl_columns)
	add r0, r0, #1
	lsl r0, r0, #8
	
	@ multiply with 2 or 4 (netx 10: 1 or 2) bytes bus width
	.if HOST==NX10
	and r1, r1, #HOSTMSK(sdram_general_ctrl_dbus16)
	lsr r1, r1, #HOSTSRT(sdram_general_ctrl_dbus16)
	lsl r0, r0, r1
	.else
	and r1, r1, #HOSTMSK(sdram_general_ctrl_dbus32)
	lsr r1, r1, #HOSTSRT(sdram_general_ctrl_dbus32)
	add r1, r1, #1
	lsl r0, r0, r1
	.endif
	
	ldmfd	sp!, {r1}
	bx lr


	
@--------------------------------------
@ Configure GPIO counter 0 for counting clock cycles.
@ The counter is stopped.
@
@ Uses r4, r5

ram_perftest_init_counter0:
	ldr r4, =HOSTADDR(gpio)
	ldr r5, =0
	str r5, [r4, #HOSTREL(gpio_counter0_ctrl)]
	str r5, [r4, #HOSTREL(gpio_counter0_cnt)]
	ldr r5, =0xffffffff
	str r5, [r4, #HOSTREL(gpio_counter0_max)]
	bx lr

@--------------------------------------
@ Start GPIO counter 0 and wait until it exceeds the given value.
@ The counter must be initialized and stopped.
@
@ Parameters:
@  r3 : compare value
@
@ Uses r4, r5

ram_perftest_delay_counter0:
	ldr r4, =HOSTADDR(gpio)
	ldr r5, =1
	str r5, [r4, #HOSTREL(gpio_counter0_ctrl)]
wait_loop:
	ldr r5, [r4, #HOSTREL(gpio_counter0_cnt)]
	cmp r5, r3
	bls wait_loop
	bx	lr


.altmacro
@--------------------------------------
@ Start GPIO counter 0.
@
@ Uses r4, r5

.macro m_start_counter0
	ldr r4, =HOSTADDR(gpio)
	ldr r5, =1
	str r5, [r4, #HOSTREL(gpio_counter0_ctrl)]
.endm

@--------------------------------------
@ Stop GPIO timer 0 and return value in r0.
@
@ Uses r0, r1
.macro m_stop_counter0
	ldr r1, =HOSTADDR(gpio)
	ldr r0, =0
	str r0, [r1, #HOSTREL(gpio_counter0_ctrl)]
	ldr r0, [r1, #HOSTREL(gpio_counter0_cnt)]
.endm

@--------------------------------------
R8    = 1
R16   = 2
R32   = 3
R256  = 4
W8    = 5
W16   = 6
W32   = 7
W256  = 8
RW8   = 9
RW16  = 10
RW32  = 11
RW256 = 12

/*
@ Sequential read/write test.
@
@ Parameters:
@  r0 : start address
@  r1 : end address
@  r2 : row size (not used)
@  r3 : refresh delay in clocks 
@ 
@ Return value:
@  r0 : >0 time in clock cycles, =0 error
@
@ Uses r0-r12
*/

.macro ram_perftest_seq accessmode
	LOCAL loop
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bl ram_perftest_init_counter0
	bl ram_perftest_delay_counter0
	bl ram_perftest_init_counter0
	m_start_counter0

loop:
	.if accessmode == R8
	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
@	ldrb r4, [r0], #1
	.elseif accessmode == R16
	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
@	ldrh r4, [r0], #2
	.elseif accessmode == R32
	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
@	ldr r4, [r0], #4
	.elseif accessmode == R256
	ldmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.elseif accessmode == W8
	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
@	strb r4, [r0], #1
	.elseif accessmode == W16
	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
@	strh r4, [r0], #2
	.elseif accessmode == W32
	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
@	str r4, [r0], #4
	.elseif accessmode == W256
	stmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.elseif accessmode == RW8
	ldrb r4, [r0]
	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
@	ldrb r4, [r0]
@	strb r4, [r0], #1
	.elseif accessmode == RW16
	ldrh r4, [r0]
	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
@	ldrh r4, [r0]
@	strh r4, [r0], #2
	.elseif accessmode == RW32
	ldr r4, [r0]
	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
@	ldr r4, [r0]
@	str r4, [r0], #4
	.elseif accessmode == RW256
	ldm r0, {r4, r5, r6, r7, r8, r9, r10, r11}
	stmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.endif
	
	cmp r0, r1
	bls loop
	
	m_stop_counter0
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr
.endm


ram_perftest_seq_R8:   ram_perftest_seq R8
ram_perftest_seq_R16:  ram_perftest_seq R16
ram_perftest_seq_R32:  ram_perftest_seq R32
ram_perftest_seq_R256: ram_perftest_seq R256
ram_perftest_seq_W8:   ram_perftest_seq W8
ram_perftest_seq_W16:  ram_perftest_seq W16
ram_perftest_seq_W32:  ram_perftest_seq W32
ram_perftest_seq_W256: ram_perftest_seq W256
ram_perftest_seq_RW8:  ram_perftest_seq RW8
ram_perftest_seq_RW16: ram_perftest_seq RW16
ram_perftest_seq_RW32: ram_perftest_seq RW32
ram_perftest_seq_RW256:ram_perftest_seq RW256

@ --------------------------------------
@  Row-by-row read/write test.
@  Increments the address by one row after each access.
@  Makes several passes with increasing offsets into the rows.
@ 
@  Parameters:
@   r0 : start address
@   r1 : end address
@   r2 : row size 
@   r3 : refresh delay in clocks 
@  
@  Return value:
@   r0 : >0 time in clock cycles, =0 error
@ 
@  Uses r0-r12
@ 
@  Work registers:
@  r3 : row offset
@  r4 : address
@  r5-r12: load/store


.macro ram_perftest_row accessmode
	LOCAL loop_pass
	LOCAL loop_row
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bl ram_perftest_init_counter0
	bl ram_perftest_delay_counter0
	bl ram_perftest_init_counter0
	m_start_counter0
	
	@ row offset = 0
	mov r3, #0
	
loop_pass:
	@ address = start address + row offset
	add r4, r0, r3
	
loop_row:
	@ load/store, inc address
	.if accessmode == R8
	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
@	ldrb r5, [r4], r2
	.elseif accessmode == R16
	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
@	ldrh r5, [r4], r2
	.elseif accessmode == R32
	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
@	ldr r5, [r4], r2
	.elseif accessmode == R256
	ldm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	add r4, r4, r2
	.elseif accessmode == W8
	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
@	strb r5, [r4], r2
	.elseif accessmode == W16
	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
@	strh r5, [r4], r2
	.elseif accessmode == W32
	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
@	str r5, [r4], r2
	.elseif accessmode == W256
	stm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	add r4, r4, r2
	.elseif accessmode == RW8
	ldrb r5, [r4]
	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
@	ldrb r5, [r4]
@	strb r5, [r4], r2
	.elseif accessmode == RW16
	ldrh r5, [r4]
	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
@	ldrh r5, [r4]
@	strh r5, [r4], r2
	.elseif accessmode == RW32
	ldr r5, [r4]
	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
@	ldr r5, [r4]
@	str r5, [r4], r2
	.elseif accessmode == RW256
	ldm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	stm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	add r4, r4, r2
	.endif
	
	@ loop until address >= end address
	cmp r4, r1
	bls loop_row
	
	@ increment row offset by 1/2/4/8
	.if accessmode == R8 || accessmode == W8 || accessmode == RW8
	add r3, r3, #1
	.elseif accessmode == R16 || accessmode == W16 || accessmode == RW16
	add r3, r3, #2
	.elseif accessmode == R32 || accessmode == W32 || accessmode == RW32
	add r3, r3, #4
	.elseif accessmode == R256 || accessmode == W256 || accessmode == RW256
	add r3, r3, #8
	.endif
	
	@ loop until row offset >= row size
	cmp r3, r2
	bls loop_pass

	m_stop_counter0
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr
.endm


ram_perftest_row_R8:   ram_perftest_row R8
ram_perftest_row_R16:  ram_perftest_row R16
ram_perftest_row_R32:  ram_perftest_row R32
ram_perftest_row_R256: ram_perftest_row R256
ram_perftest_row_W8:   ram_perftest_row W8
ram_perftest_row_W16:  ram_perftest_row W16
ram_perftest_row_W32:  ram_perftest_row W32
ram_perftest_row_W256: ram_perftest_row W256
ram_perftest_row_RW8:  ram_perftest_row RW8
ram_perftest_row_RW16: ram_perftest_row RW16
ram_perftest_row_RW32: ram_perftest_row RW32
ram_perftest_row_RW256:ram_perftest_row RW256

@--------------------------------------
@ Parameters:
@  r0 : start address
@  r1 : end address
@  r2 : row size 
@  r3 : refresh delay in clocks 
@
@ Return value:
@  r0 : >0 time in clock cycles, =0 error
@
@ Uses r0-r5
@ 
@ r4 : address
@ r5 : opcode

ram_perftest_seq_nop:
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

	mov r4, r0
	mov r5, r1
	ldr r6, =opcode_addr_nop
	bl fill_code 
	
	ldr r5, =opcode_addr_bx_lr
	ldrh r5, [r5]
	strh r5, [r4], #2

	bl ram_perftest_init_counter0
	bl ram_perftest_delay_counter0
	bl ram_perftest_init_counter0
	m_start_counter0
	orr r0, r0, #1
	blx r0
	m_stop_counter0
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr
	
	

@--------------------------------------
@ Parameters:
@  r0 : start address
@  r1 : end address
@  r2 : row size 
@  r3 : refresh delay in clocks 


@		0		1		2			m
@	0	b 10	b 11	b 12...	b 1m
@	1	b 20	b 21	b 22...	b 2m
@	2	b 30	b 31	b 32...	b 3m
@	3	b 40	b 41	b 42...
@	...
@	n	b 01	b 02	b 03...	bx lr


ram_perftest_row_jump:
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

	@ fill with 'add PC, r4'. 
	@ r4 will contain the jump distance to the next row.
	mov r4, r0
	mov r5, r1
	ldr r6, =opcode_addr_add_pc_r4
	bl fill_code
	
	@ fill the last row of the range with 'add PC, r5'. 
	@ r5 will contain the (negative) jump distance to the start of the next column.
	sub r4, r1, r2
	mov r5, r1
	ldr r6, =opcode_addr_add_pc_r5
	bl fill_code
	
	bl ram_perftest_init_counter0
	bl ram_perftest_delay_counter0
	bl ram_perftest_init_counter0
	m_start_counter0
	
	@ set r4 with jump distance from row to row
	sub r4, r2, #4
	
	@ set r5 with jump distance back to beginning of next 2 byte column
	sub r5, r0, r1
	add r5, r5, r2
	sub r5, r5, #2
	
	orr r0, r0, #1
	blx r0
	m_stop_counter0
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx	lr
	
	
	
@--------------------------------------
@ Fill a memory area with a 2-byte thumb instruction
@ and put "bx lr" into the last word.
@
@ Parameters:
@ r4 : destination address
@ r5 : end address + 1
@ r6 : pointer to thumb instruction
@
@ uses r4-r6

fill_code:
	ldrh r6, [r6]
fill_code_loop:
	strh r6, [r4], #2
	cmp r4, r5
	bcc fill_code_loop
	
	@ put the return instruction at the end
	sub r4, r4, #2
	ldr r6, =opcode_addr_bx_lr
	ldrh r6, [r6]
	strh r6, [r4], #2
	bx lr
	
	.thumb
opcode_addr_nop:
	nop
opcode_addr_add_pc_r4:
	add pc, r4
opcode_addr_add_pc_r5:
	add pc, r5
opcode_addr_bx_lr:
	bx lr
	
.end

