
#include "ramtest.h"
#include "systime.h"
#include "setup_sdram.h"

/*-------------------------------------------------------------------------*/

void ramtest_main(void) __attribute__ ((noreturn));
void ramtest_main(void)
{
	unsigned long ulSdramStart        = 0x80000000UL; 
	unsigned long ulSdramGeneralCtrl  = 0x030d0001UL;
	unsigned long ulSdramTimingCtrl   = 0x03C13251UL;
	unsigned long ulSdramMr           = 0x00000033UL;
	
	unsigned long ulRowSize           = 1024;
	unsigned long ulRefreshTime_clk   = 6400000;
	
	unsigned long ulPerfTestCases     = RAMPERFTESTCASE_SEQ_R8;
	unsigned long ulTestAreaStart     = ulSdramStart;
	unsigned long ulTestAreaSize      = 0x10000UL;
	
	RAMTEST_PARAMETER_T tTestParams;
	int iResult;
	
	/*
	 * Set the RAM test configuration.
	 */
	
	tTestParams.ulStart = ulTestAreaStart;

	/* Set the size of the test area. */
	tTestParams.ulSize = ulTestAreaSize;

	/* Run all performance test cases. */
	tTestParams.ulCases = 0;
	tTestParams.ulPerfTestCases = ulPerfTestCases;
	
	/* Row size */
	tTestParams.ulRowSize = ulRowSize;
	
	/* Time for a full refresh in 10 ns units (clock cycles) */
	tTestParams.ulRefreshTime_clk = ulRefreshTime_clk;
	
	/* Execute once. (ignored by perf. test) */
	tTestParams.ulLoops = 1;

	/* TODO: initialize the system */
	/* ram_perftest_init_netx(); */
	
	systime_init();
	
	/* Setup the SDRAM. */
	iResult = sdram_setup(ulSdramStart, ulSdramGeneralCtrl, ulSdramTimingCtrl, ulSdramMr);
	if( iResult==0 )
	{
		/*
		 * Run the RAM test.
		 * With tTestParams.ulLoops=0 this function will only return if an error occurs.
		 */
		ramtest_run_performance_tests(&tTestParams);
	}

	while(1);
}

/*-----------------------------------*/


