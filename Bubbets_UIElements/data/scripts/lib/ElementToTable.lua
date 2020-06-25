Element_New_Meta = {
	__index = function(self, ind)
		return self.element[ind] or rawget(self, ind)
	end,
	__newindex = function(self, ind, val)
		local _, ret = pcall(function(this, ind, val)
			this.element[ind] = val
			return this.element[ind]
		end, self, ind, val)
		if not ret then
			print('The following error is not causing any issues, ignore it.')
			rawset(self, ind, val)
		end
	end
}

--- @param element UIElement @Any UI element to be converted to a table
function ElementToTable(element)
	local x = {element = element, children = {}}
	for k, v in pairs(getmetatable(element)) do
		if string.find(k, 'create') then
			x[k] = function(self, ...)
				local elem = ElementToTable(v(self.element, ...))
				table.insert(self.children, elem)
				rawset(elem, 'parent', self)
				return elem
			end
		elseif not string.find(k, 'index') then
			x[k] = function(self, ...)
				return v(self.element, ...)
			end
		end
	end
	setmetatable(x, Element_New_Meta)
	return x
end

--[[function ElementToTable(element)
	local x = {element = element, children = {}}
	local old_meta = getmetatable(element)
	local new_meta = {}
	for k, v in pairs(old_meta) do
		if string.find(k, 'create') then
			new_meta[k] = function(self, ...)
				local elem = ElementToTable(v(self.element, ...))
				table.insert(self.children, elem)
				elem.parent = self
				return elem
			end
		else
			new_meta[k] = function(self, ...)
				return v(self.element, ...)
			end
		end
	end
	new_meta.__index = function(self, ind)
		local suc, ret = pcall(old_meta.__index, self.element, ind)
		if not suc then
			ret = rawget(self, ind)
		end
		return ret
	end
	new_meta.__newindex = function(self, ind, val)
		local suc, ret = pcall(old_meta.__newindex, self.element, ind, val)
		if not suc then
			ret = rawset(self, ind, val)
		end
		return ret
	end
	setmetatable(x, new_meta)
	return x
end]]