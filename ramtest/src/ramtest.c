
#include "ramtest.h"
#include "systime.h"
#include "uprintf.h"

int random_burst(unsigned long* pulStartaddress, unsigned long *pulEndAddress, unsigned long ulSeed);

void ramtest_show_sdram_config(unsigned long ulSdramStart);
unsigned long ram_test_tag_value(RAMTEST_PARAMETER_T *ptRamTestParameter, unsigned long ulValue);
void hexdump_32bit(volatile unsigned long *pulAddr);
void hexdump_32bit_buffered(volatile unsigned long *pulAddr);
static RAMTEST_RESULT_T ram_test_count_addr_32bit(RAMTEST_PARAMETER_T *ptRamTestParameter);


typedef struct RAMTEST_PAIR_STRUCT
{
	unsigned long uiSeed;

} RAMTEST_PAIR_T;

static const RAMTEST_PAIR_T testPairs[6] =
{
	{  414505433   }, /* 64 bit: 9004440025, truncated to 32 bit: 414505433*/
	{  4101696611  }, /* 300454440035 -> 4101696611*/
	{  314159265   },
	{  1215752195  }, /* 100000000003 -> 1215752195*/
	{  99989       },
	{  7271477     }
};



/*-----------------------------------*/

/* DATABUS TEST */
static RAMTEST_RESULT_T ram_test_databus(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	/*
	 * Description: Test the data bus wiring in a memory region by
	 *              performing a walking 1's test at a fixed address
	 *              within that region.  The address (and hence the
	 *              memory region) can be selected by the caller.
	 *
	*/

	volatile unsigned long *pulStart;
	volatile unsigned long *pulCnt;
	unsigned long ulWalkingOnes;
	unsigned long ulReadback;
	unsigned char errorCounter = 0;


	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);

	RAMTEST_RESULT_T tResult;

	tResult = RAMTEST_RESULT_OK;
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	pulCnt = pulStart;

	/*Write Walking Ones */
	for(ulWalkingOnes = 1; ulWalkingOnes!=0; ulWalkingOnes<<=1)
	{
		*pulCnt++ = ulWalkingOnes;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* Read Back walking Ones */


	pulCnt = pulStart;
	for(ulWalkingOnes = 1; ulWalkingOnes != 0; ulWalkingOnes<<=1)
	{
		ulReadback = *pulCnt;
		if(ulReadback != ulWalkingOnes)
		{
			if(errorCounter <= 0) uprintf("! Databus Test failed !\n");
			uprintf("                     DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD \n");
			uprintf("                     3322222222221111111111           \n");
			uprintf("                     10987654321098765432109876543210 \n");
			uprintf("! wrote     value: 0b%032b\n", ulWalkingOnes);
			uprintf("! read back value: 0b%032b\n", ulReadback);

			errorCounter ++;
			tResult = RAMTEST_RESULT_FAILED;
		}

		pulCnt+=1;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	return tResult;
}



static RAMTEST_RESULT_T ram_test_checkerboard_1pass(RAMTEST_PARAMETER_T *ptRamTestParameter, unsigned long ulPattern, unsigned long ulAntiPattern)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	unsigned long ulXor;
	unsigned long ulValue;
	unsigned long ulReadBack;

	tResult =  RAMTEST_RESULT_OK;
	pulStart = (volatile unsigned long*)ptRamTestParameter->ulStart;
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	ulXor = ulPattern ^ ulAntiPattern;

	/*
	 * Fill Ram with checkerboard pattern, e.g.
	 * 10101010101010101010101010101010
	 * 01010101010101010101010101010101
	 */
	pulCnt = pulStart;
	ulValue = ulPattern;

	while(pulCnt<pulEnd)
	{
		*pulCnt = ulValue;
		ulValue ^= ulXor;
		++pulCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* Read Back and compare */

	pulCnt     = pulStart;
	ulValue = ulPattern;
	while(pulCnt < pulEnd)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack != ulValue)
		{
			uprintf("! Checkerboard test at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			uprintf("! wrote value:     0x%08x\n", ulValue);
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

		ulValue ^= ulXor;
		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}



static RAMTEST_RESULT_T ram_test_checkerboard(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult;
	unsigned long pattern 	  = 0xAAAAAAAA;
	unsigned long antipattern = 0x55555555;

	tResult = ram_test_checkerboard_1pass(ptRamTestParameter, pattern, antipattern);
	if (tResult == RAMTEST_RESULT_OK)
	{
		tResult = ram_test_checkerboard_1pass(ptRamTestParameter, antipattern, pattern);
	}

	return tResult;
}



/*
	1: write 0s                         forward
	2: check 0s, write 1s               forward
	   check 1s, write 0s, check 0s     backward
	   write 1s                         forward
	   check 1s, write 0s               forward
	4: check 0s, write 1s               backward
	5: check 1s, write 0s               backward
	6: check 0s                         backward
*/

static RAMTEST_RESULT_T ram_test_marching(RAMTEST_PARAMETER_T *ptRamTestParameter)
{

	RAMTEST_RESULT_T tResult;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	unsigned long ulReadBack;

	unsigned long zero  = 0x00000000;
	unsigned long ones  = 0xFFFFFFFF;

	pulStart = (volatile unsigned long*) (ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*) (ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);


	tResult = RAMTEST_RESULT_OK;

	/*
	 * This test covers all:
	 *    SAF's  (Stuck at Faults)
	 *    TF's   (Transition Faults)
	 *    AF's   (Adress decoder faults)
	 *    CFin's (Coupling faults - inversion coupling)
	 *    CFid's (Coupling faults - idempotent coupling)
	 *    CFst's (State coupling faults)
	 *    SO'F   (Stuck open faults)
	 */


	/* 1 Fill Ram with zeroe's */

	pulCnt = pulStart;

	while(pulCnt < pulEnd)
	{
		*(pulCnt++) = zero;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* 2 Read zeroes, if successful fill with ones */

	pulCnt = pulStart;

	while(pulCnt < pulEnd)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack == zero)
		{
			*pulCnt = ones;
		}
		else
		{
			uprintf("! Marching test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", zero);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

		++pulCnt;

	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	if (tResult == RAMTEST_RESULT_FAILED)
	{
		return tResult;
	}

	/*
	 * next code segment is not part of the marchc- test
	 * it is implemented in order to detect SAF's due to MarchC-'s incapability of detecting these
	 * it is part of mats++
	 */

	pulCnt = pulEnd;

	while(--pulCnt >= pulStart)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack == ones)
		{
			*pulCnt = zero;
		}
		else
		{
			uprintf("! Marching test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", ones);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

		ulReadBack = *pulCnt;
		if(ulReadBack != zero)
		{
			uprintf("! Marching test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", zero);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	if (tResult == RAMTEST_RESULT_FAILED)
	{
		return tResult;
	}

	/* Now fill the ram with ones again in order to proceed with the MarchC- test */

	pulCnt = pulStart;

	while(pulCnt < pulEnd)
	{
		*(pulCnt++) = ones;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);




	/* Continue with marchc- Read ones write back zeros */

	pulCnt = pulStart;

	while(pulCnt < pulEnd)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack == ones)
		{
			*pulCnt = zero;
		}
		else
		{
			uprintf("! Marching test test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", ones);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value:  0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	if (tResult == RAMTEST_RESULT_FAILED)
	{
		return tResult;
	}

	/* 4 Read Zeros write Ones */

	pulCnt = pulEnd;

	while(--pulCnt >= pulStart)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack == zero)
		{
			*pulCnt = ones; // zero ones
		}
		else
		{
			uprintf("! Marching test test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", zero);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	if (tResult == RAMTEST_RESULT_FAILED)
	{
		return tResult;
	}

	/* 5 Read ones write zeros */

	pulCnt = pulEnd;

	while(--pulCnt >= pulStart)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack == ones)
		{
			*pulCnt = zero;
		}
		else
		{
			uprintf("! Marching test test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", ones);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	if (tResult == RAMTEST_RESULT_FAILED)
	{
		return tResult;
	}

	/* Last Step - Read back the zeros */

	pulCnt = pulEnd;

	while(--pulCnt >= pulStart)
	{
		ulReadBack = *pulCnt;
		if(ulReadBack != zero)
		{
			uprintf("! Marching test test failed at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			//uprintf("! wrote value:     0x%08x\n", zero);
			uprintf("! Wrote 0xFFFFFFFF or 0x00000000\n");
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}

	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	return tResult;


}



/* Tag a 32 bit value using a mask and value from test parameters.
   Example: ulValue = 0xdeadbeef, tag mask = 0xff000000, tag value = 0x11000000 -> return value = 0x11adbeef */
unsigned long ram_test_tag_value(RAMTEST_PARAMETER_T *ptRamTestParameter, unsigned long ulValue)
{
	return (ulValue & (~ptRamTestParameter->ulTagMask)) | ptRamTestParameter->ulTagValue;
}

/* Print the surrounding of an error location. */
void hexdump_32bit(volatile unsigned long *pulAddr)
{
	unsigned int iOffset;
	
	for (iOffset = 0; iOffset < 112; iOffset++)
	{
		if ((iOffset & 3UL) == 0)
		{
			uprintf("0x%08x: ", (unsigned long) (pulAddr+iOffset));
		}
		uprintf(" 0x%08x", pulAddr[iOffset]);
		if ((iOffset & 3UL) == 3) 
		{
			uprintf("\n");
		}
	}
}


#define HEXDUMP_BUF_SIZE 112
/* Print the surrounding of an error location. 
   Copy the data to a buffer and then print the buffer. */
void hexdump_32bit_buffered(volatile unsigned long *pulAddr)
{
	unsigned int iOffset;
	unsigned long ulBuf[HEXDUMP_BUF_SIZE];
	
	for (iOffset = 0; iOffset < HEXDUMP_BUF_SIZE; iOffset++)
	{
		ulBuf[iOffset] = pulAddr[iOffset];
	}
	
	for (iOffset = 0; iOffset < HEXDUMP_BUF_SIZE; iOffset++)
	{
		if ((iOffset & 3UL) == 0)
		{
			uprintf("0x%08x: ", (unsigned long) (pulAddr+iOffset));
		}
		uprintf(" 0x%08x", ulBuf[iOffset]);
		if ((iOffset & 3UL) == 3) 
		{
			uprintf("\n");
		}
	}
}


/* Test access sequence. 
   mem[addr] = tag(addr, core_number), e.g. mem[0x40123456] := 0x11123456 on CR7
*/
static RAMTEST_RESULT_T ram_test_count_addr_32bit(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	unsigned long ulCnt;
	unsigned long ulReadBack;

	tResult = RAMTEST_RESULT_OK;
	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);


	/* fill ram */

	pulCnt = pulStart;
	while(pulCnt<pulEnd)
	{
		ulCnt = (unsigned long) pulCnt;
		*(pulCnt) = ram_test_tag_value(ptRamTestParameter, ulCnt);
		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* Read back and compare */

	pulCnt = pulStart;
	while (pulCnt<pulEnd)
	{
		ulCnt = (unsigned long) pulCnt;
		ulReadBack = *pulCnt;

		if (ulReadBack != ram_test_tag_value(ptRamTestParameter, ulCnt))
		{
			uprintf("! 32 bit access at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			uprintf("! wrote value:     0x%08x\n", ram_test_tag_value(ptRamTestParameter, ulCnt));
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			
			{
				unsigned long ulAddr = (unsigned long) pulCnt;
				volatile unsigned long *pulAddr;
				ulAddr = (ulAddr - 128) & 0xFFFFFFF0UL;
				pulAddr = (volatile unsigned long *) ulAddr;

				if (pulAddr < pulStart) 
				{
					pulAddr = pulStart;
				}
				hexdump_32bit_buffered(pulAddr);
				hexdump_32bit_buffered(pulAddr);
			}
			
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
		++pulCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}




unsigned long pseudo_generator(unsigned long number)
{
	/* Works with a LFSR (linear feedback left shift register)
	 * with 32 Bits with MLS (Max Length sequence)
	 * which reproduces only after 2^32-1 generations
	 */

	unsigned long seed = number;

	seed =     ((((seed >> 31)
	            ^ (seed >> 6)
	            ^ (seed >> 4)
	            ^ (seed >> 1)
	            ^  seed)
	            &  0x00000001)
	            << 31)
	            | (seed>>1);

	return seed;
}



/* test byte access */
static RAMTEST_RESULT_T ram_test_08bit(RAMTEST_PARAMETER_T *ptRamTestParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned char *pucStart;
	volatile unsigned char *pucEnd;
	volatile unsigned char *pucCnt;
	unsigned long ulSeed;
	unsigned long ulRandom;
	unsigned char ucRandom;
	unsigned char ucReadBack;

	tResult = RAMTEST_RESULT_OK;
	pucStart = (volatile unsigned char*)(ptRamTestParameter->ulStart); //Start Value
	pucEnd   = (volatile unsigned char*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize); // End value
	ulSeed = ptTestPair->uiSeed;


	/* fill ram */

	ulRandom = ulSeed;
	pucCnt = pucStart;

	while( pucCnt<pucEnd )
	{
		ulRandom = pseudo_generator(ulRandom);
		ucRandom = (unsigned char)((ulRandom)&0x000000ff);
		*pucCnt = ucRandom;
		++pucCnt;
	};

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* read back and compare */

	ulRandom = ulSeed;
	pucCnt = pucStart;

	while(pucCnt<pucEnd)
	{
		ulRandom = pseudo_generator(ulRandom);
		ucRandom = (unsigned char)((ulRandom)&0x000000ff);
		ucReadBack = *pucCnt;
		if (ucReadBack!=ucRandom)
		{
			uprintf("! 8 bit access at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pucCnt, (unsigned long)(pucCnt-pucStart));
			uprintf("! wrote value:     0x%02x\n", ulRandom);
			uprintf("! read back value: 0x%02x\n", ucReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
		++pucCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	return tResult;
}



/* test word access */
static RAMTEST_RESULT_T ram_test_16bit(RAMTEST_PARAMETER_T *ptRamTestParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned short *pusStart;
	volatile unsigned short *pusEnd;
	volatile unsigned short *pusCnt;
	unsigned long ulSeed;
	unsigned long ulRandom;
	unsigned short usRandom;
	unsigned short usReadBack;

	tResult = RAMTEST_RESULT_OK;
	pusStart = (volatile unsigned short*)(ptRamTestParameter->ulStart); //Start Value
	pusEnd   = (volatile unsigned short*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize); // End value
	ulSeed = ptTestPair->uiSeed;


	/* fill ram */

	ulRandom = ulSeed;
	pusCnt = pusStart;

	while( pusCnt<pusEnd )
	{
		ulRandom = pseudo_generator(ulRandom);
		usRandom = (unsigned short)(ulRandom&0x0000ffff);
		*pusCnt = usRandom;
		++pusCnt;
	};

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* read back and compare */

	ulRandom = ulSeed;
	pusCnt = pusStart;

	while( pusCnt<pusEnd )
	{
		ulRandom = pseudo_generator(ulRandom);
		usRandom = (unsigned short)(ulRandom&0x0000ffff);
		usReadBack = *pusCnt;
		if( usReadBack != usRandom )
		{
			uprintf("! 16 bit access at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pusCnt, (unsigned long)(pusCnt-pusStart));
			uprintf("! wrote value:     0x%04x\n", usRandom);
			uprintf("! read back value: 0x%04x\n", usReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
		++pusCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	return tResult;


}


/* Test DWORD access. */
static RAMTEST_RESULT_T ram_test_32bit(RAMTEST_PARAMETER_T *ptRamTestParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	unsigned long ulSeed;
	unsigned long ulRandom;
	unsigned long ulReadBack;

	tResult = RAMTEST_RESULT_OK;
	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	ulSeed   = ptTestPair->uiSeed;


	/* fill ram */

	ulRandom = ulSeed;
	pulCnt = pulStart;

	while(pulCnt<pulEnd)
	{
		ulRandom = pseudo_generator(ulRandom);	//Generate a pseudorandom nr
		*(pulCnt) = ulRandom;
		++pulCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* Read back and compare */

	ulRandom = ulSeed;
	pulCnt = pulStart;

	while (pulCnt<pulEnd)
	{
		ulRandom = pseudo_generator(ulRandom);
		ulReadBack = *pulCnt;

		if (ulReadBack != ulRandom)
		{
			uprintf("! 32 bit access at address 0x%08x failed (offset 0x%08x)\n", (unsigned long)pulCnt, (unsigned long)(pulCnt-pulStart));
			uprintf("! wrote value:     0x%08x\n", ulRandom);
			uprintf("! read back value: 0x%08x\n", ulReadBack);
			tResult = RAMTEST_RESULT_FAILED;
			break;
		}
		++pulCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}


static RAMTEST_RESULT_T ram_test_burst(RAMTEST_PARAMETER_T *ptRamTestParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	unsigned long *pulCnt;
	unsigned long *pulEnd;
	int iResult;
	RAMTEST_RESULT_T tResult;


	pulCnt = (unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd = (unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	iResult = random_burst(pulCnt, pulEnd, ptTestPair->uiSeed);



	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	if( iResult==0 )
	{
		tResult = RAMTEST_RESULT_OK;
	}

	else
	{
		tResult = RAMTEST_RESULT_FAILED;
	}

	return tResult;
}



/*-----------------------------------*/

static RAMTEST_RESULT_T ramtest_pseudorandom(RAMTEST_PARAMETER_T *ptParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	/* This test contains
	 *     8  Bit
	 *     16 Bit
	 *     32 Bit
	 *     and 32 Bit Burst access tests
	 */

	RAMTEST_RESULT_T tResult;
	unsigned long ulCases;


	ulCases = ptParameter->ulCases;
	tResult = RAMTEST_RESULT_OK;


	/* test 8 bit access */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_08BIT)!=0 )
	{
		uprintf(". Testing 8 bit access...\n");
		tResult = ram_test_08bit(ptParameter, ptTestPair);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 8 bit access OK.\n");
		}
		else
		{
			uprintf("! 8 bit access failed.\n");
		}
	}

	/* test 16 bit access */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_16BIT)!=0 )
	{
		uprintf(". Testing 16 bit access...\n");
		tResult = ram_test_16bit(ptParameter, ptTestPair);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 16 bit access OK.\n");
		}
		else
		{
			uprintf("! 16 bit access failed.\n");
		}
	}

	/* test 32 bit access */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_32BIT)!=0 )
	{
		uprintf(". Testing 32 bit access...\n");
		tResult = ram_test_32bit(ptParameter, ptTestPair);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 Bit access OK.\n");
		}
		else
		{
			uprintf("! 32 Bit access failed.\n");
		}
	}


	/* test 32 bit burst access */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_BURST)!=0 )
	{
		uprintf(". Testing 32 bit burst access...\n");
		tResult = ram_test_burst(ptParameter, ptTestPair);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 bit burst access OK.\n");
		}
		else
		{
			uprintf("! 32 bit burst access failed.\n");
		}
	}


	return tResult;
}



/*
 * This test contains
 *     databus
 *     checkerboard
 *     marching C- tests
 *
 * This test needs to be run only one time, because it finds all mistakes it's looking for with 100% probability
 * --> 100% probability for mistakes it's looking for, doesn't find anything it's not looking for
 *
 *     databus test:
 *         looks for faulty databus lines and returns the D0..31 number of faulty line
 *
 *     checkerboard test:
 *         looks for detention faults (leakage faults)
 *
 *     marching C- test:
 *         check description above
 */

RAMTEST_RESULT_T ramtest_deterministic(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tResult;
	unsigned long ulCases;
	ulCases =  ptParameter->ulCases;

	tResult = RAMTEST_RESULT_OK;


	/* Test all Datalines independently from each other */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_DATABUS)!=0 )
	{
		uprintf(". Testing Databus...\n");
		tResult = ram_test_databus(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". Databus test OK.\n");
		}
		else
		{
			uprintf("! Databus test failed.\n");
		}
	}


	/* Test checkerboard pattern for retention + produce hard cluster for burst */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_CHECKERBOARD)!=0 )
	{
		uprintf(". Testing checkerboard pattern...\n");
		tResult = ram_test_checkerboard(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". Checkerboard test OK.\n");
		}
		else
		{
			uprintf("! Checkerboard test failed.\n");
		}
	}

	/* test Marching pattern */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_MARCHC)!=0 )
	{
		uprintf(". Testing Marching Pattern...\n");
		tResult = ram_test_marching(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". Marching test OK\n");
		}
		else
		{
			uprintf("! Marching test failed.\n");
		}
	}

	/* test access sequence */
	if( tResult==RAMTEST_RESULT_OK && (ulCases&RAMTESTCASE_SEQUENCE)!=0 )
	{
		uprintf(". Testing Access Sequence...\n");
//		tResult = ram_test_count_32bit(ptParameter);
		tResult = ram_test_count_addr_32bit(ptParameter);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". Access Sequence test OK\n");
		}
		else
		{
			uprintf("! Access Sequence test failed.\n");
		}
	}
	

	return tResult;
}

/* If the test area is in SDRAM, print the controller settings. */
void ramtest_show_sdram_config(unsigned long ulSdramStart)
{
	unsigned long ulSdramGeneralCtrl;
	unsigned long ulSdramTimingCtrl;
	unsigned long ulSdramMr;
#if ASIC_TYP==500
	NX500_EXT_SDRAM_CTRL_AREA_T *ptSdram;
#elif ASIC_TYP==4000
	NX4000_EXT_SDRAM_CTRL_AREA_T *ptSdram;
#else
	HOSTADEF(SDRAM) *ptSdram;
#endif

	/* Get the SDRAM controller address from the test area address. */
	ptSdram = NULL;
#if ASIC_TYP==4000

	if( ulSdramStart>=HOSTADDR(mem_sdram) && ulSdramStart<=HOSTADR(mem_sdram_sdram_end) )
	{
		ptSdram = (NX4000_EXT_SDRAM_CTRL_AREA_T*)HOSTADDR(ext_sdram_ctrl);
	}
	else 	if( ulSdramStart>=HOSTADDR(hif_sdram) && ulSdramStart<=HOSTADR(hif_sdram_sdram_end) )
	{
		ptSdram = (NX4000_EXT_SDRAM_CTRL_AREA_T*)HOSTADDR(hif_sdram_ctrl);
	}
	
#elif ASIC_TYP==500
	if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (NX500_EXT_SDRAM_CTRL_AREA_T*)HOSTADDR(ext_sdram_ctrl);
	}
#elif ASIC_TYP==50
	if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
#elif ASIC_TYP==56
	if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
	else if( ulSdramStart>=HOSTADDR(hif_sdram_lite) && ulSdramStart<=HOSTADR(hif_sdram_lite_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(hif_sdram_ctrl);
	}
#elif ASIC_TYP==10
	if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
#endif

	if( ptSdram!=NULL )
	{
		ulSdramGeneralCtrl	= ptSdram->ulSdram_general_ctrl ; 
		ulSdramTimingCtrl	= ptSdram->ulSdram_timing_ctrl  ; 
		ulSdramMr			= ptSdram->ulSdram_mr           ; 
		
		//sim_message(". SDRAM controller:    ", disp_data, (unsigned long) ptSdram);
		//sim_message(". SDRAM general ctrl:  ", disp_data, ulSdramGeneralCtrl);
		//sim_message(". SDRAM timing ctrl:   ", disp_data, ulSdramTimingCtrl);
		//sim_message(". SDRAM mode register: ", disp_data, ulSdramMr);
		
		uprintf("\n");
		uprintf(". SDRAM controller:    0x%08x\n", (unsigned long) ptSdram);
		uprintf(". SDRAM general ctrl:  0x%08x\n", ulSdramGeneralCtrl);
		uprintf(". SDRAM timing ctrl:   0x%08x\n", ulSdramTimingCtrl);
		uprintf(". SDRAM mode register: 0x%08x\n", ulSdramMr);
		uprintf("\n");
	}
}


RAMTEST_RESULT_T ramtest_run(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tRamTestResult;
	unsigned long ulCases;
	unsigned long ulLoopCnt;
	unsigned long ulLoopMax;
	unsigned int  uiTestCnt;


	/* Show welcome message. */
	uprintf(". Ram start address:      0x%08x\n", ptParameter->ulStart);
	uprintf(". Ram size in bytes:      0x%08x\n", ptParameter->ulSize);
	ramtest_show_sdram_config( ptParameter->ulStart);
	uprintf(". Test cases:\n");
	ulCases = ptParameter->ulCases;

	if( ulCases==0 )
	{
		uprintf("    none\n");
	}
	if( (ulCases&RAMTESTCASE_DATABUS)!=0 )
	{
		uprintf("     Databus\n");
	}
	if( (ulCases&RAMTESTCASE_MARCHC)!=0 )
	{
		uprintf("     Marching C-\n");
	}
	if( (ulCases&RAMTESTCASE_CHECKERBOARD)!=0 )
	{
		uprintf("     Checkerboard\n");
	}
	if( (ulCases&RAMTESTCASE_SEQUENCE)!=0 )
	{
		uprintf("     Access sequence\n");
	}
	if( (ulCases&RAMTESTCASE_08BIT)!=0 )
	{
		uprintf("     8 bit\n");
	}
	if( (ulCases&RAMTESTCASE_16BIT)!=0 )
	{
		uprintf("     16 bit\n");
	}
	if( (ulCases&RAMTESTCASE_32BIT)!=0 )
	{
		uprintf("     32 bit\n");
	}
	if( (ulCases&RAMTESTCASE_BURST)!=0 )
	{
		uprintf("     Burst\n");
	}

	ramtest_print_performance_tests(ptParameter);

	ulLoopMax = ptParameter->ulLoops;
	if( ulLoopMax==0 )
	{
		uprintf(". Loops:                  endless\n");
	}
	else
	{
		uprintf(". Loops:                  0x%08x\n", ulLoopMax);
	}
	uprintf("\n\n");

	/* Run test cases. */
	ulLoopCnt = 0;

	do
	{
		++ulLoopCnt;

		uprintf("****************************************\n");
		uprintf("*                                      *\n");
		uprintf("*  Deterministic test - Loop %08d  *\n", ulLoopCnt);
		uprintf("*                                      *\n");
		uprintf("****************************************\n");

		tRamTestResult = ramtest_deterministic(ptParameter);
		if(tRamTestResult == RAMTEST_RESULT_FAILED) break;


		uprintf("****************************************\n");
		uprintf("*                                      *\n");
		uprintf("*  Random number test - Loop %08d  *\n", ulLoopCnt);
		uprintf("*                                      *\n");
		uprintf("****************************************\n");

		for(uiTestCnt=0; uiTestCnt<(sizeof(testPairs)/sizeof(RAMTEST_PAIR_T)); ++uiTestCnt )
		{
			uprintf(". Start test case %d of %d\n", uiTestCnt+1, sizeof(testPairs)/sizeof(RAMTEST_PAIR_T));
			tRamTestResult = ramtest_pseudorandom(ptParameter, testPairs+uiTestCnt);
			if( tRamTestResult!=RAMTEST_RESULT_OK )
			{
				uprintf("! Test case %d failed.\n", uiTestCnt+1);
				break;
			}
			uprintf(". Test case %d OK.\n", uiTestCnt+1);
		}


		/* TODO: does it make sense to run the performance tests multiple times in a loop? */
		if (ptParameter->ulPerfTestCases != 0)
		{
			uprintf("****************************************\n");
			uprintf("*                                      *\n");
			uprintf("*  Performance Tests - Loop %08d   *\n", ulLoopCnt);
			uprintf("*                                      *\n");
			uprintf("****************************************\n");

			tRamTestResult = ramtest_run_performance_tests(ptParameter);
			if( tRamTestResult!=RAMTEST_RESULT_OK ) break;
		}


		if( tRamTestResult==RAMTEST_RESULT_OK )
		{
			/* Test loop OK. */
			uprintf("* OK *\n");
		}

		if( ulLoopMax!=0 && ulLoopCnt>=ulLoopMax )
		{
			break;
		}
	} while(tRamTestResult==RAMTEST_RESULT_OK);

	ramtest_show_sdram_config( ptParameter->ulStart);

	return tRamTestResult;
}

