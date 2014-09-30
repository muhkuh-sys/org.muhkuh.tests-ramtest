require("ramtest")

tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end


local atSdramAttributes = {
	["general_ctrl"]  = 0x030c0011,
	["timing_ctrl"]   = 0x00032251,
	["mr"]            = 0x00000023,

	["size_exponent"] = 23
}

ulSDRAMStart = ramtest.get_sdram_start(ramtest.SDRAM_INTERFACE_HIF)
ulSDRAMSize  = ramtest.get_sdram_size(atSdramAttributes)
ulChecks     = ramtest.CHECK_08BIT + ramtest.CHECK_16BIT + ramtest.CHECK_32BIT + ramtest.CHECK_BURST
--ulChecks     = ramtest.CHECK_32BIT + ramtest.CHECK_BURST
--ulChecks     = ramtest.CHECK_08BIT
ulLoops      = 4

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
