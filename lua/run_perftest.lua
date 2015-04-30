require("muhkuh_cli_init")
require("ramtest")


local atSdramAttributes = {
	netX          = 500,
--	netX          = 56,
--	netX          = 50,
--	netX          = 10,

	general_ctrl  = 0x030d0001,
	timing_ctrl   = 0x00012151,
	mr            = 0x00000033,
	size_exponent = 23,
	interface     = ramtest.SDRAM_INTERFACE_MEM
}

local ulAreaStart = 0x80000000
local ulAreaSize = 0x10000
local ulTestCases =
	ramtest.PERFTEST_SEQ_R8
	+ ramtest.PERFTEST_SEQ_R16
	+ ramtest.PERFTEST_SEQ_R32
	+ ramtest.PERFTEST_SEQ_R256
	+ ramtest.PERFTEST_SEQ_W8
	+ ramtest.PERFTEST_SEQ_W16
	+ ramtest.PERFTEST_SEQ_W32
	+ ramtest.PERFTEST_SEQ_W256
	+ ramtest.PERFTEST_SEQ_RW8
	+ ramtest.PERFTEST_SEQ_RW16
	+ ramtest.PERFTEST_SEQ_RW32
	+ ramtest.PERFTEST_SEQ_RW256
	+ ramtest.PERFTEST_SEQ_NOP
	+ ramtest.PERFTEST_ROW_R8
	+ ramtest.PERFTEST_ROW_R16
	+ ramtest.PERFTEST_ROW_R32
	+ ramtest.PERFTEST_ROW_R256
	+ ramtest.PERFTEST_ROW_W8
	+ ramtest.PERFTEST_ROW_W16
	+ ramtest.PERFTEST_ROW_W32
	+ ramtest.PERFTEST_ROW_W256
	+ ramtest.PERFTEST_ROW_RW8
	+ ramtest.PERFTEST_ROW_RW16
	+ ramtest.PERFTEST_ROW_RW32
	+ ramtest.PERFTEST_ROW_RW256
--	+ ramtest.PERFTEST_ROW_JUMP


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end

ramtest.setup_sdram(tPlugin, atSdramAttributes)
ramtest.run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulTestCases, ulLoops)
ramtest.disable_sdram(tPlugin, atSdramAttributes)


local atSdramAttributes = {
	netX          = 500,
--	netX          = 56,
--	netX          = 50,
--	netX          = 10,

	general_ctrl  = 0x030d0001,
	timing_ctrl   = 0x00012151,
	mr            = 0x00000033,
	size_exponent = 23,
	interface     = ramtest.SDRAM_INTERFACE_MEM
}

local ulAreaStart = 0x80000000
local ulAreaSize = 0x1000
local ulTestCases = ramtest.PERFTEST_ROW_JUMP
ramtest.setup_sdram(tPlugin, atSdramAttributes)
ramtest.run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulTestCases, ulLoops)
ramtest.disable_sdram(tPlugin, atSdramAttributes)

tPlugin:Disconnect()

print("")
print(" #######  ##    ## ")
print("##     ## ##   ##  ")
print("##     ## ##  ##   ")
print("##     ## #####    ")
print("##     ## ##  ##   ")
print("##     ## ##   ##  ")
print(" #######  ##    ## ")
print("")


