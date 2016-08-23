
@ =====================================================================
@
@ System Control Register - SCTRL
@  TRM chapter 4.3.9
@
@  MRC p15, 0, <Rd>, c1, c0, 0
@  MCR p15, 0, <Rd>, c1, c0, 0
@
@ =====================================================================
/* Enables the MPU:
 *   0 : MPU disabled. This is the reset value.
 *   1 : MPU enabled.
 */
.equ MSK_CR7_CP15_SCTRL_M,           0x00000001
.equ SRT_CR7_CP15_SCTRL_M,           0

/* Enables strict alignment of data to detect alignment faults in data accesses:
 *   0 : Strict alignment fault checking disabled. This is the reset value.
 *   1 : Strict alignment fault checking enabled.
 * Any unaligned access to Device or Strongly Ordered memory generates an alignment fault and
 * therefore does not cause any peripheral interface access. This means that the access examples given
 * in this manual never show unaligned accesses to Device or Strongly Ordered memory.
 */
.equ MSK_CR7_CP15_SCTRL_A,           0x00000002
.equ SRT_CR7_CP15_SCTRL_A,           1

/* Determines if data can be cached at any available cache level:
 *   0 : Data caching disabled at all levels. This is the reset value.
 *   1 : Data caching enabled.
 */
.equ MSK_CR7_CP15_SCTRL_C,           0x00000004
.equ SRT_CR7_CP15_SCTRL_C,           2

.equ MSK_CR7_CP15_SCTRL_SBOP3,       0x00000078
.equ SRT_CR7_CP15_SCTRL_SBOP3,       3

.equ MSK_CR7_CP15_SCTRL_SBZP7,       0x00000380
.equ SRT_CR7_CP15_SCTRL_SBZP7,       7

/* SWP/SWPB enable bit:
 *   0 : SWP and SWPB are UNDEFINED . This is the reset value.
 *   1 : SWP and SWPB perform normally.
 */
.equ MSK_CR7_CP15_SCTRL_SW,          0x00000400
.equ SRT_CR7_CP15_SCTRL_SW,          10

/* Enables program flow prediction:
 *   0 : Program flow prediction disabled. This is the reset value.
 *   1 : Program flow prediction enabled.
 */
.equ MSK_CR7_CP15_SCTRL_Z,           0x00000800
.equ SRT_CR7_CP15_SCTRL_Z,           11

/* Determines if instructions can be cached at any available cache level:
 *   0 : Instruction caching disabled at all levels. This is the reset value.
 *   1 : Instruction caching enabled.
 */
.equ MSK_CR7_CP15_SCTRL_I,           0x00001000
.equ SRT_CR7_CP15_SCTRL_I,           12

/* Vectors bit. This bit selects the base address of the exception vectors:
 *   0 : Normal exception vectors, base address 0x00000000 .
 *   1 : High exception vectors, Hivecs, base address 0xFFFF0000 .
 * At reset the value of this bit is taken from VINITHI.
 */
.equ MSK_CR7_CP15_SCTRL_V,           0x00002000
.equ SRT_CR7_CP15_SCTRL_V,           13

.equ MSK_CR7_CP15_SCTRL_WI14,        0x00004000
.equ SRT_CR7_CP15_SCTRL_WI14,        14

.equ MSK_CR7_CP15_SCTRL_SBZP15,      0x00008000
.equ SRT_CR7_CP15_SCTRL_SBZP15,      15

.equ MSK_CR7_CP15_SCTRL_SBOP16,      0x00010000
.equ SRT_CR7_CP15_SCTRL_SBOP16,      16

/* Background Region bit.
 * When the MPU is enabled this bit controls how an access that does not map to any MPU memory
 * region is handled:
 *   0 : Any access to an address that is not mapped to an MPU region generates a
 *       Background Fault memory abort. This is the reset value.
 *   1 : The default memory map is used as a background region:
 *       - A privileged access to an address that does not map to an MPU region takes
 *         the properties defined for that address in the default memory map.
 *       - An unprivileged access to an address that does not map to an MPU region
 *         generates a Background Fault memory abort.
 */
.equ MSK_CR7_CP15_SCTRL_BR,          0x00020000
.equ SRT_CR7_CP15_SCTRL_BR,          17

.equ MSK_CR7_CP15_SCTRL_SBOP18,      0x00040000
.equ SRT_CR7_CP15_SCTRL_SBOP18,      18

/* Divide by Zero fault enable bit.
 * This bit controls whether an integer divide by zero causes an UNDEFINED Instruction exception:
 *   0 : Divide by zero returns the result zero, and no exception is taken. This is the reset
 *       value.
 *   1 : Attempting a divide by zero causes an UNDEFINED Instruction exception on the SDIV
 *       or UDIV instruction.
 */
.equ MSK_CR7_CP15_SCTRL_DZ,          0x00080000
.equ SRT_CR7_CP15_SCTRL_DZ,          19

.equ MSK_CR7_CP15_SCTRL_SBZP20,      0x00100000
.equ SRT_CR7_CP15_SCTRL_SBZP20,      20

/* Fast Interrupts configuration enable bit.
 * This bit can be used to reduce interrupt latency. The permitted values of this bit are:
 *   0 : All performance features enabled. This is the reset value.
 *   1 : Low interrupt latency configuration. Some performance features disabled.
 */
.equ MSK_CR7_CP15_SCTRL_FI,          0x00200000
.equ SRT_CR7_CP15_SCTRL_FI,          21

.equ MSK_CR7_CP15_SCTRL_SBOP22,      0x00c00000
.equ SRT_CR7_CP15_SCTRL_SBOP22,      22

.equ MSK_CR7_CP15_SCTRL_WI24,        0x01000000
.equ SRT_CR7_CP15_SCTRL_WI24,        24

/* Exception Endianness. This bit determines how the E bit in the CPSR is set on an exception:
 *   0 : CPSR E bit is set to 0 on an exception.
 *   1 : CPSR E bit is set to 1 on an exception.
 * The CFGEND signal defines the reset value.
 */
.equ MSK_CR7_CP15_SCTRL_EE,          0x02000000
.equ SRT_CR7_CP15_SCTRL_EE,          25

.equ MSK_CR7_CP15_SCTRL_SBZP26,      0x04000000
.equ SRT_CR7_CP15_SCTRL_SBZP26,      26

/* Nonmaskable FIQ support.
 * The bit cannot be configured by software.
 * The CFGNMFI signal defines the reset value.
 */
.equ MSK_CR7_CP15_SCTRL_NMFI,        0x08000000
.equ SRT_CR7_CP15_SCTRL_NMFI,        27

.equ MSK_CR7_CP15_SCTRL_SBZP28,      0x30000000
.equ SRT_CR7_CP15_SCTRL_SBZP28,      28

/* Thumb exception Enable:
 *   0 : Exceptions including reset are handled in ARM state.
 *   1 : Exceptions including reset are handled in Thumb state.
 * The TEINIT signal defines the reset value.
 */
.equ MSK_CR7_CP15_SCTRL_TE,          0x40000000
.equ SRT_CR7_CP15_SCTRL_TE,          30

.equ MSK_CR7_CP15_SCTRL_SBZP31,      0x80000000
.equ SRT_CR7_CP15_SCTRL_SBZP31,      31



@ =====================================================================
@
@ DTCM Region Register - DTCMRR
@  TRM chapter 4.3.13
@
@  MRC p15, 0, <Rd>, c9, c1, 0
@  MCR p15, 0, <Rd>, c9, c1, 0
@
@ =====================================================================

/* Enable bit:
 *   0 : Disabled. This is the reset value.
 *   1 : Enabled.
 * If Data TCM is not implemented, this field is Read-only and its value is 0.
 */
.equ MSK_CR7_CP15_DTCMRR_Enable,     0x00000001
.equ SRT_CR7_CP15_DTCMRR_Enable,     0

.equ MSK_CR7_CP15_DTCMRR_SBZ1,       0x00000002
.equ SRT_CR7_CP15_DTCMRR_SBZ1,       1

/* Indicates the Data TCM region size:
 *   b0000 :   0KB.
 *   b0011 :   4KB.
 *   b0100 :   8KB.
 *   b0101 :  16KB.
 *   b0110 :  32KB.
 *   b0111 :  64KB.
 *   b1000 : 128KB.
 * All other values are Reserved.
 */
.equ MSK_CR7_CP15_DTCMRR_Size,       0x0000003c
.equ SRT_CR7_CP15_DTCMRR_Size,       2
.equ VAL_CR7_CP15_DTCMRR_Size_0KB,   0
.equ VAL_CR7_CP15_DTCMRR_Size_4KB,   3
.equ VAL_CR7_CP15_DTCMRR_Size_8KB,   4
.equ VAL_CR7_CP15_DTCMRR_Size_16KB,  5
.equ VAL_CR7_CP15_DTCMRR_Size_32KB,  6
.equ VAL_CR7_CP15_DTCMRR_Size_64KB,  7
.equ VAL_CR7_CP15_DTCMRR_Size_128KB, 8

.equ MSK_CR7_CP15_DTCMRR_SBZ6,       0x00000fc0
.equ SRT_CR7_CP15_DTCMRR_SBZ6,       6

/* Indicates the Data TCM region base address. The reset value is 0.
 */
.equ MSK_CR7_CP15_DTCMRR_Base,       0xfffff000
.equ SRT_CR7_CP15_DTCMRR_Base,       12



@ =====================================================================
@
@ ITCM Region Register - ITCMRR
@  TRM chapter 4.3.14
@
@  MRC p15, 0, <Rd>, c9, c1, 1
@  MCR p15, 0, <Rd>, c9, c1, 1
@
@ =====================================================================

/* Enable bit:
 *   0 : Disabled. This is the reset value.
 *   1 : Enabled.
 * When INITRAM0 is HIGH this enables the Instruction TCM for processor 0
 * directly from reset.
 * The same applies for processor 1, if present. When INITRAM1 is HIGH, this
 * enables the Instruction TCM for processor 1 directly from reset.
 * If Instruction TCM is not implemented, this field is Read-only and its value is 0.
 */
.equ MSK_CR7_CP15_ITCMRR_Enable,     0x00000001
.equ SRT_CR7_CP15_ITCMRR_Enable,     0

.equ MSK_CR7_CP15_ITCMRR_SBZ1,       0x00000002
.equ SRT_CR7_CP15_ITCMRR_SBZ1,       1

/* Indicates the Instruction TCM region size:
 *   b0000 :   0KB.
 *   b0011 :   4KB.
 *   b0100 :   8KB.
 *   b0101 :  16KB.
 *   b0110 :  32KB.
 *   b0111 :  64KB.
 *   b1000 : 128KB.
 * All other values are Reserved.
 */
.equ MSK_CR7_CP15_ITCMRR_Size,       0x0000003c
.equ SRT_CR7_CP15_ITCMRR_Size,       2
.equ VAL_CR7_CP15_ITCMRR_Size_0KB,   0
.equ VAL_CR7_CP15_ITCMRR_Size_4KB,   3
.equ VAL_CR7_CP15_ITCMRR_Size_8KB,   4
.equ VAL_CR7_CP15_ITCMRR_Size_16KB,  5
.equ VAL_CR7_CP15_ITCMRR_Size_32KB,  6
.equ VAL_CR7_CP15_ITCMRR_Size_64KB,  7
.equ VAL_CR7_CP15_ITCMRR_Size_128KB, 8

.equ MSK_CR7_CP15_ITCMRR_SBZ6,       0x00000fc0
.equ SRT_CR7_CP15_ITCMRR_SBZ6,       6

/* Indicates the Instruction TCM region base address.
 * When INITRAM0 is HIGH and VINITH0 is HIGH for processor 0, the reset
 * value is 0xFFFF0 , otherwise the reset value is 0x00000 .
 * The same applies for processor 1, if present.
 */
.equ MSK_CR7_CP15_ITCMRR_Base,       0xfffff000
.equ SRT_CR7_CP15_ITCMRR_Base,       12



@ =====================================================================
@
@ MPU Region Base Address Registers - DRBAR
@  TRM chapter 4.3.12
@
@  MRC p15, 0, <Rd>, c6, c1, 0
@  MCR p15, 0, <Rd>, c6, c1, 0
@
@ =====================================================================

.equ MSK_CR7_CP15_DRBAR_SBZ0,        0x0000001f
.equ SRT_CR7_CP15_DRBAR_SBZ0,        0

/* Physical base address. Defines the base address of a region.
 */
.equ MSK_CR7_CP15_DRBAR_BaseAddress, 0xffffffe0
.equ SRT_CR7_CP15_DRBAR_BaseAddress, 5

	

@ =====================================================================
@
@ MPU Region Size and Enable Registers - DRSR
@  TRM chapter 4.3.12
@
@  MRC p15, 0, <Rd>, c6, c1, 2
@  MCR p15, 0, <Rd>, c6, c1, 2
@
@ =====================================================================

/* Enables or disables a memory region:
 *   0 : Memory region disabled. Memory regions are disabled on reset.
 *   1 : Memory region enabled. A memory region must be enabled before it is used.
 */
.equ MSK_CR7_CP15_DRSR_Enable,       0x00000001
.equ SRT_CR7_CP15_DRSR_Enable,       0

/* Defines the region size:
 *   b00000 - b00110 : UNPREDICTABLE .
 *   b00111 : 256 bytes.
 *   b01000 : 512 bytes.
 *   b01001 : 1KB.
 *   b01010 : 2KB.
 *   b01011 : 4KB.
 *   b01100 : 8KB.
 *   b01101 : 16KB.
 *   b01110 : 32KB.
 *   b01111 : 64KB.
 *   b10000 : 128KB.
 *   b10001 : 256KB.
 *   b10010 : 512KB.
 *   b10011 : 1MB.
 *   b10100 : 2MB.
 *   b10101 : 4MB.
 *   b10110 : 8MB.
 *   b10111 : 16MB.
 *   b11000 : 32MB.
 *   b11001 : 64MB.
 *   b11010 : 128MB.
 *   b11011 : 256MB.
 *   b11100 : 512MB.
 *   b11101 : 1GB.
 *   b11110 : 2GB.
 *   b11111 : 4GB.
 */
.equ MSK_CR7_CP15_DRSR_RegionSize,          0x0000003e
.equ SRT_CR7_CP15_DRSR_RegionSize,          1
.equ VAL_CR7_CP15_DRSR_RegionSize_000000ff, 0x07
.equ VAL_CR7_CP15_DRSR_RegionSize_000001ff, 0x08
.equ VAL_CR7_CP15_DRSR_RegionSize_000003ff, 0x09
.equ VAL_CR7_CP15_DRSR_RegionSize_000007ff, 0x0a
.equ VAL_CR7_CP15_DRSR_RegionSize_00000fff, 0x0b
.equ VAL_CR7_CP15_DRSR_RegionSize_00001fff, 0x0c
.equ VAL_CR7_CP15_DRSR_RegionSize_00003fff, 0x0d
.equ VAL_CR7_CP15_DRSR_RegionSize_00007fff, 0x0e
.equ VAL_CR7_CP15_DRSR_RegionSize_0000ffff, 0x0f
.equ VAL_CR7_CP15_DRSR_RegionSize_0001ffff, 0x10
.equ VAL_CR7_CP15_DRSR_RegionSize_0003ffff, 0x11
.equ VAL_CR7_CP15_DRSR_RegionSize_0007ffff, 0x12
.equ VAL_CR7_CP15_DRSR_RegionSize_000fffff, 0x13
.equ VAL_CR7_CP15_DRSR_RegionSize_001fffff, 0x14
.equ VAL_CR7_CP15_DRSR_RegionSize_003fffff, 0x15
.equ VAL_CR7_CP15_DRSR_RegionSize_007fffff, 0x16
.equ VAL_CR7_CP15_DRSR_RegionSize_00ffffff, 0x17
.equ VAL_CR7_CP15_DRSR_RegionSize_01ffffff, 0x18
.equ VAL_CR7_CP15_DRSR_RegionSize_03ffffff, 0x19
.equ VAL_CR7_CP15_DRSR_RegionSize_07ffffff, 0x1a
.equ VAL_CR7_CP15_DRSR_RegionSize_0fffffff, 0x1b
.equ VAL_CR7_CP15_DRSR_RegionSize_1fffffff, 0x1c
.equ VAL_CR7_CP15_DRSR_RegionSize_3fffffff, 0x1d
.equ VAL_CR7_CP15_DRSR_RegionSize_7fffffff, 0x1e
.equ VAL_CR7_CP15_DRSR_RegionSize_ffffffff, 0x1f

.equ MSK_CR7_CP15_DRSR_SBZ6,                0x000000c0
.equ SRT_CR7_CP15_DRSR_SBZ6,                6

/* Each bit position represents a sub-region, 0-7.
 *   Bit[8] corresponds to sub-region 0
 *   ...
 *   Bit[15] corresponds to sub-region 7.
 *   The meaning of each bit is:
 *   0 : Address range is part of this region.
 *   1 : Address range is not part of this region.
 */
.equ MSK_CR7_CP15_DRSR_SubRegionDisable,    0x0000ff00
.equ SRT_CR7_CP15_DRSR_SubRegionDisable,    8

.equ MSK_CR7_CP15_DRSR_SBZ16,               0xffff0000
.equ SRT_CR7_CP15_DRSR_SBZ16,               16



@ =====================================================================
@
@ MPU Region Access Control Registers - DRACR
@  TRM chapter 4.3.12
@
@  MRC p15, 0, <Rd>, c6, c1, 4
@  MCR p15, 0, <Rd>, c6, c1, 4
@
@ =====================================================================

/* B bit
*/
.equ MSK_CR7_CP15_DRACR_B,                  0x00000001
.equ SRT_CR7_CP15_DRACR_B,                  0

/* C bit
*/
.equ MSK_CR7_CP15_DRACR_C,                  0x00000002
.equ SRT_CR7_CP15_DRACR_C,                  1

/* Share. Determines if the memory region is Shareable or Non-shareable:
 *   0 : Non-shareable.
 *   1 : Shareable.
 * This bit only applies to Normal, not Device or Strongly Ordered memory.
 */
.equ MSK_CR7_CP15_DRACR_S,                  0x00000004
.equ SRT_CR7_CP15_DRACR_S,                  2

/* Type extension. Defines the type extension attribute.
*/
.equ MSK_CR7_CP15_DRACR_TEX,                0x00000038
.equ SRT_CR7_CP15_DRACR_TEX,                3

.equ MSK_CR7_CP15_DRACR_SBZ6,               0x000000c0
.equ SRT_CR7_CP15_DRACR_SBZ6,               6

/* Access permission. Defines the data access permissions.
 *  AP bit values, Privileged permissions, User permissions, Description
 *  b000           No access               No access         All accesses generate a permission fault
 *  b001           Read/write              No access         Privileged access only
 *  b010           Read/write              Read-only         Writes in user mode generate permission faults
 *  b011           Read/write              Read/write        Full access
 *  b100           UNP                     UNP               Reserved
 *  b101           Read-only               No access         Privileged read-only
 *  b110           Read-only               Read-only         Privileged/user read-only
 *  b111           UNP                     UNP               Reserved
 */
.equ MSK_CR7_CP15_DRACR_AP,                 0x00000700
.equ SRT_CR7_CP15_DRACR_AP,                 8
.equ VAL_CR7_CP15_DRACR_AP_NoAccess,        0
.equ VAL_CR7_CP15_DRACR_AP_PrivilegedRW,    1
.equ VAL_CR7_CP15_DRACR_AP_UserRO,          2
.equ VAL_CR7_CP15_DRACR_AP_Full,            3
.equ VAL_CR7_CP15_DRACR_AP_PrivilegedRO,    5
.equ VAL_CR7_CP15_DRACR_AP_AllRO,           6

.equ MSK_CR7_CP15_DRACR_SBZ11,              0x00000800
.equ SRT_CR7_CP15_DRACR_SBZ11,              11

/* Execute never. Determines if a region of memory is executable:
 *   0 : All instruction fetches enabled.
 *   1 : No instruction fetches enabled.
 */
.equ MSK_CR7_CP15_DRACR_XN,                 0x00001000
.equ SRT_CR7_CP15_DRACR_XN,                 12

.equ MSK_CR7_CP15_DRACR_SBZ13,              0xffffe000
.equ SRT_CR7_CP15_DRACR_SBZ13,              13



.equ PMUEVENT_Software_increment,                                                 0x00
.equ PMUEVENT_Instruction_cache_miss,                                             0x01
.equ PMUEVENT_Data_cache_miss,                                                    0x03
.equ PMUEVENT_Data_cache_access,                                                  0x04
.equ PMUEVENT_Data_read,                                                          0x06
.equ PMUEVENT_Data_write,                                                         0x07
.equ PMUEVENT_Instruction_architecturally_executed,                               0x08
.equ PMUEVENT_Exception_taken,                                                    0x09
.equ PMUEVENT_Exception_returns,                                                  0x0A
.equ PMUEVENT_Write_context_ID,                                                   0x0B
.equ PMUEVENT_Software_change_of_PC,                                              0x0C
.equ PMUEVENT_Immediate_branch,                                                   0x0D
.equ PMUEVENT_Procedure_return_other_than_exception_return,                       0x0E
.equ PMUEVENT_Unaligned,                                                          0x0F
.equ PMUEVENT_Branch_mispredicted_or_not_predicted,                               0x10
.equ PMUEVENT_Predictable_branches,                                               0x12
.equ PMUEVENT_Instruction_cache_access,                                           0x14
.equ PMUEVENT_Number_of_cycles_IRQs_are_interrupted,                              0x50
.equ PMUEVENT_Number_of_cycles_FIQs_are_interrupted,                              0x51
.equ PMUEVENT_Parity_error_on_PRED,                                               0x61
.equ PMUEVENT_Parity_error_on_BTAC,                                               0x62
.equ PMUEVENT_Detected_ECC_errors_on_ITCM,                                        0x63
.equ PMUEVENT_Detected_ECC_errors_on_DTCM,                                        0x64
.equ PMUEVENT_Detected_ECC_errors_on_instruction_cache,                           0x65
.equ PMUEVENT_Detected_ECC_errors_on_data_cache,                                  0x66
.equ PMUEVENT_Correctable_ECC_errors_on_slave_bus_data_write_channel,             0x68
.equ PMUEVENT_Correctable_ECC_errors_on_peripheral_master_bus_data_read_channel,  0x69
.equ PMUEVENT_Correctable_ECC_errors_on_master_0_bus_data_read_channel,           0x6A
.equ PMUEVENT_Correctable_ECC_errors_on_master_1_bus_data_read_channel,           0x6B
.equ PMUEVENT_Detected_ECC_errors_on_SCU_RAM,                                     0x6C
.equ PMUEVENT_STREX_passed,                                                       0x80
.equ PMUEVENT_STREX_failed,                                                       0x81
.equ PMUEVENT_Literal_pool_in_TCM_region,                                         0x82
.equ PMUEVENT_DMB_stall,                                                          0x90
.equ PMUEVENT_ITCM_access,                                                        0x91
.equ PMUEVENT_DTCM_access,                                                        0x92
.equ PMUEVENT_Data_eviction,                                                      0x93
.equ PMUEVENT_SCU_coherency_operation,                                            0x94
.equ PMUEVENT_Instruction_cache_dependent_stall,                                  0x95
.equ PMUEVENT_Data_cache_dependent_stall,                                         0x96
.equ PMUEVENT_Non_cacheable_no_peripheral_dependent_stall,                        0x97
.equ PMUEVENT_Non_cacheable_peripheral_dependent_stall,                           0x98
.equ PMUEVENT_Data_cache_high_priority_dependent_stall,                           0x99



@ =====================================================================
@
@ MPU helper defines and macros
@
@ =====================================================================

/* This macro shifts the bits for the TEX, S, C and B fields to the correct positions for the DRACR register. */
#define MPU_DRACR_TSCB(MPU_TEX, MPU_S, MPU_C, MPU_B) (MPU_TEX<<SRT_CR7_CP15_DRACR_TEX | MPU_S<<SRT_CR7_CP15_DRACR_S | MPU_C<<SRT_CR7_CP15_DRACR_C | MPU_B<<SRT_CR7_CP15_DRACR_B)

/* These defines declare all possible memory types.
 * Source: TRM table 8-2
 */
#define MPU_MT_StronglyOrdered               MPU_DRACR_TSCB(0,0,0,0)   /* This is always shareable. */

#define MPU_MT_Device_Shareable              MPU_DRACR_TSCB(0,0,0,1)   /* This is always shareable. */
#define MPU_MT_Device_NonShareable           MPU_DRACR_TSCB(2,0,0,0)   /* This is never shareable. */

#define MPU_MT_Normal_Shareable              MPU_DRACR_TSCB(1,1,0,0)   /* This is shareable. */
#define MPU_MT_Normal_NonShareable           MPU_DRACR_TSCB(1,0,0,0)   /* This is not shareable. */

#define MPU_MT_Normal_Buffered_Shareable     MPU_DRACR_TSCB(1,1,1,1)   /* This is shareable. */
#define MPU_MT_Normal_Buffered_NonShareable  MPU_DRACR_TSCB(1,0,1,1)   /* This is not shareable. */

#define MPU_MT_Normal_Cached_Shareable       MPU_DRACR_TSCB(5,1,0,1)   /* This is shareable. */
#define MPU_MT_Normal_Cached_NonShareable    MPU_DRACR_TSCB(5,0,0,1)   /* This is not shareable. */



/* AP bits: Access permission */
#define MPU_AP_No_No  VAL_CR7_CP15_DRACR_AP_NoAccess       /* No access at all. */
#define MPU_AP_RW_No  VAL_CR7_CP15_DRACR_AP_PrivilegedRW   /* Privileged access only */
#define MPU_AP_RW_RO  VAL_CR7_CP15_DRACR_AP_UserRO         /* Writes in user mode generate permission faults */
#define MPU_AP_RW_RW  VAL_CR7_CP15_DRACR_AP_Full           /* All permissions */
#define MPU_AP_RO_No  VAL_CR7_CP15_DRACR_AP_PrivilegedRO   /* Privileged read-only */
#define MPU_AP_RO_RO  VAL_CR7_CP15_DRACR_AP_AllRO          /* Privileged/user read-only */


#define MPU_STRING_TO_REGION_SIZE(strSize) VAL_CR7_CP15_DRSR_RegionSize_ ## strSize

/* This macro generates the code to setup an MPU region. */
.macro MACRO_MPU_REGION uiRegion, uiEnable, ulBaseAddress, strSize, ulMpuMemoryType, ulAccessPermissions
	/* Select the MPU region. */
	mov     r0, #\uiRegion
	mcr     p15, 0, r0, c6, c2, 0

	/* Set the base address. */
	ldr     r0, =\ulBaseAddress
	mcr     p15, 0, r0, c6, c1, 0  // DRBAR D-Side
	mcr     p15, 0, r0, c6, c1, 1  // DRBAR I-Side

	ldr     r0, =\ulMpuMemoryType | (\ulAccessPermissions << SRT_CR7_CP15_DRACR_AP)
	mcr     p15, 0, r0, c6, c1, 4  // DRACR
	mcr     p15, 0, r0, c6, c1, 5  // DRACR
    .if \uiEnable
	ldr     r0, =(\uiEnable << SRT_CR7_CP15_DRSR_Enable) | (MPU_STRING_TO_REGION_SIZE(\strSize) << SRT_CR7_CP15_DRSR_RegionSize)
    .else
	mov     r0, #0
    .endif
	mcr     p15, 0, r0, c6, c1, 2  // DRSR
	mcr     p15, 0, r0, c6, c1, 3  // DRSR
.endm



#define SR_Mode_User           0x10
#define SR_Mode_FIQ            0x11
#define SR_Mode_IRQ            0x12
#define SR_Mode_Supervisor     0x13
#define SR_Mode_Abort          0x17
#define SR_Mode_Undefined      0x1b
#define SR_Mode_System         0x1f

#define SR_Irq       0x80
#define SR_Fiq       0x40



