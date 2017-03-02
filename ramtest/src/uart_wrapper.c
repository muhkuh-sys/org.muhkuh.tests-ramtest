/*
 * When both CA9 cores are running the same code and thus there is only one set of serial vectors,
 * both CPUs will attempt to print messages.
 * We use the CPU ID to decide whose CPU's output is printed.
 * 
 * When the wrap_uart_functions is called, the ID of the calling CPU is stored and the
 * put/flush pointers are replaced with the wrappers.
 * The wrapper functions will only pass through the output if the ID of the calling CPU
 * is equal to the stored CPU ID.
 */
 
#include "uart_wrapper.h"
#include "serial_vectors.h"

extern SERIAL_COMM_UI_FN_T tSerialVectors;
SERIAL_COMM_UI_FN_T g_tOrigSerialVectors;
static unsigned int g_uiUartCpuId;


// Get the CPU ID. 0/1 = CA9 core 0/1
unsigned int get_cpuid(void);
unsigned int get_cpuid(void)
{
	unsigned int cpuid;
	__asm__(
		"mrc     p15, 0, %[result], c0, c0, 5 \n\t"
		"ands    %[result], %[result], #0x03 \n\t" 
		: [result] "=r" (cpuid)
		:
		:
		);
	
	return cpuid;
}

static void serial_put_wrapper(unsigned int iChar)
{
	if (g_uiUartCpuId == get_cpuid())
	{
		g_tOrigSerialVectors.fn.fnPut(iChar);
	}
}

static void serial_flush_wrapper(void)
{
	if (g_uiUartCpuId == get_cpuid())
	{
		g_tOrigSerialVectors.fn.fnFlush();
	}
}

void wrap_uart_functions()
{
	g_uiUartCpuId = get_cpuid();
	
	g_tOrigSerialVectors.fn.fnPut   = tSerialVectors.fn.fnPut;
	g_tOrigSerialVectors.fn.fnGet   = tSerialVectors.fn.fnGet;
	g_tOrigSerialVectors.fn.fnPeek  = tSerialVectors.fn.fnPeek;
	g_tOrigSerialVectors.fn.fnFlush = tSerialVectors.fn.fnFlush;
	
	tSerialVectors.fn.fnPut   = serial_put_wrapper;
	tSerialVectors.fn.fnFlush = serial_flush_wrapper;
}
