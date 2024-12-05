#include <stdint.h>


#ifndef __STANDALONE_PARAMETER_H__
#define __STANDALONE_PARAMETER_H__


#define RAMTEST_PARAMETER_BLOCK_MAGIC 0x41504152
#define RAMTEST_PARAMETER_BLOCK_VERSION 0x00010001


typedef struct RAMTEST_PARAMETER_BLOCK_STRUCT
{
	uint32_t ulMagic;
	uint32_t ulVersion;
	uint32_t ulStartAddress;
	uint32_t ulSize;
	uint32_t ulSDRAMGeneralCtrl;
	uint32_t ulSDRAMTimingCtrl;
	uint32_t ulSDRAMModeRegister;
	uint32_t ulUartParameter;
	uint32_t ulProgressParameter;
} RAMTEST_PARAMETER_BLOCK_T;

extern const RAMTEST_PARAMETER_BLOCK_T s_tRamtestParameterBlock;

#endif  /* __STANDALONE_PARAMETER_H__ */
