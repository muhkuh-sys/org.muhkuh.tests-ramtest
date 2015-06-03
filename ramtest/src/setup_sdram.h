#ifndef __SETUP_SDRAM_H__
#define __SETUP_SDRAM_H__

int sdram_setup(unsigned long ulSdramStart, 
	unsigned long ulSdramGeneralCtrl,
	unsigned long ulSdramTimingCtrl,
	unsigned long ulSdramMr);

void sdram_show_config(void);

unsigned long sdram_get_size(unsigned long ulSdramGeneralCtrl);

#endif /*__SETUP_SDRAM_H__*/
