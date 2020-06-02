
#include <string.h>

#include "netx_io_areas.h"

#include "bootblock_oldstyle.h"
#include "progress.h"
#include "ramtest.h"
#include "rdy_run.h"
#include "serial_vectors.h"
#include "setup_sdram.h"
#include "systime.h"
#include "uart_standalone.h"
#include "uprintf.h"
#include "version.h"


/*-------------------------------------------------------------------------*/

#if ASIC_TYP==ASIC_TYP_NETX90
typedef struct RAMTEST_PARAMETER_BLOCK_STRUCT
{
	unsigned long ulSDRAMGeneralCtrl;
	unsigned long ulSDRAMTimingCtrl;
	unsigned long ulSDRAMModeRegister;
	unsigned long ulSizeExponent;
	unsigned long ulStartAddress;
} RAMTEST_PARAMETER_BLOCK_T;
#endif


#if ASIC_TYP==ASIC_TYP_NETX90
void ramtest_main(const RAMTEST_PARAMETER_BLOCK_T *ptRamtestParameterBlock) __attribute__ ((noreturn));
void ramtest_main(const RAMTEST_PARAMETER_BLOCK_T *ptRamtestParameterBlock)
#else
void ramtest_main(const BOOTBLOCK_OLDSTYLE_U_T *ptBootBlock) __attribute__ ((noreturn));
void ramtest_main(const BOOTBLOCK_OLDSTYLE_U_T *ptBootBlock)
#endif
{
	unsigned long ulSdramGeneralCtrl;
	unsigned long ulSdramTimingCtrl;
	unsigned long ulSdramMr;
	RAMTEST_PARAMETER_T tTestParams;
	int iResult;
#if ASIC_TYP==ASIC_TYP_NETX56
	HOSTDEF(ptAsicCtrlArea);
	HOSTDEF(ptMmioCtrlArea);
	unsigned int uiMmioGreen;
	unsigned int uiMmioYellow;
	unsigned long ulValue;
#endif

	systime_init();

	uart_standalone_initialize();
	uprintf("\f. *** RAM test by cthelen@hilscher.com ***\n");
	uprintf("V" VERSION_ALL "\n\n");


	/*
	 * Set the RAM test configuration.
	 */
	memset(&tTestParams, 0, sizeof(tTestParams));

#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
	/* On netx 4000, set hardcoded parameters for the moment. */
	/* Set the start of the test area. */
	tTestParams.ulStart = 0x40000000;

	/* Set the size of the SDRAM from the geometry. */
	ulSdramGeneralCtrl = 0xffffffff;
	tTestParams.ulSize = 0x00010000;

#elif ASIC_TYP==ASIC_TYP_NETX90
	tTestParams.ulStart = ptRamtestParameterBlock->ulStartAddress;
	tTestParams.ulSize = 1U << ptRamtestParameterBlock->ulSizeExponent;

	ulSdramGeneralCtrl = ptRamtestParameterBlock->ulSDRAMGeneralCtrl;
	ulSdramTimingCtrl = ptRamtestParameterBlock->ulSDRAMTimingCtrl;
	ulSdramMr = ptRamtestParameterBlock->ulSDRAMModeRegister;

#else
	/* Set the start of the test area. */
	tTestParams.ulStart = ptBootBlock->s.ulUserData;

	/* Set the size of the SDRAM from the geometry. */
	ulSdramGeneralCtrl = ptBootBlock->s.uMemoryCtrl.sSDRam.ulGeneralCtrl;
	ulSdramTimingCtrl = ptBootBlock->s.uMemoryCtrl.sSDRam.ulTimingCtrl;
	ulSdramMr = ptBootBlock->s.uMemoryCtrl.sSDRam.ulModeRegister;

	tTestParams.ulSize = sdram_get_size(ulSdramGeneralCtrl);
#endif
	/* TODO: Get this from the bootblock or parameter block. */
	tTestParams.ulCases  = RAMTESTCASE_08BIT;
	tTestParams.ulCases |= RAMTESTCASE_16BIT;
	tTestParams.ulCases |= RAMTESTCASE_32BIT;
	tTestParams.ulCases |= RAMTESTCASE_BURST;
	tTestParams.ulCases |= RAMTESTCASE_DATABUS;
	tTestParams.ulCases |= RAMTESTCASE_MARCHC;
	tTestParams.ulCases |= RAMTESTCASE_CHECKERBOARD;

	/* Loop endless. */
	tTestParams.ulLoops = 0;

	/* Do not run the performance tests. */
	tTestParams.ulPerfTestCases = 0;

	/* Set the progress callback. */
#if ASIC_TYP==ASIC_TYP_NETX56
	ulValue = ptBootBlock->s.uMemoryCtrl.sSDRam.aulReserved[0];
	if( ulValue!=0 )
	{
		uiMmioGreen  =  ulValue       & 0xff;
		uiMmioYellow = (ulValue >> 8) & 0xff;

		/* Setup the PIOs. */
		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptMmioCtrlArea->aulMmio_cfg[uiMmioGreen] = MMIO_CFG_PIO;
		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptMmioCtrlArea->aulMmio_cfg[uiMmioYellow] = MMIO_CFG_PIO;

		ulValue  = 1U << uiMmioGreen;
		ulValue |= 1U << uiMmioYellow;
		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[0] = ulValue;
		ptMmioCtrlArea->aulMmio_pio_oe_line_cfg[0]  = ulValue;

		ulValue  = 1U << (uiMmioGreen  - 32);
		ulValue |= 1U << (uiMmioYellow - 32);
		ptMmioCtrlArea->aulMmio_pio_out_line_cfg[1] = ulValue;
		ptMmioCtrlArea->aulMmio_pio_oe_line_cfg[1]  = ulValue;

		tTestParams.pfnProgress = progress_mmio;
		tTestParams.ulProgress = uiMmioGreen | (uiMmioYellow << 8);
	}
	else
	{
		tTestParams.pfnProgress = progress_rdyrun;
		tTestParams.ulProgress = 0;
	}
#else
	tTestParams.pfnProgress = progress_rdyrun;
	tTestParams.ulProgress = 0;
#endif

	/* No signal when a loop has finished */
	tTestParams.pfnLoopFinished = NULL;

	/* Setup the SDRAM. */
	iResult = sdram_setup(tTestParams.ulStart, ulSdramGeneralCtrl, ulSdramTimingCtrl, ulSdramMr);
	if( iResult==0 )
	{
		/*
		 * Run the RAM test.
		 * With tTestParams.ulLoops=0 this function will only return if an error occurs.
		 */
		ramtest_run(&tTestParams);
	}

	tTestParams.pfnProgress(&tTestParams, RAMTEST_RESULT_FAILED);
	while(1);
}

/*-----------------------------------*/

