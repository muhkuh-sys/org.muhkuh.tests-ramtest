require("muhkuh_cli_init")
require("ramtest")

tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end

-- Preliminary Parameters
-- IS45S16400J-7BLA2-NXHX-SDRSPM_R1
-- <hardware netX="90" type="IS45S16400J-7A2_CAS2" connection="MODULE" interface="HIF">
--   <!--This data set was disabled, but forcibly enabled at build time.-->
--   <JiraIssue>COMPVERIFY-XXX</JiraIssue>
--   <ControlRegister>0x000D0011</ControlRegister>
--   <TimingRegister>0x02303251</TimingRegister>
--   <ModeRegister>0x00000022</ModeRegister>
--   <SizeExponent>23</SizeExponent>
-- </hardware>

local atSdramAttributes = {
	netX          = "NETX90",
	general_ctrl  = 0x000d0011,
	timing_ctrl   = 0x02303251,  -- data sample phase: 2  sdclock_phase: 3
	mr            = 0x22, -- CL2
	size_exponent = 23,
	interface     = ramtest.INTERFACE_SDRAM_HIF
}

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
-- ramtest.netx90_setup_padctrl_default(tPlugin)-- ramtest.netx90_setup_padctrl_hwconfig(tPlugin)ramtest.setup_ram(tPlugin, atSdramAttributes)
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
