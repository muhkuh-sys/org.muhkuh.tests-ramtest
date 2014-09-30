
#include "netx_io_areas.h"

#include "netx_test.h"
#include "ramtest.h"
#include "rdy_run.h"
#include "systime.h"
#include "uprintf.h"
#include "version.h"

/*-----------------------------------*/

static void ramtest_rdyrun_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
{
	unsigned long ulProgress;


	if( tResult==RAMTEST_RESULT_OK )
	{
		ulProgress = ptRamTestParameter->ulProgress;
		if( ulProgress==0 )
		{
			rdy_run_setLEDs(RDYRUN_GREEN);
		}
		else
		{
			rdy_run_setLEDs(RDYRUN_OFF);
		}

		ulProgress ^= 1;
		ptRamTestParameter->ulProgress = ulProgress;
	}
	else
	{
		rdy_run_setLEDs(RDYRUN_YELLOW);
	}
}


TEST_RESULT_T test(TEST_PARAMETER_T *ptTestParam)
{
	TEST_RESULT_T tTestResult;
	RAMTEST_RESULT_T tRamTestResult;
	RAMTEST_PARAMETER_T *ptTestParams;


	systime_init();

	uprintf("\f. *** RAM test by cthelen@hilscher.com ***\n");
	uprintf("V" VERSION_ALL "\n\n");

	/* Switch off SYS led. */
	rdy_run_setLEDs(RDYRUN_OFF);

	ptTestParams = (RAMTEST_PARAMETER_T*)(ptTestParam->pvInitParams);

	ptTestParams->pfnProgress = ramtest_rdyrun_progress;
	ptTestParams->ulProgress = 0;

	tRamTestResult = ramtest_run(ptTestParams);

	/* Translate RAMTEST result to TEST result. */
	if( tRamTestResult==RAMTEST_RESULT_OK )
	{
		rdy_run_setLEDs(RDYRUN_GREEN);
		tTestResult = TEST_RESULT_OK;
	}
	else
	{
		rdy_run_setLEDs(RDYRUN_YELLOW);
		tTestResult = TEST_RESULT_ERROR;
	}

	return tTestResult;
}

/*-----------------------------------*/

