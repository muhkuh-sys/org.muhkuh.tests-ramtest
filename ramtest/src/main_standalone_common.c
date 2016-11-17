#include <string.h>
#include "main_standalone_common.h"
#include "rdy_run.h"
#include "netx_io_areas.h"
#include "serial_vectors.h"


void ramtest_clear_serial_vectors(void)
{
	tSerialVectors.fn.fnGet   = NULL;
	tSerialVectors.fn.fnPut   = NULL;
	tSerialVectors.fn.fnPeek  = NULL;
	tSerialVectors.fn.fnFlush = NULL;
}


/*-------------------------------------------------------------------------*/


void ramtest_rdyrun_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
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

