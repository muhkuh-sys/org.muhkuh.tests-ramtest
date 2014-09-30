
#include "netx_test.h"

extern unsigned int NetxTestParameter_Init;

/*-----------------------------------*/

void test_main(void)
{
	TEST_PARAMETER_T *ptTestParam;
	TEST_RESULT_T tTestResult;


	/* get pointer to the test parameters */
	ptTestParam = netx_test_getParameters();

	tTestResult = test(ptTestParam);
	ptTestParam->ulReturnValue = (unsigned int)tTestResult;
}

/*-----------------------------------*/

TEST_PARAMETER_T *netx_test_getParameters(void)
{
	return (TEST_PARAMETER_T*)NetxTestParameter_Init;
}

/*-----------------------------------*/
