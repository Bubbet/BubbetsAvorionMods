
User_Manipulation = {}

function User_Manipulation:adduser(rank, name, id)
	self.namespace.load(rank)
	self.namespace.rank[rank][id] = name

	local save = self.namespace.save(rank)
	return not save and self.namespace.rank[rank][id] and true or false -- success or fail
end

function User_Manipulation:removeuser(rank, id)
	local output = 0
	if self.namespace.hasrank(rank, id) then
		local temp = {}
		for k, v in pairs(self.namespace.rank[rank]) do
			if k ~= id then
				temp[k] = v
			end
		end
		self.namespace.rank[rank] = temp

		local save = self.namespace.save(rank)

		output = not save and not self.namespace.rank[rank][id] and 1 or 0 -- success or fail
	else
		output = 2
	end -- TODO here and adduser update their permissions with invoke if they're in-game
	return output
end

function User_Manipulation:__call(namespace)
	self.namespace = namespace
	self.namespace.adduser = function(rank, name, id) return self:adduser(rank, name, id) end -- forward the function to the main module
	self.namespace.removeuser = function(rank, id) return self:removeuser(rank, id) end
end

return setmetatable({}, {__index = User_Manipulation, __call = User_Manipulation.__call})
