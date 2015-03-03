require("muhkuh_cli_init")
require("ramtest")


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end

local atSdramAttributes = {
	["netX"]          = ${CHIP_TYPE},
	["general_ctrl"]  = ${REGISTER_GENERAL_CTRL},
	["timing_ctrl"]   = ${REGISTER_TIMING_CTRL},
	["mr"]            = ${REGISTER_MODE},
	["size_exponent"] = ${SIZE_EXPONENT},
	["interface"]     = ramtest.SDRAM_INTERFACE_${INTERFACE}
}


ulSDRAMStart = ramtest.get_sdram_start(tPlugin, atSdramAttributes)
ulSDRAMSize  = ramtest.get_sdram_size(tPlugin, atSdramAttributes)

ulChecks     = 0
ulChecks     = ulChecks + ramtest.CHECK_08BIT
ulChecks     = ulChecks + ramtest.CHECK_16BIT
ulChecks     = ulChecks + ramtest.CHECK_32BIT
ulChecks     = ulChecks + ramtest.CHECK_DATABUS
ulChecks     = ulChecks + ramtest.CHECK_MARCHC
ulChecks     = ulChecks + ramtest.CHECK_BURST
ulChecks     = ulChecks + ramtest.CHECK_CHECKERBOARD

ulLoops      = 0x1


ramtest.setup_sdram(tPlugin, atSdramAttributes)
ramtest.test_ram(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
ramtest.disable_sdram(tPlugin, atSdramAttributes)


print("")
print(" #######  ##    ## ")
print("##     ## ##   ##  ")
print("##     ## ##  ##   ")
print("##     ## #####    ")
print("##     ## ##  ##   ")
print("##     ## ##   ##  ")
print(" #######  ##    ## ")
print("")

-- Disconnect the plug-in.
tPlugin:Disconnect()
