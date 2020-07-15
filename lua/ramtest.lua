local class = require 'pl.class'
local RamTest = class()

function RamTest:_init(tLog)
  self.bit = require("bit")
  local romloader = require("romloader")
  self.romloader = romloader

  self.tLog = tLog

  -- Flags for functional tests
  self.CHECK_DATABUS            = ${RAMTESTCASE_DATABUS}
  self.CHECK_08BIT              = ${RAMTESTCASE_08BIT}
  self.CHECK_16BIT              = ${RAMTESTCASE_16BIT}
  self.CHECK_32BIT              = ${RAMTESTCASE_32BIT}
  self.CHECK_MARCHC             = ${RAMTESTCASE_MARCHC}
  self.CHECK_CHECKERBOARD       = ${RAMTESTCASE_CHECKERBOARD}
  self.CHECK_BURST              = ${RAMTESTCASE_BURST}
  self.CHECK_SEQUENCE           = ${RAMTESTCASE_SEQUENCE}
  self.CHECK_MEMCPY             = ${RAMTESTCASE_MEMCPY}
  self.CHECK_CA9SMP_ALTERNATE   = ${RAMTESTCASE_CA9SMP_ALTERNATE}
  self.CHECK_CA9SMP_BLOCK       = ${RAMTESTCASE_CA9SMP_BLOCK}


  -- Flags for performance tests
  self.PERFTEST_SEQ_R8          = ${RAMPERFTESTCASE_SEQ_R8}
  self.PERFTEST_SEQ_R16         = ${RAMPERFTESTCASE_SEQ_R16}
  self.PERFTEST_SEQ_R32         = ${RAMPERFTESTCASE_SEQ_R32}
  self.PERFTEST_SEQ_R256        = ${RAMPERFTESTCASE_SEQ_R256}
  self.PERFTEST_SEQ_W8          = ${RAMPERFTESTCASE_SEQ_W8}
  self.PERFTEST_SEQ_W16         = ${RAMPERFTESTCASE_SEQ_W16}
  self.PERFTEST_SEQ_W32         = ${RAMPERFTESTCASE_SEQ_W32}
  self.PERFTEST_SEQ_W256        = ${RAMPERFTESTCASE_SEQ_W256}
  self.PERFTEST_SEQ_RW8         = ${RAMPERFTESTCASE_SEQ_RW8}
  self.PERFTEST_SEQ_RW16        = ${RAMPERFTESTCASE_SEQ_RW16}
  self.PERFTEST_SEQ_RW32        = ${RAMPERFTESTCASE_SEQ_RW32}
  self.PERFTEST_SEQ_RW256       = ${RAMPERFTESTCASE_SEQ_RW256}
  self.PERFTEST_SEQ_NOP         = ${RAMPERFTESTCASE_SEQ_NOP}

  self.PERFTEST_ROW_R8          = ${RAMPERFTESTCASE_ROW_R8}
  self.PERFTEST_ROW_R16         = ${RAMPERFTESTCASE_ROW_R16}
  self.PERFTEST_ROW_R32         = ${RAMPERFTESTCASE_ROW_R32}
  self.PERFTEST_ROW_R256        = ${RAMPERFTESTCASE_ROW_R256}
  self.PERFTEST_ROW_W8          = ${RAMPERFTESTCASE_ROW_W8}
  self.PERFTEST_ROW_W16         = ${RAMPERFTESTCASE_ROW_W16}
  self.PERFTEST_ROW_W32         = ${RAMPERFTESTCASE_ROW_W32}
  self.PERFTEST_ROW_W256        = ${RAMPERFTESTCASE_ROW_W256}
  self.PERFTEST_ROW_RW8         = ${RAMPERFTESTCASE_ROW_RW8}
  self.PERFTEST_ROW_RW16        = ${RAMPERFTESTCASE_ROW_RW16}
  self.PERFTEST_ROW_RW32        = ${RAMPERFTESTCASE_ROW_RW32}
  self.PERFTEST_ROW_RW256       = ${RAMPERFTESTCASE_ROW_RW256}
  self.PERFTEST_ROW_JUMP        = ${RAMPERFTESTCASE_ROW_JUMP}

  -- The supported interfaces.
  self.INTERFACE_RAM            = 0
  self.INTERFACE_SDRAM_HIF      = 1
  self.INTERFACE_SDRAM_MEM      = 2
  self.INTERFACE_SRAM_HIF       = 3
  self.INTERFACE_SRAM_MEM       = 4
  self.INTERFACE_DDR            = 5


  self.atPlatformAttributes = {
    [romloader.ROMLOADER_CHIPTYP_NETX4000_FULL] = {
      strAsic = 'netx4000',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0xf40c0140,
          ulArea_Start = 0x30000000,
          setup = self.setup_sdram_netx4000
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xf40c0240,
          ulArea_Start = 0x20000000,
          setup = self.setup_sdram_netx4000
        }
      },
      ddr = {
        ulArea_Start = 0x40000000,
        setup = self.setup_ddr_netx4000
      }
    },

    [romloader.ROMLOADER_CHIPTYP_NETX4100_SMALL] = {
      strAsic = 'netx4100',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0xf40c0140,
          ulArea_Start = 0x30000000,
          setup = self.setup_sdram_netx4000
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xf40c0240,
          ulArea_Start = 0x20000000,
          setup = self.setup_sdram_netx4000
        }
      },
      ddr = {
        ulArea_Start = 0x40000000,
        setup = self.setup_ddr_netx4000
      }
    },

    [romloader.ROMLOADER_CHIPTYP_NETX4000_RELAXED] = {
      strAsic = 'netx4000_relaxed',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0xf40c0140, 
          ulArea_Start = 0x30000000,
          setup = self.setup_sdram_netx4000 
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xf40c0240,
          ulArea_Start = 0x20000000,
          setup = self.setup_sdram_netx4000
        }
      },
      ddr = {
        ulArea_Start = 0x40000000,
        setup = self.setup_ddr_netx4000
      }
    },

    [romloader.ROMLOADER_CHIPTYP_NETX500] = {
      strAsic = 'netx500',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0x00100140,
          ulArea_Start = 0x80000000,
          setup = nil
        },
        [self.INTERFACE_SDRAM_HIF] = {
        }
      },
      sram = {
        [self.INTERFACE_SRAM_HIF] = {
        },
        [self.INTERFACE_SRAM_MEM] = {
          ulController = 0x00100100,
          ulChipSelects = 4,
          aulArea_Start = {
            [0] = 0xC0000000,
            [1] = 0xC8000000,
            [2] = 0xD0000000,
            [3] = 0xD8000000
          }
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX100] = {
      strAsic = 'netx500',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0x00100140,
          ulArea_Start = 0x80000000,
          setup = nil
        },
        [self.INTERFACE_SDRAM_HIF] = {
        }
      },
      sram = {
        [self.INTERFACE_SRAM_HIF] = {
        },
        [self.INTERFACE_SRAM_MEM] = {
          ulController = 0x00100100,
          ulChipSelects = 4,
          aulArea_Start = {
            [0] = 0xC0000000,
            [1] = 0xC8000000,
            [2] = 0xD0000000,
            [3] = 0xD8000000
          }
        },
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX90_MPW] = {
      strAsic = 'netx90_mpw',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xff401540,
          ulArea_Start = 0x10000000,
          setup = self.setup_sdram_hif_netx90_mpw
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX90] = {
      strAsic = 'netx90',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xff401540,
          ulArea_Start = 0x10000000,
          setup = self.setup_sdram_hif_netx90_mpw
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX90B] = {
      strAsic = 'netx90',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0xff401540,
          ulArea_Start = 0x10000000,
          setup = self.setup_sdram_hif_netx90_mpw
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX56] = {
      strAsic = 'netx56',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0x101c0140,
          ulArea_Start = 0x80000000,
          setup = nil
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0x101c0240,
          ulArea_Start = 0x40000000,
          setup = self.setup_sdram_hif_netx56
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX56B] = {
      strAsic = 'netx56',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0x101c0140,
          ulArea_Start = 0x80000000,
          setup = nil
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0x101c0240,
          ulArea_Start = 0x40000000,
          setup = self.setup_sdram_hif_netx56
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX50] = {
      strAsic = 'netx50',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
          ulController = 0x1c000140,
          ulArea_Start = 0x80000000,
          setup = nil
        },
        [self.INTERFACE_SDRAM_HIF] = {
        }
      },
      ddr = nil
    },

    [romloader.ROMLOADER_CHIPTYP_NETX10] = {
      strAsic = 'netx10',
      sdram = {
        [self.INTERFACE_SDRAM_MEM] = {
        },
        [self.INTERFACE_SDRAM_HIF] = {
          ulController = 0x101c0140,
          ulArea_Start = 0x80000000,
          setup = self.setup_sdram_hif_netx10
        }
      },
      ddr = nil
    }
  }
end


-- Print a string with a flexible underline.
-- This is only used in the performance tests.
function RamTest:performance_test_printf_ul(ch, ...)
  local str = string.format(...)
  local line = string.rep(ch, str:len())
  print(str)
  print(line)
end


function RamTest:setup_sdram_netx4000(tPlugin, atSdramAttributes)
  local bit = self.bit
  local tLog = self.tLog
  local tGeom = self:get_sdram_geometry(tPlugin, atSdramAttributes)
  self:print_sdram_geometry(tGeom)

  -- get the number of required address signals
  local numRowLines = 11 + tGeom.ulRowBits
  local numColumnLines = 8 + tGeom.ulColumnBits
  -- line A10 is not useable as column address signal.
  if numColumnLines>=11 then
    numColumnLines = numColumnLines + 1
  end
  local numAddrLines = math.max(numRowLines, numColumnLines)

  assert(tGeom.ulBusWidthBits==0 or numAddrLines<=18,
         "Bus width and number of address lines are incompatible")
  assert(numAddrLines<=25,
         "More than 25 address lines are not supported")

  tLog.debug("numRowLines:    %d", numRowLines)
  tLog.debug("numColumnLines: %d", numColumnLines)
  tLog.debug("numAddrLines  : %d", numAddrLines)

  local sel_mem_d         = 0 -- 27 - 24   32 bit on HIF MI
  local sel_mem_a_width   = 0 -- 22 - 20   A0-A10
  local en_mem_sdram_mi   = 0 --      18   disable
  local mem_mi_cfg        = 3 --           MEM MI disabled
  local en_hif_rdy_pio_mi = 0 --      12
  local sel_hif_a_width   = 0 -- 11 -  8   A0..A10
  local en_hif_sdram_mi   = 0 --  7        disable
  local hif_mi_cfg        = 3 --  6 -  5   HIF MI disabled

  if atSdramAttributes.interface == self.INTERFACE_SDRAM_MEM then
    sel_mem_d         = 15 -- 32 bit on MEM MI
    sel_mem_a_width   = math.max(numAddrLines - 18, 0)
    en_mem_sdram_mi   = 1 -- enable
    mem_mi_cfg        = tGeom.ulBusWidthBits + 1  -- 0 (16 bits) -> 01, 1 (32 bits) -> 10
    en_hif_rdy_pio_mi = 0
    sel_hif_a_width   = 0 -- A0..A10
    en_hif_sdram_mi   = 0 -- disable
    hif_mi_cfg        = 3 -- 11 HIF MI disabled

  elseif atSdramAttributes.interface == self.INTERFACE_SDRAM_HIF then
    sel_mem_d         = 0 -- 32 bit on HIF MI
    sel_mem_a_width   = 0
    en_mem_sdram_mi   = 0
    mem_mi_cfg        = 3 -- 11 MEM MI is disabled.
    en_hif_rdy_pio_mi = 0
    sel_hif_a_width   = math.max(numAddrLines - 11, 0)
    en_hif_sdram_mi   = 1 -- enable
    hif_mi_cfg        = tGeom.ulBusWidthBits + 1  -- 0 (16 bits) -> 01, 1 (32 bits) -> 10
  end

  local ulVal_HIF_IO_CFG =
      2^24 * sel_mem_d
    + 2^20 * sel_mem_a_width
    + 2^18 * en_mem_sdram_mi
    + 2^16 * mem_mi_cfg
    + 2^12 * en_hif_rdy_pio_mi
    + 2^8  * sel_hif_a_width
    + 2^7  * en_hif_sdram_mi
    + 2^5  * hif_mi_cfg

  tLog.debug("HIF_IO_CFG: 0x%08x", ulVal_HIF_IO_CFG)

  local Addr_clock_enable = 0xf4080138
  local Addr_ASIC_CTRL_ACCESS_KEY = 0xf408017c
  local Addr_HIF_IO_CFG = 0xf4080200
  tPlugin:write_data32(Addr_ASIC_CTRL_ACCESS_KEY, tPlugin:read_data32(Addr_ASIC_CTRL_ACCESS_KEY))
  tPlugin:write_data32(Addr_HIF_IO_CFG, ulVal_HIF_IO_CFG)
  local ulValue = bit.bor(tPlugin:read_data32(Addr_clock_enable), 0x00400000)
  tPlugin:write_data32(Addr_ASIC_CTRL_ACCESS_KEY, tPlugin:read_data32(Addr_ASIC_CTRL_ACCESS_KEY))
  tPlugin:write_data32(Addr_clock_enable, ulValue)

  --self:set_hif_portcontrol_romcode(tPlugin)
end

-- ------------------------------------------------------------------------------------------------------------

-- Set Port control for 16 bit HIF SDRAM on netX 4000
-- Set drive strength 8 mA

-- Control signals on P10_3..10:
--         3 hif_bhe1
--         4 hif_bhe3
--         5 hif_csn
--         6 hif_rdn
--         7 hif_wrn
--         8 hif_rdy
--         9 hif_dirq
--         10 hif_sdclk
--
-- 07:       U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0800 U0800 U0800 U0800 U0800 U0800 U0800
-- 08: U0800 
-- 09:       U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600
-- 0a: U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 D0600 
function RamTest:set_hif_portcontrol_nxhxsdrspi(tPlugin)
  self:set_portcontrol(tPlugin, 7,  1,  8,  'PC_U0800') -- P7_1..8   HIF_D0..D7
  self:set_portcontrol(tPlugin, 7,  9,  15, 'PC_U0800') -- P7_9..15  HIF_D8..D14
  self:set_portcontrol(tPlugin, 8,  0,  0,  'PC_U0800') -- P8_0      HIF_D15
  self:set_portcontrol(tPlugin, 9,  1,  15, 'PC_U0800') -- P9_1..15  HIF_A0..A14
  self:set_portcontrol(tPlugin, 10, 3,  9,  'PC_U0800') -- P10_3..9
  self:set_portcontrol(tPlugin, 10, 10, 10, 'PC_D0800') -- P10_10
end


-- PORTCONTROL:
--     00    01    02    03    04    05    06    07    08    09    0a    0b    0c    0d    0e    0f
-- 07:       U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0800 U0800 U0800 U0800 U0800 U0800 U0800
-- 08: U0800 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600
-- 09: D0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600
-- 0a: U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 U0600 D0600 

function RamTest:set_hif_portcontrol_romcode(tPlugin)
  self:set_portcontrol(tPlugin, 7,  1,  8,  'PC_U0600') -- P7_1..8   HIF_D0..D7    U0600
  self:set_portcontrol(tPlugin, 7,  9,  15, 'PC_U0800') -- P7_9..15  HIF_D8..D14   U0800
  self:set_portcontrol(tPlugin, 8,  0,  15, 'PC_U0600') -- P8_0      HIF_D15
  self:set_portcontrol(tPlugin, 9,  0,  0,  'PC_D0600') -- P9_1..15  HIF_A0..A14   U0600
  self:set_portcontrol(tPlugin, 9,  1,  15, 'PC_U0600') -- P9_1..15  HIF_A0..A14   U0600
  self:set_portcontrol(tPlugin, 10, 3,  9,  'PC_U0600') -- P10_3..9                U0600
  self:set_portcontrol(tPlugin, 10, 10, 10, 'PC_D0600') -- P10_10                  D0600
end

-- Set the range of PortControl registers Py_x0 .. Py_x1 to val
function RamTest:set_portcontrol(tPlugin, y, x0, x1, val)
  local atPortControlValues = {
    PC_U0400 = 0x0001,
    PC_U0600 = 0x0011,
    PC_U0800 = 0x0021,
    PC_U1200 = 0x0031,
    PC_D0400 = 0x0003,
    PC_D0600 = 0x0013,
    PC_D0800 = 0x0023,
    PC_D1200 = 0x0033
  }

  local ADDR_PORTCONTROL = 0xfb100000 + 16 * y * 4
  local ulValue = atPortControlValues[val]
  if ulValue==nil then
    error(string.format('Invalid value ID "%s".', tostring(val)))
  end
  for x = x0, x1 do
    tPlugin:write_data32(ADDR_PORTCONTROL + 4*x, ulValue)
  end
end
-- ------------------------------------------------------------------------------------------------------------

function RamTest:setup_sdram_hif_netx90_mpw(tPlugin, atSdramAttributes)
  local tester = _G.tester
  local tLog = self.tLog
  local bit = self.bit
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
  -- bits 11-8 sel_hif_a_width
  local ulSdramSize = self:get_ram_size(tPlugin, atSdramAttributes)
  local ulAddressCfg = 0
  for ulSize,ulCfg in pairs(atAddressLines) do
    ulAddressCfg = ulCfg
    if ulSdramSize<=ulSize then
      break
    end
  end
  tLog.debug("ulAddressCfg=0x%08x", ulAddressCfg)

  -- Get the configuration value for the data bus size.
  -- bits 5-4 hif_mi_cfg
  local ulGeneralCtrl = atSdramAttributes.general_ctrl
  local ulDataCfg
  if bit.band(ulGeneralCtrl,0x00010000)==0 then
    -- The data bus has a size of 8 bit.
    ulDataCfg = 0x00000080
  else
    -- The data bus has a size of 16 bit.
    ulDataCfg = 0x000000a0
  end
  tLog.debug("ulDataCfg=0x%08x", ulDataCfg)

  -- Install the binary.
  local strBinaryName = "netx/setup_netx90_mpw.bin"
  local ulParameter = bit.bor(ulAddressCfg, ulDataCfg)
  local ulResult = tester:mbin_simple_run(tPlugin, strBinaryName, ulParameter)
  if ulResult~=0 then
    error(string.format("The setup returned an error code: 0x%08x", ulResult))
  end
end



function RamTest:setup_sdram_hif_netx56(tPlugin, atSdramAttributes)
  local tester = _G.tester
  local tLog = self.tLog
  local bit = self.bit
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
  -- bits 11-8 sel_hif_a_width
  local ulSdramSize = self:get_ram_size(tPlugin, atSdramAttributes)
  local ulAddressCfg = 0
  for ulSize,ulCfg in pairs(atAddressLines) do
    ulAddressCfg = ulCfg
    if ulSdramSize<=ulSize then
      break
    end
  end
  tLog.debug("ulAddressCfg=0x%08x", ulAddressCfg)

  -- Get the configuration value for the data bus size.
  -- bits 5-4 hif_mi_cfg
  local ulGeneralCtrl = atSdramAttributes.general_ctrl
  local ulDataCfg
  if bit.band(ulGeneralCtrl,0x00010000)==0 then
    -- The data bus has a size of 16 bits.
    ulDataCfg = 0x00000050
  else
    -- The data bus has a size of 32 bits.
    ulDataCfg = 0x00000060
  end
  tLog.debug("ulDataCfg=0x%08x", ulDataCfg)

  -- Install the binary.
  local strBinaryName = "netx/setup_netx56.bin"
  local ulParameter = bit.bor(ulAddressCfg, ulDataCfg)
  local ulResult = tester:mbin_simple_run(tPlugin, strBinaryName, ulParameter)
  if ulResult~=0 then
    error(string.format("The setup returned an error code: 0x%08x", ulResult))
  end
end



function RamTest:setup_sdram_hif_netx10(tPlugin, atSdramAttributes)
  local bit = self.bit

  -- Generate the value for the HIF_IO_CTRL register.
  -- This depends on the data bus width of the SDRAM device.
  local ulGeneralCtrl = atSdramAttributes.general_ctrl
  local ulHifIoCtrl
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



function RamTest:setup_ddr_netx4000(tPlugin, atDdrAttributes)
  local bit = self.bit
  local romloader = self.romloader
  local tester = _G.tester
  local tLog = self.tLog

  -- Is the RAP system running with 400 or 600MHz?
  local ulSpeed = 400
  local strConfigurationFile = atDdrAttributes['ddr_parameter_400']
  -- Read the RAP_SYSCTRL_BOOTMODE register.
  local ulValue = tPlugin:read_data32(0xf8000000)
  -- Get the SET_PLL_1200 bit.
  ulValue = bit.band(ulValue, 0x00000100)
  if ulValue~=0 then
    ulSpeed = 600
    strConfigurationFile = atDdrAttributes['ddr_parameter_600']
  end
  tLog.debug('The RAP system is running with %dMHz.', ulSpeed)
  if strConfigurationFile==nil then
    error(string.format('No DDR parameter provided for %dMHz.', ulSpeed))
  end

  local applyOptions = require 'apply_options'()
  local strOpts = applyOptions:parse(strConfigurationFile)

  -- Apply the parameters.
  -- Basically this is a programatic version of the "LCFG" console command.
  local sizOpts = string.len(strOpts)
  local strSize = string.char( bit.band(sizOpts,0xff), bit.band(bit.rshift(sizOpts,8),0xff), bit.band(bit.rshift(sizOpts,16),0xff), bit.band(bit.rshift(sizOpts,24),0xff) )
  local strChipType
  local tChipType = tPlugin:GetChiptyp()
  if tChipType==romloader.ROMLOADER_CHIPTYP_NETX4000_FULL or tChipType==romloader.ROMLOADER_CHIPTYP_NETX4100_SMALL then
    strChipType = '4000'
  elseif tChipType==romloader.ROMLOADER_CHIPTYP_NETX4000_RELAXED then
    strChipType = '4000_relaxed'
  else
    error('Unknown chip type for DDR.')
  end
  local ulOptionsResult = tester:mbin_simple_run(tPlugin, string.format('netx/apply_options_netx%s.bin', strChipType), strSize .. strOpts)
  if ulOptionsResult~=0 then
    error(string.format('Falied to apply the option file for %dMHz: 0x%08x', ulSpeed, ulOptionsResult))
  end

  -- Setup the DDR controller.
  local ulMdupResult = tester:mbin_simple_run(tPlugin, string.format('netx/mdup_netx%s.bin', strChipType), 10)
  if ulMdupResult~=0 then
    error(string.format('Falied to setup the DDR controller: 0x%08x', ulMdupResult))
  end
end



function RamTest:get_sdram_interface_attributes(tPlugin, tInterface)
  -- Get the platform attributes for the chip type.
  local tChipType = tPlugin:GetChiptyp()
  local atPlatform = self.atPlatformAttributes[tChipType]
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



function RamTest:get_sram_interface_attributes(tPlugin, tInterface)
  -- Get the platform attributes for the chip type.
  local tChipType = tPlugin:GetChiptyp()
  local atPlatform = self.atPlatformAttributes[tChipType]
  if atPlatform==nil then
    error("Unknown chip type: ", tChipType)
  end
  -- Get the interface attributes.
  local atSram = atPlatform.sram
  if atSram==nil then
    error("Chiptype has no sram attributes: ", tChipType)
  end
  local atInterface = atSram[tInterface]
  if atInterface==nil then
    error("Chiptype "..tChipType.." has no SRAM attributes for interface: ", tInterface)
  end

  return atInterface
end



function RamTest:get_ddr_interface_attributes(tPlugin)
  -- Get the platform attributes for the chip type.
  local tChipType = tPlugin:GetChiptyp()
  local atPlatform = self.atPlatformAttributes[tChipType]
  if atPlatform==nil then
    error("Unknown chip type: ", tChipType)
  end
  -- Get the interface attributes.
  local atDdrInterface = atPlatform.ddr
  if atDdrInterface==nil then
    error("Chiptype has no ddr attributes: ", tChipType)
  end

  return atDdrInterface
end



function RamTest:compare_netx_version(tPlugin, atRamAttributes)
  local romloader = self.romloader
  local atChipTypes = {
    ['NETX4000'] = {
      romloader.ROMLOADER_CHIPTYP_NETX4000_FULL
    },
    ['NETX4100'] = {
      romloader.ROMLOADER_CHIPTYP_NETX4100_SMALL
    },
    ['NETX4000_RELAXED'] = {
      romloader.ROMLOADER_CHIPTYP_NETX4000_RELAXED
    },
    ['NETX500'] = {
      romloader.ROMLOADER_CHIPTYP_NETX500,
      romloader.ROMLOADER_CHIPTYP_NETX100
    },
    ['NETX90_MPW'] = {
      romloader.ROMLOADER_CHIPTYP_NETX90_MPW,
    },
    ['NETX90'] = {
      romloader.ROMLOADER_CHIPTYP_NETX90,
    },
    ['NETX90B'] = {
      romloader.ROMLOADER_CHIPTYP_NETX90B,
    },
    ['NETX56'] = {
      romloader.ROMLOADER_CHIPTYP_NETX56,
      romloader.ROMLOADER_CHIPTYP_NETX56B
    },
    ['NETX50'] = {
      romloader.ROMLOADER_CHIPTYP_NETX50
    },
    ['NETX10'] = {
      romloader.ROMLOADER_CHIPTYP_NETX10
    }
  }

  -- Get the connected chip type.
  local tChipType = tPlugin:GetChiptyp()

  local atChipTypesStr = {}
  for strNetxTyp,atTypes in pairs(atChipTypes) do
    local strChipTypes = ""
    local sizChipTypes = #atTypes
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
    atChipTypesStr[strNetxTyp] = strChipTypes
  end

  local strHelp = "Possible values are:\n"
  for strNetxTyp,strTypes in pairs(atChipTypesStr) do
    strHelp = strHelp .. string.format("  %s: %s\n", strNetxTyp, strTypes)
  end

  -- Get the required chip type for the parameter.
  local tRequiredChipType = atRamAttributes.netX
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
  for _,tTyp in ipairs(atTypes) do
    if tTyp==tChipType then
      fChipTypeMatches = true
      break
    end
  end

  if fChipTypeMatches~=true then
    local strError =       "The connected chip type does not match the one specified in the SDRAM parameters.\n"
    strError = strError .. "In other words: the parameters do not work with the connected netX.\n"
    strError = strError .. "Connected netX:     " .. tPlugin:GetChiptypName(tChipType) .. "\n"
    strError = strError .. "Parameters are for: " .. atChipTypesStr[tRequiredChipType] .. "\n"
    error(strError)
  end
end



function RamTest:setup_ram(tPlugin, atRamAttributes)
  local tLog = self.tLog
  local tInterface = atRamAttributes.interface
  if tInterface==self.INTERFACE_RAM then
    -- The RAM interface needs no enable/disable.
  elseif tInterface==self.INTERFACE_SDRAM_HIF or tInterface==self.INTERFACE_SDRAM_MEM then
    -- Compare the chip type.
    self:compare_netx_version(tPlugin, atRamAttributes)

    -- Get the interface attributes.
    local atInterface = self:get_sdram_interface_attributes(tPlugin, atRamAttributes.interface)

    -- Call the setup function for the platform and interface.
    local pfnSetup = atInterface.setup
    if pfnSetup~=nil then
      pfnSetup(self, tPlugin, atRamAttributes)
    end

    -- Get the base address of the SDRAM controller.
    local ulSDRamController = atInterface.ulController

    -- Combine the timing control value from the base timing and the SDRAM specific value.
    local ulGeneralCtrl = atRamAttributes.general_ctrl
    local ulTimingCtrl  = atRamAttributes.timing_ctrl
    local ulMr = atRamAttributes.mr

    tLog.info("SDRAM general ctrl: 0x%08x", ulGeneralCtrl)
    tLog.info("SDRAM timing ctrl:  0x%08x", ulTimingCtrl)
    tLog.info("SDRAM mr:           0x%08x", ulMr)

    -- Disable the SDRAM controller.
    tPlugin:write_data32(ulSDRamController+0, 0)

    -- Setup the SDRAM controller.
    tPlugin:write_data32(ulSDRamController+8, ulMr)
    tPlugin:write_data32(ulSDRamController+4, ulTimingCtrl)
    tPlugin:write_data32(ulSDRamController+0, ulGeneralCtrl)
  elseif tInterface==self.INTERFACE_SRAM_HIF or tInterface==self.INTERFACE_SRAM_MEM then
    local ulChipSelect = atRamAttributes.sram_chip_select
    local atInterface = self:get_sram_interface_attributes(tPlugin, tInterface)
    local ulController = atInterface.ulController + 4*ulChipSelect

    -- Setup the RAM controller.
    tPlugin:write_data32(ulController, atRamAttributes.sram_ctrl)

  elseif tInterface==self.INTERFACE_DDR then
    -- Get the interface attributes.
    local atInterface = self:get_ddr_interface_attributes(tPlugin)

    -- Call the setup function for the platform and interface.
    local pfnSetup = atInterface.setup
    if pfnSetup~=nil then
      pfnSetup(self, tPlugin, atRamAttributes)
    end

  else
    error("Unknown interface ID:"..tInterface)
  end
end



function RamTest:disable_ram(tPlugin, atRamAttributes)
  local tLog = self.tLog
  local tInterface = atRamAttributes.interface
  if tInterface==self.INTERFACE_RAM then
    -- The RAM interface needs no enable/disable.
  elseif tInterface==self.INTERFACE_SDRAM_HIF or tInterface==self.INTERFACE_SDRAM_MEM then
    -- Get the interface attributes.
    local atInterface = self:get_sdram_interface_attributes(tPlugin, tInterface)

    -- Get the base address of the SDRAM controller.
    local ulController = atInterface.ulController

    -- Disable the SDRAM controller.
    tPlugin:write_data32(ulController+0, 0)
    tPlugin:write_data32(ulController+4, 0)
    tPlugin:write_data32(ulController+8, 0)
  elseif tInterface==self.INTERFACE_SRAM_HIF or tInterface==self.INTERFACE_SRAM_MEM then
    local ulChipSelect = atRamAttributes.sram_chip_select
    local atInterface = self:get_sram_interface_attributes(tPlugin, tInterface)
    local ulController = atInterface.ulController + 4*ulChipSelect

    -- Disable the RAM controller.
    tPlugin:write_data32(ulController, 0x03000000)
  elseif tInterface==self.INTERFACE_DDR then
    tLog.warning('The DDR shutdown routine is not implemented yet.')
--  TODO: Add a shutdown routine here.
  else
    error("Unknown interface ID:"..tInterface)
  end
end




-- Note: the geometry fields have slightly different definitions:
--           netx 500/100/50                  netx 10                          netx 56/4000
-- width    1 bit,  0..1     = 16..32        1 bit,  0..1     = 8..16        1 bit,  0..1     = 16..32
-- columns  3 bits, 000..110 = 256..16k      3 bits, 000..100 = 256..4k      3 bits, 000..100 = 256..4k
-- rows     3 bits, 000..101 = 2k..64k       3 bits, 000..011 = 2k..16k      2 bits, 000..011 = 2k..16k
-- banks    2 bits, 00..10   = 2..8          2 bits, 00..01   = 2..4         2 bits, 00..01   = 2..4

-- Extract the geometry parameters.
function RamTest:decode_sdram_geometry(ulGeneralCtrl, tAsicTyp)
  local bit = self.bit
  local romloader = self.romloader

  local ulBankBits     =            bit.band(ulGeneralCtrl, 0x00000003)
  local ulRowBits      = bit.rshift(bit.band(ulGeneralCtrl, 0x00000070), 4)
  local ulColumnBits   = bit.rshift(bit.band(ulGeneralCtrl, 0x00000700), 8)
  local ulBusWidthBits = bit.rshift(bit.band(ulGeneralCtrl, 0x00010000), 16)

  local ulBanks    = bit.lshift(2,    ulBankBits)
  local ulRows     = bit.lshift(2048, ulRowBits)
  local ulColumns  = bit.lshift(256,  ulColumnBits)
  local ulBusWidth = bit.lshift(1,    ulBusWidthBits)

  if tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX100 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX500
  or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX50
  or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56 or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX56B
  or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX4000_RELAXED or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX4000_FULL or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX4100_SMALL
  then
    ulBusWidth = ulBusWidth * 2
  elseif tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX10 
  or tAsicTyp==romloader.ROMLOADER_CHIPTYP_NETX90_MPW then
    ulBusWidth = ulBusWidth
  else
    error("Unknown chiptyp!")
  end

  local ulRowSize  = ulColumns * ulBusWidth
  local ulBankSize = ulRows * ulRowSize
  local ulSize     = ulBanks * ulBankSize

  -- bus width, row size and size are in bytes
  local tGeom = {
    ulBankBits     = ulBankBits,
    ulRowBits      = ulRowBits,
    ulColumnBits   = ulColumnBits,
    ulBusWidthBits = ulBusWidthBits,

    ulBanks        = ulBanks,
    ulRows         = ulRows,
    ulColumns      = ulColumns,
    ulBusWidth     = ulBusWidth,

    ulRowSize      = ulRowSize,
    ulBankSize     = ulBankSize,
    ulSize         = ulSize
  }

  return tGeom
end



function RamTest:print_sdram_geometry(tGeom)
  local tLog = self.tLog

  tLog.info('')
  tLog.info("Geometry:")
  tLog.info("Banks    : %d",           tGeom.ulBanks    )
  tLog.info("Rows     : %d",           tGeom.ulRows     )
  tLog.info("Columns  : %d",           tGeom.ulColumns  )
  tLog.info("BusWidth : %d bytes",     tGeom.ulBusWidth )
  tLog.info("RowSize  : 0x%08x bytes", tGeom.ulRowSize  )
  tLog.info("Bank Size: 0x%08x bytes", tGeom.ulBankSize )
  tLog.info("Size     : 0x%08x bytes", tGeom.ulSize     )
  tLog.info('')
end



function RamTest:get_sdram_geometry(tPlugin, atSdramAttributes)
  local ulGeneralCtrl = atSdramAttributes.general_ctrl
  local tAsicTyp = tPlugin:GetChiptyp()
  local tGeom = self:decode_sdram_geometry(ulGeneralCtrl, tAsicTyp)
  return tGeom
end



function RamTest:get_ram_area(tPlugin, atRamAttributes)
  local ulRamStart = nil
  local ulRamSize = nil

  local tInterface = atRamAttributes.interface

  if tInterface==self.INTERFACE_RAM then
    ulRamStart = atRamAttributes.ram_start
    ulRamSize = atRamAttributes.ram_size

  elseif tInterface==self.INTERFACE_SDRAM_HIF or tInterface==self.INTERFACE_SDRAM_MEM then
    local atInterface = self:get_sdram_interface_attributes(tPlugin, tInterface)
    ulRamStart = atInterface.ulArea_Start

    if atRamAttributes.size_exponent==nil then
      -- No -> get the size from the geometry parameters.
      local tGeom = self:get_sdram_geometry(tPlugin, atRamAttributes)
      ulRamSize = tGeom.ulSize
    else
      -- Yes -> ignore the geometry parameters.
      ulRamSize = math.pow(2, atRamAttributes.size_exponent)
    end

  elseif tInterface==self.INTERFACE_SRAM_HIF or tInterface==self.INTERFACE_SRAM_MEM then
    local ulChipSelect = atRamAttributes.sram_chip_select
    local atInterface = self:get_sram_interface_attributes(tPlugin, tInterface)
    ulRamStart = atInterface.aulArea_Start[ulChipSelect]
    ulRamSize = atRamAttributes.sram_size

  elseif tInterface==self.INTERFACE_DDR then
    local atInterface = self:get_ddr_interface_attributes(tPlugin)
    ulRamStart = atInterface.ulArea_Start

    -- Get the size from the exponent parameter.
    ulRamSize = math.pow(2, atRamAttributes.size_exponent)

  else
    error("Unknown interface ID:"..tInterface)
  end

  return ulRamStart, ulRamSize
end



function RamTest:get_ram_start(tPlugin, atRamAttributes)
  local ulRamStart, _ = self:get_ram_area(tPlugin, atRamAttributes)
  return ulRamStart
end



function RamTest:get_ram_size(tPlugin, atRamAttributes)
  local _, ulRamSize = self:get_ram_area(tPlugin, atRamAttributes)
  return ulRamSize
end



-- run the ram test
function RamTest:test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
  local tester = _G.tester

  -- Get the platform attributes for the chip type.
  local tChipType = tPlugin:GetChiptyp()
  local atChipAttributes = self.atPlatformAttributes[tChipType]
  if atChipAttributes==nil then
    error("Unknown chip type: ", tChipType)
  end

  -- Get the binary.
  local strBinaryName = string.format("netx/ramtest_%s.bin", atChipAttributes.strAsic)

  -- Construct the parameter.
  local aulParameter = {
    ulAreaStart,
    ulAreaSize,
    ulChecks,
    ulLoops,
    0,
    0,
    0,
    0,
    0
  }

  -- Install the binary.
  local ulResult = tester:mbin_simple_run(tPlugin, strBinaryName, aulParameter)
  return ulResult
end



-- wrapper: run ram test and abort on error
function RamTest:test_ram(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
  local ulResult = self:test_ram_noerror(tPlugin, ulAreaStart, ulAreaSize, ulChecks, ulLoops)
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

function RamTest:test_phase_parameters(tPlugin, atSdramAttributes, ulMaxLoops)
  local tLog = self.tLog
  local bit = self.bit

  -- Compare the chip type.
  self:compare_netx_version(tPlugin, atSdramAttributes)

  -- define test parameters
  -- clear bit 26-24 data_sample_phase
  -- clear bit 22-20 mem_sdclk_phase
  local timing_ctrl_base = bit.band(atSdramAttributes.timing_ctrl, 0xf88fffff)
  local ulSDRAMStart     = self:get_ram_start(tPlugin, atSdramAttributes)
  local ulSDRAMSize      = self:get_ram_size(tPlugin, atSdramAttributes)
  local ulChecks         = self.CHECK_08BIT + self.CHECK_16BIT + self.CHECK_32BIT + self.CHECK_BURST + self.CHECK_DATABUS + self.CHECK_CHECKERBOARD + self.CHECK_MARCHC + self.CHECK_SEQUENCE + self.CHECK_MEMCPY
  
  -- init the result matrix, define print function
  local aiTestResults = {}

  for iClockPhase = 0, 5 do
    aiTestResults[iClockPhase] = {}
  end

  -- run the test
  local ulLoops          = 1

  while ulLoops <= ulMaxLoops do
    for iClockPhase = 0, 5 do
      for iSamplePhase = 0, 5 do
        local ulPreviousResult = aiTestResults[iClockPhase][iSamplePhase]
        if ulPreviousResult ~= nil and ulPreviousResult ~= 0 then
          tLog.info(" ")
          tLog.info("======================================================================================")
          tLog.info("Clock phase: %d   Data sample phase: %d   Previous result: 0x%08x -- Skipping", iClockPhase, iSamplePhase, ulPreviousResult)
          tLog.info("======================================================================================")
          tLog.info(" ")

        else
          -- Timing Control:
          -- 22:20 MEM_SDCLK_PHASE 0-5
          -- 26:24 DATA_SAMPLE_PHASE 0-5
          local ulTiming =
            iClockPhase *     0x100000
            + iSamplePhase * 0x1000000
          atSdramAttributes.timing_ctrl = timing_ctrl_base + ulTiming

          tLog.info(" ")
          tLog.info("======================================================================================")
          tLog.info("Clock phase: %d   Data sample phase: %d   timing_ctrl: 0x%08x", iClockPhase, iSamplePhase, atSdramAttributes.timing_ctrl)
          tLog.info("Ram test loops %d times", ulLoops)
          tLog.info("======================================================================================")
          tLog.info(" ")

          self:setup_ram(tPlugin, atSdramAttributes)
          local ulResult = self:test_ram_noerror(tPlugin, ulSDRAMStart, ulSDRAMSize, ulChecks, ulLoops)
          aiTestResults[iClockPhase][iSamplePhase] = ulResult
          self:disable_ram(tPlugin, atSdramAttributes)

          tLog.info("Clock phase: %d   Data sample phase: %d   Result: 0x%08x", iClockPhase, iSamplePhase, ulResult)
          self:printPhaseTestResults(aiTestResults)
        end
      end
    end
    ulLoops = ulLoops * 2
  end

  return aiTestResults
end


function RamTest:printPhaseTestResults(aiTestResults)
  print(" ")
  print("--------------------+------------------")
  print("  Data sample phase:|  0  1  2  3  4  5")
  print("--------------------+------------------")
  for iClockPhase = 0, 5 do
    local strLine = string.format("Clock phase: %d      |", iClockPhase)
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
  print("--------------------+------------------")
  print("0 = Ok   1 = failed   - = not tested")
  print(" ")
end



-- Run the RAM test
-- parameters:
-- ulAreaStart
-- ulAreaSize
-- ulChecks
-- ulPerfTests
-- ulLoops
function RamTest:performance_test_run_ramtest(par)
  local tester = _G.tester
  local tLog = self.tLog
  local tPlugin = par.tPlugin
  -- Get the platform attributes for the chip type.
  local tChipType = tPlugin:GetChiptyp()
  local atChipAttributes = self.atPlatformAttributes[tChipType]
  if atChipAttributes==nil then
    error("Unknown chip type: ", tChipType)
  end

  local ulAreaStart       = par.ulAreaStart        or 0
  local ulAreaSize        = par.ulAreaSize         or 0
  local ulChecks          = par.ulChecks           or 0
  local ulLoops           = par.ulLoops            or 1
  local ulPerfTests       = par.ulPerfTests        or 0
  local ulRowSize         = par.ulRowSize          or 0
  local ulRefreshTime_clk = par.ulRefreshTime_clk  or 0

  tLog.info('')
  tLog.info("Call parameters:")
  tLog.info("ulAreaStart        0x%08x", ulAreaStart)
  tLog.info("ulAreaSize         0x%08x", ulAreaSize)
  tLog.info("ulChecks           0x%08x", ulChecks)
  tLog.info("ulPerfTests        0x%08x", ulPerfTests)
  tLog.info("ulLoops            0x%08x", ulLoops)
  tLog.info("ulRowSize          0x%08x", ulRowSize)
  tLog.info("ulRefreshTime_clk  0x%08x", ulRefreshTime_clk)
  tLog.info('')

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
  for _=1, 32 do
    table.insert(aulParameter, "OUTPUT")
  end

  -- Get the binary.
  local strBinaryName = string.format("netx/ramtest_%s.bin", atChipAttributes.strAsic)

  -- Install the binary.
  local ulResult = tester.mbin_simple_run(nil, tPlugin, strBinaryName, aulParameter)

  local aulTimes = {}
  for i=1, 32 do
    aulTimes[i] = aulParameter[iParLen+i]
  end

  return ulResult, aulTimes
end



function RamTest:vector_scale(v, factor)
  local vres = {}
  for i, comp in pairs(v) do
    vres[i] = comp*factor
  end
  return vres
end



function RamTest:vector_add(v1, v2)
  local vres = {}
  for i, comp1 in pairs(v1) do
    vres[i] = comp1+v2[i]
  end
  return vres
end



function RamTest:vector_subtract(v1, v2)
  return self:vector_add(v1, self:vector_scale(v2, -1))
end



function RamTest:vector_shift0(v)
  local vres = {}
  for i, comp in pairs(v) do
    vres[i-1] = comp
  end
  return vres
end



-- Takes an array of arrays of values and 
-- calculates, the min, avg and max across all subtables
function RamTest:vector_min_avg_max(aVectors)
  local aMin = {}
  local aMax = {}
  local aAvg = {}
  local aAvgCnt = {}

  for _, v in pairs(aVectors) do
    for j, comp in pairs(v) do
      aMin[j] = math.min(aMin[j] or comp, comp)
      aMax[j] = math.max(aMax[j] or 0, comp)
      aAvg[j] = (aAvg[j] or 0) + comp
      aAvgCnt[j] = (aAvgCnt[j] or 0) + 1
    end
  end

  for i in pairs(aAvg) do
    aAvg[i] = aAvg[i] / aAvgCnt[i]
  end

  return aMin, aMax, aAvg
end


-- print time array
function RamTest:performance_test_print_times(aulTimes)
  local tLog = self.tLog
  local t = aulTimes
  tLog.info("Times in microseconds:")
  tLog.info("                           8 Bit     16 Bit     32 Bit    256 Bit")
  tLog.info("sequential read       %10.3f %10.3f %10.3f %10.3f ", t[ 0],   t[ 1],   t[ 2],    t[ 3])
  tLog.info("sequential write      %10.3f %10.3f %10.3f %10.3f ", t[ 4],   t[ 5],   t[ 6],    t[ 7])
  tLog.info("sequential read/write %10.3f %10.3f %10.3f %10.3f ", t[ 8],   t[ 9],   t[10],    t[11])
  tLog.info("row read              %10.3f %10.3f %10.3f %10.3f ", t[13],   t[14],   t[15],    t[16])
  tLog.info("row write             %10.3f %10.3f %10.3f %10.3f ", t[17],   t[18],   t[19],    t[20])
  tLog.info("row read/write        %10.3f %10.3f %10.3f %10.3f ", t[21],   t[22],   t[23],    t[24])
  tLog.info("sequential NOP Thumb  %10.3f", t[12])
  tLog.info("row-to-row jump Thumb %10.3f", t[25])
end

function RamTest:performance_test_print_times_min_avg_max_dif(tmin, tavg, tmax, tdif)
  local tLog = self.tLog
  tLog.info("Times in microseconds:")
  tLog.info("                           8 Bit     16 Bit     32 Bit    256 Bit")
  tLog.info("sequential read       %10.3f %10.3f %10.3f %10.3f Min", tmin[ 0],   tmin[ 1],   tmin[ 2],    tmin[ 3])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 0],   tavg[ 1],   tavg[ 2],    tavg[ 3])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 0],   tmax[ 1],   tmax[ 2],    tmax[ 3])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 0],   tdif[ 1],   tdif[ 2],    tdif[ 3])
  tLog.info('')
  tLog.info("sequential write      %10.3f %10.3f %10.3f %10.3f Min", tmin[ 4],   tmin[ 5],   tmin[ 6],    tmin[ 7])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 4],   tavg[ 5],   tavg[ 6],    tavg[ 7])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 4],   tmax[ 5],   tmax[ 6],    tmax[ 7])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 4],   tdif[ 5],   tdif[ 6],    tdif[ 7])
  tLog.info('')
  tLog.info("sequential read/write %10.3f %10.3f %10.3f %10.3f Min", tmin[ 8],   tmin[ 9],   tmin[10],    tmin[11])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[ 8],   tavg[ 9],   tavg[10],    tavg[11])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[ 8],   tmax[ 9],   tmax[10],    tmax[11])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[ 8],   tdif[ 9],   tdif[10],    tdif[11])
  tLog.info('')
  tLog.info("row read              %10.3f %10.3f %10.3f %10.3f Min", tmin[13],   tmin[14],   tmin[15],    tmin[16])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[13],   tavg[14],   tavg[15],    tavg[16])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[13],   tmax[14],   tmax[15],    tmax[16])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[13],   tdif[14],   tdif[15],    tdif[16])
  tLog.info('')
  tLog.info("row write             %10.3f %10.3f %10.3f %10.3f Min", tmin[17],   tmin[18],   tmin[19],    tmin[20])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[17],   tavg[18],   tavg[19],    tavg[20])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[17],   tmax[18],   tmax[19],    tmax[20])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[17],   tdif[18],   tdif[19],    tdif[20])
  tLog.info('')
  tLog.info("row read/write        %10.3f %10.3f %10.3f %10.3f Min", tmin[21],   tmin[22],   tmin[23],    tmin[24])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Avg", tavg[21],   tavg[22],   tavg[23],    tavg[24])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Max", tmax[21],   tmax[22],   tmax[23],    tmax[24])
  tLog.info("                      %10.3f %10.3f %10.3f %10.3f Dif", tdif[21],   tdif[22],   tdif[23],    tdif[24])
  tLog.info('')
  tLog.info("sequential NOP Thumb  %10.3f Min", tmin[12])
  tLog.info("                      %10.3f Avg", tavg[12])
  tLog.info("                      %10.3f Max", tmax[12])
  tLog.info("                      %10.3f Dif", tdif[12])
  tLog.info('')
  tLog.info("row-to-row jump Thumb %10.3f Min", tmin[25])
  tLog.info("                      %10.3f Avg", tavg[25])
  tLog.info("                      %10.3f Max", tmax[25])
  tLog.info("                      %10.3f Dif", tdif[25])
end

-- Run the performance test
function RamTest:run_performance_test(tPlugin, atSdramAttributes, ulAreaStart, ulAreaSize, ulPerfTests)
  local bit = self.bit
  local tLog = self.tLog

  -- Get the row size
  local tGeometry = self:get_sdram_geometry(tPlugin, atSdramAttributes)
  local ulRowSize = tGeometry.ulRowSize
  
  -- Get the array refresh time
  local ulTimingCtrl = atSdramAttributes.timing_ctrl
  local ult_REFI    = 3.9 * bit.lshift(1, bit.rshift(bit.band(ulTimingCtrl, 0x00030000), 16))
  local ulArrayRefreshTime_us = ult_REFI * tGeometry.ulRows * tGeometry.ulBanks
  local ulRefreshTime_clk = ulArrayRefreshTime_us * 100
  tLog.info('')
  tLog.info("t_REFI: %3.2f microseconds", ult_REFI)
  tLog.info("Array refresh time: %5.2f ms, %d * 10ns clocks", ulArrayRefreshTime_us/1000, ulRefreshTime_clk)
  tLog.info('')
  
  -- Do a calibration run using intram
  local ulCalibrationAreaStart = 0x10000
  local ulResult, aulCalibrationTimes
  if ulCalibrationAreaStart then
    ulResult, aulCalibrationTimes = self:performance_test_run_ramtest{tPlugin=tPlugin, ulAreaStart=ulCalibrationAreaStart, ulAreaSize=ulAreaSize, ulPerfTests=ulPerfTests,
    ulRowSize = ulRowSize, ulRefreshTime_clk=ulRefreshTime_clk}
    aulCalibrationTimes = self:vector_shift0(aulCalibrationTimes)
    aulCalibrationTimes = self:vector_scale(aulCalibrationTimes, 0.01)
    
  end

  -- Execute the tests
  local iLoops = 10
  local aaulTimes = {}
  for iLoop = 1, iLoops do
    local ulResult, aulTimes = self:performance_test_run_ramtest{tPlugin=tPlugin, ulAreaStart=ulAreaStart, ulAreaSize=ulAreaSize, ulPerfTests=ulPerfTests,
    ulRowSize = ulRowSize, ulRefreshTime_clk=ulRefreshTime_clk}
    print("Result: ", ulResult)
    aulTimes = self:vector_shift0(aulTimes)
    aulTimes = self:vector_scale(aulTimes, 0.01)
    self:performance_test_print_times(aulTimes)
    print()
    aaulTimes[iLoop] = aulTimes
  end

  -- Print the results
  if iLoops == 1 then
    tLog.info("Start address: 0x%08x", ulAreaStart)
    tLog.info("Area size:     0x%08x", ulAreaSize)
    tLog.info('')
    local aulTimes = aaulTimes[1]
    self:performance_test_printf_ul("-", "Times using SDRAM:")
    self:performance_test_print_times(aulTimes)
    tLog.info('')
    self:performance_test_printf_ul("-", "Times using Intram:")
    self:performance_test_print_times(aulCalibrationTimes)
    tLog.info('')
    self:performance_test_printf_ul("-", "Times SDRAM - Intram:")
    aulTimes = self:vector_subtract(aulTimes, aulCalibrationTimes)
    self:performance_test_print_times(aulTimes)
  else
    tLog.info("Start address: 0x%08x", ulAreaStart)
    tLog.info("Area size:     0x%08x", ulAreaSize)
    tLog.info('')
    self:performance_test_printf_ul("-", "Times using SDRAM:")
    local tmin, tmax, tavg = self:vector_min_avg_max(aaulTimes)
    local tdif = self:vector_subtract(tmax, tmin)
    self:performance_test_print_times_min_avg_max_dif(tmin, tavg, tmax, tdif)
    tLog.info('')
    self:performance_test_printf_ul("-", "Times using Intram:")
    self:performance_test_print_times(aulCalibrationTimes)
    tLog.info('')
    self:performance_test_printf_ul("-", "Times SDRAM - Intram:")
    tmin = self:vector_subtract(tmin, aulCalibrationTimes)
    tavg = self:vector_subtract(tavg, aulCalibrationTimes)
    tmax = self:vector_subtract(tmax, aulCalibrationTimes)
    self:performance_test_print_times_min_avg_max_dif(tmin, tavg, tmax, tdif)

  end
end


return RamTest
