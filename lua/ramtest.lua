-- 28.07.14 SL * added test_phase_parameters to determine working combinations
--               of clock/sample phase
--             * setup_sdram uses atSdramAttributes.ulTiming if present,
--               instead of the value in atPlatformAttributes
--             * test_ram_noerror always returns the status code from netx

module("ramtest", package.seeall)

require("bit")
require("romloader")


	CHECK_DATABUS            = 0x00000001
	CHECK_08BIT  	         = 0x00000002
	CHECK_16BIT  	         = 0x00000004
	CHECK_32BIT  	         = 0x00000008
	CHECK_MARCHC             = 0x00000010
	CHECK_CHECKERBOARD       = 0x00000020
	CHECK_BURST 	         = 0x00000040



SDRAM_INTERFACE_MEM = 1
SDRAM_INTERFACE_HIF = 2


local function setup_sdram_hif_netx56(tPlugin, atSdramAttributes)
	local atAddressLines = {
		[0x00000800] = 0x00000000,
		[0x00001000] = 0x00000100,
		[0x00002000] = 0x00000200,
		[0x00004000] = 0x00000300,
		[0x00008000] = 0x00000400,
		[0x00010000] = 0x00000500,
		[0x00020000] = 0x00000600,
		[0x00040000] = 0x00000700,
		[0x00080000] = 0x00000800,
		[0x00100000] = 0x00000900,
		[0x00200000] = 0x00000a00,
		[0x00400000] = 0x00000b00,
		[0x00800000] = 0x00000c00,
		[0x01000000] = 0x00000d00,
		[0x02000000] = 0x00000e00
	}

	-- Get the configuration value for the number of address lines.
	ulSdramSize = get_sdram_size(atSdramAttributes)
	ulAddressCfg = 0
	for ulSize,ulCfg in pairs(atAddressLines) do
		ulAddressCfg = ulCfg
		if ulSdramSize<=ulSize then
			break
		end
	end
	print(string.format("ulAddressCfg=0x%08x", ulAddressCfg))
	
	-- Get the configuration value for the data bus size.
	ulGeneralCtrl = atSdramAttributes["general_ctrl"]
	if bit.band(ulGeneralCtrl,0x00010000)==0 then
		-- The data bus has a size of 16 bits.
		ulDataCfg = 0x00000050
	else 
		-- The data bus has a size of 32 bits.
		ulDataCfg = 0x00000060
	end
	print(string.format("ulDataCfg=0x%08x", ulDataCfg))
	
	-- Install the binary.
	strBinaryName = "netx/setup_netx56.bin"
	ulParameter = bit.bor(ulAddressCfg, ulDataCfg)
	local ulResult = tester.mbin_simple_run(nil, tPlugin, strBinaryName, ulParameter)
	if ulResult~=0 then
		error(string.format("The setup returned an error code: 0x%08x", ulResult))
	end
end



local function setup_sdram_hif_netx10(tPlugin, atSdramAttributes)
	-- Generate the value for the HIF_IO_CTRL register.
	-- This depends on the data bus width of the SDRAM device.
	ulGeneralCtrl = atSdramAttributes["general_ctrl"]
	if bit.band(ulGeneralCtrl,0x00010000)==0 then
		-- The data bus has a size of 8 bits.
		ulHifIoCtrl = 0x00000040
	else 
		-- The data bus has a size of 16 bits.
		ulHifIoCtrl = 0x00000050
	end

	-- Read and write ASIC_CTRL access key.
	local ulValue = tPlugin:read_data32(0x101c0070)
	tPlugin:write_data32(0x101c0070, ulValue)
	
	tPlugin:write_data32(0x101c0c40, ulHifIoCtrl)
end


local atPlatformAttributes = {
	[romloader.ROMLOADER_CHIPTYP_NETX500] = {
		["ulAsic"] = 500,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
				["ulController"] = 0x00100140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"] = 0x03c00000,
				["setup"] = nil
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX100] = {
		["ulAsic"] = 500,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
				["ulController"] = 0x00100140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"] = 0x03c00000,
				["setup"] = nil
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX56] = {
		["ulAsic"] = 56,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
				["ulController"] = 0x101c0140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"] = 0x00a00000,
				["setup"] = nil
			},
			[SDRAM_INTERFACE_HIF] = {
				["ulController"] = 0x101c0240,
				["ulArea_Start"] = 0x40000000,
				-- ACHTUNG: bei Svens SDR SPI Test war *nur* 0x03a stabil!
				-- Alt: 0x00b00000
				["ulTiming"] = 0x03a00000,
				["setup"] = setup_sdram_hif_netx56
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX56B] = {
		["ulAsic"] = 56,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
				["ulController"] = 0x101c0140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"] = 0x00a00000,
				["setup"] = nil
			},
			[SDRAM_INTERFACE_HIF] = {
				["ulController"] = 0x101c0240,
				["ulArea_Start"] = 0x40000000,
				-- ACHTUNG: bei Svens SDR SPI Test war *nur* 0x03a stabil!
				-- Alt: 0x00b00000
				["ulTiming"] = 0x03a00000,
				["setup"] = setup_sdram_hif_netx56
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX50] = {
		["ulAsic"] = 50,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
				["ulController"] = 0x1c000140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"]     = 0x00a00000,
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX10] = {
		["ulAsic"] = 10,
		["sdram"] = {
			[SDRAM_INTERFACE_MEM] = {
			},
			[SDRAM_INTERFACE_HIF] = {
				["ulController"] = 0x101c0140,
				["ulArea_Start"] = 0x80000000,
				["ulTiming"] = 0x00A00000,
				["setup"] = setup_sdram_hif_netx10
			}
		}
	}
}


local function get_interface_attributes(tPlugin, tInterface)
	-- Get the platform attributes for the chip type.
	local tChipType = tPlugin:GetChiptyp()
	local atPlatform = atPlatformAttributes[tChipType]
	if atPlatform==nil then
		error("Unknown chip type: ", tChipType)
	end
	-- Get the interface attributes.
	local atSdram = atPlatform["sdram"]
	if atSdram==nil then
		error("Chiptype has no sdram attributes: ", tChipType)
	end
	local atInterface = atSdram[tInterface]
	if atInterface==nil then
		error("Chiptype "..tChipType.." has no SDRAM attributes for interface: ", tInterface)
	end

	return atInterface
end

function setup_sdram(tPlugin, tInterface, atSdramAttributes)
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, tInterface)
	
	-- Call the setup function for the platform and interface.
	local pfnSetup = atInterface["setup"]
	if pfnSetup~=nil then
		pfnSetup(tPlugin, atSdramAttributes)
	end
	
	-- Get the base address of the SDRAM controller.
	local ulSDRamController = atInterface["ulController"]
	
	-- Combine the timing control value from the base timing and the SDRAM specific value.
	local ulGeneralCtrl = atSdramAttributes["general_ctrl"]
	local ulTimingCtrl = atSdramAttributes["ulTiming"] or atInterface["ulTiming"]
	local ulTimingCtrl = ulTimingCtrl + atSdramAttributes["timing_ctrl"]
	local ulMr = atSdramAttributes["mr"]
	
	print(string.format("SDRAM general ctrl: 0x%08x", ulGeneralCtrl))
	print(string.format("SDRAM timing ctrl:  0x%08x", ulTimingCtrl))
	print(string.format("SDRAM mr:           0x%08x", ulMr))
	
	-- Disable the SDRam controller.
	tPlugin:write_data32(ulSDRamController+0, 0)
	
	-- Setup the SDRam controller.
	tPlugin:write_data32(ulSDRamController+8, ulMr)
	tPlugin:write_data32(ulSDRamController+4, ulTimingCtrl)
	tPlugin:write_data32(ulSDRamController+0, ulGeneralCtrl)
end



function disable_sdram(tPlugin, tInterface)
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, tInterface)
	
	-- Get the base address of the SDRAM controller.
	local ulSDRamController = atInterface["ulController"]
	
	-- Disable the SDRam controller.
	tPlugin:write_data32(ulSDRamController+0, 0)
	tPlugin:write_data32(ulSDRamController+4, 0)
	tPlugin:write_data32(ulSDRamController+8, 0)
end



function get_sdram_size(atSdramAttributes)
	return math.pow(2, atSdramAttributes["size_exponent"])
end



function get_sdram_start(tPlugin, tInterface)
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, tInterface)

	return atInterface["ulArea_Start"]
end



function test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	-- Get the platform attributes for the chip type.
	local tChipType = tPlugin:GetChiptyp()
	local atPlatformAttributes = atPlatformAttributes[tChipType]
	if atPlatformAttributes==nil then
		error("Unknown chip type: ", tChipType)
	end
	
	-- Get the binary.
	local strBinaryName = string.format("netx/ramtest_netx%d.bin", atPlatformAttributes["ulAsic"])
	
	-- Construct the parameter.
	local aulParameter = {
		ulAreaStart,
		ulAreaSize,
		ulChecks,
		ulLoops,
	}

	-- Install the binary.
	local ulResult = tester.mbin_simple_run(nil, tPlugin, strBinaryName, aulParameter)
	return ulResult
end



function test_ram(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	local ulResult = test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	if ulResult~=0 then
		error(string.format("The RAM test returned an error code: 0x%08x", ulResult))
	end
end



-- test all combinations of SDCLK phase and data sample phase.
-- iInterface = ramtest.SDRAM_INTERFACE_MEM/HIF
function test_phase_parameters(tPlugin, atSdramAttributes, iInterface, ulMaxLoops)

	-- init/print results
	local aiTestResults = {}

	for iClockPhase = 0, 5 do
		aiTestResults[iClockPhase] = {}
	end

	local function printf(...) print(string.format(...)) end

	local function printResults()
		print("    Sample phase: 0  1  2  3  4  5")
		for iClockPhase = 0, 5 do
			local strLine = string.format("Clock phase: %d  ", iClockPhase)
			for iSamplePhase = 0, 5 do
				local ulResult = aiTestResults[iClockPhase][iSamplePhase]
				local strResult
				if ulResult then
					strResult = string.format("%3d", ulResult)
				else
					strResult = "  -"
				end
				strLine = strLine .. strResult
			end
			print(strLine)
		end
	end


	ulSDRAMStart = get_sdram_start(tPlugin, iInterface)
	ulSDRAMSize  = get_sdram_size(atSdramAttributes)
	ulChecks     = CHECK_08BIT + CHECK_16BIT + CHECK_32BIT + CHECK_BURST + CHECK_DATABUS + CHECK_CHECKERBOARD + CHECK_MARCHC
	ulLoops      = 1

	while ulLoops <= ulMaxLoops do
		for iClockPhase = 0, 5 do
			for iSamplePhase = 0, 5 do
				local ulPreviousResult = aiTestResults[iClockPhase][iSamplePhase]
				if ulPreviousResult ~= nil and ulPreviousResult ~= 0 then
					printf("Clock phase: %d   Sample phase: %d   Previous result: 0x%08x -- Skipping", iClockPhase, iSamplePhase, ulPreviousResult)

				else
					-- Timing Control:
					-- 22:20 MEM_SDCLK_PHASE 0-5
					-- 23    MEM_SDCLK_SSNEG 1
					-- 26:24 DATA_SAMPLE_PHASE 0-5

					local ulTiming =
						iClockPhase * 0x100000
						+ 0x800000
						+ iSamplePhase * 0x1000000
					atSdramAttributes.ulTiming = ulTiming

					printf("Clock phase: %d   Sample phase: %d   ulTiming: 0x%08x", iClockPhase, iSamplePhase, ulTiming)

					setup_sdram(tPlugin, iInterface, atSdramAttributes)
					ulResult = test_ram_noerror(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
					disable_sdram(tPlugin, iInterface)

					printf("Clock phase: %d   Sample phase: %d   Result: 0x%08x", iClockPhase, iSamplePhase, ulResult)
					aiTestResults[iClockPhase][iSamplePhase] = ulResult
					printResults()
				end
			end
		end
		ulLoops = ulLoops * 2
	end

	return aiTestResults
end


