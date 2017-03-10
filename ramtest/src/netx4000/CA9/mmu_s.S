/* strongly ordered: One access at a time */
#define MT_STRONGLY_ORDERED          (MSK_MMU_ENTRY_S) /* shareable */

/* device: Number, size and order of accesses are preserved */
#define MT_DEVICE                    (MSK_MMU_ENTRY_S | MSK_MMU_ENTRY_B) /* shareable and bufferable */

/* normal: Accesses may be combined and/or repeated, speculative reads are allowed */
#define MT_NORMAL                    (0x1 << SRT_MMU_ENTRY_TEX)  /* normal, non-cacheable, non-shareable */
#define MT_NORMAL_CACHED             ((0x1 << SRT_MMU_ENTRY_TEX) | MSK_MMU_ENTRY_B | MSK_MMU_ENTRY_C)  /* normal, Outer and Inner write-back, write-allocate, non-shareable */
#define MT_NORMAL_SHARED             ((0x1 << SRT_MMU_ENTRY_TEX) | MSK_MMU_ENTRY_S)  /* normal, non-cacheable, shareable */
#define MT_NORMAL_CACHED_SHARED      ((0x1 << SRT_MMU_ENTRY_TEX) | MSK_MMU_ENTRY_B | MSK_MMU_ENTRY_C | MSK_MMU_ENTRY_S)  /* normal, Outer and Inner write-back, write-allocate, shareable */


/* AP bits: Access permission */
#define AP_NONE                      (0x00 << SRT_MMU_ENTRY_AP)
#define AP_RW_NONE                   (0x01 << SRT_MMU_ENTRY_AP) /* Privileged access only */
#define AP_RW_RO                     (0x02 << SRT_MMU_ENTRY_AP) /* Writes in user mode generate permission faults */
#define AP_RW_RW                     (0x03 << SRT_MMU_ENTRY_AP) /* All permissions */
#define AP_RO_NONE                   (0x21 << SRT_MMU_ENTRY_AP) /* Privileged read-only */
#define AP_RO_RO                     (0x23 << SRT_MMU_ENTRY_AP) /* Privileged/user read-only */


#define SIZE_1M   (1)
#define SIZE_2M   (2)
#define SIZE_4M   (4)
#define SIZE_8M   (8)
#define SIZE_16M  (16)
#define SIZE_32M  (32)
#define SIZE_64M  (64)
#define SIZE_128M (128)
#define SIZE_256M (256)
#define SIZE_512M (512)
#define SIZE_1G   (1024)
#define SIZE_2G   (2048)

/* layout of MEM_REGION entry: 
   0: base address
   4: size in MB
   8: memory type/access permissions 
   c: 0: no execute, 1: execute
   */
#define OFF_MEM_REGION_BASE    0
#define OFF_MEM_REGION_SIZE_MB 4
#define OFF_MEM_REGION_TYPE    8
#define OFF_MEM_REGION_EXEC    12

#define MEM_REGION(phys_addr, size_mb, mem_type, access, exec) .word phys_addr, size_mb, mem_type | access, exec
#define MMU_REGIONS_END 0xffffffff





/* ------------------------------------------------------------------------ */

#define MMU_ENTRY_TYPE_FAULT         0x00000000
#define MMU_ENTRY_TYPE_PAGE_TABLE    0x00000001
#define MMU_ENTRY_TYPE_SECTION       0x00000002
#define MMU_ENTRY_TYPE_SUPERSECTION  0x00040002

#define NUM_MMU_ENTRIES              4096 /* 4GB / 1MB */

#define SRT_MMU_ENTRY_B       2
#define MSK_MMU_ENTRY_B       0x00000004
#define SRT_MMU_ENTRY_C       3
#define MSK_MMU_ENTRY_C       0x00000008
#define SRT_MMU_ENTRY_XN      4
#define MSK_MMU_ENTRY_XN      0x00000010
#define SRT_MMU_ENTRY_AP      10
#define MSK_MMU_ENTRY_AP      0x00008c00
#define SRT_MMU_ENTRY_TEX     12
#define MSK_MMU_ENTRY_TEX     0x00007000
#define SRT_MMU_ENTRY_S       16
#define MSK_MMU_ENTRY_S       0x00010000

/* ------------------------------------------------------------------------ */


/* Generate the MMU table.
   This table is only intended to control caching and access permissions, 
   the virtual and physical addresses are identical.
 */
 
	.global mmu_table
	.section .init_code, "ax"
	.arm

	.global mmu_table_init
	.func mmu_table_init
mmu_table_init:
clear_mmu_table:
	ldr r0, =MMU_ENTRY_TYPE_FAULT                /* default value */
	ldr r1, =mmu_table                           /* start of MMU table */
	add r2, r1, #(NUM_MMU_ENTRIES*4)             /* end of MMU table (+4) */
clear_mmu_table_loop:
	str r0, [r1]
	add r1, r1, #4
	cmp r1, r2
	bne clear_mmu_table_loop
	
	
	/* r0: pointer into mmu regions table
	   r1: base pointer to mmu table
	   r2: value
	   r3: mmu table index
	   r4: mmu table max index */
	ldr r0, =mmu_regions
	ldr r1, =mmu_table

regions_loop:
	ldr r2, [r0, #OFF_MEM_REGION_BASE]           /* region address */
	cmp r2, #MMU_REGIONS_END
	beq mmu_table_done
	
	orr r2, r2, #MMU_ENTRY_TYPE_SECTION          /* entry type "section" */
	
	ldr r3, [r0, #OFF_MEM_REGION_TYPE]           /* with memory type and access mode */
	orr r2, r2, r3
	
	ldr r3, [r0, #OFF_MEM_REGION_EXEC]           /* execute/no execute */
	cmp r3, #0
	orreq r2, r2, #MSK_MMU_ENTRY_XN

	ldr r3, [r0, #OFF_MEM_REGION_BASE]           /* MMU table index = region address / 1MB */
	lsr r3, r3, #20                              
	lsl r3, r3, #2
	
	ldr r4, [r0, #OFF_MEM_REGION_SIZE_MB]        /* region size in MB */
	lsl r4, r4, #2
	add r4, r4, r3                               /* end index = start index + region size / 1 MB */
region_entries_loop:
	str r2, [r1, r3]
	add r2, r2, #1<<20
	add r3, r3, #4
	cmp r3, r4
	bne region_entries_loop
	
	add r0, r0, #16
	b regions_loop
	
mmu_table_done:
	bx lr
	
	.endfunc
	
 
/* ------------------------------------------------------------------------ */

/* default memory types */
#ifndef MT_ROM_LO
#define MT_ROM_LO MT_NORMAL_CACHED
#endif

#ifndef AP_ROM_LO
#define AP_ROM_LO AP_RO_RO
#endif

#ifndef MT_ROM_HI
#define MT_ROM_HI MT_NORMAL
#endif

#ifndef MT_INTRAM
#define MT_INTRAM MT_DEVICE
#endif

#ifndef MT_INTRAM_MIRROR1
#define MT_INTRAM_MIRROR1 MT_NORMAL_SHARED
#endif

#ifndef MT_INTRAM_MIRROR2
#define MT_INTRAM_MIRROR2 MT_NORMAL_CACHED_SHARED
#endif

#ifndef MT_PCI
#define MT_PCI MT_NORMAL_SHARED
#endif

#ifndef MT_SDRAM
#define MT_SDRAM MT_NORMAL_SHARED
#endif

#ifndef MT_EXTSRAM
#define MT_EXTSRAM MT_NORMAL_SHARED
#endif

#ifndef MT_RAP_EXTSRAM
#define MT_RAP_EXTSRAM MT_NORMAL_CACHED
#endif

/* Global memory regions, visible to all CPUs
 * The base address can either be a hexadecimal address or an address of an area from the regdef.h (beginning with Addr_).
 * The size must be 'SIZE_' followed by an integer power of 2 followed by either 'M' for MegaByte or 'G' for GigaByte.
 * The following memory types are supported:
 *   MT_STRONGLY_ORDERED     - strongly ordered: Number, size and order of accesses are preserved and wait for
 *                             all previously issued accesses into other memories finished
 *   MT_DEVICE               - device: Number, size and order of accesses are preserved
 *   MT_NORMAL               - normal: Accesses may be combined and/or repeated, speculative reads are allowed
 *   MT_NORMAL_CACHED        - see MT_NORMAL plus read/written data may be cached
 *   MT_NORMAL_SHARED        - see MT_NORMAL plus memory is shared between different processors, this has impact on how LDREX/STREX are handled
 *   MT_NORMAL_CACHED_SHARED - see MT_NORMAL_CACHED and MT_NORMAL_SHARED plus caches are kept coherent between CA9 cores
 * The access permission is "AP" followed by the privileged access permission, followed by the non-privileged access permission.
 * Each access permission can either be "_NONE" (no access allowed), "_RW" (read/write) or "_RO" (read only).
 * The executable definition is either 0 (no instruction fetches allowed) or 1 (instruction fetches allowed).
 */  

#include "netx_io_areas.S"
	.section .init_code, "ax"
mmu_regions:
/*          base address                            size        memory type           access     executable */ 
MEM_REGION( 0x00000000,                             SIZE_1M,    MT_ROM_LO,            AP_ROM_LO, 1 ) /* ROM/TCM with r/w necessary before branch to high ROM mirror. */ 
MEM_REGION( Addr_NX4000_CR7_rom,                    SIZE_1M,    MT_ROM_HI,            AP_RO_RO,  1 ) /* CR7/CA9 ROM high mirror, memory type defined by application  */ 
MEM_REGION( Addr_NX4000_NX2RAP_intram_rap0,         SIZE_16M,   MT_INTRAM,            AP_RW_RW,  1 ) /* INTRAMs, memory type defined by application                  */ 
MEM_REGION( Addr_NX4000_NX2RAP_intram_rap0_mirror1, SIZE_16M,   MT_INTRAM_MIRROR1,    AP_RW_RW,  1 ) /* INTRAMs normal shared memory type                            */ 
MEM_REGION( Addr_NX4000_NX2RAP_intram_rap0_mirror2, SIZE_16M,   MT_INTRAM_MIRROR2,    AP_RW_RW,  1 ) /* INTRAMs device memory type                                   */ 
MEM_REGION( Addr_NX4000_NX2RAP_nflash,              SIZE_16M,   MT_DEVICE,            AP_RW_RW,  1 ) /* PL353.IF1 (NAND)                                             */ 
MEM_REGION( Addr_NX4000_NX2RAP_SQIROM0,             SIZE_128M,  MT_NORMAL_CACHED,     AP_RO_RO,  1 ) /* XiP0 and XiP1                                                */ 
MEM_REGION( Addr_NX4000_NX2RAP_extsram0,            SIZE_128M,  MT_RAP_EXTSRAM,       AP_RW_RW,  1 ) /* rap_extsram0 and rap_extsram1                                */ 
MEM_REGION( Addr_NX4000_hif_sdram,                  SIZE_512M,  MT_SDRAM,             AP_RW_RW,  1 ) /* hif_sdram and mem_sdram                                      */ 
MEM_REGION( Addr_NX4000_NX2RAP_ddr_lo,              SIZE_1G,    MT_NORMAL_CACHED,     AP_RW_RW,  1 ) /* DDR lo                                                       */ 
MEM_REGION( Addr_NX4000_NX2RAP_ddr_hi,              SIZE_1G,    MT_NORMAL_CACHED,     AP_RW_RW,  1 ) /* DDR hi                                                       */ 
MEM_REGION( Addr_NX4000_NX2RAP_pci,                 SIZE_512M,  MT_PCI,               AP_RW_RW,  1 ) /* PCI                                                          */ 
MEM_REGION( Addr_NX4000_hif_extsram,                SIZE_256M,  MT_EXTSRAM,           AP_RW_RW,  1 ) /* hif_extsram and mem_extsram                                  */ 
MEM_REGION( 0xEA000000,                             SIZE_32M,   MT_STRONGLY_ORDERED,  AP_RW_RW,  0 ) /* sim_message and tb_regs in extmem_cs1                        */ 
MEM_REGION( Addr_NX4000_NX2RAP_APB_DBG,             SIZE_256M,  MT_DEVICE,            AP_RW_RW,  0 ) /* peripherals APB-DBG, ERICH, NETX-REG, RAP_REGS               */ 
.word MMU_REGIONS_END /* end marker */
  
  .end
 
