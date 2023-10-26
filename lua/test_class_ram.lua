local class = require 'pl.class'
local TestClass = require 'test_class'
local TestClassRam = class(TestClass)


function TestClassRam:_init(strTestName, uiTestCase, tLogWriter, strLogLevel)
  self:super(strTestName, uiTestCase, tLogWriter, strLogLevel)

  self.json = require 'dkjson'
  self.bit = require 'bit'

  local cRamTest = require 'ramtest'
  self.ramtest = cRamTest(self.tLog)

  local P = self.P
  self:__parameter {
    P:P('plugin', 'A pattern for the plugin to use.'):
      required(false),

    P:P('plugin_options', 'Plugin options as a JSON object.'):
      required(false),

    P:SC('interface', 'This is the interface where the RAM is connected.'):
      required(true):
      constraint('RAM,SDRAM_HIF,SDRAM_MEM,SRAM_HIF,SRAM_MEM,DDR'),

    P:U32('ram_start', 'Only if interface is RAM: the start of the RAM area.'):
      required(false),

    P:U32('ram_size', 'Only if interface is RAM: The size of the RAM area in bytes.'):
      required(false),

    P:SC('sdram_netx', 'This specifies the chip type for the parameter set.'):
      required(false):
      constraint('NETX4000,NETX4100,NETX4000_RELAXED,NETX500,NETX90_MPW,NETX90,NETX90B,NETX56,NETX50,NETX10'),

    P:U32('sdram_general_ctrl', 'Only if interface is SDRAM: The complete value for the netX general_ctrl register.'):
      required(false),

    P:U32('sdram_timing_ctrl', 'Only if interface is SDRAM: The complete value for the netX timing_ctrl register.'):
      required(false),

    P:U32('sdram_mr', 'Only if interface is SDRAM: The complete value for the netX mr register.'):
      required(false),

    P:U32('sdram_size_exponent', 'Only if interface is SDRAM: The size exponent.'):
      required(false),

    P:P('sdram_parameter_dp', 'The data provider item for the SDRAM parameter.'):
      required(false),

    P:U32('sram_chip_select', 'Only if interface is SRAM: The chip select of the SRAM device.'):
      required(false),

    P:U32('sram_ctrl', 'Only if interface is SRAM: The complete value for the netX extsramX_ctrl register.'):
      required(false),

    P:U32('sram_size', 'Only if interface is SRAM: The size of the SRAM area in bytes.'):
      required(false),

    P:P('ddr_parameter_400', 'Only if interface is DDR: the DDR parameter file for 400MHz.'):
      required(false),

    P:P('ddr_parameter_600', 'Only if interface is DDR: the DDR parameter file for 600MHz.'):
      required(false),

    P:U32('ddr_size_exponent', 'Only if interface is DDR: The size exponent.'):
      required(false),

    P:MC('checks',
         'This determines which checks to run. Select one or more values from this list and separate ' ..
         'them with commata: 08BIT, 16BIT, 32BIT and BURST.'):
      default('DATABUS,MARCHC,CHECKERBOARD,32BIT,BURST'):
      required(true):
      constraint('DATABUS,08BIT,16BIT,32BIT,MARCHC,CHECKERBOARD,BURST'),

    P:U32('loops', 'The number of loops to run.'):
      default(1):
      required(true),

    P:U8('patterns',
         'The number of patterns to use for the test cases 08BIT, 16BIT, 32BIT and BURST. ' ..
         'A values of "0" selects all tests.'):
      default(0):
      required(true)
  }
end



function TestClassRam:run()
  local atParameter = self.atParameter
  local json = self.json
  local tLog = self.tLog
  local ramtest = self.ramtest
  local bit = self.bit
  local pl = self.pl

  ----------------------------------------------------------------------
  --
  -- Parse the parameters and collect all options.
  --
  local strPluginPattern = atParameter['plugin']:get()
  local strPluginOptions = atParameter['plugin_options']:get()

  -- Parse the interface option.
  local strValue = atParameter["interface"]:get()
  local atInterfaces = {
    ["RAM"]       = ramtest.INTERFACE_RAM,
    ["SDRAM_HIF"] = ramtest.INTERFACE_SDRAM_HIF,
    ["SDRAM_MEM"] = ramtest.INTERFACE_SDRAM_MEM,
    ["SRAM_HIF"]  = ramtest.INTERFACE_SRAM_HIF,
    ["SRAM_MEM"]  = ramtest.INTERFACE_SRAM_MEM,
    ["DDR"]       = ramtest.INTERFACE_DDR
  }
  local ulInterface = atInterfaces[strValue]
  if ulInterface==nil then
    error(string.format("Unknown interface ID: %s", strValue))
  end

  -- Parse the test list.
  local astrElements = atParameter["checks"]:get()
  local ulChecks = 0
  local atTests = {
    ["DATABUS"]      = ramtest.CHECK_DATABUS,
    ["08BIT"]        = ramtest.CHECK_08BIT,
    ["16BIT"]        = ramtest.CHECK_16BIT,
    ["32BIT"]        = ramtest.CHECK_32BIT,
    ["MARCHC"]       = ramtest.CHECK_MARCHC,
    ["CHECKERBOARD"] = ramtest.CHECK_CHECKERBOARD,
    ["BURST"]        = ramtest.CHECK_BURST
  }
  for _, strElement in ipairs(astrElements) do
    local ulValue = atTests[strElement]
    if ulValue==nil then
      error(string.format("Unknown check ID: %s", strElement))
    end
    ulChecks = bit.bor(ulChecks,ulValue)
  end

  local ulLoops = atParameter["loops"]:get()
  local uiPatterns = atParameter["patterns"]:get()

  local atRamAttributes = {
    ["interface"] = ulInterface
  }
  -- Check if the required parameters are present. This depends on the interface.
  -- The RAM interface needs ram_start and ram_size.
  if ulInterface==ramtest.INTERFACE_RAM then
    if atParameter["ram_start"]:has_value()~=true or atParameter["ram_size"]:has_value()~=true then
      error("The RAM interface needs the ram_start and ram_size parameter set.")
    end

    atRamAttributes["ram_start"]  = atParameter["ram_start"]:get()
    atRamAttributes["ram_size"]   = atParameter["ram_size"]:get()
  -- The SDRAM interfaces need sdram_general_ctrl, sdram_timing_ctrl, sdram_mr.
  -- NOTE: The sdram_size_exponent is optional. It can be derived from the sdram_general_ctrl.
  elseif ulInterface==ramtest.INTERFACE_SDRAM_HIF or ulInterface==ramtest.INTERFACE_SDRAM_MEM then
    -- Only the direct parameter or the data provider item can be set, but not both.
    if(
      atParameter['sdram_parameter_dp']:has_value() and
      (
        atParameter["sdram_netx"]:has_value() or
        atParameter["sdram_general_ctrl"]:has_value() or
        atParameter["sdram_timing_ctrl"]:has_value() or
        atParameter["sdram_mr"]:has_value()
      )
    ) then
      error('Direct SDRAM parameters and a data provider item are set.')
    end

    -- Get the data provider item.
    if atParameter['sdram_parameter_dp']:has_value() then
      local strDataProviderItem = atParameter.sdram_parameter_dp:get()
      local tItem = _G.tester:getDataItem(strDataProviderItem)
      if tItem==nil then
        local strMsg = string.format('No data provider item found with the name "%s".', strDataProviderItem)
        tLog.error(strMsg)
        error(strMsg)
      end

      -- Compare the selected interface with the setting from the data provider item.
      local strDpInterface = tostring(tItem.interface)
      local atExpectedIf = {
        [ramtest.INTERFACE_SDRAM_HIF] = 'HIF',
        [ramtest.INTERFACE_SDRAM_MEM] = 'MEM'
      }
      local strExpectedIf = atExpectedIf[ulInterface]
      if strDpInterface~=strExpectedIf then
        -- The test parameter select a differen interface than the data provider item.
        local strMsg = string.format(
          'The test parameter select the %s interface, but the data provider item is for interface "%s".',
          strExpectedIf,
          strDpInterface
        )
        tLog.error(strMsg)
        error(strMsg)
      end

      -- Translate the netX information.
      local atNetx = {
        ['4000'] = 'NETX4000',  -- All netX4000 timings are for the released chip.
                                -- The "relaxed" version and the "4100" variant are not supported yet.

        ['500'] = 'NETX500',

        ['90'] = 'NETX90B',     -- All SDRAM settings are for the new netX90.

        ['51'] = 'NETX56',      -- netX51 and netX52 are both the same silicon inside.
        ['52'] = 'NETX56',

        ['50'] = 'NETX50'
      }
      local strNetxDataItem = tostring(tItem.netx)
      local strNetxRamTest = atNetx[strNetxDataItem]
      if strNetxRamTest==nil then
        local tablex = require 'pl.tablex'
        local astrItems = tablex.keys()
        table.sort(astrItems)
        local strMsg = string.format(
          'Failed to translate the netX ID "%s" to a ramtest definition. Possible values are: %s',
          strNetxDataItem,
          table.concat(astrItems, ',')
        )
        tLog.error(strMsg)
        error(strMsg)
      end

      atRamAttributes["netX"]          = strNetxRamTest
      atRamAttributes["general_ctrl"]  = tItem.control_register
      atRamAttributes["timing_ctrl"]   = tItem.timing_register
      atRamAttributes["mr"]            = tItem.mode_register
      atRamAttributes["size_exponent"] = tItem.size_exponent
    else
      if(
        atParameter["sdram_netx"]:has_value()~=true or
        atParameter["sdram_general_ctrl"]:has_value()~=true or
        atParameter["sdram_timing_ctrl"]:has_value()~=true or
        atParameter["sdram_mr"]:has_value()~=true
      ) then
        error(
          "The SDRAM interface needs the sdram_netx, sdram_general_ctrl, sdram_timing_ctrl and sdram_mr parameter set."
        )
      end

      atRamAttributes["netX"]          = atParameter["sdram_netx"]:get()
      atRamAttributes["general_ctrl"]  = atParameter["sdram_general_ctrl"]:get()
      atRamAttributes["timing_ctrl"]   = atParameter["sdram_timing_ctrl"]:get()
      atRamAttributes["mr"]            = atParameter["sdram_mr"]:get()
      atRamAttributes["size_exponent"] = atParameter["sdram_size_exponent"]:get()
    end

  -- The SRAM interface needs sram_chip_select, sram_ctrl and sram_size.
  elseif ulInterface==ramtest.INTERFACE_SRAM_HIF or ulInterface==ramtest.INTERFACE_SRAM_MEM then
    if(
      atParameter["sram_chip_select"]:has_value()~=true or
      atParameter["sram_ctrl"]:has_value()~=true or
      atParameter["sram_size"]:has_value()~=true
    ) then
      error("The SRAM interface needs the sram_chip_select, sram_ctrl and sram_size parameter set.")
    end

    atRamAttributes["sram_chip_select"]  = atParameter["sram_chip_select"]:get()
    atRamAttributes["sram_ctrl"]         = atParameter["sram_ctrl"]:get()
    atRamAttributes["sram_size"]         = atParameter["sram_size"]:get()

  -- The DDR interface needs the parameter files for 400 and 600MHz and the size exponent.
  elseif ulInterface==ramtest.INTERFACE_DDR then
    if(
      atParameter['ddr_parameter_400']:has_value()~=true or
      atParameter['ddr_parameter_600']:has_value()~=true or
      atParameter['ddr_size_exponent']:has_value()~=true
    ) then
      error('The DDR interface needs the ddr_parameter_400, ddr_parameter_600 and ddr_size_exponent parameter set.')
    end

    atRamAttributes['ddr_parameter_400'] = atParameter['ddr_parameter_400']:get()
    atRamAttributes['ddr_parameter_600'] = atParameter['ddr_parameter_600']:get()
    atRamAttributes['size_exponent']     = atParameter['ddr_size_exponent']:get()

  else
    error("Unknown interface ID:"..ulInterface)
  end


  ----------------------------------------------------------------------
  --
  -- Open the connection to the netX.
  -- (or re-use an existing connection.)
  --
  local atPluginOptions = {}
  if strPluginOptions~=nil then
    local tJson, uiPos, strJsonErr = json.decode(strPluginOptions)
    if tJson==nil then
      tLog.warning('Ignoring invalid plugin options. Error parsing the JSON: %d %s', uiPos, strJsonErr)
    else
      atPluginOptions = tJson
    end
  end
  local tPlugin = _G.tester:getCommonPlugin(strPluginPattern, atPluginOptions)
  if tPlugin==nil then
    if strPluginOptions~=nil and #atPluginOptions ~= 0 then
      local strTablePluginOptions = pl.pretty.write(atPluginOptions,'  ',true)
      error(
        string.format(
          table.concat({
            'Failed to connect to the netX with plugin pattern "%s" and options:',
            ' %s',
            'Possible fixes:',
            ' - Wrong plugin name',
            ' - Check the connection cable',
            ' - Check the power supply of the test board'
          }, '\n'),
          strPluginPattern,
          strTablePluginOptions
        )
      )
    else
      error(
        string.format(
          table.concat({
            'Failed to connect to the netX with plugin pattern "%s"!',
            'Possible fixes:',
            ' - Wrong plugin name',
            ' - Check the connection cable',
            ' - Check the power supply of the test board'
          }, '\n'),
          strPluginPattern
        )
      )
    end
  end


  local ulRAMStart = ramtest:get_ram_start(tPlugin, atRamAttributes)
  local ulRAMSize  = ramtest:get_ram_size(tPlugin, atRamAttributes)

  ramtest:setup_ram(tPlugin, atRamAttributes)
  ramtest:test_ram(tPlugin, ulRAMStart, ulRAMSize, ulChecks, ulLoops, uiPatterns)
  ramtest:disable_ram(tPlugin, atRamAttributes)


  print("")
  print(" #######  ##    ## ")
  print("##     ## ##   ##  ")
  print("##     ## ##  ##   ")
  print("##     ## #####    ")
  print("##     ## ##  ##   ")
  print("##     ## ##   ##  ")
  print(" #######  ##    ## ")
  print("")
end


return TestClassRam
