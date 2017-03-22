#include <string.h>
#include "ramtest.h"
#include "systime.h"
#include "setup_sdram.h"

/*-------------------------------------------------------------------------*/
/*
  <hardware connection="ONBOARD" interface="MEM" netX="500" type="MT48LC2M32B2-7IT">
    <!--tRas neu: 5clk (alt 4) tRfc neu: 7clk (alt 6) Grund: alte Werte wurden falsch aus dem Datenblatt genommen-->
    <ControlRegister>0x030D0001</ControlRegister>
    <TimingRegister>0x03C13251</TimingRegister>
    <ModeRegister>0x00000033</ModeRegister>
    <SizeExponent>23</SizeExponent>
  </hardware>
  
  
  Row size: 1024 bytes
  test area size: 4 KB
  
  sequential NOP:
  80000000 -> 80000002 -> 800000004 -> 80000ffe 
  
  row jump:
  80000000 -> 80000400 -> 80000800 -> 80000c00 ->
  80000002 -> 80000402 -> 80000802 ->...
  
  memory: 
  80000000-80000bfe 0x44a7 jump to next row
  80000c00-80000ffe 0x44af jump to first row, next column
  80001000          0x4770 return
  
  reads in row jump:
  655120 ns  80000000 80000000/4/8/c/10
  655280 ns  80000400 80000400/4/8/c/10
  655460 ns  80000800 80000800/4/8/c/10
  655640 ns  80000c00 80000c00/4/8/c/10
  655820 ns  80000002 80000000/4/8/c/10/14
  656050 ns  80000402 80000400/4/8/c/10/14
  656250 ns  80000802 80000800/4/8/c/10/14
  656450 ns  80000c02 80000c00/4/8/c/10/14
  656650 ns  80000004 80000004/8/c/10/14
  656840 ns  80000404 80000404/8/c/10
  
  
*/
int main(void);
int main(void)
{
	unsigned long ulSdramStart        = 0x80000000UL; 
	unsigned long ulSdramGeneralCtrl  = 0x030d0001UL;
	//unsigned long ulSdramTimingCtrl   = 0x03C13251UL;
	unsigned long ulSdramTimingCtrl   = 0x01b242a2UL;
	unsigned long ulSdramMr           = 0x00000033UL;
	
	unsigned long ulRowSize           = 1024;
	unsigned long ulRefreshTime_clk   = 6400000;
	
	unsigned long ulPerfTestCases     = 0;
	unsigned long ulTestAreaStart     = ulSdramStart;
	unsigned long ulTestAreaSize      = 0x0800UL;
	
	RAMTEST_PARAMETER_T tTestParams;
	int iResult;
	
	ulPerfTestCases     = 
	  RAMPERFTESTCASE_SEQ_R8  | RAMPERFTESTCASE_SEQ_R16  | RAMPERFTESTCASE_SEQ_R32  | RAMPERFTESTCASE_SEQ_R256
	| RAMPERFTESTCASE_SEQ_W8  | RAMPERFTESTCASE_SEQ_W16  | RAMPERFTESTCASE_SEQ_W32  | RAMPERFTESTCASE_SEQ_W256
	| RAMPERFTESTCASE_SEQ_RW8 | RAMPERFTESTCASE_SEQ_RW16 | RAMPERFTESTCASE_SEQ_RW32 | RAMPERFTESTCASE_SEQ_RW256
	| RAMPERFTESTCASE_SEQ_NOP
	| RAMPERFTESTCASE_ROW_R8  | RAMPERFTESTCASE_ROW_R16  | RAMPERFTESTCASE_ROW_R32  | RAMPERFTESTCASE_ROW_R256
	| RAMPERFTESTCASE_ROW_W8  | RAMPERFTESTCASE_ROW_W16  | RAMPERFTESTCASE_ROW_W32  | RAMPERFTESTCASE_ROW_W256
	| RAMPERFTESTCASE_ROW_RW8 | RAMPERFTESTCASE_ROW_RW16 | RAMPERFTESTCASE_ROW_RW32 | RAMPERFTESTCASE_ROW_RW256
	| RAMPERFTESTCASE_ROW_JUMP;
			
	//ulPerfTestCases     =  RAMPERFTESTCASE_SEQ_NOP + RAMPERFTESTCASE_ROW_JUMP;
	
	//ulTestAreaStart     = 0x10000UL;
	//ulTestAreaSize      = 0x1000UL;
	ulRefreshTime_clk   = 0x100;
	
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

	/* No signal when a loop has finished */
	tTestParams.pfnLoopFinished = NULL;
	
	/* TODO: initialize the system */
	/* ram_perftest_init_netx(); */
	
	systime_init();
	
	/* Setup the SDRAM. */
	iResult = sdram_setup(ulSdramStart, ulSdramGeneralCtrl, ulSdramTimingCtrl, ulSdramMr);
	
	if( iResult==0 )
	{
		/*
		 * Run the RAM test.
		 */
		ramtest_run_performance_tests(&tTestParams);
	}

	//sim_message(". End of test", stop_clock, 0);
	while(1);
  return 0;
}

/*-----------------------------------*/


