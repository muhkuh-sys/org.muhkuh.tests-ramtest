-- 28.07.14 SL * added test_phase_parameters to determine working combinations
--               of clock/sample phase
--             * setup_sdram uses atSdramAttributes.ulTiming if present,
--               instead of the value in atPlatformAttributes
--             * test_ram_noerror always returns the status code from netx
-- 27.01.15 SL * prettified output of phaseshift test
-- 28.01.15 SL * fixed call to get_sdram_size in test_phase_parameters
-- 03.03.15 SL * adapted calculation of timing_ctrl to changes in setup_sdram
-- 05.03.15 SL * test_phase_parameters: adapted to changed function interfaces
--               ["x"] rewritten as .x
-- 29.04.15 SL * added performance test

module("ramtest", package.seeall)

require("bit")
require("romloader")

-- Flags for functional tests
CHECK_DATABUS            = 0x00000001
CHECK_08BIT              = 0x00000002
CHECK_16BIT              = 0x00000004
CHECK_32BIT              = 0x00000008
CHECK_MARCHC             = 0x00000010
CHECK_CHECKERBOARD       = 0x00000020
CHECK_BURST              = 0x00000040

-- Flags for performance tests
PERFTEST_SEQ_R8          = 0x00000001
PERFTEST_SEQ_R16         = 0x00000002
PERFTEST_SEQ_R32         = 0x00000004
PERFTEST_SEQ_R256        = 0x00000008
PERFTEST_SEQ_W8          = 0x00000010
PERFTEST_SEQ_W16         = 0x00000020
PERFTEST_SEQ_W32         = 0x00000040
PERFTEST_SEQ_W256        = 0x00000080
PERFTEST_SEQ_RW8         = 0x00000100
PERFTEST_SEQ_RW16        = 0x00000200
PERFTEST_SEQ_RW32        = 0x00000400
PERFTEST_SEQ_RW256       = 0x00000800
PERFTEST_SEQ_NOP         = 0x00001000

PERFTEST_ROW_R8          = 0x00010000
PERFTEST_ROW_R16         = 0x00020000
PERFTEST_ROW_R32         = 0x00040000
PERFTEST_ROW_R256        = 0x00080000
PERFTEST_ROW_W8          = 0x00100000
PERFTEST_ROW_W16         = 0x00200000
PERFTEST_ROW_W32         = 0x00400000
PERFTEST_ROW_W256        = 0x00800000
PERFTEST_ROW_RW8         = 0x01000000
PERFTEST_ROW_RW16        = 0x02000000
PERFTEST_ROW_RW32        = 0x04000000
PERFTEST_ROW_RW256       = 0x08000000
PERFTEST_ROW_JUMP        = 0x10000000


SDRAM_INTERFACE_MEM = 1
SDRAM_INTERFACE_HIF = 2

local function printf(...) print(string.format(...)) end

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
	ulGeneralCtrl = atSdramAttributes.general_ctrl
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
	ulGeneralCtrl = atSdramAttributes.general_ctrl
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
		ulAsic = 500,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
				ulController = 0x00100140,
				ulArea_Start = 0x80000000,
				setup = nil
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX100] = {
		ulAsic = 500,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
				ulController = 0x00100140,
				ulArea_Start = 0x80000000,
				setup = nil
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX56] = {
		ulAsic = 56,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
				ulController = 0x101c0140,
				ulArea_Start = 0x80000000,
				setup = nil
			},
			[SDRAM_INTERFACE_HIF] = {
				ulController = 0x101c0240,
				ulArea_Start = 0x40000000,
				setup = setup_sdram_hif_netx56
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX56B] = {
		ulAsic = 56,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
				ulController = 0x101c0140,
				ulArea_Start = 0x80000000,
				setup = nil
			},
			[SDRAM_INTERFACE_HIF] = {
				ulController = 0x101c0240,
				ulArea_Start = 0x40000000,
				setup = setup_sdram_hif_netx56
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX50] = {
		ulAsic = 50,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
				ulController = 0x1c000140,
				ulArea_Start = 0x80000000,
				setup = nil
			},
			[SDRAM_INTERFACE_HIF] = {
			}
		}
	},

	[romloader.ROMLOADER_CHIPTYP_NETX10] = {
		ulAsic = 10,
		sdram = {
			[SDRAM_INTERFACE_MEM] = {
			},
			[SDRAM_INTERFACE_HIF] = {
				ulController = 0x101c0140,
				ulArea_Start = 0x80000000,
				setup = setup_sdram_hif_netx10
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
	local atSdram = atPlatform.sdram
	if atSdram==nil then
		error("Chiptype has no sdram attributes: ", tChipType)
	end
	local atInterface = atSdram[tInterface]
	if atInterface==nil then
		error("Chiptype "..tChipType.." has no SDRAM attributes for interface: ", tInterface)
	end
	
	return atInterface
end



local function compare_netx_version(tPlugin, atSdramAttributes)
	local atChipTypes = {
		[500] = {
			romloader.ROMLOADER_CHIPTYP_NETX500,
			romloader.ROMLOADER_CHIPTYP_NETX100
		},
		[56] = {
			romloader.ROMLOADER_CHIPTYP_NETX56,
			romloader.ROMLOADER_CHIPTYP_NETX56B
		},
		[50] = {
			romloader.ROMLOADER_CHIPTYP_NETX50
		},
		[10] = {
			romloader.ROMLOADER_CHIPTYP_NETX10
		}
	}
	
	-- Get the connected chip type.
	local tChipType = tPlugin:GetChiptyp()
	
	local atChipTypesStr = {}
	for uiNetxTyp,atTypes in pairs(atChipTypes) do
		local strChipTypes = ""
		sizChipTypes = #atTypes
		for uiCnt,tTyp in ipairs(atTypes) do
			strChipTypes = strChipTypes .. tPlugin:GetChiptypName(tTyp)
			-- Is more than one element left?
			if uiCnt+1<sizChipTypes then
				-- Yes, more than one left. Use a comma as a separator.
				strChipTypes = strChipTypes .. ", "
			-- Is exactly one element left?
			elseif uiCnt+1==sizChipTypes then
				-- Yes, connect it with "and".
				strChipTypes = strChipTypes .. " and "
			end
		end
		atChipTypesStr[uiNetxTyp] = strChipTypes
	end
	
	
	local strHelp = "Possible values are:\n"
	for uiNetxTyp,strTypes in pairs(atChipTypesStr) do
		strHelp = strHelp .. string.format("  %3d: %s\n", uiNetxTyp, strTypes)
	end
	
	-- Get the required chip type for the parameter.
	local tRequiredChipType = atSdramAttributes.netX
	if tRequiredChipType==nil then
		local strError = "The SDRAM parameter have no 'netX' entry. It specifies the chip type for the parameter set.\n"
		strError = strError .. strHelp
		error(strError)
	end
	
	local atTypes = atChipTypes[tRequiredChipType]
	if atTypes==nil then
		local strError = string.format("The SDRAM parameter have an invalid netX value: %s", tRequiredChipType)
		strError = strError .. strHelp
		error(strError)
	end
	
	local fChipTypeMatches = false
	for uiCnt,tTyp in ipairs(atTypes) do
		if tTyp==tChipType then
			fChipTypeMatches = true
			break
		end
	end
	
	if fChipTypeMatches~=true then
		local strError =      "The connected chip type does not match the one specified in the SDRAM parameters.\n"
		strError = strError .. "In other words: the parameters do not work with the connected netX.\n"
		strError = strError .. "Connected netX:     " .. tPlugin:GetChiptypName(tChipType) .. "\n"
		strError = strError .. "Parameters are for: " .. atChipTypesStr[tRequiredChipType] .. "\n"
		error(strError)
	end
end



function setup_sdram(tPlugin, atSdramAttributes)
	-- Compare the chip type.
	compare_netx_version(tPlugin, atSdramAttributes)
	
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, atSdramAttributes.interface)
	
	-- Call the setup function for the platform and interface.
	local pfnSetup = atInterface.setup
	if pfnSetup~=nil then
		pfnSetup(tPlugin, atSdramAttributes)
	end
	
	-- Get the base address of the SDRAM controller.
	local ulSDRamController = atInterface.ulController
	
	-- Combine the timing control value from the base timing and the SDRAM specific value.
	local ulGeneralCtrl = atSdramAttributes.general_ctrl
	local ulTimingCtrl  = atSdramAttributes.timing_ctrl
	local ulMr = atSdramAttributes.mr
	
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



function disable_sdram(tPlugin, atSdramAttributes)
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, atSdramAttributes.interface)
	
	-- Get the base address of the SDRAM controller.
	local ulSDRamController = atInterface.ulController
	
	-- Disable the SDRam controller.
	tPlugin:write_data32(ulSDRamController+0, 0)
	tPlugin:write_data32(ulSDRamController+4, 0)
	tPlugin:write_data32(ulSDRamController+8, 0)
end


function get_sdram_geometry(tPlugin, atSdramAttributes)
	local ulGeneralCtrl = atSdramAttributes.general_ctrl
	-- Extract the geometry parameters.
	local ulBanks    = bit.lshift(2,               bit.band(ulGeneralCtrl, 0x00000003))
	local ulRows     = bit.lshift(2048, bit.rshift(bit.band(ulGeneralCtrl, 0x00000070), 4))
	local ulColumns  = bit.lshift(256,  bit.rshift(bit.band(ulGeneralCtrl, 0x00000700), 8))
	local ulBusWidth = bit.lshift(1,    bit.rshift(bit.band(ulGeneralCtrl, 0x00010000), 16))
	
	local tAsicTyp = tPlugin:GetChiptyp()
	if tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX100 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX500 
	or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX50
	or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56B then
		ulBusWidth = ulBusWidth * 2
	elseif tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX10 then
		ulBusWidth = ulBusWidth
	else
		error("Unknown chiptyp!")
	end
	
	local ulRowSize = ulColumns * ulBusWidth
	local ulSize    = ulRowSize * ulRows * ulBanks
	
	print()
	print("Geometry:")
	printf("Banks    : %d",       ulBanks    )
	printf("Rows     : %d",       ulRows     )
	printf("Columns  : %d bytes", ulColumns  )
	printf("BusWidth : %d bytes", ulBusWidth )
	printf("RowSize  : %d bytes", ulRowSize  )
	printf("Size     : %d bytes", ulSize     )
	print()

	-- bus width, row size and size are in bytes
	local tGeom = {
		ulBanks    = ulBanks    ,    
		ulRows     = ulRows     ,    
		ulColumns  = ulColumns  ,    
		ulBusWidth = ulBusWidth ,    
		ulRowSize  = ulRowSize, 
		ulSize     = ulSize
	}
	
	return tGeom
end


function get_sdram_size(tPlugin, atSdramAttributes)
	local ulSize = nil
	
	-- Is a size specified in the attributes?
	if atSdramAttributes.size_exponent==nil then
		-- No -> get the size from the geometry parameters.
		local ulGeneralCtrl = atSdramAttributes.general_ctrl
		-- Extract the geometry parameters.
		local ulBanks    =            bit.band(ulGeneralCtrl, 0x00000003)
		local ulRows     = bit.rshift(bit.band(ulGeneralCtrl, 0x00000030), 4)
		local ulColumns  = bit.rshift(bit.band(ulGeneralCtrl, 0x00000700), 8)
		local ulBusWidth = nil
		
		local tAsicTyp = tPlugin:GetChiptyp()
		if tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX100 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX500 then
			ulBusWidth = 2
			if bit.band(ulGeneralCtrl, 0x00010000)~=0 then
				ulBusWidth = 4
			end
		elseif tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX50 then
			ulBusWidth = 2
			if bit.band(ulGeneralCtrl, 0x00010000)~=0 then
				ulBusWidth = 4
			end
		elseif tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX10 then
			ulBusWidth = 1
			if bit.band(ulGeneralCtrl, 0x00010000)~=0 then
				ulBusWidth = 2
			end
		elseif tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56B then
			ulBusWidth = 2
			if bit.band(ulGeneralCtrl, 0x00010000)~=0 then
				ulBusWidth = 4
			end
		else
			error("Unknown chiptyp!")
		end
		
		-- Combine the geometry parameters to the size in bytes.
		ulSize = bit.lshift(2, ulBanks) * bit.lshift(256, ulColumns) * bit.lshift(2048, ulRows) * ulBusWidth
	else
		-- Yes -> ignore the geometry parameters.
		ulSize = math.pow(2, atSdramAttributes.size_exponent)
	end
	
	return ulSize
end



function get_sdram_start(tPlugin, atSdramAttributes)
	-- Get the interface attributes.
	local atInterface = get_interface_attributes(tPlugin, atSdramAttributes.interface)

	return atInterface.ulArea_Start
end


-- run the ram test
function test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	-- Get the platform attributes for the chip type.
	local tChipType = tPlugin:GetChiptyp()
	local atPlatformAttributes = atPlatformAttributes[tChipType]
	if atPlatformAttributes==nil then
		error("Unknown chip type: ", tChipType)
	end
	
	-- Get the binary.
	local strBinaryName = string.format("netx/ramtest_netx%d.bin", atPlatformAttributes.ulAsic)
	
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


-- wrapper: run ram test and abort on error
function test_ram(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	local ulResult = test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
	if ulResult~=0 then
		error(string.format("The RAM test returned an error code: 0x%08x", ulResult))
	end
end





-- Detect the working values of SDCLK phase and data sample phase
-- by running the SDRAM test for all valid combinations.
--
-- Initially, the SDRAM test is run once for all combinations.
-- In further rounds, the SDRAM test is re-run for all combinations 
-- which passed the previous tests. 
-- The number of runs of the SDRAM test is doubled in each round until
-- it exceeds ulMaxLoops.

function test_phase_parameters(tPlugin, atSdramAttributes, ulMaxLoops)
	-- Compare the chip type.
	compare_netx_version(tPlugin, atSdramAttributes)
	
	-- define test parameters
	local timing_ctrl_base = bit.band(atSdramAttributes.timing_ctrl, 0x000fffff)
	local ulSDRAMStart     = get_sdram_start(tPlugin, atSdramAttributes)
	local ulSDRAMSize      = get_sdram_size(tPlugin, atSdramAttributes)
	local ulChecks         = CHECK_08BIT + CHECK_16BIT + CHECK_32BIT + CHECK_BURST + CHECK_DATABUS + CHECK_CHECKERBOARD + CHECK_MARCHC
	
	-- init the result matrix, define print function
	local aiTestResults = {}

	for iClockPhase = 0, 5 do
		aiTestResults[iClockPhase] = {}
	end

	local function printf(...) print(string.format(...)) end

	local function printResults()
		print(" ")
		print("---------------+------------------")
		print("  Sample phase:|  0  1  2  3  4  5")
		print("---------------+------------------")
		for iClockPhase = 0, 5 do
			local strLine = string.format("Clock phase: %d |", iClockPhase)
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
		print("---------------+------------------")
		print("0 = Ok   1 = failed   - = not tested")
		print(" ")
	end
	
	-- run the test
	local ulLoops          = 1

	while ulLoops <= ulMaxLoops do
		for iClockPhase = 0, 5 do
			for iSamplePhase = 0, 5 do
				local ulPreviousResult = aiTestResults[iClockPhase][iSamplePhase]
				if ulPreviousResult ~= nil and ulPreviousResult ~= 0 then
					printf(" ")
					printf("======================================================================================")
					printf("Clock phase: %d   Sample phase: %d   Previous result: 0x%08x -- Skipping", iClockPhase, iSamplePhase, ulPreviousResult)
					printf("======================================================================================")
					printf(" ")

				else
					-- Timing Control:
					-- 22:20 MEM_SDCLK_PHASE 0-5
					-- 23    MEM_SDCLK_SSNEG 1
					-- 26:24 DATA_SAMPLE_PHASE 0-5
					local ulTiming =
						iClockPhase * 0x100000
						+ 0x800000
						+ iSamplePhase * 0x1000000
					atSdramAttributes.timing_ctrl = timing_ctrl_base + ulTiming
					
					printf(" ")
					printf("======================================================================================")
					printf("Clock phase: %d   Sample phase: %d   timing_ctrl: 0x%08x", iClockPhase, iSamplePhase, atSdramAttributes.timing_ctrl)
					printf("======================================================================================")
					printf(" ")

					setup_sdram(tPlugin, atSdramAttributes)
					ulResult = test_ram_noerror(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
					aiTestResults[iClockPhase][iSamplePhase] = ulResult
					disable_sdram(tPlugin, atSdramAttributes)

					printf("Clock phase: %d   Sample phase: %d   Result: 0x%08x", iClockPhase, iSamplePhase, ulResult)
					printResults()
				end
			end
		end
		ulLoops = ulLoops * 2
	end

	return aiTestResults
end



-- Run the RAM test
-- parameters:
-- ulAreaStart
-- ulAreaSize
-- ulChecks
-- ulPerfTests
-- ulLoops
function run_ramtest(par)
	-- Get the platform attributes for the chip type.
	local tChipType = tPlugin:GetChiptyp()
	local atPlatformAttributes = atPlatformAttributes[tChipType]
	if atPlatformAttributes==nil then
		error("Unknown chip type: ", tChipType)
	end
	
	local ulAreaStart       = par.ulAreaStart        or 0
	local ulAreaSize        = par.ulAreaSize         or 0
	local ulChecks          = par.ulChecks           or 0
	local ulLoops           = par.ulLoops            or 1
	local ulPerfTests       = par.ulPerfTests        or 0
	local ulRowSize         = par.ulRowSize          or 0
	local ulRefreshTime_clk = par.ulRefreshTime_clk  or 0
	
	print()
	print("Call parameters:")
	printf("ulAreaStart        0x%08x", ulAreaStart )
	printf("ulAreaSize         0x%08x", ulAreaSize  )
	printf("ulChecks           0x%08x", ulChecks    )
	printf("ulPerfTests        0x%08x", ulPerfTests )
	printf("ulLoops            0x%08x", ulLoops     )
	printf("ulRowSize          0x%08x", ulRowSize     )
	printf("ulRefreshTime_clk  0x%08x", ulRefreshTime_clk     )
	print()
	
	local aulParameter = {
		ulAreaStart ,
		ulAreaSize  ,
		ulChecks    ,
		ulLoops     ,
		ulPerfTests ,
		ulRowSize   ,
		ulRefreshTime_clk,
		0           , -- pfnProgress
		0           , -- ulProgress
	}
	local iParLen = #aulParameter -- offset of time array -1
	for i=1, 32 do
		table.insert(aulParameter, "OUTPUT")
	end
	
	-- Get the binary.
	local strBinaryName = string.format("netx/ramtest_netx%d.bin", atPlatformAttributes.ulAsic)
	
	-- Install the binary.
	local ulResult = tester.mbin_simple_run(nil, tPlugin, strBinaryName, aulParameter)
	
	local aulTimes = {}
	for i=1, 32 do
		aulTimes[i] = aulParameter[iParLen+i]
	end
	
	return ulResult, aulTimes
end


-- Run the performance test
function run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulPerfTests)

	-- Get the row size
	local tGeometry = get_sdram_geometry(tPlugin, atSdramAttributes)
	local ulRowSize = tGeometry.ulRowSize
	
	-- Get the array refresh time
	local ulTimingCtrl = atSdramAttributes.timing_ctrl
	local ult_REFI    = 3.9 * bit.lshift(1, bit.rshift(bit.band(ulTimingCtrl, 0x00030000), 16))
	local ulArrayRefreshTime_us = ult_REFI * tGeometry.ulRows * tGeometry.ulBanks
	local ulRefreshTime_clk = ulArrayRefreshTime_us * 100
	print()
	printf("t_REFI: %3.2f microseconds", ult_REFI)
	printf("Array refresh time: %5.2f ms, %d * 10ns clocks", ulArrayRefreshTime_us/1000, ulRefreshTime_clk)
	print()
	
	--local iLoops = 1
	local iLoops = 10

	
	local aaulTimes = {}
	for iLoop = 1, iLoops do
		local ulResult, aulTimes = run_ramtest{tPlugin=tPlugin, ulAreaStart=ulAreaStart, ulAreaSize=ulAreaSize, ulPerfTests=ulPerfTests,
		ulRowSize = ulRowSize, ulRefreshTime_clk=ulRefreshTime_clk}
		
		print("Result: ", ulResult)
		
		local t = {}
		for i, v in ipairs(aulTimes) do
			t[i-1] = v/100
		end
		
		printf("Start address: 0x%08x", ulAreaStart)
		printf("Area size:     0x%08x", ulAreaSize)
		print()
		print("Times in microseconds:")
		printf("                           8 Bit     16 Bit     32 Bit    256 Bit")
		printf("sequential read       %10.3f %10.3f %10.3f %10.3f ", t[ 0],   t[ 1],   t[ 2],    t[ 3])
		printf("sequential write      %10.3f %10.3f %10.3f %10.3f ", t[ 4],   t[ 5],   t[ 6],    t[ 7])
		printf("sequential read/write %10.3f %10.3f %10.3f %10.3f ", t[ 8],   t[ 9],   t[10],    t[11])
		printf("row read              %10.3f %10.3f %10.3f %10.3f ", t[13],   t[14],   t[15],    t[16])
		printf("row write             %10.3f %10.3f %10.3f %10.3f ", t[17],   t[18],   t[19],    t[20])
		printf("row read/write        %10.3f %10.3f %10.3f %10.3f ", t[21],   t[22],   t[23],    t[24])
		
		printf("sequential NOP Thumb  %10.3f", t[12])
		printf("row-to-row jump Thumb %10.3f", t[25])
		
		aaulTimes[iLoop] = aulTimes
	end

	if iLoops > 1 then
		
		local aulTimesMin = {}
		local aulTimesMax = {}
		local aulTimesAvg = {}
		for iLoop = 1, iLoops do
			for i, v in ipairs(aaulTimes[iLoop]) do
				aulTimesMin[i] = math.min(aulTimesMin[i] or v, v)
				aulTimesMax[i] = math.max(aulTimesMax[i] or 0, v)
				aulTimesAvg[i] = (aulTimesAvg[i] or 0) + (v / iLoops)
			end
		end
	
		local tmin = {}
		for i, v in ipairs(aulTimesMin) do
			tmin[i-1] = v/100
		end
		local tmax = {}
		for i, v in ipairs(aulTimesMax) do
			tmax[i-1] = v/100
		end
		local tavg = {}
		for i, v in ipairs(aulTimesAvg) do
			tavg[i-1] = v/100
		end
		local tdif = {}
		for i, v in pairs(aulTimesMax) do
			tdif[i-1] = (v - aulTimesMin[i]) / 100
		end
		
		printf("Start address: 0x%08x", ulAreaStart)
		printf("Area size:     0x%08x", ulAreaSize)
		print()
		print("Times in microseconds:")
		printf("                           8 Bit     16 Bit     32 Bit    256 Bit")
		printf("sequential read       %10.3f %10.3f %10.3f %10.3f Min", tmin[ 0],   tmin[ 1],   tmin[ 2],    tmin[ 3])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 0],   tavg[ 1],   tavg[ 2],    tavg[ 3])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 0],   tmax[ 1],   tmax[ 2],    tmax[ 3])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 0],   tdif[ 1],   tdif[ 2],    tdif[ 3])
		print()
		printf("sequential write      %10.3f %10.3f %10.3f %10.3f Min", tmin[ 4],   tmin[ 5],   tmin[ 6],    tmin[ 7])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 4],   tavg[ 5],   tavg[ 6],    tavg[ 7])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 4],   tmax[ 5],   tmax[ 6],    tmax[ 7])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 4],   tdif[ 5],   tdif[ 6],    tdif[ 7])
		print()
		printf("sequential read/write %10.3f %10.3f %10.3f %10.3f Min", tmin[ 8],   tmin[ 9],   tmin[10],    tmin[11])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 8],   tavg[ 9],   tavg[10],    tavg[11])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 8],   tmax[ 9],   tmax[10],    tmax[11])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 8],   tdif[ 9],   tdif[10],    tdif[11])
		print()
		printf("row read              %10.3f %10.3f %10.3f %10.3f Min", tmin[13],   tmin[14],   tmin[15],    tmin[16])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[13],   tavg[14],   tavg[15],    tavg[16])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[13],   tmax[14],   tmax[15],    tmax[16])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[13],   tdif[14],   tdif[15],    tdif[16])
		print()
		printf("row write             %10.3f %10.3f %10.3f %10.3f Min", tmin[17],   tmin[18],   tmin[19],    tmin[20])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[17],   tavg[18],   tavg[19],    tavg[20])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[17],   tmax[18],   tmax[19],    tmax[20])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[17],   tdif[18],   tdif[19],    tdif[20])
		print()
		printf("row read/write        %10.3f %10.3f %10.3f %10.3f Min", tmin[21],   tmin[22],   tmin[23],    tmin[24])
		printf("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[21],   tavg[22],   tavg[23],    tavg[24])
		printf("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[21],   tmax[22],   tmax[23],    tmax[24])
		printf("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[21],   tdif[22],   tdif[23],    tdif[24])
		print()
		
		printf("sequential NOP Thumb  %10.3f Min", tmin[12])
		printf("                      %10.3f Avg", tavg[12])
		printf("                      %10.3f Max", tmax[12])
		printf("                      %10.3f Dif", tdif[12])
		print()
		printf("row-to-row jump Thumb %10.3f Min", tmin[25])
		printf("                      %10.3f Avg", tavg[25])
		printf("                      %10.3f Max", tmax[25])
		printf("                      %10.3f Dif", tdif[25])
	end

end
		
