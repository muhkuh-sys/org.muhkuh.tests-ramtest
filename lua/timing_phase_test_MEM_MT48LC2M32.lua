-- 28.07.14 SL try all combinations of sdclk_phase and data_sample_phase
-- 03.03.15 SL adapt to new API taking a netx type and no extra ulTiming value
-- 05.05.15 SL removed extra interface parameter from call

-- NXHX51-ETM Rev.2, netX51 Step A
--                  sample phase
-- clock phase     0  1  2  3  4  5
--         0       0  0  0  0  0  0
--         1       0  0  0  0  0  0
--         2       0  0  0  0  0  1
--         3       0  0  0  0  1  1
--         4       0  0  0  1  1  1
--         5       0  0  1  1  1  1
--

local strLuaBinPath = arg[-1] .. "/.."
local strScriptPath = arg[0] .. "/.."

package.cpath =
	strLuaBinPath .. "/lua_plugins/?.dll;" ..
	strLuaBinPath .. "/../lua_plugins/?.dll;" ..
	package.cpath

package.path =
	strScriptPath .. "/?.lua;" ..
	strScriptPath .. "/lua/?.lua;" ..
	strLuaBinPath .. "/lua/?.lua;" ..
	strLuaBinPath .. "/../lua/?.lua;" ..
	package.path

__MUHKUH_WORKING_FOLDER = strScriptPath .. "/"

require("select_plugin_cli")
require("romloader_usb")
require("romloader_uart")
require("romloader_eth")
require("tester_cli")
require("ramtest")


tPlugin = tester.getCommonPlugin()
if tPlugin==nil then
	error("No plug-in selected, nothing to do!")
end


local atSdramAttributes = {
	["netX"]          = 500,
--	["netX"]          = 56,
--	["netX"]          = 50,
--	["netX"]          = 10,

	["general_ctrl"]  = 0x030d0001,
	["timing_ctrl"]   = 0x00012151,
	["mr"]            = 0x00000033,
	["size_exponent"] = 23
}

ramtest.test_phase_parameters(tPlugin, atSdramAttributes, 2)

-- Disconnect the plug-in.
tPlugin:Disconnect()
