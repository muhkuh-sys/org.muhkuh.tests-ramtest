#include "standalone_parameter.h"

const RAMTEST_PARAMETER_BLOCK_T s_tRamtestParameterBlock __attribute__ ((section (".standalone_parameter"))) =
{
	.ulMagic = RAMTEST_PARAMETER_BLOCK_MAGIC,
	.ulVersion = RAMTEST_PARAMETER_BLOCK_VERSION
};
