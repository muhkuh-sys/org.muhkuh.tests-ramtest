#include "ramtest_ecc.h"
#include "ecc_a9.h"
#include "ecc_ddr.h"


/*

          enable               clear mem        test                check
CR7 L1    CR7                  CR7              CR7                  CR7
CA9 L1    core 0/1             core 0/1         core 0               core 0
CA9 L2   
DDR       romcode/bootimage  romcode/bootimage  CR7/boot chunk      ramtest (all cores)
          (DDR config)                           not currently

L1 cache/ECC: each CPU has to enable the cache and ECC. The CPU which has the UART checks for ECC errors.
l1c     CR7 CA9 core 0    CA9 core 1
         0        0            1       CA9 core 1 check
         0        1            0       CA9 core 0 check  
         0        1            1       CA9 core 0 check  
         1        0            0       CR7 check
         1        0            1       CR7 check
         1        1            0       CR7 check
         1        1            1       CR7 check

L2 cache/ECC: enabled by CA9 core 


DDR ECC: enabled by ROM code/boot chunk. The CPU which has the UART checks for ECC errors.
DDR ECC CR7 CA9 core 0    CA9 core 1
         0        0            1       CA9 core 1 enable/check
         0        1            0       CA9 core 0 enable/check  
         0        1            1       CA9 core 0 enable/check  
         1        0            0       CR7 enable/check
         1        0            1       CR7 enable/check
         1        1            0       CR7 enable/check
         1        1            1       CR7 enable/check
		 

0x00200000 CA9 ECC CTRL (offset in CoreSight)
*/


RAMTEST_RESULT_T ramtest_ecc_test(void)
{
	RAMTEST_RESULT_T tRet = RAMTEST_RESULT_OK;
	
	#ifdef CA9_L1C_ECC
		if (0 == ca9_l1_ecc_ctrl_trigger_errors())
		{
			tRet = RAMTEST_RESULT_FAILED;
		}
	#endif  
	
	#ifdef DDR_ECC
		if (0 ==  ddr_ecc_trigger_error())
		{
			tRet = RAMTEST_RESULT_FAILED;
		}
	#endif
	
	return tRet;
}

void ramtest_ecc_show(void)
{
	#ifdef CA9_L1C_ECC
		ca9_ecc_ctrl_show();
	#endif        
	
	#ifdef DDR_ECC
		ddr_ecc_print();
	#endif
}

RAMTEST_RESULT_T ramtest_ecc_check(void)
{
	RAMTEST_RESULT_T tRet = RAMTEST_RESULT_OK;
	#ifdef CA9_L1C_ECC
		if (0 != ca9_ecc_ctrl_check())
		{
			tRet = RAMTEST_RESULT_FAILED;
		}
	#endif        
	
	#ifdef DDR_ECC
		ddr_ecc_print();
		if (0 != ddr_ecc_check_status())
		{
			tRet = RAMTEST_RESULT_FAILED;
		}
	#endif
	return tRet;
}


RAMTEST_RESULT_T ramtest_ecc_check_wrapper(RAMTEST_RESULT_T tResult)
{
	if (RAMTEST_RESULT_OK != ramtest_ecc_check()) 
	{
		tResult = RAMTEST_RESULT_FAILED;
	}
	return tResult;
}


void ramtest_ecc_ack(void)
{
	#ifdef CA9_L1C_ECC
		ca9_ecc_ctrl_clear();
	#endif        
	#ifdef DDR_ECC
		ddr_ecc_ack();
	#endif
}
