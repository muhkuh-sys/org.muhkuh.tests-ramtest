@ core routines for RAM performance test
@ SL Apr 23, 2015

@ todo:
@ netx Initialisierung - Caches aus
@ Bei Variante Row: ein Durchlauf mit Offset 0, einer mit Offset 1/2/4/32 usw.
@ Best Case Codeausfuehrung aus SDRAM: NOP-Folge als Thumb
@ Worst Case Codeausfuehrung aus SDRAM: Sprung von Row zu Row (Thumb) (optional)
@ row size/refresh time in C Code setzen und ausgeben

#include "netx_io_areas.S"

	.text
	.arm

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

@--------------------------------------

@ Setup GPIO counter 0 to count cycles
@ Uses r4, r5

ram_perftest_start_time:
	ldr r4, =HOSTADDR(gpio)
	ldr r5, =0
	str r5, [r4, #HOSTREL(gpio_counter0_ctrl)]
	str r5, [r4, #HOSTREL(gpio_counter0_cnt)]
	ldr r5, =0xffffffff
	str r5, [r4, #HOSTREL(gpio_counter0_max)]
	ldr r5, =1
	str r5, [r4, #HOSTREL(gpio_counter0_ctrl)]
	bx lr
	
@--------------------------------------

@ Stop GPIO counter 0 and return its value in r0
@ Uses r0, r1
ram_perftest_end_time:
	ldr r1, =HOSTADDR(gpio)
	ldr r0, =0
	str r0, [r1, #HOSTREL(gpio_counter0_ctrl)]
	ldr r0, [r1, #HOSTREL(gpio_counter0_cnt)]
	bx lr

	
@--------------------------------------

@ Get refresh time based on current SDRAM controller settings
@ Returns time in clock cycles (100 MHz)
@ refresh time = #rows * #banks * t_refi
@ Worst case:    64k     8        32 microseconds = 2^(16+3+5) = 2^24 microseconds = 16s
@ Uses r4-r6
ram_perftest_get_refresh_time:
	@ r4 = sdram_general_ctrl
	ldr r4, =HOSTADDR(ext_sdram_ctrl)
	mov r5, #100 /* r5 = 100 clock cycles (= 1 microsecond) */
	
	@ t_REFI
	ldr r6, [r4, #HOSTREL(sdram_timing_ctrl)]
	and r6, r6, #HOSTMSK(sdram_timing_ctrl_t_REFI)
	lsr r6, r6, #HOSTSRT(sdram_timing_ctrl_t_REFI)
	add r6, r6, #2 /* 0 = 3.9 microseconds */
	lsl r5, r6 /* r5 = r5 * microseconds per refresh */
	
	@ number of rows
	ldr r6, [r4, #HOSTREL(sdram_general_ctrl)]
	and r6, r6, #HOSTMSK(sdram_general_ctrl_rows)
	lsr r6, r6, #HOSTSRT(sdram_general_ctrl_rows)
	add r6, r6, #11 /* 0 = 2048 rows */
	lsl r5, r6 /* r5 = r5 * rows/bank */
	
	@ number of banks
	ldr r6, [r4, #HOSTREL(sdram_general_ctrl)]
	and r6, r6, #HOSTMSK(sdram_general_ctrl_banks)
	lsr r6, r6, #HOSTSRT(sdram_general_ctrl_banks)
	add r6, r6, #1 /* 0 = 2 banks */
	lsl r5, r6 /* r5 = r5 * number of banks */

	bx lr

@--------------------------------------
@ (sdram_general_ctrl.rows+1) * 2k 
@ quick hack: wait 64 ms
ram_perftest_wait_refresh:
	stmfd	sp!, {r4, r5, r6, lr}
	bl ram_perftest_start_time
	bl ram_perftest_get_refresh_time
	mov r6, r5
	ldr r4, =HOSTADDR(gpio)
wait_loop:
	ldr r5, [r4, #HOSTREL(gpio_counter0_cnt)]
	cmp r5, r6
	bls wait_loop
	ldmfd	sp!, {r4, r5, r6,  lr}
	bx	lr
	
@--------------------------------------

@ row length = number of columns * number of data bits

ram_perftest_get_row_size:
	@ r4 = sdram_general_ctrl
	ldr r4, =HOSTADDR(ext_sdram_ctrl)
	ldr r4, [r4, #HOSTREL(sdram_general_ctrl)]
	
	@ number of columns
	@ r5 = sdram_general_ctrl_columns * 256
	and r5, r4, #HOSTMSK(sdram_general_ctrl_columns)
	lsr r5, r5, #HOSTSRT(sdram_general_ctrl_columns)
	add r5, r5, #1
	lsl r5, r5, #8
	
	@ number of data bits
	@ r6 = sdram_general_ctrl_dbus32 + 4
	.if HOST==NX10
	and r6, r4, #HOSTMSK(sdram_general_ctrl_dbus16)
	lsr r6, r6, #HOSTSRT(sdram_general_ctrl_dbus16)
	add r6, r6, #3
	.else
	and r6, r4, #HOSTMSK(sdram_general_ctrl_dbus32)
	lsr r6, r6, #HOSTSRT(sdram_general_ctrl_dbus32)
	add r6, r6, #4
	.endif
	
	@ r5 = r5 << r6 (multiply number of 
	lsl r2, r5, r6
	bx lr
	

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

.altmacro
@ sequential test
@ r0 : start address
@ r1 : end address
@ r2 : unused
@ r3 : pointer to timer value
@ r4-r12: scratch

.macro ram_perftest_seq accessmode
	LOCAL loop
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bl ram_perftest_wait_refresh
	bl ram_perftest_start_time
	
loop:
	.if accessmode == R8
	ldrb r4, [r0], #1
	.elseif accessmode == R16
	ldrh r4, [r0], #2
	.elseif accessmode == R32
	ldr r4, [r0], #4
	.elseif accessmode == R256
	ldmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.elseif accessmode == W8
	strb r4, [r0], #1
	.elseif accessmode == W16
	strh r4, [r0], #2
	.elseif accessmode == W32
	str r4, [r0], #4
	.elseif accessmode == W256
	stmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.elseif accessmode == RW8
	ldrb r4, [r0]
	strb r4, [r0], #1
	.elseif accessmode == RW16
	ldrh r4, [r0]
	strh r4, [r0], #2
	.elseif accessmode == RW32
	ldr r4, [r0]
	str r4, [r0], #4
	.elseif accessmode == RW256
	ldm r0, {r4, r5, r6, r7, r8, r9, r10, r11}
	stmia r0!, {r4, r5, r6, r7, r8, r9, r10, r11}
	.endif
	
	cmp r0, r1
	bls loop
	
	bl ram_perftest_end_time
	str r0, [r3]
	
	mov	r0, #0				@ set return value to 0
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


@--------------------------------------
@ Increment the address by one row after each access.
@ Make several passes with increasing offsets into the rows.

@ Parameters:
@ r0 : start address
@ r1 : end address
@ r2 : row size
@ r3 : pointer to return value (elapsed time)

@ Work registers:
@ r3 : row offset
@ r4 : address
@ r5-r12: load/store
.macro ram_perftest_row accessmode
	LOCAL loop_pass
	LOCAL loop_row
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bl ram_perftest_wait_refresh
	bl ram_perftest_get_row_size
	bl ram_perftest_start_time
	
	@ row offset = 0
	mov r3, #0
	
loop_pass:
	@ address = start address + row offset
	add r4, r0, r3
	
loop_row:
	@ load/store, inc address
	.if accessmode == R8
	ldrb r5, [r4], r2
	.elseif accessmode == R16
	ldrh r5, [r4], r2
	.elseif accessmode == R32
	ldr r5, [r4], r2
	.elseif accessmode == R256
	ldm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	add r4, r4, r2
	.elseif accessmode == W8
	strb r5, [r4], r2
	.elseif accessmode == W16
	strh r5, [r4], r2
	.elseif accessmode == W32
	str r5, [r4], r2
	.elseif accessmode == W256
	stm r4, {r5, r6, r7, r8, r9, r10, r11, r12}
	add r4, r4, r2
	.elseif accessmode == RW8
	ldrb r5, [r4]
	strb r5, [r4], r2
	.elseif accessmode == RW16
	ldrh r5, [r4]
	strh r5, [r4], r2
	.elseif accessmode == RW32
	ldr r5, [r4]
	str r5, [r4], r2
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

	bl ram_perftest_end_time
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	str r0, [r3]
	
	mov	r0, #0				@ set return value to 0
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
@ r0 : start address
@ r1 : end address
@ r2 : unused
@ r3 : pointer to timer value
@ r4-r12: scratch

@ r4 : address
@ r5 : opcode
ram_perftest_seq_nop:
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

	ldr r5, =opcode_addr_nop
	ldrh r5, [r5]
	mov r4, r0
gen_nop_loop:
	strh r5, [r4], #2
	cmp r4, r1
	bls gen_nop_loop
	
	ldr r5, =opcode_addr_bx_lr
	ldrh r5, [r5]
	strh r5, [r4], #2
	
	bl ram_perftest_wait_refresh
	bl ram_perftest_start_time
	orr r0, r0, #1
	blx r0
	bl ram_perftest_end_time
	
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	str r0, [r3]
	
	mov	r0, #0				@ set return value to 0
	bx	lr
	
	
	.thumb
opcode_addr_nop:
	nop
opcode_addr_bx_lr:
	bx lr

	



.end

