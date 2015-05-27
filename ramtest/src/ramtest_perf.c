#include "ramtest.h"

#include <stddef.h> /* defines NULL */

#if defined(SIMULATION)
#define uprintf(...)
#else
#include "uprintf.h"
#endif

/* not used */
unsigned long ram_perftest_get_row_size(void);
unsigned long ram_perftest_get_refresh_time(void);

typedef RAMTEST_RESULT_T (FN_RAMPERFTEST_T) (unsigned long ulStartaddress, unsigned long ulEndAddress,unsigned long ulRowSize, unsigned long ulRefreshTime);


typedef struct RAMPERFTEST_DESC_Ttag {
	FN_RAMPERFTEST_T  *pfnTestCode;
	char              *pszTestName;
	RAMPERFTESTCASE_T  tTestFlag;
	int                iResultIndex;
} RAMPERFTEST_DESC_T;

FN_RAMPERFTEST_T ram_perftest_seq_R8;
FN_RAMPERFTEST_T ram_perftest_seq_R16;
FN_RAMPERFTEST_T ram_perftest_seq_R32;
FN_RAMPERFTEST_T ram_perftest_seq_R256;
FN_RAMPERFTEST_T ram_perftest_seq_W8;
FN_RAMPERFTEST_T ram_perftest_seq_W16;
FN_RAMPERFTEST_T ram_perftest_seq_W32;
FN_RAMPERFTEST_T ram_perftest_seq_W256;
FN_RAMPERFTEST_T ram_perftest_seq_RW8;
FN_RAMPERFTEST_T ram_perftest_seq_RW16;
FN_RAMPERFTEST_T ram_perftest_seq_RW32;
FN_RAMPERFTEST_T ram_perftest_seq_RW256;
FN_RAMPERFTEST_T ram_perftest_row_R8;
FN_RAMPERFTEST_T ram_perftest_row_R16;
FN_RAMPERFTEST_T ram_perftest_row_R32;
FN_RAMPERFTEST_T ram_perftest_row_R256;
FN_RAMPERFTEST_T ram_perftest_row_W8;
FN_RAMPERFTEST_T ram_perftest_row_W16;
FN_RAMPERFTEST_T ram_perftest_row_W32;
FN_RAMPERFTEST_T ram_perftest_row_W256;
FN_RAMPERFTEST_T ram_perftest_row_RW8;
FN_RAMPERFTEST_T ram_perftest_row_RW16;
FN_RAMPERFTEST_T ram_perftest_row_RW32;
FN_RAMPERFTEST_T ram_perftest_row_RW256;
FN_RAMPERFTEST_T ram_perftest_seq_nop;
FN_RAMPERFTEST_T ram_perftest_row_jump;


/* causes warning: initialization discards 'const' qualifier from pointer target type [enabled by default]
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=62198 */

const RAMPERFTEST_DESC_T atRamPerfTests[27] = {
	{ram_perftest_seq_R8,    "ram_perftest_seq_R8",    RAMPERFTESTCASE_SEQ_R8,    0} ,
	{ram_perftest_seq_R16,   "ram_perftest_seq_R16",   RAMPERFTESTCASE_SEQ_R16,   1} ,
	{ram_perftest_seq_R32,   "ram_perftest_seq_R32",   RAMPERFTESTCASE_SEQ_R32,   2} ,
	{ram_perftest_seq_R256,  "ram_perftest_seq_R256",  RAMPERFTESTCASE_SEQ_R256,  3} ,
	{ram_perftest_seq_W8,    "ram_perftest_seq_W8",    RAMPERFTESTCASE_SEQ_W8,    4} ,
	{ram_perftest_seq_W16,   "ram_perftest_seq_W16",   RAMPERFTESTCASE_SEQ_W16,   5} ,
	{ram_perftest_seq_W32,   "ram_perftest_seq_W32",   RAMPERFTESTCASE_SEQ_W32,   6} ,
	{ram_perftest_seq_W256,  "ram_perftest_seq_W256",  RAMPERFTESTCASE_SEQ_W256,  7} ,
	{ram_perftest_seq_RW8,   "ram_perftest_seq_RW8",   RAMPERFTESTCASE_SEQ_RW8,   8} ,
	{ram_perftest_seq_RW16,  "ram_perftest_seq_RW16",  RAMPERFTESTCASE_SEQ_RW16,  9} ,
	{ram_perftest_seq_RW32,  "ram_perftest_seq_RW32",  RAMPERFTESTCASE_SEQ_RW32,  10} ,
	{ram_perftest_seq_RW256, "ram_perftest_seq_RW256", RAMPERFTESTCASE_SEQ_RW256, 11} ,
	{ram_perftest_seq_nop,   "ram_perftest_seq_nop",   RAMPERFTESTCASE_SEQ_NOP,   12} ,

	{ram_perftest_row_R8,    "ram_perftest_row_R8",    RAMPERFTESTCASE_ROW_R8,    13} ,
	{ram_perftest_row_R16,   "ram_perftest_row_R16",   RAMPERFTESTCASE_ROW_R16,   14} ,
	{ram_perftest_row_R32,   "ram_perftest_row_R32",   RAMPERFTESTCASE_ROW_R32,   15} ,
	{ram_perftest_row_R256,  "ram_perftest_row_R256",  RAMPERFTESTCASE_ROW_R256,  16} ,
	{ram_perftest_row_W8,    "ram_perftest_row_W8",    RAMPERFTESTCASE_ROW_W8,    17} ,
	{ram_perftest_row_W16,   "ram_perftest_row_W16",   RAMPERFTESTCASE_ROW_W16,   18} ,
	{ram_perftest_row_W32,   "ram_perftest_row_W32",   RAMPERFTESTCASE_ROW_W32,   19} ,
	{ram_perftest_row_W256,  "ram_perftest_row_W256",  RAMPERFTESTCASE_ROW_W256,  20} ,
	{ram_perftest_row_RW8,   "ram_perftest_row_RW8",   RAMPERFTESTCASE_ROW_RW8,   21} ,
	{ram_perftest_row_RW16,  "ram_perftest_row_RW16",  RAMPERFTESTCASE_ROW_RW16,  22} ,
	{ram_perftest_row_RW32,  "ram_perftest_row_RW32",  RAMPERFTESTCASE_ROW_RW32,  23} ,
	{ram_perftest_row_RW256, "ram_perftest_row_RW256", RAMPERFTESTCASE_ROW_RW256, 24} ,
	{ram_perftest_row_jump,  "ram_perftest_row_jump",  RAMPERFTESTCASE_ROW_JUMP,  25} ,
	{NULL}
};


RAMTEST_RESULT_T ramtest_run_performance_tests(RAMTEST_PARAMETER_T *ptParameter)
{
	RAMTEST_RESULT_T tResult;
	unsigned long ulStartAddress;
	unsigned long ulEndAddress;
	unsigned long ulRowSizeBytes;
	unsigned long ulRefreshTimeClocks;
	unsigned long ulCases;
	unsigned long ulTime;
	const RAMPERFTEST_DESC_T *ptRamPerfTest;
	int iNumTimeEntries;
	int i;
	
	tResult         = RAMTEST_RESULT_OK;
	ulCases         = ptParameter->ulPerfTestCases;
	ulStartAddress = ptParameter->ulStart;
	ulEndAddress   = ulStartAddress + ptParameter->ulSize;
	ptRamPerfTest = atRamPerfTests;
	
	ulRowSizeBytes = ptParameter->ulRowSize;
	ulRefreshTimeClocks = ptParameter->ulRefreshTime_clk;
	
	uprintf(". \n");
	uprintf(". Row size: %d bytes\n", ulRowSizeBytes);
	uprintf(". Refresh time: %d * 10ns\n", ulRefreshTimeClocks);
	uprintf(". \n");
	
	iNumTimeEntries = sizeof(ptParameter->ulTimes)/sizeof(ptParameter->ulTimes[0]);
	for (i=0; i<iNumTimeEntries; i++)
	{
		ptParameter->ulTimes[i] = 0;
	}

	while ((tResult==RAMTEST_RESULT_OK) && (ptRamPerfTest -> pfnTestCode != NULL))
	{

		if ((ulCases & ( ptRamPerfTest -> tTestFlag) ) == 0)
		{
			uprintf(". Skipping test %s ...\n", ptRamPerfTest -> pszTestName);
			ulTime = 0;
		}
		else
		{
			uprintf(". Running test %s ...", ptRamPerfTest -> pszTestName);
			ulTime = ptRamPerfTest -> pfnTestCode(ulStartAddress, ulEndAddress, ulRowSizeBytes, ulRefreshTimeClocks);
			uprintf(" %d cycles\n", ulTime);
		}
		ptParameter->ulTimes[ptRamPerfTest -> iResultIndex] = ulTime;
		++ptRamPerfTest;
	}

	return tResult;
}

void ramtest_print_performance_tests(RAMTEST_PARAMETER_T *ptParameter)
{
	const RAMPERFTEST_DESC_T *ptRamPerfTest;
	int iCnt;

	uprintf(". Performance tests:\n");
	iCnt = 0;
	for (ptRamPerfTest = atRamPerfTests; ptRamPerfTest->pfnTestCode != NULL; ++ptRamPerfTest)
	{
		if ((ptParameter->ulPerfTestCases & ptRamPerfTest->tTestFlag) != 0)
		{
			uprintf(". %s\n", ptRamPerfTest -> pszTestName);
			iCnt = iCnt + 1;
		}
	}

	if (iCnt == 0) {
		uprintf(".  none\n");
	}
}
