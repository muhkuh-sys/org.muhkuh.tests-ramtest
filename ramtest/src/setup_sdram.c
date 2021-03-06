
#include <string.h>

#include "netx_io_areas.h"
#include "systime.h"
#include "setup_sdram.h"

#if defined(SIMULATION)
#define uprintf(...)
#else
#include "uprintf.h"
#endif


/*-------------------------------------------------------------------------*/

unsigned long sdram_get_size(unsigned long ulSdramGeneralCtrl)
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
	ulRows      = 2048U << ulRows;

	ulColumns   = ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_columns);
	ulColumns >>= HOSTSRT(sdram_general_ctrl_columns);
	ulColumns   = 256U << ulColumns;

#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000 || ASIC_TYP==ASIC_TYP_NETX500 || ASIC_TYP==ASIC_TYP_NETX50 || ASIC_TYP==ASIC_TYP_NETX56
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
#elif ASIC_TYP==ASIC_TYP_NETX90_MPW
	/* NOTE: The netX90 regdef has a typo in the SDRAM controller. The signal sdram_general_ctrl_dbus16 is named sdram_general_ctrl_dbus32. */
	if( (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_dbus32))!=0 )
	{
		/* 16 bit bus. */
		ulBus = 2;
	}
	else
	{
		/* 8 bit bus. */
		ulBus = 1;
	}
#elif ASIC_TYP==ASIC_TYP_NETX90
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
#elif ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
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


static int setup_sdram_hif_netx90_mpw(unsigned long ulSdramGeneralCtrl)
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
#if ASIC_TYP==ASIC_TYP_NETX90_MPW
		/* NOTE: The netX90 regdef has a typo in the SDRAM controller. The signal sdram_general_ctrl_dbus16 is named sdram_general_ctrl_dbus32. */
		if( (ulSdramGeneralCtrl&HOSTMSK(sdram_general_ctrl_dbus32))==0 )
#elif ASIC_TYP==ASIC_TYP_NETX90
		if( (ulSdramGeneralCtrl&HOSTMSK(sdram_general_ctrl_dbus16))==0 )
#endif
		{
			/* The data bus has a size of 8 bits. */
			ulDataCfg  = 0U << HOSTSRT(hif_io_cfg_hif_mi_cfg);
			ulDataCfg |= HOSTMSK(hif_io_cfg_en_hif_sdram_mi);
		}
		else
		{
			/* The data bus has a size of 16 bits. */
			ulDataCfg  = 1U << HOSTSRT(hif_io_cfg_hif_mi_cfg);
			ulDataCfg |= HOSTMSK(hif_io_cfg_en_hif_sdram_mi);
		}

		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
		ptHifIoCtrlArea->ulHif_io_cfg = ulAddressCfg | ulDataCfg;

		iResult = 0;
	}

	return iResult;
}
#elif ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000

static int setup_sdram_mem_netx4000(unsigned long ulSdramGeneralCtrl)
{
#if 0
	/* Enable an SDRAM on the MEM pins. */
	ulValue |= HOSTMSK(hif_io_cfg_en_mem_sdram_mi);
	/* Set the bus width from the general control value. */
	ulValue &= ~HOSTMSK(hif_io_cfg_mem_mi_cfg);
	if( (ulGeneralCtrl&HOSTMSK(sdram_general_ctrl_dbus32))==0 )
	{
		/* The SDRAM general control register selects 16 bits. */
		ulValue |= 1U << HOSTSRT(hif_io_cfg_mem_mi_cfg);
	}
	else
	{
		/* The SDRAM general control register selects 32 bits. */
		ulValue |= 2U << HOSTSRT(hif_io_cfg_mem_mi_cfg);
	}
#endif
	return -1;
}


static int setup_sdram_hif_netx4000(unsigned long ulSdramGeneralCtrl)
{
	HOSTDEF(ptAsicCtrlArea);
	HOSTDEF(ptHifIoCtrlArea);
	int iResult;
	unsigned long ulValue;
	unsigned long ulRowLines;
	unsigned long ulColumnLines;
	unsigned long ulAddressLines;
	unsigned long ulBusWidthBits;


	/* Get the number of */
	ulRowLines  = (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_rows)) >> HOSTSRT(sdram_general_ctrl_rows);
	ulRowLines += 11U;

	ulColumnLines  = (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_columns)) >> HOSTSRT(sdram_general_ctrl_columns);
	ulColumnLines += 8U;
	/* Line A10 is not useable as column address signal. */
	if( ulColumnLines>=11 )
	{
		++ulColumnLines;
	}

	ulAddressLines = ulRowLines;
	if( ulAddressLines<ulColumnLines )
	{
		ulAddressLines = ulColumnLines;
	}

	ulBusWidthBits = (ulSdramGeneralCtrl & HOSTMSK(sdram_general_ctrl_dbus32)) >> HOSTSRT(sdram_general_ctrl_dbus32);
	if( ulBusWidthBits==1 && ulAddressLines>18 )
	{
		uprintf("The number address lines is not availble with 32bits: %d\n", ulAddressLines);
		iResult = -1;
	}
	else if( ulAddressLines>25 )
	{
		uprintf("The number of address lines exceeds available lines: %d\n", ulAddressLines);
		iResult = -1;
	}
	else
	{
		/* Use all data bus lines for the HIF memory interface. */
		ulValue  = 0U << HOSTSRT(hif_io_cfg_sel_mem_d);
		/* No additional address pins for the MEM interface. */
		ulValue |= 0U << HOSTSRT(hif_io_cfg_sel_mem_a_width);
		/* Disable the MEM interface. */
		ulValue |= 0U << HOSTSRT(hif_io_cfg_en_mem_sdram_mi);
		ulValue |= 3U << HOSTSRT(hif_io_cfg_mem_mi_cfg);
		/* No PIO. */
		ulValue |= 0U << HOSTSRT(hif_io_cfg_en_hif_rdy_pio_mi);
		/* Use all unused pins as PIOs. */
		if( ulAddressLines>11U )
		{
			ulValue |= (ulAddressLines-11U) << HOSTSRT(hif_io_cfg_sel_hif_a_width);
		}
		else
		{
			ulValue |= 0U << HOSTSRT(hif_io_cfg_sel_hif_a_width);
		}

		/* Enable an SDRAM on the HIF pins. */
		ulValue |= 1U << HOSTSRT(hif_io_cfg_en_hif_sdram_mi);

		/* 0 (16 bits) -> 01, 1 (32 bits) -> 10 */
		ulValue |= (ulBusWidthBits+1) << HOSTSRT(hif_io_cfg_hif_mi_cfg);

		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;  /* @suppress("Assignment to itself") */
		ptHifIoCtrlArea->ulHif_io_cfg = ulValue;

		/* Activate the DPM clock. */
		ulValue  = ptAsicCtrlArea->ulClock_enable;
		ulValue |= HOSTMSK(clock_enable_dpm);
		ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;  /* @suppress("Assignment to itself") */
		ptAsicCtrlArea->ulClock_enable = ulValue;

		iResult = 0;
	}

	return iResult;
}
#endif



SDRAM_CTRL_T *get_sdram_controller(unsigned long ulTestAreaStart)
{
	SDRAM_CTRL_T *ptSdram;


	/* Get the SDRAM controller address from the test area address. */
	ptSdram = NULL;

#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
	/* Is the test area inside the MEM SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(mem_sdram) && ulTestAreaStart<=HOSTADR(mem_sdram_sdram_end) )
	{
		ptSdram = (HOSTADEF(EXT_SDRAM_CTRL)*)HOSTADDR(ext_sdram_ctrl);
	}
	/* Is the test area inside the HIF SDRAM? */
	else if( ulTestAreaStart>=HOSTADDR(hif_sdram) && ulTestAreaStart<=HOSTADR(hif_sdram_sdram_end) )
	{
		ptSdram = (HOSTADEF(EXT_SDRAM_CTRL)*)HOSTADDR(hif_sdram_ctrl);
	}

#elif ASIC_TYP==ASIC_TYP_NETX500
	/* Is the test area inside the SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(sdram) && ulTestAreaStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (NX500_EXT_SDRAM_CTRL_AREA_T*)HOSTADDR(ext_sdram_ctrl);
	}

#elif ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
	/* Is the test area inside the SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(sdram) && ulTestAreaStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(EXT_SDRAM_CTRL)*)HOSTADDR(hif_sdram_ctrl);
	}

#elif ASIC_TYP==ASIC_TYP_NETX50
	/* Is the test area inside the SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(sdram) && ulTestAreaStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}

#elif ASIC_TYP==ASIC_TYP_NETX56
	/* Is the test area inside the SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(sdram) && ulTestAreaStart<=HOSTADR(sdram_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
	/* Is the test area inside the HIF SDRAM? */
	else if( ulTestAreaStart>=HOSTADDR(hif_sdram_lite) && ulTestAreaStart<=HOSTADR(hif_sdram_lite_sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(hif_sdram_ctrl);
	}

#elif ASIC_TYP==ASIC_TYP_NETX10
	/* Is the test area inside the SDRAM? */
	if( ulTestAreaStart>=HOSTADDR(sdram) && ulTestAreaStart<=HOSTADR(sdram_end) )
	{
		ptSdram = (HOSTADEF(SDRAM)*)HOSTADDR(ext_sdram_ctrl);
	}
#endif

	return ptSdram;
}



int sdram_setup(unsigned long ulSdramStart, unsigned long ulSdramGeneralCtrl, unsigned long ulSdramTimingCtrl, unsigned long ulSdramMr)
{
	SDRAM_CTRL_T *ptSdram;
	unsigned long ulValue;
	unsigned long ulTimer;
	int iTimeout;
	int iResult;


	/* Expect success. */
	iResult = 0;

	uprintf("Parameter:\n");
	uprintf("  SDRAM start:         0x%08x\n", ulSdramStart);
	uprintf("  SDRAM general ctrl:  0x%08x\n", ulSdramGeneralCtrl);
	uprintf("  SDRAM timing ctrl:   0x%08x\n", ulSdramTimingCtrl);
	uprintf("  SDRAM mr:            0x%08x\n", ulSdramMr);

	ptSdram = get_sdram_controller(ulSdramStart);
	if( ptSdram==NULL )
	{
		uprintf("No SDRAM controller available for the test area. Skipping SDRAM init.\n");
	}
	else
	{
		/* Run the device specific initialization. */
#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX4000
		/* Is the test area inside the MEM SDRAM? */
		if( ulSdramStart>=HOSTADDR(mem_sdram) && ulSdramStart<=HOSTADR(mem_sdram_sdram_end) )
		{
			/* MEM SDRAM needs special preparation. */
			iResult = setup_sdram_mem_netx4000(ulSdramGeneralCtrl);
			uprintf("netX4000 SDRAM MEM init: %d\n", iResult);
		}
		/* Is the test area inside the HIF SDRAM? */
		else if( ulSdramStart>=HOSTADDR(hif_sdram) && ulSdramStart<=HOSTADR(hif_sdram_sdram_end) )
		{
			/* HIF SDRAM needs special preparation. */
			iResult = setup_sdram_hif_netx4000(ulSdramGeneralCtrl);
			uprintf("netX4000 SDRAM HIF init: %d\n", iResult);
		}
		else
		{
			uprintf("No special init needed.\n");
		}
#elif ASIC_TYP==ASIC_TYP_NETX90_MPW || ASIC_TYP==ASIC_TYP_NETX90
		/* Is the test area inside the SDRAM? */
		if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_end) )
		{
			/* HIF SDRAM needs special preparation. */
			iResult = setup_sdram_hif_netx90_mpw(ulSdramGeneralCtrl);
			uprintf("netX90 SDRAM HIF init: %d\n", iResult);
		}
		else
		{
			uprintf("No special init needed.\n");
		}
#elif ASIC_TYP==ASIC_TYP_NETX56
		/* Is the test area inside the HIF SDRAM? */
		if( ulSdramStart>=HOSTADDR(hif_sdram_lite) && ulSdramStart<=HOSTADR(hif_sdram_lite_sdram_end) )
		{
			/* HIF SDRAM needs special preparation. */
			iResult = setup_sdram_hif_netx56(ulSdramGeneralCtrl);
			uprintf("netX56 SDRAM HIF init: %d\n", iResult);
		}
		else
		{
			uprintf("No special init needed.\n");
		}
#elif ASIC_TYP==ASIC_TYP_NETX10
		/* Is the test area inside the SDRAM? */
		if( ulSdramStart>=HOSTADDR(sdram) && ulSdramStart<=HOSTADR(sdram_end) )
		{
			/* Setup netX10 HIF for SDRAM. */
			iResult = setup_sdram_hif_netx10(ulSdramGeneralCtrl);
			uprintf("netX10 SDRAM HIF init: %d\n", iResult);
		}
		else
		{
			uprintf("No special init needed.\n");
		}
#endif

		if( iResult!=0 )
		{
			uprintf("The special init failed!\n");
		}
		else
		{
			/* The MR value is an extension to the boot block. Use the default value if it is 0. */
			if( ulSdramMr==0 )
			{
				ulSdramMr = HOSTDFLT(sdram_mr);
			}

			//sim_message(". SDRAM controller:    ", disp_data, (unsigned long) ptSdram);
			//sim_message(". SDRAM general ctrl:  ", disp_data, ulSdramGeneralCtrl);
			//sim_message(". SDRAM timing ctrl:   ", disp_data, ulSdramTimingCtrl);
			//sim_message(". SDRAM mode register: ", disp_data, ulSdramMr);
			
			uprintf("SDRAM controller:    0x%08x\n", (unsigned long) ptSdram);
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
