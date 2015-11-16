--	seed =     ((((seed >> 31)
--				^ (seed >> 6)
--				^ (seed >> 4)
--				^ (seed >> 1)
--				^  seed)
--			    &  0x00000001)
--			    << 31)
--			    | (seed>>1);

package.cpath = arg[-1] .. "/../../lua_plugins/?.dll;" .. package.cpath
require("bit")

local r, b0, b1, b4, b6, b31, b

r = 314159265 -- seed
t = {}
i = 0

while true do
	i = i + 1
	print(string.format("%6d  0x%08x", i, r))
	
	if t[r] then
		error("Repeat")
	else
		t[r] = true
	end
	
	b0 =  bit.band(r,                 1)
	b1 =  bit.band(bit.rshift(r, 1),  1)
	b4 =  bit.band(bit.rshift(r, 4),  1)
	b6 =  bit.band(bit.rshift(r, 6),  1)
	b31 = bit.band(bit.rshift(r, 31), 1)
	b = bit.bxor(
				bit.bxor(
					bit.bxor(b0, b1),
					bit.bxor(b4, b6)
				),
				b31
			)
			
	--print(b0, b1, b4, b6, b31, b)
	--print(b)
	r = bit.bor(
				bit.rshift(r, 1),
				bit.lshift(b, 31)
			)
end

