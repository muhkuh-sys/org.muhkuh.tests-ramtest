local class = require 'pl.class'
local ApplyOptions = class()

function ApplyOptions:_init()
  self.bit = require 'bit'
  self.pl = require'pl.import_into'()
  self.vstruct = require "vstruct"
end



function ApplyOptions:__read_image(strFile)
  -- Read the file.
  local strStandaloneImage, strError = self.pl.utils.readfile(strFile, true)
  if strStandaloneImage==nil then
    error(string.format('Failed to read the standalone option file "%s": %s', strFile, strError))
  end

  local tImage = {
    strHeader = string.sub(strStandaloneImage, 1, 65),
    strImage = string.sub(strStandaloneImage, 65)
  }
  return tImage
end



function ApplyOptions:__check_bootheader(tImage)
  local bit = self.bit

  -- Parse the standalone DDR parameter file.
  local strFormatBootHeader = [[
ulMagic:u4
aulReserved04:{3*u4}
ulImageSizeDw:u4
ulReserved14:u4
ulSignature:u4
ulReserved1c:u4
aulImageSha:{7*u4}
ulHeaderChecksum:u4
]]
  local tBootHeader = self.vstruct.read(strFormatBootHeader, tImage.strHeader)

  -- Some basic header checks.
  local ulMagic = 0xf3beaf00
  local ulSignature = 0x484f4f4d
  if tBootHeader.ulMagic~=ulMagic then
    error(string.format('The standalone option file does not start with the magic 0x%08x, but 0x%08x. Is this really a standalone option file?', ulMagic, tBootHeader.ulMagic))
  end
  if tBootHeader.ulSignature~=ulSignature then
    error(string.format('The standalone option file has an invalid magic of 0x%08x. The expected magic is 0x%08x.', tBootHeader.ulSignature, ulSignature))
  end

  -- Test the header checksum.
  local strFormatChecksumHeader = [[
aulData:{15*u4}
ulHeaderChecksum:u4
]]
  local tChecksumHeader = self.vstruct.read(strFormatChecksumHeader, tImage.strHeader)
  local ulChecksum = 0
  for _, ulValue in ipairs(tChecksumHeader.aulData) do
    ulChecksum = bit.band(ulChecksum + ulValue, 0xffffffff)
  end
  ulChecksum = bit.bxor(ulChecksum-1, 0xffffffff)
  if bit.tobit(tBootHeader.ulHeaderChecksum)~=ulChecksum then
    error(string.format('The standalone option file has an invalid header checksum of 0x%08x. The correct header checksum is 0x%s.', tBootHeader.ulHeaderChecksum, bit.tohex(ulChecksum)))
  end
end



function ApplyOptions:__check_option_chunk(tImage)
  -- Parse the chunk header.
  local strFormatHBootHdr = [[
ulID:u4,
ulChunkSizeInDW:u4
]]
  local tHdr = self.vstruct.read(strFormatHBootHdr, tImage.strImage)

  -- The image must start with an "OPTS" header.
  if tHdr.ulID~=0x5354504f then
    error(string.format('The standalone option file does not start with an "OPTS" chunk, but with 0x%08x.', tHdr.ulID))
  end

  if tHdr.ulChunkSizeInDW==0 then
    error('The chunk has a size of 0 which is invalid.')
  end

  if string.len(tImage.strImage)<(4*(tHdr.ulChunkSizeInDW+2)) then
    error('The file is too small.')
  end

  -- Extract the data of the "OPTS" chunk.
  local strFormatOptsChunk = string.format([[
ulID:u4,
ulChunkSizeInDW:u4
strData:s%d
strHash:s%d
]], (tHdr.ulChunkSizeInDW-1)*4, 1*4)
  print(strFormatOptsChunk)
  local tOpts = self.vstruct.read(strFormatOptsChunk, tImage.strImage)
  self.pl.pretty.dump(tOpts)

  -- TODO: Test the checksum of the chunk.

  -- Add the data of the option chunk.
  tImage.strOptions = tOpts.strData
end



function ApplyOptions:parse(strFile)
  local tImage = self:__read_image(strFile)
  self:__check_bootheader(tImage)
  self:__check_option_chunk(tImage)
  return tImage.strOptions
end


return ApplyOptions
