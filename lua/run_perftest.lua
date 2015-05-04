require("muhkuh_cli_init")
require("ramtest")



--  <hardware connection="ONBOARD" interface="MEM" netX="500" type="MT48LC2M32B2-7IT">
--    <!--tRas neu: 5clk (alt 4) tRfc neu: 7clk (alt 6) Grund: alte Werte wurden falsch aus dem Datenblatt genommen-->
local atSdramAttributes_500 = {
	netX          = 500,
	general_ctrl  = 0x030d0001,
	timing_ctrl   = 0x03C13251,
	mr            = 0x00000033,
	size_exponent = 23,
	interface     = ramtest.SDRAM_INTERFACE_MEM
}


--  <hardware connection="ONBOARD" interface="MEM" netX="50" type="MT48LC2M32B2-7IT">
--    <!--tRas neu: 5clk (alt 4) tRfc neu: 7clk (alt 6) Grund: alte Werte wurden falsch aus dem Datenblatt genommen, Im Bootwizzard file stand kein typ (-5,-6,-7) jedoch passen die Werte zum -7er -->
local atSdramAttributes_50 = {
	netX          = 50,
	general_ctrl  = 0x030d0001,
	timing_ctrl   = 0x00A13251,
	mr            = 0x00000033,
	size_exponent = 23,
	interface     = ramtest.SDRAM_INTERFACE_MEM
}


--  <hardware connection="ONBOARD" interface="MEM" netX="56" type="MT48LC2M32B2-7IT">
--    <!--HW im Klimaschrank getestet mit alten t-Werten, tRas neu: 5clk (alt 4) tRfc neu: 7clk (alt 6) Grund: alte Werte wurden falsch aus dem Datenblatt genommen-->
local atSdramAttributes_56 = {
	netX          = 56,
	general_ctrl  = 0x030d0001,
	timing_ctrl   = 0x00A13251,
	mr            = 0x00000033,
	size_exponent = 23,
	interface     = ramtest.SDRAM_INTERFACE_MEM
}



local atSdramAttributes = atSdramAttributes_56

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
	+ ramtest.PERFTEST_ROW_JUMP


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end

ramtest.setup_sdram(tPlugin, atSdramAttributes)
ramtest.run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulTestCases, ulLoops)
ramtest.disable_sdram(tPlugin, atSdramAttributes)


-- local ulAreaStart = 0x80000000
-- local ulAreaSize = 0x10000
-- local ulTestCases = ramtest.PERFTEST_ROW_JUMP
-- ramtest.setup_sdram(tPlugin, atSdramAttributes)
-- ramtest.run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulTestCases, ulLoops)
-- ramtest.disable_sdram(tPlugin, atSdramAttributes)

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


