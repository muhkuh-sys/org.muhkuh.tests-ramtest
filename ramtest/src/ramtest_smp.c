#include "ramtest_smp.h"
#include "uprintf.h"

#ifdef ECC
#include "ramtest_ecc.h"
#define CHECK_ECC(res) res = ramtest_ecc_check_wrapper(res);
#else
#define CHECK_ECC(res)
#endif

/* todo: 
- pass CPU ID in parameters  (optional)
- pass loop counter in parameters
*/

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


volatile unsigned long ulSync0;
volatile unsigned long ulSync1;
/*
	core 0: copy sync1 and wait for a change while incrementing sync0
	core 1: copy sync0 and wait for a change while incrementing sync1
*/

void sync_a9_cores(void)
{
	unsigned int uiCPUNo;
	unsigned long ulVal;
	uiCPUNo = ramtest_get_cpuid(); 
	
	if (uiCPUNo == 0)
	{
		ulVal = ulSync1;
		do 
		{
			++ulSync0;
		}while (ulVal == ulSync1); 
	}
	else
	{
		ulVal = ulSync0;
		do 
		{
			++ulSync1;
		}while (ulVal == ulSync0); 
	}
}



/*
   The test area is expected to be 32 KB in size, and the same for both cores.
   Each core writes a dword (with a certain format) and then waits until a dword (with a 
   certain format) is written by the other core. 
   Core 0 writes the first 32 bit of a 64 bit word and waits on the second 32 bits.
   Core 1 writes the second 32 bit ad waits on the first.

   0x05040000: 0x222d0000 0x442d0004 0x222d0008 0x442d000c 
   
   bit 31-24  CPU tag (x022/0x44)
   bit 23     0
   bit 22-16  counter
   bit 15-0   address
 */


static RAMTEST_RESULT_T ramtest_smp_alternate32(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult;
	unsigned int uiCPUNo;
	unsigned long ulCount;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulWrite;
	volatile unsigned long *pulRead;
	unsigned long ulWriteVal;
	unsigned long ulCheckVal;
	unsigned long ulReadVal;
	
	unsigned long ulMask;
	unsigned long ulWTag;
	unsigned long ulRTag;
	
	tResult = RAMTEST_RESULT_OK;
	uiCPUNo = ramtest_get_cpuid(); 
	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	
	if (uiCPUNo == 0)
	{
		pulWrite = pulStart;
		pulRead = pulStart+1;
		ulWTag = 0x22UL;
		ulRTag = 0x44UL; 
	}
	else
	{
		pulWrite = pulStart+1;
		pulRead = pulStart;
		ulWTag = 0x44UL;
		ulRTag = 0x22UL; 
	}
	ulCount = ptRamTestParameter->ulLoopCnt & 0x7fUL; /* bit 23 == 0 */
	ulWTag = (ulWTag<<24) | (ulCount<<16);
	ulRTag = (ulRTag<<24) | (ulCount<<16);
	ulMask = 0x0000ffffUL;
	
	
	while ((pulWrite < pulEnd) && (tResult == RAMTEST_RESULT_OK)) {
		ulWriteVal = (((unsigned long) pulWrite) & ulMask )| ulWTag;
		ulCheckVal = (((unsigned long) pulRead) & ulMask )| ulRTag;
		
		*pulWrite = ulWriteVal;
		while (ulCheckVal != (ulReadVal=*pulRead)) {}
		
		pulWrite += 2;
		pulRead += 2;
	}
	
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}

/* The test area is expected to be 64 KB and the same for both CPUs. 
   It is split into 2x 32 KB areas, areas 1 and 2. 
   Core 0 fills area 1 and core 1 fills area 2.
   Then, each core waits for the last value in the area of the other CPU to appear.
   Then, each core preloads its cache from the area of the other CPU.
   Then, each core checks the area of the other CPU.
   
   0x05040000 0x22800000 0x22800004 0x22800008 0x2280000c
   ...
   0x05044000 0x44800000 0x44800004 0x44800008 0x4480000c
   ...
   
   bit 31-24  CPU tag (x022/0x44)
   bit 23     1
   bit 22-16  counter
   bit 15-0   address
 */
static RAMTEST_RESULT_T ramtest_smp_block32(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned long* pulStart;
	volatile unsigned long* pulEnd;
	volatile unsigned long* pulStart1;
	volatile unsigned long* pulEnd1;
	volatile unsigned long* pulStart2;
	volatile unsigned long* pulEnd2;
	volatile unsigned long* pulCnt;
	unsigned long ulVal;
	unsigned int uiCPUNo;
	unsigned long ulCount;
	unsigned long ulMask;
	unsigned long ulWTag;
	unsigned long ulRTag;
	
	tResult = RAMTEST_RESULT_OK;
	
	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	uiCPUNo = ramtest_get_cpuid(); 
	
	if (uiCPUNo == 0)
	{
		pulStart1 = pulStart;
		pulEnd1   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize/2);
		pulStart2 = pulEnd1;
		pulEnd2   = pulEnd;
		ulWTag = 0x22UL;
		ulRTag = 0x44UL; 
		
	}
	else
	{
		pulStart2 = pulStart;
		pulEnd2   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize/2);
		pulStart1 = pulEnd2;
		pulEnd1   = pulEnd;
		ulWTag = 0x44UL;
		ulRTag = 0x22UL; 
	}
	ulCount = ptRamTestParameter->ulLoopCnt & 0x7fUL; /* bit 23 == 1 */
	ulWTag = ((ulWTag<<24) | (ulCount<<16)) | (0x80UL<<16);
	ulRTag = ((ulRTag<<24) | (ulCount<<16)) | (0x80UL<<16);
	ulMask = 0x0000ffffUL;
	
	/* fill area 1 (cached) */
	for (pulCnt = pulStart1; pulCnt < pulEnd1; pulCnt++)
	{
		ulVal = (((unsigned long) pulCnt) & ulMask) | ulWTag;
		*pulCnt = ulVal;
	}
	/* wait for last byte in area 2   todo: abort if the value does not appear for some time */
	pulCnt = pulEnd2-1;
	ulVal = (((unsigned long) pulCnt) & ulMask )| ulRTag;
	while (*pulCnt != ulVal) {}
	
	/* preload area 2 into dcache */
	for (pulCnt = pulStart2; pulCnt < pulEnd2; pulCnt++)
	{
		__asm__("pld [%[ptr], #0]\n\t" : : [ptr] "r" (pulCnt) :);
	}
	
	/* check area 2 contents */
	for (pulCnt = pulStart2; (pulCnt < pulEnd2) && (tResult == RAMTEST_RESULT_OK); pulCnt++)
	{
		ulVal = (((unsigned long) pulCnt) & ulMask )| ulRTag;
		if (*pulCnt != ulVal) 
		{
			tResult = RAMTEST_RESULT_FAILED;
		}
	}
	
	return tResult;
}


RAMTEST_RESULT_T ramtest_smp(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tResult;
	unsigned long ulCases;
	
	uprintf("Sync\n");
	sync_a9_cores();
	uprintf("Sync done\n");
	
	ulCases =  ptParameter->ulCases;
	tResult = RAMTEST_RESULT_OK;
	
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_CA9SMP_ALTERNATE)!=0 )
	{
		uprintf(". Testing L1C/SMP with alternating reads and writes...\n");
		tResult = ramtest_smp_alternate32(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". L1C/SMP test OK.\n");
		}
		else
		{
			uprintf("! L1C/SMP test failed.\n");
		}
		CHECK_ECC(tResult)
	}


	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_CA9SMP_BLOCK)!=0 )
	{
		uprintf(". Testing L1C/SMP with blocks/preload ...\n");
		tResult = ramtest_smp_block32(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". L1C/SMP block test OK\n");
		}
		else
		{
			uprintf("! L1C/SMP block test failed.\n");
		}
		CHECK_ECC(tResult)
	}
	return tResult;
}
