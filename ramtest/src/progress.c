#include "progress.h"

#include "netx_io_areas.h"
#include "rdy_run.h"


void progress_rdyrun(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
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



#if ASIC_TYP==ASIC_TYP_NETX56
void progress_mmio(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
{
	HOSTDEF(ptMmioCtrlArea);
	unsigned long ulProgress;
	unsigned int uiMmioIdxGreen;
	unsigned int uiMmioIdxYellow;
	unsigned long ulMask0;
	unsigned long ulMask1;


	ulProgress = ptRamTestParameter->ulProgress;
	uiMmioIdxGreen  =  ulProgress       & 0xff;
	uiMmioIdxYellow = (ulProgress >> 8) & 0xff;


	if( tResult==RAMTEST_RESULT_OK )
	{
		if( (ulProgress & 0x00010000)==0 )
		{
			/* Show the green LED -> green is 0 and yellow is 1. */
			ulMask0 = 1U <<  uiMmioIdxYellow;
			ulMask1 = 1U << (uiMmioIdxYellow - 32);
		}
		else
		{
			/* All LEDs off -> green is 1 and yellow is 1. */
			ulMask0  = 1U <<  uiMmioIdxGreen;
			ulMask0 |= 1U <<  uiMmioIdxYellow;
			ulMask1  = 1U << (uiMmioIdxGreen  - 32);
			ulMask1 |= 1U << (uiMmioIdxYellow - 32);
		}

		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[0] = ulMask0;
		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[1] = ulMask1;

		ulProgress ^= 0x00010000;
		ptRamTestParameter->ulProgress = ulProgress;
	}
	else
	{
		/* Show the yellow LED -> green is 1 and yellow is 0. */
		ulMask0 = 1U <<  uiMmioIdxGreen;
		ulMask1 = 1U << (uiMmioIdxGreen - 32);

		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[0] = ulMask0;
		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[1] = ulMask1;
	}
}
#endif
