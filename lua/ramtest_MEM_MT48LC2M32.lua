require("muhkuh_cli_init")
require("ramtest")


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end

local atSdramAttributes = {
	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX500,
--	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX100,
--	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX56,
--	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX56B,
--	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX50,
--	["netX"]          = romloader.ROMLOADER_CHIPTYP_NETX10,

	["general_ctrl"]  = 0x030d0001,
	["timing_ctrl"]   = 0x03c12151,
	["mr"]            = 0x00000033,
	["size_exponent"] = nil
}


ulSDRAMStart = ramtest.get_sdram_start(tPlugin, ramtest.SDRAM_INTERFACE_MEM)
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

-- Disconnect the plug-in.
tPlugin:Disconnect()
