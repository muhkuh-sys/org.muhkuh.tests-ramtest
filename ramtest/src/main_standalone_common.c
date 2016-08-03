#include <string.h>
#include "main_standalone_common.h"
#include "rdy_run.h"
#include "netx_io_areas.h"
#include "serial_vectors.h"
#include "uart.h"


#if ASIC_TYP==10
/* NXHX10-ETM */
static const UART_CONFIGURATION_T tUartCfg =
{
        .uc_rx_mmio = 20U,
        .uc_tx_mmio = 21U,
        .uc_rts_mmio = 0xffU,
        .uc_cts_mmio = 0xffU,
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
};
#elif ASIC_TYP==56
/* NXHX51-ETM */
static const UART_CONFIGURATION_T tUartCfg_netx51 =
{
        .uc_rx_mmio = 34U,
        .uc_tx_mmio = 35U,
        .uc_rts_mmio = 0xffU,
        .uc_cts_mmio = 0xffU,
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
};
/* NXHX51-ETM */
static const UART_CONFIGURATION_T tUartCfg_netx52 =
{
        .uc_rx_mmio = 20U,
        .uc_tx_mmio = 21U,
        .uc_rts_mmio = 0xffU,
        .uc_cts_mmio = 0xffU,
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
};
#elif ASIC_TYP==50
/* NXHX50-ETM */
static const UART_CONFIGURATION_T tUartCfg =
{
        .uc_rx_mmio = 34U,
        .uc_tx_mmio = 35U,
        .uc_rts_mmio = 0xffU,
        .uc_cts_mmio = 0xffU,
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
};
#elif ASIC_TYP==100 || ASIC_TYP==500
static const UART_CONFIGURATION_T tUartCfg =
{
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
};
#elif ASIC_TYP==4000
static const UART_CONFIGURATION_T tUartCfg =
{
        .uc_rx_mmio = 26U,
        .uc_tx_mmio = 27U,
        .uc_rts_mmio = 0xffU,
        .uc_cts_mmio = 0xffU,
        .us_baud_div = UART_BAUDRATE_DIV(UART_BAUDRATE_115200)
}; 
#endif

#define IO_UART_UNIT 0

static unsigned char io_uart_get(void)
{
	return (unsigned char)uart_get(IO_UART_UNIT);
}


static void io_uart_put(unsigned int uiChar)
{
	uart_put(IO_UART_UNIT, (unsigned char)uiChar);
}


static unsigned int io_uart_peek(void)
{
	return uart_peek(IO_UART_UNIT);
}


static void io_uart_flush(void)
{
	uart_flush(IO_UART_UNIT);
}


static const SERIAL_COMM_UI_FN_T tSerialVectors_Uart =
{
	.fn =
	{
		.fnGet = io_uart_get,
		.fnPut = io_uart_put,
		.fnPeek = io_uart_peek,
		.fnFlush = io_uart_flush
	}
};

SERIAL_COMM_UI_FN_T tSerialVectors;


void ramtest_init_uart(void)
{
	/* Set the serial vectors. */
	memcpy(&tSerialVectors, &tSerialVectors_Uart, sizeof(SERIAL_COMM_UI_FN_T));

	uart_init(IO_UART_UNIT, &tUartCfg);
}

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

