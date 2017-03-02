/*
#define NX4000_DEF_ptDdrCtrlArea NX4000_DDR_CTRL_AREA_T * const ptDdrCtrlArea = (NX4000_DDR_CTRL_AREA_T * const)Addr_NX4000_DDR_CTRL;

typedef struct NX4000_DDR_CTRL_AREA_Ttag
{
  volatile unsigned long aulDDR_CTRL_CTL[154];
} NX4000_DDR_CTRL_AREA_T;


DDR_CTRL_CTL152 	Address : 0xf8001260
NA R/W	0x00000000	 Bits 	Reset value 	Name 	Description
31 - 13 	0	-	 reserved 
12 - 8 	"00000"	LONG_COUNT_MASK Reduces the length of the long counter from 1024 cycles. The only supported values are 0x00 (1024 cycles), 0x10 (512 clocks), 0x18 (256 clocks), 0x1C (128 clocks), 0x1E (64 clocks) and 0x1F (32 clocks).
7 - 1 	0	-	 reserved 
0 	"0" ECC_EN	 ECC error checking and correcting control. Clear to 0 to disable ECC or set to 1 for ECC reporting and correcting. 

DDR_CTRL_CTL39 0      FWC 	Force a write check. Xor the XOR_CHECK_BITS parameter with the ECC code and write to memory. Set to 1 to trigger. WRITE-ONLY 
DDR_CTRL_CTL40 27 - 0 XOR_CHECK_BITS	Value to xor with generated ECC codes for forced write check. 
DDR_CTRL_CTL41 0      ECC_DISABLE_W_UC_ERR	Controls auto-corruption of ECC when un-correctable errors occur in R/M/W operations. Set to 1 to disable corruption.

DDR_CTRL_CTL42 30 - 0 ECC_U_ADDR	Address of uncorrectable ECC event. READ-ONLY 
DDR_CTRL_CTL43 14 - 8 ECC_U_SYND	Syndrome for uncorrectable ECC event. READ-ONLY
DDR_CTRL_CTL44 31 - 0 ECC_U_DATA	Data associated with uncorrectable ECC event. READ-ONLY

DDR_CTRL_CTL45 30 - 0 ECC_C_ADDR	Address of correctable ECC event. READ-ONLY
DDR_CTRL_CTL46 14 - 8 ECC_C_SYND	Syndrome for correctable ECC event. READ-ONLY
DDR_CTRL_CTL47 31 - 0 ECC_C_DATA	Data associated with correctable ECC event. READ-ONLY

DDR_CTRL_CTL48  26 - 16 ECC_C_ID Source ID associated with correctable ECC event. READ-ONLY
                15 - 11 - reserved
                10 - 0  ECC_U_ID Source ID associated with the uncorrectable ECC event. READ-ONLY

DDR_CTRL_CTL61 	22 - 0 	INT_STATUS Status of interrupt features in the controller. READ-ONLY
DDR_CTRL_CTL62 	21 - 0 	INT_ACK Clear mask of the INT_STATUS parameter. WRITE-ONLY
DDR_CTRL_CTL63  22 - 0 	INT_MASK Mask for controller_int signals from the INT_STATUS parameter.

int_status [3] Set to ’b1 if a correctable ECC event has been detected on a read operation.
int_status [5] Set to ’b1 if an un-correctable ECC event has been detected on a read operation.
int_status [4] Set to ’b1 if another correctable ECC event has been detected on a read operation, prior to the initial event being acknowledged.
int_status [6] Set to ’b1 if another un-correctable ECC event has been detected on a read operation, prior to the initial event being acknowledged.

ddr_ecc_check: check int_status[3:6] != 0000
ddr_ecc_ack: write 1 to int_ack[3:6]
ddr_ecc_print: print ECC status info
*/

#include "ecc_ddr.h"
#include "netx_io_areas.h"
#include "uprintf.h"

/* returns 0: no error, !=0: error */
unsigned long ddr_ecc_check_status(void)
{
	NX4000_DEF_ptDdrCtrlArea;
	unsigned long ulStatus;
	ulStatus = ptDdrCtrlArea->aulDDR_CTRL_CTL[61] & 0x00000078UL;
	return ulStatus;
}

void ddr_ecc_ack(void)
{
	NX4000_DEF_ptDdrCtrlArea;
	//ptDdrCtrlArea->aulDDR_CTRL_CTL[61] &= 0x00000078UL;
	ptDdrCtrlArea->aulDDR_CTRL_CTL[62] = ptDdrCtrlArea->aulDDR_CTRL_CTL[61] & 0x00000078UL;
}

void ddr_ecc_print(void)
{
	NX4000_DEF_ptDdrCtrlArea;
	
	unsigned long ulECC_U_ADDR = ptDdrCtrlArea->aulDDR_CTRL_CTL[42];
	unsigned long ulECC_U_SYND = ptDdrCtrlArea->aulDDR_CTRL_CTL[43];
	unsigned long ulECC_U_DATA = ptDdrCtrlArea->aulDDR_CTRL_CTL[44];
	unsigned long ulECC_U_ID;
	
	unsigned long ulECC_C_ADDR = ptDdrCtrlArea->aulDDR_CTRL_CTL[45];
	unsigned long ulECC_C_SYND = ptDdrCtrlArea->aulDDR_CTRL_CTL[46];
	unsigned long ulECC_C_DATA = ptDdrCtrlArea->aulDDR_CTRL_CTL[47];
	unsigned long ulECC_C_ID;
	
	//NX4000_DDR_CTRL_CTL48_T *ptDDR_CTRL_CTL_48 = (NX4000_DDR_CTRL_CTL48_T *) Adr_NX4000_DDR_CTRL_CTL48;
	
	NX4000_DDR_CTRL_CTL48_T tDDR_CTL48;
	tDDR_CTL48.val = ptDdrCtrlArea->aulDDR_CTRL_CTL[48];
	ulECC_U_ID = tDDR_CTL48.bf.ECC_U_ID;
	ulECC_C_ID = tDDR_CTL48.bf.ECC_C_ID;
	
	unsigned long ulStatus = ptDdrCtrlArea->aulDDR_CTRL_CTL[61] & 0x00000078UL;
	if (ulStatus == 0) 
	{
		uprintf("DDR ECC: no error\n");
	}
	else 
	{
		uprintf("*****************************\n");
		uprintf("DDR ECC: Error detected\n");
		
		
		if ((ulStatus & 0x8UL) != 0)
		{
			uprintf("DDR correctable ECC error: addr: 0x%08x  data: 0x%08x  syndrome: 0x%08x  ID: 0x%08x\n", 
				ulECC_C_ADDR, ulECC_C_DATA, ulECC_C_SYND, ulECC_C_ID);
		
		}
		
		if ((ulStatus & 0x10UL) != 0)
		{
			uprintf("DDR UNcorrectable ECC error: addr: 0x%08x  data: 0x%08x  syndrome: 0x%08x  ID: 0x%08x\n", 
				ulECC_U_ADDR, ulECC_U_DATA, ulECC_U_SYND, ulECC_U_ID);
		}
		
		if ((ulStatus & 0x20UL) != 0)
		{
			uprintf("Additional correctable error\n");
		}
		
		
		if ((ulStatus & 0x40UL) != 0)
		{
			uprintf("Additional UNcorrectable error\n");
		}
		uprintf("*****************************\n");
	}
}

/*
DDR_CTRL_CTL39 0      FWC 	Force a write check. Xor the XOR_CHECK_BITS parameter with the ECC code and write to memory. Set to 1 to trigger. WRITE-ONLY 
DDR_CTRL_CTL40 27 - 0 XOR_CHECK_BITS	Value to xor with generated ECC codes for forced write check. 
DDR_CTRL_CTL41 0      ECC_DISABLE_W_UC_ERR	Controls auto-corruption of ECC when un-correctable errors occur in R/M/W operations. Set to 1 to disable corruption.
*/
unsigned long ddr_ecc_trigger_error (void)
{
	unsigned long ulRes;
	volatile unsigned long *ulAddr = (volatile unsigned long *)0x40200000;
	unsigned long ulWriteVal = 0x12345678;
	unsigned long ulReadVal;
	(void) ulReadVal;
	unsigned int i;
	
	uprintf("DDR ECC: Testing ECC check \n");
	NX4000_DEF_ptDdrCtrlArea;
	ptDdrCtrlArea->aulDDR_CTRL_CTL[40] = 0x0eUL; /* data[30] */
	ptDdrCtrlArea->aulDDR_CTRL_CTL[39] = 0x01UL; /* force write check */
	
	
	for (i=0; i<1000000; i++)
	{
		ulAddr[i] = (unsigned long) (ulWriteVal+i);
	}
	for (i=0; i<1000000; i++)
	{
		ulReadVal = ulAddr[i];
	}
	
	ulReadVal = *ulAddr;
	
	ulRes = ddr_ecc_check_status();
	ddr_ecc_print();
	ddr_ecc_ack();
	
	ptDdrCtrlArea->aulDDR_CTRL_CTL[40] = 0x00UL; /* data[30] */
	ptDdrCtrlArea->aulDDR_CTRL_CTL[39] = 0x00UL; /* clear force write check */
	
	uprintf("DDR ECC: End testing ECC check \n");
	
	return ulRes;
}