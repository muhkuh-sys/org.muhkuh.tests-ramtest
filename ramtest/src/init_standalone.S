#include "asic_types.h"
#include "netx_io_areas.S"

	.section .init_code, "ax"

@ The Cortex-M4 in the netX90 is a THUMB-only CPU.
@ All others start in 32 bit mode.
#if ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
        .syntax unified
        .thumb
#else
        .arm
#endif

	.extern ramtest_main
	.extern stack_top

	.global start

   @ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
   @ define entry point for CA9_core0
	.global start_core0
   @ define entry point for CA9_core1
	.global start_core1
#endif

@--------------------------------------

	@ optional can be used by python script to define individual entry points for cortex CA9 core0/1
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
	@ define entry point for CA9_core0
start_core0:
	@ define entry point for CA9_core1
start_core1:
#endif 

    .func start, start
    .type start, STT_FUNC
start:
	push    {r0, r1, r2, r3, r4, lr}

#if ASIC_TYP==ASIC_TYP_NETX50
	@ SDRAM fix
	@ Setup the DMA controller to stop the fake transfer at 0x800DEAD0.
	ldr     r2,     =HOSTADDR(dmac_ch0)
	ldr     r3,     =HOSTADDR(dmac_reg)
	
	ldr     r4,     =0x00000001
	str     r4,     [r3, #0x30]    /* Enable DMA controller generally */
	
	ldr     r4,     =0xBFFFFFFC
	str     r4,     [r2, #0x04]    /* DMA Target address = physical end of SDRAM area */
	
	ldr     r4,     =0x00480001
	str     r4,     [r2, #0x0C]    /* Setup DMA transfer (memory cycle) */
	
	ldr     r4,     =0x00000001
	str     r4,     [r2, #0x10]    /* Start DMA transfer*/
	
	ldr     r4,     =0x00000000
	str     r4,     [r2, #0x0C]    /* Stop and disable DMA */
	str     r4,     [r2, #0x10]
	str     r4,     [r3, #0x30]    /* Disable DMA controller */
#endif

	@ Set own stack position
	ldr     r2, =stack_top
	mov     sp, r2

	@ Clear the .bss section.
	mov     r2, #0
	ldr     r3, =__bss_start__
	ldr     r4, =__bss_end__
clear_bss:
	str     r2, [r3], #4
	cmp     r3, r4
	bmi     clear_bss

	bl      ramtest_main

  .endfunc

@--------------------------------------

  .end

