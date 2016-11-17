#include <string.h>
#include "ramtest.h"
#include "systime.h"
#include "uprintf.h"
#include "version.h"
#include "main_standalone_common.h"
#include "uart_standalone.h"

#include "netx_io_areas.h"

/*-------------------------------------------------------------------------*/

/* 
	NXHX 4000:
	MMIO 51 CH0 LNK LED (green)  -> CA9 core 0 OK
	MMIO 52 CH0 ACT LED (yellow) -> CA9 core 0 Error
	MMIO 53 CH1 LNK LED (green)  -> CA9 core 1 OK
	MMIO 54 CH1 ACT LED (yellow) -> CA9 core 1 Error
	
	Note: these MMIOs must be pre-configured for PIO function, which is the default.
*/

const unsigned long MMIO_LED_ON  = 0x000100ffUL;
const unsigned long MMIO_LED_OFF = 0x000300ffUL;

#define LED_OFF 0
#define LED_GREEN 1
#define LED_YELLOW 2

void ramtest_mmio_led_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult);
void ramtest_mmio_led_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
{

	unsigned long ulProgressRaw     =  ptRamTestParameter->ulProgress;
	unsigned long ulProgressLedMmioNr  = (ulProgressRaw >> 16) & 0xff;
	unsigned long ulErrorLedMmioNr = (ulProgressRaw >> 24) & 0xff;
	unsigned long ulProgress        =  ulProgressRaw & 1;
	
	HOSTDEF(ptMmioCtrlArea);
	int iLedStates;
	unsigned long ulProgressLedState;
	unsigned long ulErrorLedState;
	
	if( tResult==RAMTEST_RESULT_OK )
	{
		if( ulProgress==0 )
		{
			iLedStates = LED_GREEN;
		}
		else
		{
			iLedStates = LED_OFF;
		}

		ptRamTestParameter->ulProgress ^= 1;
	}
	else
	{
		iLedStates = LED_YELLOW;
	}
	
	/* set leds */
	switch(iLedStates) 
	{
		case LED_OFF:
			ulProgressLedState = MMIO_LED_OFF;
			ulErrorLedState = MMIO_LED_OFF;
			break;
		case LED_GREEN:
			ulProgressLedState = MMIO_LED_ON;
			ulErrorLedState = MMIO_LED_OFF;
			break;
		case LED_YELLOW:
			ulProgressLedState = MMIO_LED_OFF;
			ulErrorLedState = MMIO_LED_ON;
			break;
	}
	
	ptMmioCtrlArea->aulMmio_cfg[ulProgressLedMmioNr] = ulProgressLedState;
	ptMmioCtrlArea->aulMmio_cfg[ulErrorLedMmioNr] = ulErrorLedState;
	
}


void systime_wait_ms(unsigned long ulDelay_ms);
void systime_wait_ms(unsigned long ulDelay_ms)
{
	unsigned long ulStart = systime_get_ms();
	while (!systime_elapsed(ulStart, ulDelay_ms)) {}
}


typedef struct RAMTEST_STANDALONE_NETX4000_PARAMETER_STRUCT
{
	unsigned long ulStart;
	unsigned long ulSize;
	unsigned long ulCases;
	unsigned long ulLoops;
	unsigned long ulPerfTestCases;
	unsigned long ulStatusLedMmioNr;
	unsigned long ulUseUart;
	unsigned long ulTagMask;
	unsigned long ulTagValue;
} RAMTEST_STANDALONE_NETX4000_PARAMETER_T; 

void print_ddr_config(void);
void print_ddr_config(void)
{
	HOSTDEF(ptDdrCtrlArea);
	unsigned long ulDdrCtrl009 = ptDdrCtrlArea->aulDDR_CTRL_CTL[9];
	unsigned long ulDdrCtrl010 = ptDdrCtrlArea->aulDDR_CTRL_CTL[10];
	unsigned long ulDdrCtrl058 = ptDdrCtrlArea->aulDDR_CTRL_CTL[58];
	unsigned long ulDdrCtrl125 = ptDdrCtrlArea->aulDDR_CTRL_CTL[125];
	unsigned long ulDdrCtrl152 = ptDdrCtrlArea->aulDDR_CTRL_CTL[152];
	
	uprintf("\n");
	uprintf("DDR controller config:\n");
	uprintf("DDR_CTRL_009 = 0x%08x\n", ulDdrCtrl009);
	uprintf("    CASLAT_LIN = %d\n",         (ulDdrCtrl009 & MSK_NX4000_DDR_CTRL_CTL9_CASLAT_LIN)    >> SRT_NX4000_DDR_CTRL_CTL9_CASLAT_LIN);

	uprintf("DDR_CTRL_010 = 0x%08x\n", ulDdrCtrl010);
	uprintf("    WRLAT = %d\n",              (ulDdrCtrl010 & MSK_NX4000_DDR_CTRL_CTL10_WRLAT)        >> SRT_NX4000_DDR_CTRL_CTL10_WRLAT);
	uprintf("    ADDITIVE_LAT = %d\n",       (ulDdrCtrl010 & MSK_NX4000_DDR_CTRL_CTL10_ADDITIVE_LAT) >> SRT_NX4000_DDR_CTRL_CTL10_ADDITIVE_LAT);
	
	uprintf("DDR_CTRL_058 = 0x%08x\n", ulDdrCtrl058);
	uprintf("    REDUC = %d\n",              (ulDdrCtrl058 & MSK_NX4000_DDR_CTRL_CTL58_REDUC)        >> SRT_NX4000_DDR_CTRL_CTL58_REDUC);
	
	uprintf("DDR_CTRL_125 = 0x%08x\n", ulDdrCtrl125);
	uprintf("    WRLAT_ADJ = %d\n",          (ulDdrCtrl125 & MSK_NX4000_DDR_CTRL_CTL125_WRLAT_ADJ)   >> SRT_NX4000_DDR_CTRL_CTL125_WRLAT_ADJ);
	uprintf("    RDLAT_ADJ = %d\n",          (ulDdrCtrl125 & MSK_NX4000_DDR_CTRL_CTL125_RDLAT_ADJ)   >> SRT_NX4000_DDR_CTRL_CTL125_RDLAT_ADJ);
	
	uprintf("DDR_CTRL_152 = 0x%08x\n", ulDdrCtrl152);
	uprintf("\n");
}


void ramtest_main(const RAMTEST_STANDALONE_NETX4000_PARAMETER_T* ptParam) /* __attribute__ ((noreturn))*/;
void ramtest_main(const RAMTEST_STANDALONE_NETX4000_PARAMETER_T* ptParam)
{
	RAMTEST_PARAMETER_T tTestParams;
	RAMTEST_RESULT_T tRes;
	HOSTDEF(ptDdrCtrlArea);
	unsigned long fDdrCtrlReduc;
	
#ifdef CPU_CR7
	systime_init();
#endif

	if (ptParam->ulUseUart == 1)
	{
		uart_standalone_initialize();
		systime_wait_ms(1);
		//__asm__("dsb");
	}
	else
	{
		ramtest_clear_serial_vectors();
	}
	
	
	uprintf("\f. *** RAM test by cthelen@hilscher.com ***\n");
	uprintf("V" VERSION_ALL "\n\n");
	
	volatile unsigned long *pulBootmode = (volatile unsigned long*) Adr_NX4000_RAP_SYSCTRL_RAP_SYSCTRL_BOOTMODE;
	volatile unsigned long   ulBootmode = *pulBootmode;
	
	uprintf("Bootstrap status register: 0x%08x\n", ulBootmode);
	if ((ulBootmode & MSK_NX4000_RAP_SYSCTRL_BOOTMODE_SET_PLL_1200) == 0)
	{
		uprintf("PLL speed: 800 MHz\n");
	}
	else
	{
		uprintf("PLL speed: 1200 MHz\n");
	}
	
	/*
	 * Set the RAM test configuration.
	 */
	memset(&tTestParams, 0, sizeof(tTestParams));
	tTestParams.ulStart         = ptParam->ulStart;
	tTestParams.ulSize          = ptParam->ulSize;
	tTestParams.ulCases         = ptParam->ulCases;
	tTestParams.ulLoops         = ptParam->ulLoops;
	tTestParams.ulPerfTestCases = ptParam->ulPerfTestCases;
	tTestParams.ulTagMask       = ptParam->ulTagMask;
	tTestParams.ulTagValue      = ptParam->ulTagValue;
		
	/* Override the test case selection: use only the address sequence test */
	//tTestParams.ulCases         = 0x80;
	
	if ((ptParam->ulStart >= 0x40000000UL) && (ptParam->ulStart <= 0x7fffffff))
	{
		print_ddr_config();
    
		/* If the DDR ctrl is configured for 16 bit, divide the start offsets and sizes by two. */
		fDdrCtrlReduc = (ptDdrCtrlArea->aulDDR_CTRL_CTL[58] & MSK_NX4000_DDR_CTRL_CTL58_REDUC) >> SRT_NX4000_DDR_CTRL_CTL58_REDUC;
		if (fDdrCtrlReduc) 
		{
			uprintf("Adjusting area start/size for 16 bit DDR mode.\n");
			tTestParams.ulStart -= (tTestParams.ulStart - 0x40000000)/2;
			tTestParams.ulSize /= 2;
		}
    
    /*initialize DDR memory to be able to enable ECC feature*/
    // do not use memset(ptParam->ulStart, 0, ptParam->ulSize);
    // make sure to execute only 32 and large data with accesses into DDR

    volatile unsigned long *ptrAddr;
    unsigned long ulEndAddr = (ptParam->ulStart & 0xFFFFFFFCUL) + (ptParam->ulSize & 0xFFFFFFFCUL);

    uprintf("Initialize DDR memory\n");
    uprintf("Start Addr: 0x%08x  EndAddr: 0x%08x \n", (ptParam->ulStart & 0xFFFFFFFCUL), ulEndAddr );
    
    ptrAddr = (volatile unsigned long *)(ptParam->ulStart & 0xFFFFFFFCUL);
	  do {
		  // *ptrAddr = 0x00UL;
		  *ptrAddr = (unsigned long)ptrAddr;
      ptrAddr++;
	  } while ( (unsigned long)ptrAddr < ulEndAddr);
	
    uprintf("Read DDR memory\n");
    ptrAddr = (volatile unsigned long *)(ptParam->ulStart & 0xFFFFFFFCUL);
    ulEndAddr = (unsigned long)(ptrAddr + 10);
    do {
		  // *ptrAddr = 0x00UL;
      uprintf("Addr: 0x%08x  Value: 0x%08x \n", ((unsigned long)ptrAddr), *ptrAddr );
      ptrAddr++;
	  } while ( (unsigned long)ptrAddr < ulEndAddr);

  }

  /* Set the progress callback. */
	if (ptParam->ulStatusLedMmioNr == 0)
	{
		tTestParams.pfnProgress = ramtest_rdyrun_progress;
		tTestParams.ulProgress = 0;
	}
	else
	{
		tTestParams.pfnProgress = ramtest_mmio_led_progress;
		tTestParams.ulProgress = ptParam->ulStatusLedMmioNr;
	}
	
	uprintf("tag mask: 0x%08x  tag value: 0x%08x \n", tTestParams.ulTagMask, tTestParams.ulTagValue );
	
	/*
	 * Run the RAM test.
	 * With tTestParams.ulLoops=0 this function will only return if an error occurs.
	 */
	tRes = ramtest_run(&tTestParams);

	tTestParams.pfnProgress(&tTestParams, tRes);
	
	/* while(1); */
	
	if (tRes == RAMTEST_RESULT_OK) 
	{
		uprintf("RAM test SUCCESSFUL.\n");
	}
	else
	{
		uprintf("RAM test FAILED.\n");
		while(1);
	}
	return;
}
