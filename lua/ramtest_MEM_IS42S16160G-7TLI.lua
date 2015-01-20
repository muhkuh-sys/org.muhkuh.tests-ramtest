require("muhkuh_cli_init")
require("ramtest")

tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end


local atSdramAttributes = {
	["general_ctrl"]  = 0x030D0121,
	["timing_ctrl"]   = 0x00a13151,
	["mr"]            = 0x33,
	["size_exponent"] = 24
}

ulSDRAMStart = ramtest.get_sdram_start(tPlugin, ramtest.SDRAM_INTERFACE_HIF)
ulSDRAMSize  = ramtest.get_sdram_size(tPlugin, atSdramAttributes)
ulChecks     = ramtest.CHECK_08BIT + ramtest.CHECK_16BIT + ramtest.CHECK_32BIT + ramtest.CHECK_BURST
ulChecks = ulChecks +ramtest.CHECK_DATABUS + ramtest.CHECK_MARCHC + ramtest.CHECK_CHECKERBOARD
--ulChecks     = ramtest.CHECK_08BIT
ulLoops      = 2

ramtest.setup_sdram(tPlugin, ramtest.SDRAM_INTERFACE_HIF, atSdramAttributes)
ramtest.test_ram(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
ramtest.disable_sdram(tPlugin, ramtest.SDRAM_INTERFACE_HIF)


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
