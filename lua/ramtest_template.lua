require("muhkuh_cli_init")
require("ramtest")


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end


${SDRAM_ATTRIBUTES}


ulSDRAMStart = ramtest.get_ram_start(tPlugin, atSdramAttributes)
ulSDRAMSize  = ramtest.get_ram_size(tPlugin, atSdramAttributes)

ulChecks     = 0
ulChecks     = ulChecks + ramtest.CHECK_08BIT
ulChecks     = ulChecks + ramtest.CHECK_16BIT
ulChecks     = ulChecks + ramtest.CHECK_32BIT
ulChecks     = ulChecks + ramtest.CHECK_DATABUS
ulChecks     = ulChecks + ramtest.CHECK_MARCHC
ulChecks     = ulChecks + ramtest.CHECK_BURST
ulChecks     = ulChecks + ramtest.CHECK_CHECKERBOARD
ulChecks     = ulChecks + ramtest.CHECK_SEQUENCE
ulChecks     = ulChecks + ramtest.CHECK_MEMCPY

ulLoops      = 0x1


ramtest.setup_ram(tPlugin, atSdramAttributes)
ramtest.test_ram(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
ramtest.disable_ram(tPlugin, atSdramAttributes)


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
