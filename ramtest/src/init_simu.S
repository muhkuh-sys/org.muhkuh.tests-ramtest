#include "netx_io_areas.S"

	.section .init_code, "ax"
	.arm

	.extern ramtest_main
	.extern stack_top

	.global start


@--------------------------------------

  .func start_init_s

start:
	stmfd   sp!, {r0, r1, r2, r3, r4, lr}

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

	bl      main

  .endfunc

@--------------------------------------

  .end

