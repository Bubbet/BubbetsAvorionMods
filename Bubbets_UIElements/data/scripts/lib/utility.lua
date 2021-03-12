function pairsByValues(t)
	local a = {}
	for k, v in pairs(t) do table.insert(a, {ind = k, val = v}) end
	table.sort(a, function(a, b) return a.val > b.val end)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i].ind, a[i].val
		end
	end
	return iter
end

function table.find(self, value, func)
	if not func then
		func = function(k, v, val)
			return v == val
		end
	end
	for k, v in pairs(self) do
		if func(k, v, value) then
			return k, v
		end
	end
end
