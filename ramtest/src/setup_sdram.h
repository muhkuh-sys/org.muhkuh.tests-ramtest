#include "asic_types.h"


#ifndef __SETUP_SDRAM_H__
#define __SETUP_SDRAM_H__


#if ASIC_TYP==ASIC_TYP_NETX4000_RELAXED || ASIC_TYP==ASIC_TYP_NETX500 || ASIC_TYP==ASIC_TYP_NETX90_MPW
typedef HOSTADEF(EXT_SDRAM_CTRL) SDRAM_CTRL_T;
#else
typedef HOSTADEF(SDRAM) SDRAM_CTRL_T;
#endif


unsigned long sdram_get_size(unsigned long ulSdramGeneralCtrl);
SDRAM_CTRL_T *get_sdram_controller(unsigned long ulTestAreaStart);
int sdram_setup(unsigned long ulSdramStart, unsigned long ulSdramGeneralCtrl, unsigned long ulSdramTimingCtrl, unsigned long ulSdramMr);


#endif /*__SETUP_SDRAM_H__*/
