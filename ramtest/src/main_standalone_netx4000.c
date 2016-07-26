#include <string.h>
#include "ramtest.h"
#include "systime.h"
#include "uprintf.h"
#include "version.h"
#include "main_standalone_common.h"

/*-------------------------------------------------------------------------*/

typedef struct RAMTEST_STANDALONE_NETX4000_PARAMETER_STRUCT
{
	unsigned long ulStart;
	unsigned long ulSize;
	unsigned long ulCases;
	unsigned long ulLoops;
	unsigned long ulPerfTestCases;
} RAMTEST_STANDALONE_NETX4000_PARAMETER_T; 


void ramtest_main(const RAMTEST_STANDALONE_NETX4000_PARAMETER_T* ptParam) __attribute__ ((noreturn));
void ramtest_main(const RAMTEST_STANDALONE_NETX4000_PARAMETER_T* ptParam)
{
	RAMTEST_PARAMETER_T tTestParams;
	RAMTEST_RESULT_T tRes;
	
	systime_init();

	ramtest_init_uart();

	uprintf("\f. *** RAM test by cthelen@hilscher.com ***\n");
	uprintf("V" VERSION_ALL "\n\n");

	/*
	 * Set the RAM test configuration.
	 */
	memset(&tTestParams, 0, sizeof(tTestParams));
	tTestParams.ulStart         = ptParam->ulStart;
	tTestParams.ulSize          = ptParam->ulSize;
	tTestParams.ulCases         = ptParam->ulCases;
	tTestParams.ulLoops         = ptParam->ulLoops;
	tTestParams.ulPerfTestCases = ptParam->ulPerfTestCases;
	
	/* Set the progress callback. */
	tTestParams.pfnProgress = ramtest_rdyrun_progress;
	tTestParams.ulProgress = 0;

	/*
	 * Run the RAM test.
	 * With tTestParams.ulLoops=0 this function will only return if an error occurs.
	 */
	tRes = ramtest_run(&tTestParams);

	tTestParams.pfnProgress(&tTestParams, tRes);
	while(1);
}
