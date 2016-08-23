#ifndef __MEMORY_MAP_H
#define __MEMORY_MAP_H

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

#define MEM_REGIONS /* base address                  size        memory type           access     executable */ \
        MEM_REGION( 0x00000000,                      SIZE_1M,    MT_ROM_LO,            AP_ROM_LO, 1 ), /* ROM/TCM with r/w necessary before branch to high ROM mirror. */ \
        MEM_REGION( Addr_CR7_rom,                    SIZE_1M,    MT_ROM_HI,            AP_RO_RO,  1 ), /* CR7/CA9 ROM high mirror, memory type defined by application  */ \
        MEM_REGION( Addr_NX2RAP_intram_rap0,         SIZE_16M,   MT_INTRAM,            AP_RW_RW,  1 ), /* INTRAMs, memory type defined by application                  */ \
        MEM_REGION( Addr_NX2RAP_intram_rap0_mirror1, SIZE_16M,   MT_INTRAM_MIRROR1,    AP_RW_RW,  1 ), /* INTRAMs normal shared memory type                            */ \
        MEM_REGION( Addr_NX2RAP_intram_rap0_mirror2, SIZE_16M,   MT_INTRAM_MIRROR2,    AP_RW_RW,  1 ), /* INTRAMs device memory type                                   */ \
        MEM_REGION( Addr_NX2RAP_nflash,              SIZE_16M,   MT_DEVICE,            AP_RW_RW,  1 ), /* PL353.IF1 (NAND)                                             */ \
        MEM_REGION( Addr_NX2RAP_SQIROM0,             SIZE_128M,  MT_NORMAL_CACHED,     AP_RO_RO,  1 ), /* XiP0 and XiP1                                                */ \
        MEM_REGION( Addr_NX2RAP_extsram0,            SIZE_128M,  MT_RAP_EXTSRAM,       AP_RW_RW,  1 ), /* rap_extsram0 and rap_extsram1                                */ \
        MEM_REGION( Addr_hif_sdram,                  SIZE_512M,  MT_SDRAM,             AP_RW_RW,  1 ), /* hif_sdram and mem_sdram                                      */ \
        MEM_REGION( Addr_NX2RAP_ddr_lo,              SIZE_1G,    MT_NORMAL_CACHED,     AP_RW_RW,  1 ), /* DDR lo                                                       */ \
        MEM_REGION( Addr_NX2RAP_ddr_hi,              SIZE_1G,    MT_NORMAL_CACHED,     AP_RW_RW,  1 ), /* DDR hi                                                       */ \
        MEM_REGION( Addr_NX2RAP_pci,                 SIZE_512M,  MT_PCI,               AP_RW_RW,  1 ), /* PCI                                                          */ \
        MEM_REGION( Addr_hif_extsram,                SIZE_256M,  MT_EXTSRAM,           AP_RW_RW,  1 ), /* hif_extsram and mem_extsram                                  */ \
        MEM_REGION( 0xEA000000,                      SIZE_32M,   MT_STRONGLY_ORDERED,  AP_RW_RW,  0 ), /* sim_message and tb_regs in extmem_cs1                        */ \
        MEM_REGION( Addr_NX2RAP_APB_DBG,             SIZE_256M,  MT_DEVICE,            AP_RW_RW,  0 )  /* peripherals APB-DBG, ERICH, NETX-REG, RAP_REGS               */


#endif  /* __MEMORY_MAP_H */
