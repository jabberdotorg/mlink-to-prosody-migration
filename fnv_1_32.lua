
function fnv_1_32(s)
	local hash = 2166136261;
	for i=1,#s do
		hash = hash
			+ bit32.lshift(hash, 1)
			+ bit32.lshift(hash, 4)
			+ bit32.lshift(hash, 7)
			+ bit32.lshift(hash, 8)
			+ bit32.lshift(hash, 24);
		hash = bit32.bxor(hash, s:byte(i));
	end
	return hash;
end
-- FIXME how to handle unicode? As UTF-8?
