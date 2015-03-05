local atSdramAttributes = {
	netX          = ${CHIP_TYPE},
	general_ctrl  = ${REGISTER_GENERAL_CTRL},
	timing_ctrl   = ${REGISTER_TIMING_CTRL},
	mr            = ${REGISTER_MODE},
	size_exponent = ${SIZE_EXPONENT},
	interface     = ramtest.SDRAM_INTERFACE_${INTERFACE}
}
