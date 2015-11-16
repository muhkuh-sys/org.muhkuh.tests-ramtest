package.cpath = arg[-1] .. "/../../lua_plugins/?.dll;" .. package.cpath
require("bit")

strUsage = [[
Usage: lua lfsr_gen.lua seed width length
	seed:   32 bit seed value.
	width:  8/16/32 bits
	length: number of values to generate
	
Example: lua lfsr2.lua 414505433 32 4096
]]

--	ulRandom = ((((ulRandom >> 31)
--				^ (ulRandom >> 6)
--				^ (ulRandom >> 4)
--				^ (ulRandom >> 1)
--				^  ulRandom)
--				&  0x00000001)
--				<< 31)
--				| (ulRandom>>1);

function lfsr(r)
	local b0, b1, b4, b6, b31, b
	b0 =  bit.band(r,                 1)
	b1 =  bit.band(bit.rshift(r, 1),  1)
	b4 =  bit.band(bit.rshift(r, 4),  1)
	b6 =  bit.band(bit.rshift(r, 6),  1)
	b31 = bit.band(bit.rshift(r, 31), 1)
	b = bit.bxor(bit.bxor(bit.bxor(bit.bxor(b0, b1), b4), b6), b31)
	r = bit.bor(
				bit.rshift(r, 1),
				bit.lshift(b, 31)
			)
	return r
end

if #arg ~= 3 then
	print(strUsage)
else
	local ulSeed = tonumber(arg[1])
	local iWidth = tonumber(arg[2])
	local iLength = tonumber(arg[3])
	
	local ulMask
	local strFormat
	local iAddrSize
	if iWidth == 8 then
		ulMask = 0xff
		strFormat = "0x%08x 0x%02x"
		iAddrSize = 1
	elseif iWidth ==16 then
		ulMask = 0xffff
		strFormat = "0x%08x 0x%04x"
		iAddrSize = 2
	elseif iWidth == 32 then
		ulMask = 0xffffffff
		strFormat = "0x%08x 0x%08x"
		iAddrSize = 4
	else
		error ("invalid width")
	end
	
	local t = {}
	local ulRandom = ulSeed
	for iAddr=0, iLength-1, iAddrSize do
		ulRandom = lfsr(ulRandom)
		assert(t[ulRandom] == nil, "random generator repeating")
		t[ulRandom] = true
		uData = bit.band(ulRandom, ulMask)
		print(string.format(strFormat, iAddr, uData))
	end

end
