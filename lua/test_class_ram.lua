local class = require 'pl.class'
local TestClass = require 'test_class'
local TestClassRam = class(TestClass)


function TestClassRam:_init(strTestName, uiTestCase, tLogWriter, strLogLevel)
  self:super(strTestName, uiTestCase, tLogWriter, strLogLevel)

  self.ramtest = require 'ramtest'

  local P = self.P
  self:__parameter {
    P:SC('interface', 'This is the interface where the RAM is connected.'):
      required(true):
      constraint('RAM,SDRAM_HIF,SDRAM_MEM,SRAM_HIF,SRAM_MEM,DDR'),

    P:U32('ram_start', 'Only if interface is RAM: the start of the RAM area.'):
      required(false),

    P:U32('ram_size', 'Only if interface is RAM: The size of the RAM area in bytes.'):
      required(false),

    P:SC('sdram_netx', 'This specifies the chip type for the parameter set.'):
      required(false):
      constraint('NETX4000,NETX4100,NETX4000_RELAXED,NETX500,NETX90_MPW,NETX90,NETX56,NETX50,NETX10'),

    P:U32('sdram_general_ctrl', 'Only if interface is SDRAM: The complete value for the netX general_ctrl register.'):
      required(false),

    P:U32('sdram_timing_ctrl', 'Only if interface is SDRAM: The complete value for the netX timing_ctrl register.'):
      required(false),

    P:U32('sdram_mr', 'Only if interface is SDRAM: The complete value for the netX mr register.'):
      required(false),

    P:U32('sdram_size_exponent', 'Only if interface is SDRAM: The size exponent.'):
      default(23):
      required(true),

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

    P:MC('checks', 'This determines which checks to run. Select one or more values from this list and separate them with commata: 08BIT, 16BIT, 32BIT and BURST.'):
      default('DATABUS,MARCHC,CHECKERBOARD,32BIT,BURST'):
      required(true):
      constraint('DATABUS,08BIT,16BIT,32BIT,MARCHC,CHECKERBOARD,BURST'),

    P:U32('loops', 'The number of loops to run.'):
      default(1):
      required(true)
  }
end



function TestClassRam:run()
  local atParameter = self.atParameter
  local tLog = self.tLog

  ----------------------------------------------------------------------
  --
  -- Parse the parameters and collect all options.
  --

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
  for iCnt,strElement in ipairs(astrElements) do
    local ulValue = atTests[strElement]
    if ulValue==nil then
      error(string.format("Unknown check ID: %s", strElement))
    end
    ulChecks = ulChecks + ulValue
  end

  local ulLoops = atParameter["loops"]:get()


  local atRamAttributes = {
    ["interface"] = ulInterface
  }
  -- Check if the required parameters are present. This depends on the interface.
  -- The RAM interface needs ram_start and ram_size.
  if ulInterface==ramtest.INTERFACE_RAM then
    if atParameter["ram_start"]:get()==nil or atParameter["ram_size"]:get() then
      error("The RAM interface needs the ram_start and ram_size parameter set.")
    end

    atRamAttributes["ram_start"]  = atParameter["ram_start"]:get()
    atRamAttributes["ram_size"]   = atParameter["ram_size"]:get()
  -- The SDRAM interfaces need sdram_general_ctrl, sdram_timing_ctrl, sdram_mr.
  -- NOTE: The sdram_size_exponent is optional. It can be derived from the sdram_general_ctrl.
  elseif ulInterface==ramtest.INTERFACE_SDRAM_HIF or ulInterface==ramtest.INTERFACE_SDRAM_MEM then
    if atParameter["sdram_netx"]:get()==nil or atParameter["sdram_general_ctrl"]:get()==nil or atParameter["sdram_timing_ctrl"]:get()==nil or atParameter["sdram_mr"]:get()==nil then
      error("The SDRAM interface needs the sdram_netx, sdram_general_ctrl, sdram_timing_ctrl and sdram_mr parameter set.")
    end

    atRamAttributes["netX"]          = atParameter["sdram_netx"]:get()
    atRamAttributes["general_ctrl"]  = atParameter["sdram_general_ctrl"]:get()
    atRamAttributes["timing_ctrl"]   = atParameter["sdram_timing_ctrl"]:get()
    atRamAttributes["mr"]            = atParameter["sdram_mr"]:get()
    atRamAttributes["size_exponent"] = atParameter["sdram_size_exponent"]:get()
  -- The SRAM interface needs sram_chip_select, sram_ctrl and sram_size.
  elseif ulInterface==ramtest.INTERFACE_SRAM_HIF or ulInterface==ramtest.INTERFACE_SRAM_MEM then
    if atParameter["sram_chip_select"]:get()==nil or atParameter["sram_ctrl"]:get()==nil or atParameter["sram_size"]:get()==nil then
      error("The SRAM interface needs the sram_chip_select, sram_ctrl and sram_size parameter set.")
    end

    atRamAttributes["sram_chip_select"]  = atParameter["sram_chip_select"]:get()
    atRamAttributes["sram_ctrl"]         = atParameter["sram_ctrl"]:get()
    atRamAttributes["sram_size"]         = atParameter["sram_size"]:get()

  -- The DDR interface needs the parameter files for 400 and 600MHz and the size exponent.
  elseif ulInterface==ramtest.INTERFACE_DDR then
    if atParameter['ddr_parameter_400']:get()==nil or atParameter['ddr_parameter_600']:get()==nil or atParameter['ddr_size_exponent']:get()==nil then
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
  local tPlugin = tester.getCommonPlugin()
  if tPlugin==nil then
    error("No plug-in selected, nothing to do!")
  end


  local ulRAMStart = ramtest.get_ram_start(tPlugin, atRamAttributes)
  local ulRAMSize  = ramtest.get_ram_size(tPlugin, atRamAttributes)

  ramtest.setup_ram(tPlugin, atRamAttributes)
  ramtest.test_ram(tPlugin, ulRAMStart, ulRAMSize, ulChecks, ulLoops)
  ramtest.disable_ram(tPlugin, atRamAttributes)


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
