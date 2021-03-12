Rank_Info = {}

function Rank_Info:findRank(rank)
	for k, v in pairs(self.namespace.rank) do
		if string.find(k, rank) then
			return v
		end
	end
end

function Rank_Info:listUsers(rank)
	return self.namespace.rank[rank]
end

function Rank_Info:__call(namespace)
	self.namespace = namespace
	self.namespace.findRank = function(rank) return self:findRank(rank) end
	self.namespace.listUsers = function(rank) return self:listUsers(rank) end
end

return setmetatable({}, {__index = Rank_Info, __call = Rank_Info.__call})