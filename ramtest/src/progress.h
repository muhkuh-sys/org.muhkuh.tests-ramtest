#include "asic_types.h"
#include "ramtest.h"

#ifndef __PROGRESS_H__
#define __PROGRESS_H__


void progress_rdyrun(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult);

#if ASIC_TYP==ASIC_TYP_NETX56
void progress_mmio(struct RAMTEST_PARAMETER_STRUCT *ptRamTestParameter, RAMTEST_RESULT_T tResult);
#endif

#endif  /* __PROGRESS_H__ */
