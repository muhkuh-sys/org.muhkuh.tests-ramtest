#ifndef MMU_H_
#define MMU_H_

#include <stdint.h>

#define MMU_ENTRY_TYPE_FAULT         0x00000000
#define MMU_ENTRY_TYPE_PAGE_TABLE    0x00000001
#define MMU_ENTRY_TYPE_SECTION       0x00000002
#define MMU_ENTRY_TYPE_SUPERSECTION  0x00040002

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

#define MMU_SECTION(vadr, ofs, val) (MMU_ENTRY_TYPE_SECTION | vadr | (ofs << 20) | val )

void mmu_table_init(uint32_t uiBaseAddr);

#endif
