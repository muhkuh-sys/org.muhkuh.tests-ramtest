typedef struct {
	volatile unsigned long ulCPU0_IDATA;     /* RW 32     0x00000000     0x0000 */ 
	volatile unsigned long ulCPU0_ITAG;      /* RW 32     0x00000000     0x0004 */ 
	volatile unsigned long ulCPU0_DDATA;     /* RW 32     0x00000000     0x0008 */ 
	volatile unsigned long ulCPU0_DTAG;      /* RW 32     0x00000000     0x000C */ 
	volatile unsigned long ulCPU0_DOUTER;    /* RW 32     0x00000000     0x0010 */ 
	volatile unsigned long ulCPU0_TLB;       /* RW 32     0x00000000     0x0014 */ 
	volatile unsigned long ulCPU0_SNOOP_TAG; /* RW 32     0x00000000     0x0018 */ 
	volatile unsigned long ulReserved0;      /*                          0x001c */ 
	volatile unsigned long ulCPU1_IDATA;     /* RW 32     0x00000000     0x0020 */ 
	volatile unsigned long ulCPU1_ITAG;      /* RW 32     0x00000000     0x0024 */ 
	volatile unsigned long ulCPU1_DDATA;     /* RW 32     0x00000000     0x0028 */ 
	volatile unsigned long ulCPU1_DTAG;      /* RW 32     0x00000000     0x002C */ 
	volatile unsigned long ulCPU1_DOUTER;    /* RW 32     0x00000000     0x0030 */ 
	volatile unsigned long ulCPU1_TLB;       /* RW 32     0x00000000     0x0034 */ 
	volatile unsigned long ulCPU1_SNOOP_TAG; /* RW 32     0x00000000     0x0038 */ 
	volatile unsigned long ulReserved1;      /*                          0x003c */ 
	volatile unsigned long ulPL310_DATA;     /* RW 32     0x00000000     0x0040 */ 
	volatile unsigned long ulPL310_TAG;      /* RW 32     0x00000000     0x0044 */ 
	volatile unsigned long aulReserved[14];  /*                   0x0048-0x007c */ 
	volatile unsigned long ulCPU0_SBE_INT    /* RW 8      0x00000000     0x0080 */  __attribute__ ((aligned (4)));
	volatile unsigned long ulCPU1_SBE_INT    /* RW 8      0x00000000     0x0084 */  __attribute__ ((aligned (4)));
	volatile unsigned long ulCPU0_DBE_INT    /* RW 8      0x00000000     0x0088 */  __attribute__ ((aligned (4)));
	volatile unsigned long ulCPU1_DBE_INT    /* RW 8      0x00000000     0x008C */  __attribute__ ((aligned (4)));
} CA9_ECC_CTRL_T;

#define ADDR_CA9_ECC_CTRL 0xf0200000

#define NX4000_DEF_ptCA9_EccCtrl CA9_ECC_CTRL_T * const ptCA9_EccCtrl = (CA9_ECC_CTRL_T * const) ADDR_CA9_ECC_CTRL;

void wait_for_debug(void);
int ca9_l1_ecc_ctrl_trigger_errors(void);
void ca9_ecc_ctrl_clear(void);
int ca9_ecc_ctrl_check(void);
int ca9_ecc_ctrl_check_print(void);
void ca9_ecc_ctrl_show(void);


