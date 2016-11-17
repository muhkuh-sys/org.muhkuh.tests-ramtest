
#include <string.h>

#include "netx_io_areas.h"

#include "bootblock_oldstyle.h"
#include "ramtest.h"
#include "rdy_run.h"
#include "serial_vectors.h"
#include "systime.h"
#include "uart_standalone.h"
#include "uprintf.h"
#include "version.h"


/*-------------------------------------------------------------------------*/

static unsigned long sdram_get_size(unsigned long ulSdramGeneralCtrl)
{
	unsigned long ulBanks;
	unsigned long ulRows;
	unsigned long ulColumns;
	unsigned long ulBus;
	unsigned long ulSize;


	ulBanks     = ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_banks);
	ulBanks   >>= HOSTSRT(sdram_general_ctrl_banks);
	ulBanks     = 2U << ulBanks;

	ulRows      = ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_rows);
	ulRows    >>= HOSTSRT(sdram_general_ctrl_rows);
	ulRows      = 256U << ulRows;

	ulColumns   = ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_columns);
	ulColumns >>= HOSTSRT(sdram_general_ctrl_columns);
	ulColumns   = 2048U << ulColumns;

#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX500 || ASIC_TYP==ASIC_TYP_NETX50 || ASIC_TYP==ASIC_TYP_NETX56
	if( (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_dbus32))!=0 )
	{
		/* 32 bit bus. */
		ulBus = 4;
	}
	else
	{
		/* 16 bit bus. */
		ulBus = 2;
	}
#elif ASIC_TYP==ASIC_TYP_NETX10
	if( (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_dbus16))!=0 )
	{
		/* 16 bit bus. */
		ulBus = 2;
	}
	else
	{
		/* 8 bit bus. */
		ulBus = 1;
	}
#endif

	ulSize  = ulBanks * ulRows * ulColumns * ulBus;

	return ulSize;
}



#if ASIC_TYP==ASIC_TYP_NETX10
static int setup_sdram_hif_netx10(unsigned long ulSdramGeneralCtrl)
{
	HOSTDEF(ptAsicCtrlArea);
	HOSTDEF(ptHifIoCtrlArea);
	unsigned long ulMiCfg;
	unsigned long ulValue;


	ulMiCfg = 0;
	if( (ulSdramGeneralCtrl&HOSTMSK(sdram_general_ctrl_dbus16))!=0 )
	{
		ulMiCfg = 1;
	}

	ulValue  = HOSTMSK(hif_io_cfg_en_hif_sdram_mi);
	ulValue |= ulMiCfg << HOSTSRT(hif_io_cfg_hif_mi_cfg);

	ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
	ptHifIoCtrlArea->ulHif_io_cfg = ulValue;

	/* All OK! */
	return 0;
}


#elif ASIC_TYP==ASIC_TYP_NETX56
typedef struct HIF_SIZE_TO_ADRCFG_STRUCT
{
	unsigned long ulSDRAMSize;
	unsigned long ulAdrCfg;
} HIF_SIZE_TO_ADRCFG_T;

static const HIF_SIZE_TO_ADRCFG_T atAddressLines[] =
{
	{0x00000800, 0x00000000},
	{0x00001000, 0x00000100},
	{0x00002000, 0x00000200},
	{0x00004000, 0x00000300},
	{0x00008000, 0x00000400},
	{0x00010000, 0x00000500},
	{0x00020000, 0x00000600},
	{0x00040000, 0x00000700},
	{0x00080000, 0x00000800},
	{0x00100000, 0x00000900},
	{0x00200000, 0x00000a00},
	{0x00400000, 0x00000b00},
	{0x00800000, 0x00000c00},
	{0x01000000, 0x00000d00},
	{0x02000000, 0x00000e00}
};


static int setup_sdram_hif_netx56(unsigned long ulSdramGeneralCtrl)
{
	HOSTDEF(ptAsicCtrlArea);
	HOSTDEF(ptHifIoCtrlArea);
	int iResult;
	const HIF_SIZE_TO_ADRCFG_T *ptCnt;
	const HIF_SIZE_TO_ADRCFG_T *ptEnd;
	unsigned long ulSdramSize;
	unsigned long ulAddressCfg;
	unsigned long ulDataCfg;


	/*
	 * Get the configuration value for the number of address lines.
	 */
	/* Get the SDRAM size from the geometry settings. */
	ulSdramSize = sdram_get_size(ulSdramGeneralCtrl);
	/* Set the HIF address configuration to an invalid value. */
	ulAddressCfg = 0xffffffffU;

	/* Find the matching SDRAM size. */
	ptCnt = atAddressLines;
	ptEnd = atAddressLines + (sizeof(atAddressLines)/sizeof(atAddressLines[0]));
	do
	{
		if( ulSdramSize<=ptCnt->ulSDRAMSize )
		{
			ulAddressCfg = ptCnt->ulAdrCfg;
			break;
		}
		else
		{
			++ptCnt;
		}
	} while( ptCnt<ptEnd );

	if( ulAddressCfg==0xffffffffU )
	{
		iResult = 1;
	}
	else
	{
		/* Get the configuration value for the data bus size. */
		if( (ulSdramGeneralCtrl&HOSTMSK(sdram_general_ctrl_dbus32))==0 )
		{
			/* The data bus has a size of 16 bits. */
			ulDataCfg  = 1U << HOSTSRT(hif_io_cfg_hif_mi_cfg);
			ulDataCfg |= HOSTMSK(hif_io_cfg_en_hif_sdram_mi);
		}
		else
		{
			/* The data bus has a size of 32 bits. */
			ulDataCfg  = 2U << HOSTSRT(hif_io_cfg_hif_mi_cfg);
			ulDataCfg |= HOSTMSK(hif_io_cfg_en_hif_sdram_mi);
		}

		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptHifIoCtrlArea->ulHif_io_cfg = ulAddressCfg | ulDataCfg;

		iResult = 0;
	}

	return iResult;
}
#endif


static int sdram_setup(const BOOTBLOCK_OLDSTYLE_U_T *ptBootBlock)
{
#if ASIC_TYP==ASIC_TYP_NETX500
	NX500_EXT_SDRAM_CTRL_AREA_T *ptSdram;
#elif ASIC_TYP==ASIC_TYP_NETX4000_RELAXED
	NX4000_EXT_SDRAM_CTRL_AREA_T *ptSdram;
#else
	HOSTADEF(SDRAM) *ptSdram;
#endif
	unsigned long ulSdramGeneralCtrl;
	unsigned long ulSdramTimingCtrl;
	unsigned long ulSdramMr;
	unsigned long ulValue;
	unsigned long ulTimer;
	int iTimeout;
	int iResult;


	/* Expect success. */
	iResult = 0;

	/* Get the SDRAM controller address from the test area address. */
	ptSdram = NULL;
	ulValue = ptBootBlock->s.ulUserData;
#if ASIC_TYP==ASIC_TYP_NETX500
	/* Is the test area inside the SDRAM? */
	if( ulValue>=HOSTADDR(sdram) && ulValue<=HOSTADR(sdram_end) )
	{
		ptSdram = (NX500_EXT_SDRAM_CTRL_AREA_T*)HOSTADDR(ext_sdram_ctrl);
	}
#elif ASIC_TYP==ASIC_TYP_NETX50
	/* Is the test area inside the SDRAM? */
	if( ulValue>=HOSTADDR(sdram) && ulValue<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
#elif ASIC_TYP==ASIC_TYP_NETX56
	/* Is the test area inside the SDRAM? */
	if( ulValue>=HOSTADDR(sdram) && ulValue<=HOSTADR(sdram_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
	/* Is the test area inside the HIF SDRAM? */
	else if( ulValue>=HOSTADDR(hif_sdram_lite) && ulValue<=HOSTADR(hif_sdram_lite_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(hif_sdram_ctrl);

		/* HIF SDRAM needs special preparation. */
		iResult = setup_sdram_hif_netx56(ptBootBlock->s.uMemoryCtrl.sSDRam.ulGeneralCtrl);
	}
#elif ASIC_TYP==ASIC_TYP_NETX10
	/* Is the test area inside the SDRAM? */
	if( ulValue>=HOSTADDR(sdram) && ulValue<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);

		/* Setup netX10 HIF for SDRAM. */
		iResult = setup_sdram_hif_netx10(ptBootBlock->s.uMemoryCtrl.sSDRam.ulGeneralCtrl);
	}
#endif

	if( iResult==0 )
	{
		if( ptSdram==NULL )
		{
			/* No SDRAM -> Setup OK. */
			iResult = 0;
		}
		else
		{
			/* Get the SDRAM parameter from the boot block. */
			/* This will not work on netx 4000. */
			ulSdramGeneralCtrl = ptBootBlock->s.uMemoryCtrl.sSDRam.ulGeneralCtrl;
			ulSdramTimingCtrl  = ptBootBlock->s.uMemoryCtrl.sSDRam.ulTimingCtrl;
			ulSdramMr          = ptBootBlock->s.uMemoryCtrl.sSDRam.ulModeRegister;
			/* The MR value is an extension to the boot block. Use the default value if it is 0. */
			if( ulSdramMr==0 )
			{
				ulSdramMr = HOSTDFLT(sdram_mr);
			}

			uprintf("SDRAM general ctrl:  0x%08x\n", ulSdramGeneralCtrl);
			uprintf("SDRAM timing ctrl:   0x%08x\n", ulSdramTimingCtrl);
			uprintf("SDRAM mode register: 0x%08x\n", ulSdramMr);

			/* Deactivate the SDRAM controller. */
			ptSdram->ulSdram_general_ctrl = 0;

			/* Set the timing and MR parameter. */
			ptSdram->ulSdram_timing_ctrl = ulSdramTimingCtrl;
			ptSdram->ulSdram_mr = ulSdramMr;

			/* Set the general control value and activate the controller. */
			ptSdram->ulSdram_general_ctrl = ulSdramGeneralCtrl;

			/* Wait until the SDRAM is ready with a timeout of 1 second. */
			ulTimer = systime_get_ms();
			do
			{
				/* Did already 1 second pass? */
				iTimeout = systime_elapsed(ulTimer, 1000U);
				if( iTimeout!=0 )
				{
					break;
				}
				ulValue  = ptSdram->ulSdram_general_ctrl;
				ulValue &= HOSTMSK(sdram_general_ctrl_sdram_ready);
			} while( ulValue==0 );

			if( iTimeout!=0 )
			{
				iResult = 1;
			}
			else
			{
				iResult = 0;
			}
		}
	}

	return iResult;
}


static void ramtest_rdyrun_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
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
static void ramtest_mmio_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
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

void ramtest_main(const BOOTBLOCK_OLDSTYLE_U_T *ptBootBlock) __attribute__ ((noreturn));
void ramtest_main(const BOOTBLOCK_OLDSTYLE_U_T *ptBootBlock)
{
	unsigned long ulSdramGeneralCtrl;
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
	
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED
	/* On netx 4000, set hardcoded parameters for the moment. */
	/* Set the start of the test area. */
	tTestParams.ulStart = 0x40000000;
	
	/* Set the size of the SDRAM from the geometry. */
	ulSdramGeneralCtrl = 0xffffffff;
	tTestParams.ulSize = 0x00010000;

#else
	/* Set the start of the test area. */
	tTestParams.ulStart = ptBootBlock->s.ulUserData;
	
	/* Set the size of the SDRAM from the geometry. */
	ulSdramGeneralCtrl = ptBootBlock->s.uMemoryCtrl.sSDRam.ulGeneralCtrl;
	tTestParams.ulSize = sdram_get_size(ulSdramGeneralCtrl);
#endif
	/* Run all test cases. */
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

		tTestParams.pfnProgress = ramtest_mmio_progress;
		tTestParams.ulProgress = uiMmioGreen | (uiMmioYellow << 8);
	}
	else
	{
		tTestParams.pfnProgress = ramtest_rdyrun_progress;
		tTestParams.ulProgress = 0;
	}
#else
	tTestParams.pfnProgress = ramtest_rdyrun_progress;
	tTestParams.ulProgress = 0;
#endif

	/* Setup the SDRAM. */
	iResult = sdram_setup(ptBootBlock);
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

