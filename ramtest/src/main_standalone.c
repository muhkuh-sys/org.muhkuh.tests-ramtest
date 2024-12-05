
#include <string.h>

#include "netx_io_areas.h"

#include "bootblock_oldstyle.h"
#include "standalone_parameter.h"
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

#if ASIC_TYP==ASIC_TYP_NETX50
void netx50_special_setup(RAMTEST_PARAMETER_T *ptTestParameter)
{
	unsigned long ulUartParameter;
	unsigned int uiMmioMax;
	unsigned long ulMmioUartRx;
	unsigned long ulMmioUartTx;
	unsigned int uiCnt;
	unsigned long ulValue;
	HOSTDEF(ptAsicCtrlArea);
	HOSTDEF(ptMmioCtrlArea);


	/* TODO: Evaluate the progress parameter.
	 *       For now this is fixed to RDY/RUN.
	 */
	ptTestParameter->pfnProgress = progress_rdyrun;
	ptTestParameter->ulProgress = 0;

	ulUartParameter = s_tRamtestParameterBlock.ulUartParameter;
	uiMmioMax = sizeof(ptMmioCtrlArea->aulMmio_cfg) / sizeof(unsigned long);
	ulMmioUartRx = (ulUartParameter & 0x00ff0000U) >> 16U;
	ulMmioUartTx = (ulUartParameter & 0xff000000U) >> 24U;
//	uprintf("*** MMIO max=%d, RX=%d, TX=%d\n", uiMmioMax, ulMmioUartRx, ulMmioUartTx);
	/* The pin numbers must not be the same and within the valid range of MMIO pins. */
	if( ulMmioUartRx!=ulMmioUartTx && ulMmioUartRx<uiMmioMax && ulMmioUartTx<uiMmioMax )
	{
		/* Re-configure the MMIO pins.
		 * It is important that a function is mapped to only one pin. Strange things
		 * will happen otherwise for input signals.
		 *
		 * Loop over all MMIOs and remove the UART RX and TX.
		 */
		for(uiCnt=0; uiCnt<(sizeof(ptMmioCtrlArea->aulMmio_cfg)/sizeof(unsigned long)); ++uiCnt)
		{
			ulValue   = ptMmioCtrlArea->aulMmio_cfg[uiCnt];
			ulValue  &= HOSTMSK(mmio0_cfg_mmio0_sel);
			ulValue >>= HOSTSRT(mmio0_cfg_mmio0_sel);
			if( (ulValue==NX50_MMIO_CFG_uart0_rxd) || (ulValue==NX50_MMIO_CFG_uart0_txd) )
			{
				/* Remove the UART function from the MMIO pin. */
				ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
				ptMmioCtrlArea->aulMmio_cfg[uiCnt] = 0xffU;
//				uprintf("*** Set MMIO %d from 0x%08x -> 0x%08x\n", uiCnt, ptMmioCtrlArea->aulMmio_cfg[uiCnt], 0xff);
			}
		}

		/* Extract the MMIOs for the UART pins from the parameter DWORD. */

		/* Set the new MMIO pins to the UART RX and TX function. */
		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptMmioCtrlArea->aulMmio_cfg[ulMmioUartRx] = NX50_MMIO_CFG_uart0_rxd;
//		uprintf("*** Set MMIO %d from 0x%08x -> 0x%08x\n", ulMmioUartRx, ptMmioCtrlArea->aulMmio_cfg[ulMmioUartRx], NX50_MMIO_CFG_uart0_rxd);

		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptMmioCtrlArea->aulMmio_cfg[ulMmioUartTx] = NX50_MMIO_CFG_uart0_txd;
//		uprintf("*** Set MMIO %d from 0x%08x -> 0x%08x\n", ulMmioUartTx, ptMmioCtrlArea->aulMmio_cfg[ulMmioUartTx], NX50_MMIO_CFG_uart0_txd);
	}
}
#endif


/*-------------------------------------------------------------------------*/

void ramtest_main(void) __attribute__ ((noreturn));
void ramtest_main(void)
{
	unsigned long ulSdramGeneralCtrl;
	unsigned long ulSdramTimingCtrl;
	unsigned long ulSdramMr;
	RAMTEST_PARAMETER_T tTestParams;
	int iResult;
#if 0 /* ASIC_TYP==ASIC_TYP_NETX56 */
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

	tTestParams.ulStart = s_tRamtestParameterBlock.ulStartAddress;
	tTestParams.ulSize = s_tRamtestParameterBlock.ulSize;

	ulSdramGeneralCtrl = s_tRamtestParameterBlock.ulSDRAMGeneralCtrl;
	ulSdramTimingCtrl = s_tRamtestParameterBlock.ulSDRAMTimingCtrl;
	ulSdramMr = s_tRamtestParameterBlock.ulSDRAMModeRegister;

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
#if 0 /* ASIC_TYP==ASIC_TYP_NETX56 */
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
#elif ASIC_TYP==ASIC_TYP_NETX50
	netx50_special_setup(&tTestParams);
#else
	tTestParams.pfnProgress = progress_rdyrun;
	tTestParams.ulProgress = 0;
#endif

	/* No signal when a loop has finished */
	tTestParams.pfnLoopFinished = NULL;

	/* The SDRAM should not be setup if all 3 parameters are 0.
	 * This is important for an environment with a HWC.
	 */
	if( (ulSdramGeneralCtrl|ulSdramTimingCtrl|ulSdramMr)==0x00000000 )
	{
		uprintf("All SDRAM parameter are 0. Skipping SDRAM setup.\n");
		iResult = 0;
	}
	else
	{
		/* Setup the SDRAM. */
		iResult = sdram_setup(tTestParams.ulStart, ulSdramGeneralCtrl, ulSdramTimingCtrl, ulSdramMr);
	}

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

