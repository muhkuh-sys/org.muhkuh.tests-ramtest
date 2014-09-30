
#ifndef __RAMTEST_H__
#define __RAMTEST_H__


typedef enum RAMTEST_RESULT_ENUM
{
	RAMTEST_RESULT_OK     = 0,
	RAMTEST_RESULT_FAILED = 1
} RAMTEST_RESULT_T;


typedef enum
{
	RAMTESTCASE_DATABUS            = 0x00000001,
	RAMTESTCASE_08BIT              = 0x00000002,
	RAMTESTCASE_16BIT              = 0x00000004,
	RAMTESTCASE_32BIT              = 0x00000008,
	RAMTESTCASE_MARCHC             = 0x00000010,
	RAMTESTCASE_CHECKERBOARD       = 0x00000020,
	RAMTESTCASE_BURST              = 0x00000040
} RAMTESTCASE_T;


struct RAMTEST_PARAMETER_STRUCT;
typedef void (*PFN_RAMTEST_PROGRESS_T) (struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult);

typedef struct RAMTEST_PARAMETER_STRUCT
{
	unsigned long ulStart;
	unsigned long ulSize;
	unsigned long ulCases;
	unsigned long ulLoops;
	PFN_RAMTEST_PROGRESS_T pfnProgress;
	unsigned long ulProgress;
} RAMTEST_PARAMETER_T;



RAMTEST_RESULT_T ramtest_run(RAMTEST_PARAMETER_T *ptParameter);
RAMTEST_RESULT_T ramtest_deterministic(RAMTEST_PARAMETER_T *ptParameter);
unsigned long pseudo_generator(unsigned long number);

#endif  /* __RAMTEST_H__ */
