
require("muhkuh_cli_init")
-- Preliminary Parameters
-- IS45S16400J-7BLA2-NXHX-SDRSPM_R1
--   <!--This data set was disabled, but forcibly enabled at build time.-->
--   <JiraIssue>COMPVERIFY-XXX</JiraIssue>
--   <ControlRegister>0x000D0011</ControlRegister>
--   <TimingRegister>0x02303251</TimingRegister>
--   <ModeRegister>0x00000022</ModeRegister>
--   <SizeExponent>23</SizeExponent>
-- </hardware>

local atSdramAttributes = {

ramtest.netx90_setup_padctrl_default(tPlugin)
tPhaseTestResults_Default = ramtest.test_phase_parameters(tPlugin, atSdramAttributes, 2)

ramtest.netx90_setup_padctrl_hwconfig(tPlugin)
tPhaseTestResults_HWConfig = ramtest.test_phase_parameters(tPlugin, atSdramAttributes, 2)

print()
print("Test results with default pad control settings")
ramtest.printPhaseTestResults(tPhaseTestResults_Default)

print()
print("Test results with hwconfig pad control settings")
ramtest.printPhaseTestResults(tPhaseTestResults_HWConfig)
print()

-- Disconnect the plug-in.