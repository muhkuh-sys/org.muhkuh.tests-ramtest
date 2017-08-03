#include "uprintf.h"


typedef enum ENUM_MEMDEV
{
	MEMDEV_SDRAM_E          = 0,
	MEMDEV_SRAM_E_CS0       = 1,
	MEMDEV_SRAM_E_CS1       = 2,
	MEMDEV_SRAM_E_CS2       = 3,
	MEMDEV_SRAM_E_CS3       = 4,
	MEMDEV_SDRAM_H          = 5,
	MEMDEV_SRAM_H_CS0       = 6,
	MEMDEV_SRAM_H_CS1       = 7,
	MEMDEV_SRAM_H_CS2       = 8,
	MEMDEV_SRAM_H_CS3       = 9,
	MEMDEV_DDR              = 10
} MEMDEV_T;



typedef enum ENUM_BOOTING
{
	BOOTING_Ok                              = 0,  /* Booting was OK and the code returned. */
	BOOTING_Not_Allowed                     = 1,  /* The configuration does not allow access to this interface. */
	BOOTING_Setup_Error                     = 2,  /* Detection or setup of the media failed. */
	BOOTING_Transfer_Error                  = 3,  /* Transferring the data from the media failed. */
	BOOTING_Cookie_Invalid                  = 4,  /* The magic cookie is invalid. */
	BOOTING_Signature_Invalid               = 5,  /* The signature is invalid. */
	BOOTING_Header_Checksum_Invalid         = 6,  /* The header checksum is not correct. */
	BOOTING_Image_Processing_Errors         = 7,  /* Errors occurred while processing the HBOOT image. */
	BOOTING_Secure_Error                    = 8,  /* Something bad with the security stuff happened. */
} BOOTING_T;



typedef enum MEMORY_INTERFACE_ENUM
{
	MEMORY_INTERFACE_MEM_SRAM     = 0,
	MEMORY_INTERFACE_MEM_SDRAM    = 1,
	MEMORY_INTERFACE_HIF_SRAM     = 2,
	MEMORY_INTERFACE_HIF_SDRAM    = 3,
	MEMORY_INTERFACE_PL353_NAND   = 4,
	MEMORY_INTERFACE_PL353_SRAM   = 5,
	MEMORY_INTERFACE_DDR          = 6
} MEMORY_INTERFACE_T;



typedef struct STRUCT_NETX_SRAM_CONFIGURATION
{
	unsigned long aulCtrl[4];
	unsigned long  ulApmCtrl;
	unsigned long  ulRdyCfg;
} NETX_SRAM_CONFIGURATION_T;


extern NETX_SRAM_CONFIGURATION_T tNetxHifSram; //0x23C88
extern NETX_SRAM_CONFIGURATION_T tNetxMemSram; //0x23CA0

int memory_setup_sdram(MEMORY_INTERFACE_T tInterface);
int memory_setup_sram(MEMORY_INTERFACE_T tInterface, unsigned int uiChipSelect, unsigned long ulSRamCtrl);
int memory_setup_ddr(void);



BOOTING_T local_main(unsigned long ulParameter);
BOOTING_T local_main(unsigned long ulParameter)
{
	BOOTING_T tResult;
	MEMDEV_T tMemDev;
	int iResult;


	uprintf("MDUP 0x%08x\n", ulParameter);

	tMemDev = (MEMDEV_T)ulParameter;
	tResult = BOOTING_Image_Processing_Errors;
	switch(tMemDev)
	{
	case MEMDEV_SDRAM_E:
	case MEMDEV_SRAM_E_CS0:
	case MEMDEV_SRAM_E_CS1:
	case MEMDEV_SRAM_E_CS2:
	case MEMDEV_SRAM_E_CS3:
	case MEMDEV_SDRAM_H:
	case MEMDEV_SRAM_H_CS0:
	case MEMDEV_SRAM_H_CS1:
	case MEMDEV_SRAM_H_CS2:
	case MEMDEV_SRAM_H_CS3:
	case MEMDEV_DDR:
		tResult = BOOTING_Ok;
		break;
	}

	if( tResult!=BOOTING_Ok )
	{
		uprintf("Invalid memory device: %d.\n", ulParameter);
	}
	else
	{
		/* Setup the memory device. */
		switch(tMemDev)
		{
		case MEMDEV_SDRAM_E:
			uprintf("Setup SDRAM E\n");
			iResult = memory_setup_sdram(MEMORY_INTERFACE_MEM_SDRAM);
			break;

		case MEMDEV_SRAM_E_CS0:
			uprintf("Setup SRAM E CS0\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_MEM_SRAM, 0, tNetxMemSram.aulCtrl[0]);
			break;

		case MEMDEV_SRAM_E_CS1:
			uprintf("Setup SRAM E CS1\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_MEM_SRAM, 1, tNetxMemSram.aulCtrl[1]);
			break;

		case MEMDEV_SRAM_E_CS2:
			uprintf("Setup SRAM E CS2\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_MEM_SRAM, 2, tNetxMemSram.aulCtrl[2]);
			break;

		case MEMDEV_SRAM_E_CS3:
			uprintf("Setup SRAM E CS3\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_MEM_SRAM, 3, tNetxMemSram.aulCtrl[3]);
			break;

		case MEMDEV_SDRAM_H:
			uprintf("Setup SDRAM H\n");
			iResult = memory_setup_sdram(MEMORY_INTERFACE_HIF_SDRAM);
			break;

		case MEMDEV_SRAM_H_CS0:
			uprintf("Setup SRAM H CS0\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_HIF_SRAM, 0, tNetxHifSram.aulCtrl[0]);
			break;

		case MEMDEV_SRAM_H_CS1:
			uprintf("Setup SRAM H CS1\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_HIF_SRAM, 1, tNetxHifSram.aulCtrl[1]);
			break;

		case MEMDEV_SRAM_H_CS2:
			uprintf("Setup SRAM H CS2\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_HIF_SRAM, 2, tNetxHifSram.aulCtrl[2]);
			break;

		case MEMDEV_SRAM_H_CS3:
			uprintf("Setup SRAM H CS3\n");
			iResult = memory_setup_sram(MEMORY_INTERFACE_HIF_SRAM, 3, tNetxHifSram.aulCtrl[3]);
			break;

		case MEMDEV_DDR:
			uprintf("Setup DDR\n");
			iResult = memory_setup_ddr();
			break;
		}
		if( iResult!=0 )
		{
			tResult = BOOTING_Image_Processing_Errors;
		}
		uprintf("MDUP finished with status %d.\n", tResult);
	}

	return tResult;
}
