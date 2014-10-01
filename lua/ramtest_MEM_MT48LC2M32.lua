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

-- SDRAM spezifische ATTRIBUTE -- 
local atSdramAttributes = {
	["general_ctrl"]  = 0x030d0001, -- Inhalt des general_ctrl registers 
	["timing_ctrl"]   = 0x00012151, -- teil des inhalts des timing-ctrl registers  
	["mr"]            = 0x00000033, -- mode register 
	["size_exponent"] = 23 -- 8 MB
-- NOTE: Some boards with netX51/52 Step A are limited to 2MB.
--	["size_exponent"] = 21 -- 2 MB
}


ulSDRAMStart = ramtest.get_sdram_start(tPlugin, ramtest.SDRAM_INTERFACE_MEM)
--get the SDRAM_INTERFACE_MEM (contains start adress, ulControl, timing)

ulSDRAMSize  = ramtest.get_sdram_size(atSdramAttributes) -- returns 2 ^^ size_exponent = 2^21 in diesem fall (2M)
-- was soll getestet werden ?
-- ulSDRAMSize ist nicht die tatsächliche von einer hardware gelieferte größe, sondern eine gespeicherte

ulChecks         = ramtest.CHECK_08BIT + ramtest.CHECK_16BIT + ramtest.CHECK_32BIT + ramtest.CHECK_DATABUS
ulChecks         =  ulChecks +  ramtest.CHECK_MARCHC + ramtest.CHECK_BURST + ramtest.CHECK_CHECKERBOARD


ulLoops      = 0x1


-- Setup the SDRAM we are working with
-- give parameters  Interface Mem:
								     --Start Adress, Control Register, and Timing parameters 
-- give parameters atSdramAttributes:--General Control, Timing Control, mr, size exponent 
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
