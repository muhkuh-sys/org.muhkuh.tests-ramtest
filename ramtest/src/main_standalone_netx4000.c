#include <string.h>
#include "ramtest.h"
#include "systime.h"
#include "uprintf.h"
#include "version.h"
#include "main_standalone_common.h"
#include "ramtest_ecc.h"
#include "uart_standalone.h"
#include "uart_wrapper.h"
#include "netx_io_areas.h"
#include "rdy_run.h"

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

void set_mmio_leds(unsigned long ulMMIOLed, int iLedStates);
void set_mmio_leds(unsigned long ulMMIOLed, int iLedStates)
{
	unsigned long ulProgressLedMmioNr  = (ulMMIOLed >> 16) & 0xff;
	unsigned long ulErrorLedMmioNr = (ulMMIOLed >> 24) & 0xff;
	
	HOSTDEF(ptMmioCtrlArea);
	unsigned long ulProgressLedState;
	unsigned long ulErrorLedState;
	
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
		/* default to error? */
		default:
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


void alternate_leds(unsigned long ulLedMMIOs);
void alternate_leds(unsigned long ulLedMMIOs)
{
	int i;
	if (ulLedMMIOs == 0)
	{
		for (i=1; i<=16; i++) 
		{
			rdy_run_setLEDs(RDYRUN_GREEN);
			systime_wait_ms(200);
			rdy_run_setLEDs(RDYRUN_YELLOW);
			systime_wait_ms(200);
		}
		rdy_run_setLEDs(RDYRUN_OFF);
	}
	else
	{
		for (i=1; i<=16; i++) 
		{
			set_mmio_leds(ulLedMMIOs, LED_GREEN);
			systime_wait_ms(200);
			set_mmio_leds(ulLedMMIOs, LED_YELLOW);
			systime_wait_ms(200);
		}
		set_mmio_leds(ulLedMMIOs, LED_OFF);
	}
}


void ramtest_progress_loop_finished(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter);
void ramtest_progress_loop_finished(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter)
{
	unsigned long ulLedMmioNr = ptRamTestParameter->ulProgress & 0xffff0000UL;
	alternate_leds(ulLedMmioNr);
}

void ramtest_mmio_led_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult);
void ramtest_mmio_led_progress(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult)
{

	unsigned long ulProgress  = ptRamTestParameter->ulProgress & 1;
	unsigned long ulLedMmioNr = ptRamTestParameter->ulProgress & 0xffff0000UL;
	int iLedStates;
	
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
	
	set_mmio_leds(ulLedMmioNr, iLedStates);
}


/* ulUseUart
    0: clear serial vectors
    1: init serial vectors, wait 1 ms
    2: do not change serial vectors, wait 1 ms
 */
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

/*
    Changes in DDR_CTRL registers between netx 4000 Relaxed and Full:
    Reg. 9, 10, 58, 125: equal
    Reg. 152: Bit 0 is ECC_EN, other bits changed.
*/
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
//	HOSTDEF(ptDdrCtrlArea);
//	unsigned long fDdrCtrlReduc;
	
	/* It is OK to call systime_init from multiple CPUs, because it writes constants to the border and count regs. */
	systime_init();

	if (ptParam->ulUseUart == 0)
	{
		ramtest_clear_serial_vectors();
	}
	else if (ptParam->ulUseUart == 1)
	{
		uart_standalone_initialize();
		#ifdef WRAP_UART
		wrap_uart_functions();
		#endif
		systime_wait_ms(1);
	}
	else if (ptParam->ulUseUart == 2)
	{
		systime_wait_ms(1);
		/* do nothing */
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
	
	
	if ((ptParam->ulStart >= 0x40000000UL) && (ptParam->ulStart <= 0xbfffffff))
	{
		print_ddr_config();
    
//		/* If the DDR ctrl is configured for 16 bit, divide the start offsets and sizes by two. */
//		fDdrCtrlReduc = (ptDdrCtrlArea->aulDDR_CTRL_CTL[58] & MSK_NX4000_DDR_CTRL_CTL58_REDUC) >> SRT_NX4000_DDR_CTRL_CTL58_REDUC;
//		if (fDdrCtrlReduc) 
//		{
//			uprintf("Adjusting area start/size for 16 bit DDR mode.\n");
//			tTestParams.ulStart -= (tTestParams.ulStart - 0x40000000)/2;
//			tTestParams.ulSize /= 2;
//		}
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
	
	/* flash LEDs when a loop has finished */
	tTestParams.pfnLoopFinished = ramtest_progress_loop_finished;
	
	/*
	 * Run the RAM test.
	 * With tTestParams.ulLoops=0 this function will only return if an error occurs.
	 */
	tRes = ramtest_run(&tTestParams);

#ifdef ECC
	ramtest_ecc_show();
#endif

	tTestParams.pfnProgress(&tTestParams, tRes);
	
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
