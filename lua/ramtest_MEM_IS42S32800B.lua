require("ramtest")

tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plugin selected, nothing to do!")
end


local atSdramAttributes = {
	["general_ctrl"]  = 0x030d0001,
	["timing_ctrl"]   = 0x00033151,
	["mr"]            = 0x00000023,
	["size_exponent"] = 23
}


ulSDRAMStart = ramtest.get_sdram_start(ramtest.SDRAM_INTERFACE_MEM)
ulSDRAMSize  = ramtest.get_sdram_size(atSdramAttributes)
ulChecks     = ramtest.CHECK_08BIT + ramtest.CHECK_16BIT + ramtest.CHECK_32BIT + ramtest.CHECK_BURST
--ulChecks     = ramtest.CHECK_32BIT + ramtest.CHECK_BURST
--ulChecks     = ramtest.CHECK_08BIT
ulLoops      = 4

ramtest.setup_sdram(tPlugin, ramtest.SDRAM_INTERFACE_MEM, atSdramAttributes)
ramtest.test_ram(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
ramtest.disable_sdram(tPlugin, ramtest.SDRAM_INTERFACE_MEM)


print("")
print(" #######  ##    ## ")
print("##     ## ##   ##  ")
print("##     ## ##  ##   ")
print("##     ## #####    ")
print("##     ## ##  ##   ")
print("##     ## ##   ##  ")
print(" #######  ##    ## ")
print("")

-- Disconnect the plugin.
tPlugin:Disconnect()
