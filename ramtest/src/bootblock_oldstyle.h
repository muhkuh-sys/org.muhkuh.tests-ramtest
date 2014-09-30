/***************************************************************************
 *   Copyright (C) 2005, 2006, 2007, 2008, 2009 by Hilscher GmbH           *
 *                                                                         *
 *   Author: Christoph Thelen (cthelen@hilscher.com)                       *
 *                                                                         *
 *   Redistribution or unauthorized use without expressed written          *
 *   agreement from the Hilscher GmbH is forbidden.                        *
 ***************************************************************************/


#include <stddef.h>


#ifndef __BOOTBLOCK_OLDSTYLE_H__
#define __BOOTBLOCK_OLDSTYLE_H__


/* Magic Cookie */
#define BOOTBLOCK_OLDSTYLE_MAGIC	0xf8beaf00U
/* 'NETX' signature in HEX format */
#define BOOTBLOCK_OLDSTYLE_SIGNATURE	0x5854454eU


/* Enumerator defining the different boot option.
 * It is used as parameter for the application.
 */
typedef enum ENUM_BOOTOPTION
{
	BOOTOPTION_PFlash_SRAMBus       = 0,
	BOOTOPTION_PFlash_ExtBus        = 1,
	BOOTOPTION_DualPort             = 2,
	BOOTOPTION_PCI                  = 3,
	BOOTOPTION_MMC                  = 4,
	BOOTOPTION_I2C                  = 5,
	BOOTOPTION_SpiFlash             = 6,
	BOOTOPTION_Ethernet             = 7
} BOOTOPTION_T;



/* application entry point is a "void blah(void)" function */
struct BOOTBLOCK_OLDSTYLE_Ttag;
typedef void(*pfnAppEntryPoint_t)(struct BOOTBLOCK_OLDSTYLE_Ttag *ptBootblock, BOOTOPTION_T bootOption);

/* Structure definition of the Bootblock */
typedef struct BOOTBLOCK_OLDSTYLE_Ttag
{
	unsigned long ulMagic;

	union BOOT_CTRL_UNION
	{
		unsigned long ulSRamCtrl;
		unsigned long ulSpiSpeed;
	} uBootCtrl;

	pfnAppEntryPoint_t pfnExecutionAddress;
	unsigned long ulApplicationChecksum;
	size_t sizApplicationDword;
	unsigned long *pulApplicationLoadAddress;
	unsigned long ulSignature;

	union MEMORY_CTRL_UNION
	{
		struct SDRAM_STRUCT
		{
			unsigned long  ulGeneralCtrl;
			unsigned long  ulTimingCtrl;
			unsigned long  ulModeRegister;
			unsigned long aulReserved[2];
		} sSDRam;
		struct SRAM_STRUCT
		{
			unsigned long ulCtrl;
			unsigned long aulReserved[4];
		} sSRam;
		struct DPM_STRUCT
		{
			unsigned long ulExpBusReg;
			unsigned long ulIoRegMode0;
			unsigned long ulIoRegMode1; 
			unsigned long ulIfConf1;
			unsigned long ulIfConf2;
		} sDpm;
	} uMemoryCtrl;

	unsigned long ulMiscAsicCtrl;
	unsigned long ulUserData;
	unsigned long ulSrcType;
	unsigned long ulBootChksm;
} BOOTBLOCK_OLDSTYLE_T;

typedef union
{
	BOOTBLOCK_OLDSTYLE_T s;
	unsigned long aul[16];
	unsigned char auc[64];
} BOOTBLOCK_OLDSTYLE_U_T;


#endif	/* __BOOTBLOCK_OLDSTYLE_H__ */
