#include "ecc_a9.h"
#include "uprintf.h"
//#include <math.h>

//wint ca9_ecc_ctrl_check_1(void);

void wait_for_debug(void)
{
	volatile unsigned long* const ulAddr = (volatile unsigned long*)0x05000000;
	unsigned long ulOldVal = *ulAddr;
	*ulAddr = 1;
	uprintf("Set 0x%08x to 0\n", ulAddr);
	while (*ulAddr == 1)  {}
	uprintf("Continuing\n");
	*ulAddr = ulOldVal;
}

/* clear all error flag registers */
void ca9_ecc_ctrl_clear(void)
{
	NX4000_DEF_ptCA9_EccCtrl;
	uprintf("Clearing CA9 L1 ECC error flags\n");
	
	ptCA9_EccCtrl->ulCPU0_SBE_INT = ptCA9_EccCtrl->ulCPU0_SBE_INT;
	uprintf("1\n");
	ptCA9_EccCtrl->ulCPU1_SBE_INT = ptCA9_EccCtrl->ulCPU1_SBE_INT;
	uprintf("2\n");
	ptCA9_EccCtrl->ulCPU0_DBE_INT = ptCA9_EccCtrl->ulCPU0_DBE_INT;
	uprintf("3\n");
	ptCA9_EccCtrl->ulCPU1_DBE_INT = ptCA9_EccCtrl->ulCPU1_DBE_INT;    
	uprintf("4\n");
}

/* returns 0 if all error flag registers are 0, otherwise 1 */
int ca9_ecc_ctrl_check_print(void) {
	NX4000_DEF_ptCA9_EccCtrl;
	int iRet;
	unsigned long ulCPU0_SBE_INT;
	unsigned long ulCPU1_SBE_INT;
	unsigned long ulCPU0_DBE_INT;
	unsigned long ulCPU1_DBE_INT;
	
	ulCPU0_SBE_INT = ptCA9_EccCtrl->ulCPU0_SBE_INT;
	ulCPU1_SBE_INT = ptCA9_EccCtrl->ulCPU1_SBE_INT;
	ulCPU0_DBE_INT = ptCA9_EccCtrl->ulCPU0_DBE_INT;
	ulCPU1_DBE_INT = ptCA9_EccCtrl->ulCPU1_DBE_INT;
	
	if (ulCPU0_SBE_INT == 0
		&& ulCPU1_SBE_INT == 0
		&& ulCPU0_DBE_INT == 0 
		&& ulCPU1_DBE_INT == 0
		)
	{
		uprintf("CA9 L1 ECC: No error\n");
		iRet = 0;
	}
	else
	{
		uprintf("********************************\n");
		uprintf("CA9 L1 ECC ECC errors detected:\n");
		uprintf("CPU0 SBE: 0x%02x\n", ulCPU0_SBE_INT);
		uprintf("CPU1 SBE: 0x%02x\n", ulCPU1_SBE_INT);
		uprintf("CPU0 DBE: 0x%02x\n", ulCPU0_DBE_INT);
		uprintf("CPU1 DBE: 0x%02x\n", ulCPU1_DBE_INT);
		uprintf("*********************************\n");
		
		iRet = 1;
	}
	
	return iRet;
}



void ca9_ecc_ctrl_show(void) {
	ca9_ecc_ctrl_check_print();
}

/* return s 0 if all error flag registers are 0, otherwise 1 */
int ca9_ecc_ctrl_check(void) {
	//sqrt(42);
	//int iRet = ca9_ecc_ctrl_check_1();
	//while (iRet == 1) {};
	return ca9_ecc_ctrl_check_print();
}

// Get the CPU ID. 0/1 = CA9 core 0/1
static unsigned int ramtest_get_cpuid(void)
{
	unsigned int cpuid;
	__asm__(
		"mrc     p15, 0, %[result], c0, c0, 5 \n\t"
		"ands    %[result], %[result], #0x03 \n\t" 
		: [result] "=r" (cpuid)
		:
		:
		);
	
	return cpuid;
}

/* returns 1 if an error occurs as intended, 0 if it does not */
int ca9_l1_ecc_ctrl_trigger_errors(void){
	unsigned int uiCPUNo;
	int iRes;
	
	NX4000_DEF_ptCA9_EccCtrl;
	unsigned long ulAddr;
	volatile unsigned long *pulAddr;
	unsigned long ulWriteVal;
	unsigned long ulReadVal;
	int i;

	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	
	iRes = 0;
	uiCPUNo = ramtest_get_cpuid(); 
	
	uprintf("\n");
	uprintf("CA9 core %d L1 ECC error test\n", uiCPUNo);
	
	if (uiCPUNo == 0)
	{
		ulAddr = 0x07040000UL;
		ulWriteVal = 0x12345678UL;
	}
	else
	{
		ulAddr = 0x07050000UL;
		ulWriteVal = 0x87654321UL;
	}
	
	pulAddr = (volatile unsigned long *) ulAddr;
	*pulAddr = ulWriteVal;
	__asm__("dsb");
	
	for (i=1; i<8192; i++) 
	{
		pulAddr[i] = (unsigned long) i;
	}
	__asm__("dsb");
	
	/* preload dcache */
	pulStart = pulAddr;
	pulEnd = pulStart + 8192;
	
	for (pulCnt=pulEnd-4; pulCnt>=pulStart; pulCnt-=4)
	{
		__asm__("pld [%[ptr], #0]\n\t" : : [ptr] "r" (pulCnt) :);
	}
	__asm__("dsb");
		
	if (uiCPUNo == 0)
	{
		/* clear error flags */
		uprintf("Clearing CA9 core0 L1 ECC error flags before test\n");
		ptCA9_EccCtrl->ulCPU0_SBE_INT = ptCA9_EccCtrl->ulCPU0_SBE_INT;
		ptCA9_EccCtrl->ulCPU0_DBE_INT = ptCA9_EccCtrl->ulCPU0_DBE_INT;
		__asm__("dsb");
		
		if ((ptCA9_EccCtrl->ulCPU0_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU0_DBE_INT != 0))
		{
			uprintf("Could not clear CA9 core 0 L1 ECC error flags before test\n");
			iRes = 0;
		}
		else
		{
			/* set syndrome bits */
			/* setting/clearing bit 0 (dec_bypass) makes no visible difference to the value read */
			ptCA9_EccCtrl->ulCPU0_DDATA = 0x3;
			//ptCA9_EccCtrl->ulCPU0_DTAG = 0x3;
			__asm__("dsb");
			
			/* memory access should trigger an ECC error */
			ulReadVal = *pulAddr;
			__asm__("dsb");
			
			/* reset syndrome bits */
			ptCA9_EccCtrl->ulCPU0_DDATA = 0;
			ptCA9_EccCtrl->ulCPU0_DTAG = 0;
			__asm__("dsb");
			
			/* check for ECC error */
			ca9_ecc_ctrl_check_print();
			iRes = (ptCA9_EccCtrl->ulCPU0_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU0_DBE_INT != 0);
			
			uprintf("CA9 core 0 addr: 0x%08x  written: 0x%08x  read: 0x%08x\n", ulAddr, ulWriteVal, ulReadVal);

			/* clear error flags */
			uprintf("Clearing CA9 core0 L1 ECC error flags after test\n");
			ptCA9_EccCtrl->ulCPU0_SBE_INT = ptCA9_EccCtrl->ulCPU0_SBE_INT;
			ptCA9_EccCtrl->ulCPU0_DBE_INT = ptCA9_EccCtrl->ulCPU0_DBE_INT;
			__asm__("dsb");
			if ((ptCA9_EccCtrl->ulCPU0_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU0_DBE_INT != 0))
			{
				uprintf("Could not clear CA9 core 0 L1 ECC error flags after test\n");
				iRes = 0;
			}
		}
	}
	else
	{
		uprintf("Clearing CA9 core1 L1 ECC error flags before test\n");
		ptCA9_EccCtrl->ulCPU1_SBE_INT = ptCA9_EccCtrl->ulCPU1_SBE_INT;
		ptCA9_EccCtrl->ulCPU1_DBE_INT = ptCA9_EccCtrl->ulCPU1_DBE_INT;    
		__asm__("dsb");
		
		if ((ptCA9_EccCtrl->ulCPU1_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU1_DBE_INT != 0))
		{
			uprintf("Could not clear CA9 core 1 L1 ECC error flags before test\n");
			iRes = 0;
		}
		else
		{
		
			ptCA9_EccCtrl->ulCPU1_DDATA = 0x3;
			//ptCA9_EccCtrl->ulCPU1_DTAG = 0x3;
			__asm__("dsb");
			
			ulReadVal = *pulAddr;
			__asm__("dsb");
			
			ptCA9_EccCtrl->ulCPU1_DDATA = 0;
			ptCA9_EccCtrl->ulCPU1_DTAG = 0;
			__asm__("dsb");
			
			ca9_ecc_ctrl_check_print();
			iRes = (ptCA9_EccCtrl->ulCPU1_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU1_DBE_INT != 0);
			
			uprintf("CA9 core 1 addr: 0x%08x  written: 0x%08x  read: 0x%08x\n", ulAddr, ulWriteVal, ulReadVal);
			
			uprintf("Clearing CA9 core1 L1 ECC error flags after test\n");
			ptCA9_EccCtrl->ulCPU1_SBE_INT = ptCA9_EccCtrl->ulCPU1_SBE_INT;
			ptCA9_EccCtrl->ulCPU1_DBE_INT = ptCA9_EccCtrl->ulCPU1_DBE_INT;    
			__asm__("dsb");
			if ((ptCA9_EccCtrl->ulCPU1_SBE_INT != 0) || (ptCA9_EccCtrl->ulCPU1_DBE_INT != 0))
			{
				uprintf("Could not clear CA9 core 1 L1 ECC error flags after test\n");
				iRes = 0;
			}
		}
	}
	
	
	if (iRes == 0)
	{   
		uprintf("*****************************\n");
		uprintf("CA9 core %d: L1 cache ECC error test FAILED!\n", uiCPUNo);
		uprintf("*****************************\n");
		uprintf("\n\n");
	}
	else
	{   
		uprintf("*****************************\n");
		uprintf("CA9 core %d: L1 cache ECC error test SUCCEEDED!\n", uiCPUNo);
		uprintf("*****************************\n");
		uprintf("\n\n");
	}
	
	return iRes;
}


/* L2C ECC check: WIP */
int ca9_l2_ecc_ctrl_trigger_errors(void);
int ca9_l2_ecc_ctrl_trigger_errors(void){
	unsigned int uiCPUNo;
	int iRes;
	
	uiCPUNo = ramtest_get_cpuid(); 
	if (uiCPUNo == 0)
	{
		NX4000_DEF_ptCA9_EccCtrl;
		unsigned long ulAddr;
		volatile unsigned long *pulAddr;
		unsigned long ulWriteVal;
		unsigned long ulReadVal;
		//int i;

		volatile unsigned long *pulStart;
		volatile unsigned long *pulEnd;
		volatile unsigned long *pulCnt;
		
		ulAddr = 0x07040000UL;
		ulWriteVal = 0x12345678UL;
		pulAddr = (volatile unsigned long *) ulAddr;
		
		//ca9_ecc_ctrl_clear();
		uprintf("CA9 L2 ECC: triggering errors\n");
		
		*pulAddr = ulWriteVal;
		
		/* test L2 cache ECC */
		
		/* Fill L1 cache with addresses other than pulAddr */
		/*
		pulStart = pulAddr + 0x100;
		pulEnd = pulStart + 0x100 + 8192;
		for (pulCnt=pulStart; pulCnt<pulEnd; pulCnt+=4)
		{
			__asm__("pld [%[ptr], #0]\n\t" : : [ptr] "r" (pulCnt) :);
		}

		__asm__("dsb");
		*/
		/* setting/clearing bit 0 makes no visible difference to the value read */
		ptCA9_EccCtrl->ulPL310_DATA = 0x3;
		//ptCA9_EccCtrl->ulPL310_TAG = 0x3;
		
		__asm__("dsb");
		
		//ulReadVal = *pulAddr;
		pulStart = pulAddr + 0x100;
		pulEnd = pulStart + 0x100 + 8192;
		for (pulCnt=pulStart; pulCnt<pulEnd; pulCnt+=4)
		{
			ulReadVal = *pulCnt;
		}
		ulReadVal = *pulAddr;
		
		__asm__("dsb");
		
		ptCA9_EccCtrl->ulPL310_DATA = 0;
		ptCA9_EccCtrl->ulPL310_TAG = 0;
		
		__asm__("dsb");
		
		iRes = ca9_ecc_ctrl_check_print();
		
		uprintf("addr: 0x%08x  written: 0x%08x  read: 0x%08x\n", ulAddr, ulWriteVal, ulReadVal);
		
		ca9_ecc_ctrl_clear();
		}
	else
	{
		//ulAddr = 0x05048000;
		//ulWriteVal = 0x44;
		iRes = 1;
	}
	
	if (iRes == 0)
	{   
		uprintf("*****************************\n");
		uprintf("CA9 L2 ECC: ECC check failed!\n");
		uprintf("*****************************\n");
	}
	
	return iRes;
}

