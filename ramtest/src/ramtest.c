
/*
	20.10.15
	Continue testing in spite of errors.
	Print expected and read value in one line.
	
	22.10.15
	introduced error counter with maximum values for printing and aborting.
	Todo: max. values are hardcoded, turn into parameters passed down from Lua
	unified random test into one routine 
	random test: re-configure memory for writing and verifying
	todo: pass sdram configs down from script
	
 */

#include "ramtest.h"
#include "systime.h"
#include "uprintf.h"

int random_burst(unsigned long* pulStartaddress, unsigned long *pulEndAddress, unsigned long ulSeed);

/* configurations for pseudorandom test */

typedef struct RAMTEST_PAIR_STRUCT
{
	unsigned long uiSeed;

} RAMTEST_PAIR_T;

/* 
Write: test config       Verify: test config       seed 0:   414505433  0x18b4d9d9
Write: known-good config Verify: test config       seed 1:   4101696611 0xf47aec63  
Write: test config       Verify: known-good config seed 2:   314159265  0x12b9b0a1
*/
#if 1
static const RAMTEST_PAIR_T testPairs[6] =
{
	{  414505433       }, /* 64 bit: 9004440025 */
	{  4101696611      }, /* 64 bit: 300454440035 */ 
	{  314159265       },
	{  1215752195      }, /* 64 bit: 100000000003 */
	{  99989           },
	{  7271477         }
};

#else

static const RAMTEST_PAIR_T testPairs[1] =
{
	{  414505433      }
};
#endif




#if ASIC_TYP==500
	#define SDRAM_CTRL_AREA_T NX500_EXT_SDRAM_CTRL_AREA_T
#else
	#define SDRAM_CTRL_AREA_T HOSTADEF(SDRAM)
#endif

typedef struct{
	unsigned long ulSdramGeneralCtrl;
	unsigned long ulSdramTimingCtrl;
	unsigned long ulSdramMr;
} SDRAM_PARAM_T;


/* disable SDRAM, setup SDRAM and wait for SDRAM ready = 1 */
SDRAM_CTRL_AREA_T* ramtest_get_controller_addr(unsigned long ulSdramStart);
int set_sdram_config(SDRAM_CTRL_AREA_T* ptSdram, SDRAM_PARAM_T* ptSdramParam);
int get_sdram_config(SDRAM_CTRL_AREA_T* ptSdram, SDRAM_PARAM_T* ptSdramParam);
void ramtest_show_sdram_config(unsigned long ulSdramStart);

static RAMTEST_RESULT_T ramtest_pseudorandom(
	RAMTEST_PARAMETER_T *ptRamTestParameter, 
	const RAMTEST_PAIR_T *ptTestPair,
	SDRAM_PARAM_T *ptWriteParams,
	int iWriteWidth,
	SDRAM_PARAM_T *ptVerifyParams,
	int iVerifyWidth
	);


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
	unsigned char errorCounter = 0;
	unsigned long ulReadback;

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
			/*if(errorCounter <= 0)*/ 
			uprintf("! Databus Test failed! wrote 0x%08x  read 0x%08x\n", ulWalkingOnes, ulReadback);
			uprintf("!                    DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD \n");
			uprintf("!                    3322222222221111111111           \n");
			uprintf("!                    10987654321098765432109876543210 \n");
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

	int iErrorCount = 0;
	int iErrorCountMaxPrint = 200; /* TODO: make this a parameter */
	int iErrorCountMaxAbort = 200; /* TODO: make this a parameter */
	

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
				tResult = RAMTEST_RESULT_FAILED;
				++iErrorCount;
				if (iErrorCount <= iErrorCountMaxPrint)
				{
				uprintf("! Checkerboard test failed at address 0x%08x offset 0x%08x: wrote 0x%08x, read 0x%08x, xor 0x%08x \n", 
					(unsigned long)pulCnt, 
					(unsigned long)(pulCnt-pulStart),
					ulValue,
					ulReadBack,
					ulValue ^ ulReadBack
					);
				}
				if (iErrorCount >= iErrorCountMaxAbort)
				{
					break;
				}
		}

		ulValue ^= ulXor;
		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}



static RAMTEST_RESULT_T ram_test_checkerboard(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult1;
	RAMTEST_RESULT_T tResult2;
	unsigned long pattern 	  = 0xAAAAAAAA;
	unsigned long antipattern = 0x55555555;

	tResult1 = ram_test_checkerboard_1pass(ptRamTestParameter, pattern, antipattern);
	tResult2 = ram_test_checkerboard_1pass(ptRamTestParameter, antipattern, pattern);
	return (tResult1 == RAMTEST_RESULT_OK) && (tResult2 == RAMTEST_RESULT_OK)? RAMTEST_RESULT_OK:RAMTEST_RESULT_FAILED;

	/*
	if (tResult == RAMTEST_RESULT_OK)
	{
		tResult = ram_test_checkerboard_1pass(ptRamTestParameter, antipattern, pattern);
	}
	return tResult;
	*/
}

/*
	This test covers all:
		SAF's  (Stuck at Faults)
		TF's   (Transition Faults)
		AF's   (Adress decoder faults)
		CFin's (Coupling faults - inversion coupling)
		CFid's (Coupling faults - idempotent coupling)
		CFst's (State coupling faults)
		SO'F   (Stuck open faults)
	
	
	1:  forward   write 0s                         
	2:  forward   check 0s, write 1s               
	    backward  check 1s, write 0s, check 0s     
	    forward   write 1s                         
	    forward   check 1s, write 0s               
	4:  backward  check 0s, write 1s               
	5:  backward  check 1s, write 0s               
	6:  backward  check 0s                         
*/
	

/* read back and check 
   uses variables pulCnt, pulStart, ulReadback */
#define MARCH_CHECK(ulCheckVal)\
	ulReadback = *pulCnt;\
	if(ulReadback != ulCheckVal)\
	{\
		tResult = RAMTEST_RESULT_FAILED; \
		++iErrorCount;\
		if (iErrorCount <= iErrorCountMaxPrint)\
		{\
			uprintf("! Marching test failed at address 0x%08x (offset 0x%08x): wrote 0x%08x  read 0x%08x  xor 0x%08x\n", \
			(unsigned long)pulCnt, \
			(unsigned long)(pulCnt-pulStart), \
			ulCheckVal, \
			ulReadback, \
			ulCheckVal ^ ulReadback \
			); \
		}\
		if (iErrorCount >= iErrorCountMaxAbort)\
		{\
			break;\
		}\
	}

#define RETURN_ON_ERROR\
	if (tResult == RAMTEST_RESULT_FAILED)\
	{\
		return tResult;\
	}
	
static RAMTEST_RESULT_T ram_test_marching(RAMTEST_PARAMETER_T *ptRamTestParameter)
{
	RAMTEST_RESULT_T tResult;
	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	volatile unsigned long ulReadback;

	unsigned long zero  = 0x00000000;
	unsigned long ones  = 0xFFFFFFFF;

	pulStart = (volatile unsigned long*) (ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*) (ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);

	int iErrorCount = 0;
	int iErrorCountMaxPrint = 200; /* TODO: make this a parameter */
	int iErrorCountMaxAbort = 200; /* TODO: make this a parameter */

	tResult = RAMTEST_RESULT_OK;


	/* 1 Fill Ram with zeroe's */
	/* forward-fill with 0 */
	pulCnt = pulStart;
	while(pulCnt < pulEnd)
	{
		*(pulCnt++) = zero;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* 2 Read zeroes, if successful fill with ones */
	/* forward check 0 fill 1 */
	pulCnt = pulStart;
	while(pulCnt < pulEnd)
	{
		MARCH_CHECK(zero)
		*pulCnt = ones;
		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* RETURN_ON_ERROR */
	
	
	/*
	 * next code segment is not part of the marchc- test
	 * it is implemented in order to detect SAF's due to MarchC-'s incapability of detecting these
	 * it is part of mats++
	 */
	/* backward check 1 fill 0 check 0 */
	pulCnt = pulEnd;
	while(--pulCnt >= pulStart)
	{
		MARCH_CHECK(ones)
		*pulCnt = zero;
		MARCH_CHECK(zero)
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* RETURN_ON_ERROR */
	
	
	/* Now fill the ram with ones again in order to proceed with the MarchC- test */
	/* forward fill 1 */
	pulCnt = pulStart;
	while(pulCnt < pulEnd)
	{
		*(pulCnt++) = ones;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);


	/* Continue with marchc- Read ones write back zeros */
	/* forward check 1 fill 0 */
	pulCnt = pulStart;
	while(pulCnt < pulEnd)
	{
		MARCH_CHECK(ones)
		*pulCnt = zero;
		++pulCnt;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* RETURN_ON_ERROR */
	
	
	/* 4 Read Zeros write Ones */
	/* backward check 0 fill 1 */
	
	pulCnt = pulEnd;
	while(--pulCnt >= pulStart)
	{
		MARCH_CHECK(zero)
		*pulCnt = ones; // zero ones
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* RETURN_ON_ERROR */
	
	
	/* 5 Read ones write zeros */
	/* backward check 1 fill 0 */
	pulCnt = pulEnd;
	while(--pulCnt >= pulStart)
	{
		MARCH_CHECK(ones)
		*pulCnt = zero;
	}
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	/* RETURN_ON_ERROR */
	
	
	/* Last Step - Read back the zeros */
	/* backward check 0 */
	pulCnt = pulEnd;
	while(--pulCnt >= pulStart)
	{
		MARCH_CHECK(zero)
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


#if 0
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
			uprintf("! 8 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%02x  read 0x%02x  xor 0x%02x\n", 
				(unsigned long)pucCnt, 
				(unsigned long)(pucCnt-pucStart),
				ucRandom,
				ucReadBack,
				ucRandom ^ ucReadBack
				);
			tResult = RAMTEST_RESULT_FAILED;
			/* break; */
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
			uprintf("! 16 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%04x  read 0x%04x  xor 0x%04x\n", 
			(unsigned long)pusCnt, 
			(unsigned long)(pusCnt-pusStart),
			usRandom,
			usReadBack,
			usRandom ^ usReadBack
			);
			tResult = RAMTEST_RESULT_FAILED;
			/* break; */
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
		*pulCnt = ulRandom;
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
			uprintf("! 32 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%08x  read 0x%08x  xor 0x%08x\n", 
				(unsigned long)pulCnt, 
				(unsigned long)(pulCnt-pulStart),
				ulRandom,
				ulReadBack,
				ulRandom ^ ulReadBack
				);
			tResult = RAMTEST_RESULT_FAILED;
			/* break; */
		}
		++pulCnt;
	}

	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);

	return tResult;
}
#endif

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

/*
	Random data test.
	Step 1: configure SDRAM using ptWriteParams 
	Step 2: fill RAM area with random data using byte/word/dword accesses
	Step 3: configure SDRAM using ptVerifyParams 
	Step 4: verify RAM area using byte/word/dword accesses
	All steps are optional.
*/
static RAMTEST_RESULT_T ramtest_pseudorandom(
	RAMTEST_PARAMETER_T *ptRamTestParameter, 
	const RAMTEST_PAIR_T *ptTestPair,
	SDRAM_PARAM_T *ptWriteParams,
	int iWriteWidth,
	SDRAM_PARAM_T *ptVerifyParams,
	int iVerifyWidth
	)
{
	SDRAM_CTRL_AREA_T* ptSdramCtrl; 
	RAMTEST_RESULT_T tResult;

	volatile unsigned long *pulStart;
	volatile unsigned long *pulEnd;
	volatile unsigned long *pulCnt;
	
	volatile unsigned short *pusStart;
	volatile unsigned short *pusEnd;
	volatile unsigned short *pusCnt;
	
	volatile unsigned char *pucStart;
	volatile unsigned char *pucEnd;
	volatile unsigned char *pucCnt;
	
	unsigned long   ulSeed;
	unsigned long   ulRandom;
	unsigned short  usRandom;
	unsigned char   ucRandom;
	unsigned long   ulReadBack;
	unsigned short  usReadBack;
	unsigned char   ucReadBack;

	int iErrorCount = 0;
	int iErrorCountMaxPrint = 200; /* TODO: make this a parameter */
	int iErrorCountMaxAbort = 200; /* TODO: make this a parameter */
	
	tResult = RAMTEST_RESULT_OK;
	
	ulSeed = ptTestPair->uiSeed;
	uprintf(". Seed: 0x%08x\n", ulSeed);
	
	pucStart = (volatile unsigned char*)(ptRamTestParameter->ulStart);
	pucEnd   = (volatile unsigned char*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	
	pusStart = (volatile unsigned short*)(ptRamTestParameter->ulStart);
	pusEnd   = (volatile unsigned short*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);
	
	pulStart = (volatile unsigned long*)(ptRamTestParameter->ulStart);
	pulEnd   = (volatile unsigned long*)(ptRamTestParameter->ulStart + ptRamTestParameter->ulSize);

	ptSdramCtrl = ramtest_get_controller_addr(ptRamTestParameter->ulStart);

	/* Reconfigure SDRAM controller for write pass*/
	if ((ptWriteParams != NULL) && (ptSdramCtrl != NULL))
	{
		uprintf("SDRAM config:");
		set_sdram_config(ptSdramCtrl, ptWriteParams);
		ramtest_show_sdram_config(ptRamTestParameter->ulStart);
	}
	
	
	/* Fill ram with random data. */
	if (iWriteWidth == 8)
	{
		uprintf("Writing\n");
		ulRandom = ulSeed;
		for (pucCnt = pucStart; pucCnt<pucEnd; ++pucCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			ucRandom = (unsigned char)(ulRandom&0x000000ff);
			*pucCnt = ucRandom;
		}
	} 
	else if (iWriteWidth == 16)
	{
		uprintf("Writing\n");
		ulRandom = ulSeed;
		for (pusCnt = pusStart; pusCnt<pusEnd; ++pusCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			usRandom = (unsigned short)(ulRandom&0x0000ffff);
			*pusCnt = usRandom;
		}
	} 
	else if (iWriteWidth == 32)
	{
		uprintf("Writing\n");
		ulRandom = ulSeed;
		for (pulCnt = pulStart; pulCnt<pulEnd; ++pulCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			*pulCnt = ulRandom;
		}
	} 
	
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	
	/* Reconfigure SDRAM controller for verify pass*/
	if ((ptVerifyParams != NULL) && (ptSdramCtrl != NULL))
	{
		uprintf("SDRAM config:");
		set_sdram_config(ptSdramCtrl, ptVerifyParams);
		ramtest_show_sdram_config(ptRamTestParameter->ulStart);
	}
	
	/* Verify the random data. */
	
	if (iVerifyWidth == 8)
	{
		uprintf("Verifying\n");
		ulRandom = ulSeed;
		for (pucCnt = pucStart; pucCnt<pucEnd; ++pucCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			ucRandom = (unsigned char)(ulRandom&0x000000ff);
		/*	VERIFY_MEM("8 bit access", "0x%02x", ucRandom, ucReadBack, pucCnt, pucStart) */
			ucReadBack = *pucCnt;
			if (ucReadBack!=ucRandom)
			{
				tResult = RAMTEST_RESULT_FAILED;
				++iErrorCount;
				if (iErrorCount <= iErrorCountMaxPrint)
				{
					uprintf("! 8 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%02x  read 0x%02x  xor 0x%02x\n", 
						(unsigned long)pucCnt, 
						(unsigned long)(pucCnt-pucStart),
						ucRandom,
						ucReadBack,
						ucRandom ^ ucReadBack
						);
				}
				if (iErrorCount >= iErrorCountMaxAbort)
				{
					break;
				}
			}
		}
	} 
	else if (iVerifyWidth == 16)
	{
		uprintf("Verifying\n");
		ulRandom = ulSeed;
		for (pusCnt = pusStart; pusCnt<pusEnd; ++pusCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			usRandom = (unsigned short)(ulRandom&0x0000ffff);
			usReadBack = *pusCnt;
			if( usReadBack != usRandom )
			{
				tResult = RAMTEST_RESULT_FAILED;
				++iErrorCount;
				if (iErrorCount <= iErrorCountMaxPrint)
				{
					uprintf("! 16 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%04x  read 0x%04x  xor 0x%04x\n", 
						(unsigned long)pusCnt, 
						(unsigned long)(pusCnt-pusStart),
						usRandom,
						usReadBack,
						usRandom ^ usReadBack
						);
				}
				if (iErrorCount >= iErrorCountMaxAbort)
				{
					break;
				}
			}
		}
	} 
	else if (iVerifyWidth == 32)
	{
		uprintf("Verifying\n");
		ulRandom = ulSeed;
		for (pulCnt = pulStart; pulCnt<pulEnd; ++pulCnt)
		{
			ulRandom = pseudo_generator(ulRandom);
			ulReadBack = *pulCnt;
	
			if (ulReadBack != ulRandom)
			{
				tResult = RAMTEST_RESULT_FAILED;
				++iErrorCount;
				if (iErrorCount <= iErrorCountMaxPrint)
				{
					uprintf("! 32 bit access at address 0x%08x failed (offset 0x%08x): wrote 0x%08x  read 0x%08x  xor 0x%08x\n", 
						(unsigned long)pulCnt, 
						(unsigned long)(pulCnt-pulStart),
						ulRandom,
						ulReadBack,
						ulRandom ^ ulReadBack
						);
				}
				if (iErrorCount >= iErrorCountMaxAbort)
				{
					break;
				}
			}
		}
	} 
	
	ptRamTestParameter->pfnProgress(ptRamTestParameter, RAMTEST_RESULT_OK);
	
	return tResult;
}


/* --------------------------------------------------------------------------*/
/* Get the SDRAM controller address from the test area address. */
SDRAM_CTRL_AREA_T* ramtest_get_controller_addr(unsigned long ulSdramStart)
{
	SDRAM_CTRL_AREA_T* ptSdram = NULL;
	
#if ASIC_TYP==500
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

	return ptSdram;
}

/* --------------------------------------------------------------------------*/
int set_sdram_config(SDRAM_CTRL_AREA_T* ptSdram, SDRAM_PARAM_T* ptSdramParam)
{
	int iRet; 
	
	if (ptSdram != NULL)
	{
		ptSdram->ulSdram_general_ctrl = 0;
		ptSdram->ulSdram_timing_ctrl  = ptSdramParam->ulSdramTimingCtrl; 
		ptSdram->ulSdram_mr           = ptSdramParam->ulSdramMr; 
		ptSdram->ulSdram_general_ctrl = ptSdramParam->ulSdramGeneralCtrl; 
		
		while (((ptSdram->ulSdram_general_ctrl & HOSTMSK(sdram_general_ctrl_sdram_ready)) >> HOSTSRT(sdram_general_ctrl_sdram_ready)) == 0) {}
		iRet = 1;
	}
	else
	{
		iRet = 0;
	}
	
	return iRet;
}

/* --------------------------------------------------------------------------*/
int get_sdram_config(SDRAM_CTRL_AREA_T* ptSdram, SDRAM_PARAM_T* ptSdramParam)
{
	int iRet; 
	
	if (ptSdram != NULL)
	{
		ptSdramParam->ulSdramTimingCtrl  = ptSdram->ulSdram_timing_ctrl;
		ptSdramParam->ulSdramMr          = ptSdram->ulSdram_mr;
		ptSdramParam->ulSdramGeneralCtrl = ptSdram->ulSdram_general_ctrl;
		
		iRet = 1;
	}
	else
	{
		iRet = 0;
	}
	
	return iRet;
}

/* --------------------------------------------------------------------------*/
/* If the test area is in SDRAM, print the controller settings. */
void ramtest_show_sdram_config(unsigned long ulSdramStart)
{
	SDRAM_CTRL_AREA_T *ptSdramCtrl;
	SDRAM_PARAM_T tSdramParam;
	
	ptSdramCtrl = ramtest_get_controller_addr(ulSdramStart);
	if( ptSdramCtrl!=NULL )
	{
		get_sdram_config(ptSdramCtrl, &tSdramParam);
		
		//sim_message(". SDRAM controller:    ", disp_data, (unsigned long) ptSdramCtrl);
		//sim_message(". SDRAM general ctrl:  ", disp_data, tSdramParam.ulSdramGeneralCtrl);
		//sim_message(". SDRAM timing ctrl:   ", disp_data, tSdramParam.ulSdramTimingCtrl);
		//sim_message(". SDRAM mode register: ", disp_data, tSdramParam.ulSdramMr);
		
		uprintf("\n");
		uprintf(". SDRAM controller:    0x%08x\n", (unsigned long) ptSdramCtrl);
		uprintf(". SDRAM general ctrl:  0x%08x\n", tSdramParam.ulSdramGeneralCtrl);
		uprintf(". SDRAM timing ctrl:   0x%08x\n", tSdramParam.ulSdramTimingCtrl);
		uprintf(". SDRAM mode register: 0x%08x\n", tSdramParam.ulSdramMr);
		uprintf("\n");
	}
}


/*-----------------------------------*/
#if 0
static RAMTEST_RESULT_T ramtest_run_pseudorandom(RAMTEST_PARAMETER_T *ptParameter, const RAMTEST_PAIR_T *ptTestPair)
{
	/* This test contains
	 *     8  Bit
	 *     16 Bit
	 *     32 Bit
	 *     and 32 Bit Burst access tests
	 */

	RAMTEST_RESULT_T tResult;
	RAMTEST_RESULT_T tGlobalResult;
	unsigned long ulCases;


	ulCases = ptParameter->ulCases;
	tGlobalResult = RAMTEST_RESULT_OK;
	
	/* test 8 bit access */
	if( /* tResult==RAMTEST_RESULT_OK &&  */(ulCases&RAMTESTCASE_08BIT)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}
	
	/* test 16 bit access */
	if( /* tResult==RAMTEST_RESULT_OK && */ (ulCases&RAMTESTCASE_16BIT)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}

	/* test 32 bit access */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_32BIT)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}


	/* test 32 bit burst access */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_BURST)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}


	return tGlobalResult;
}
#endif


static RAMTEST_RESULT_T ramtest_run_pseudorandom(RAMTEST_PARAMETER_T *ptParameter)
{
	/* This test contains
	 *     8  Bit
	 *     16 Bit
	 *     32 Bit
	 *     and 32 Bit Burst access tests
	 */

	RAMTEST_RESULT_T tResult;
	RAMTEST_RESULT_T tGlobalResult;
	unsigned long ulCases;

	ulCases = ptParameter->ulCases;
	tGlobalResult = RAMTEST_RESULT_OK;
	
	const RAMTEST_PAIR_T *ptTestPair0 = &testPairs[0];
	const RAMTEST_PAIR_T *ptTestPair1 = &testPairs[1];
	const RAMTEST_PAIR_T *ptTestPair2 = &testPairs[2];
	
	SDRAM_CTRL_AREA_T* ptSdramCtrl; 
	SDRAM_PARAM_T tCheckParams;
	SDRAM_PARAM_T tKnownGoodParams = {
		.ulSdramGeneralCtrl = 0x030d0001,
		/* Clock phase: 2   Sample phase: 2 */
		.ulSdramTimingCtrl  = 0x02a13251,
		.ulSdramMr          = 0x00000033
	};
	
	ptSdramCtrl = ramtest_get_controller_addr(ptParameter->ulStart);
	if (ptSdramCtrl != NULL) {
		get_sdram_config(ptSdramCtrl, &tCheckParams);
	}
	
	/* test 8 bit access */
	if( /* tResult==RAMTEST_RESULT_OK &&  */(ulCases&RAMTESTCASE_08BIT)!=0 )
	{
		uprintf(". Testing 8 bit access...\n");
		uprintf(". Write: test config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair0, &tCheckParams, 8, NULL, 8);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 8 bit access OK.\n");
		}
		else
		{
			uprintf("! 8 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 8 bit access...\n");
		uprintf(". Write: known-good config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair1, &tKnownGoodParams, 8, &tCheckParams, 8);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 8 bit access OK.\n");
		}
		else
		{
			uprintf("! 8 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 8 bit access...\n");
		uprintf(". Write: test config Verify: known-good config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair2, &tCheckParams, 8, &tKnownGoodParams, 8);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 8 bit access OK.\n");
		}
		else
		{
			uprintf("! 8 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}
	
	/* test 16 bit access */
	if( /* tResult==RAMTEST_RESULT_OK && */ (ulCases&RAMTESTCASE_16BIT)!=0 )
	{
		uprintf(". Testing 16 bit access...\n");
		uprintf(". Write: test config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair0, &tCheckParams, 16, NULL, 16);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 16 bit access OK.\n");
		}
		else
		{
			uprintf("! 16 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 16 bit access...\n");
		uprintf(". Write: known-good config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair1, &tKnownGoodParams, 16, &tCheckParams, 16);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 16 bit access OK.\n");
		}
		else
		{
			uprintf("! 16 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 16 bit access...\n");
		uprintf(". Write: test config Verify: known-good config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair2, &tCheckParams, 16, &tKnownGoodParams, 16);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 16 bit access OK.\n");
		}
		else
		{
			uprintf("! 16 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}

	/* test 32 bit access */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_32BIT)!=0 )
	{
		uprintf(". Testing 32 bit access...\n");
		uprintf(". Write: test config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair0, &tCheckParams, 32, NULL, 32);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 bit access OK.\n");
		}
		else
		{
			uprintf("! 32 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 32 bit access...\n");
		uprintf(". Write: known-good config Verify: test config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair1, &tKnownGoodParams, 32, &tCheckParams, 32);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 bit access OK.\n");
		}
		else
		{
			uprintf("! 32 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
		
		uprintf(". Testing 32 bit access...\n");
		uprintf(". Write: test config Verify: known-good config\n");
		tResult = ramtest_pseudorandom(ptParameter, ptTestPair2, &tCheckParams, 32, &tKnownGoodParams, 32);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 bit access OK.\n");
		}
		else
		{
			uprintf("! 32 bit access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}

	if (ptSdramCtrl != NULL) {
		set_sdram_config(ptSdramCtrl, &tCheckParams);
	}

	/* test 32 bit burst access */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_BURST)!=0 )
	{
		uprintf(". Testing 32 bit burst access...\n");
		tResult = ram_test_burst(ptParameter, ptTestPair0);
		if( tResult==RAMTEST_RESULT_OK )
		{
			uprintf(". 32 bit burst access OK.\n");
		}
		else
		{
			uprintf("! 32 bit burst access failed.\n");
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}


	return tGlobalResult;
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

RAMTEST_RESULT_T ramtest_run_deterministic(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tResult;
	RAMTEST_RESULT_T tGlobalResult;
	unsigned long ulCases;
	ulCases =  ptParameter->ulCases;

	tGlobalResult = RAMTEST_RESULT_OK;


	/* Test all Datalines independently from each other */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_DATABUS)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}


	/* Test checkerboard pattern for retention + produce hard cluster for burst */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_CHECKERBOARD)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}

	/* test Marching pattern */
	if( /* tResult==RAMTEST_RESULT_OK && */(ulCases&RAMTESTCASE_MARCHC)!=0 )
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
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
	}


	return tGlobalResult;
}



RAMTEST_RESULT_T ramtest_run(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tRamTestResult;
	RAMTEST_RESULT_T tGlobalResult;
	unsigned long ulCases;
	unsigned long ulLoopCnt;
	unsigned long ulLoopMax;
	/* unsigned int  uiTestCnt; */

	tGlobalResult = RAMTEST_RESULT_OK;

	/* Show welcome message. */
	uprintf(". Ram start address:      0x%08x\n", ptParameter->ulStart);
	uprintf(". Ram size in bytes:      0x%08x\n", ptParameter->ulSize);
	ramtest_show_sdram_config( ptParameter->ulStart);
	uprintf(". Test cases:\n");
	ulCases = ptParameter->ulCases;

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
	if( ulCases==0 )
	{
		uprintf("    none\n");
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

		tRamTestResult = ramtest_run_deterministic(ptParameter);
		if(tRamTestResult == RAMTEST_RESULT_FAILED) 
		{
			tGlobalResult = RAMTEST_RESULT_FAILED;
			/*break;*/
		}


		uprintf("****************************************\n");
		uprintf("*                                      *\n");
		uprintf("*  Random number test - Loop %08d  *\n", ulLoopCnt);
		uprintf("*                                      *\n");
		uprintf("****************************************\n");

		tRamTestResult = ramtest_run_pseudorandom(ptParameter);
		if( tRamTestResult!=RAMTEST_RESULT_OK )
		{
			tGlobalResult = RAMTEST_RESULT_FAILED;
		}
#if 0
		for(uiTestCnt=0; uiTestCnt<(sizeof(testPairs)/sizeof(RAMTEST_PAIR_T)); ++uiTestCnt )
		{
			uprintf(". Start test case %d of %d\n", uiTestCnt+1, sizeof(testPairs)/sizeof(RAMTEST_PAIR_T));
			tRamTestResult = ramtest_run_pseudorandom(ptParameter, testPairs+uiTestCnt);
			if( tRamTestResult!=RAMTEST_RESULT_OK )
			{
				uprintf("! Test case %d failed.\n", uiTestCnt+1);
				tGlobalResult = RAMTEST_RESULT_FAILED;
				/*break;*/
			}
			uprintf(". Test case %d OK.\n", uiTestCnt+1);
		}
#endif

		/* TODO: does it make sense to run the performance tests multiple times in a loop? */
		if (ptParameter->ulPerfTestCases != 0)
		{
			uprintf("****************************************\n");
			uprintf("*                                      *\n");
			uprintf("*  Performance Tests - Loop %08d   *\n", ulLoopCnt);
			uprintf("*                                      *\n");
			uprintf("****************************************\n");

			tRamTestResult = ramtest_run_performance_tests(ptParameter);
			if( tRamTestResult!=RAMTEST_RESULT_OK ) 
			{
				break;
				tGlobalResult = RAMTEST_RESULT_FAILED;
			}
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
	} while(tGlobalResult==RAMTEST_RESULT_OK);

	ramtest_show_sdram_config( ptParameter->ulStart);

	return tGlobalResult;
}

