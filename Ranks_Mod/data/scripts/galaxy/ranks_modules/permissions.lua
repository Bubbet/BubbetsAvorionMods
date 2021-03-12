
Permissions = {}

function Permissions:hasrank(rank, id)
	if rank == "default" then return true end
	local exists = false
	self.namespace.load(rank)
	for k, _ in pairs(self.namespace.rank[rank]) do
		if k == id then exists = true end
	end
	return exists
end

function Permissions:checkList(check, id, ...)
	local args = {...}
	local temp = {}
	local haspermission = false
	for rank, v in pairs(self.namespace.files) do -- ["rank"] should already be initalized by this point
		if self:hasrank(rank, id) then
			if v[check] then
				if #v[check] > 0 then haspermission = true end
				for _, privilege in pairs(v[check]) do
					temp[privilege] = true
				end
			end
		end
	end
	for _, privilege in pairs(args) do
		if not temp[privilege] then
			haspermission = false
		end
	end
	return haspermission
end

function Permissions:findBestPower(id)
	local bestrank = math.huge
	for k, v in pairs(self.namespace.files) do
		if self:hasrank(k, id) then
			if v.power < bestrank then bestrank = v.power end
		end
	end
	return bestrank -- returns highest power level
end

function Permissions:hasPowerOver(id1, id2)
	return self:findBestPower(id1) < self:findBestPower(id2)
end

function Permissions:hasPowerOverWithRank(sender, target, rank)
	if not target then
		return self:findBestPower(sender) < self.namespace.files[rank or "default"].power
	else
		return self:hasPowerOver(sender, target) and (self:findBestPower(sender) < self.namespace.files[rank or "default"].power)
	end
end

function Permissions:listPlayerPrivileges(id)
	local privileges = {}
	for rank, v in pairs(self.namespace.files) do -- ["rank"] should already be initalized by this point
		if self:hasrank(rank, id) then
			if not v.privileges then return print('no privileges in rank', rank) end
			for _, privilege in pairs(v.privileges) do
				privileges[privilege] = true
			end
		end
	end
	return privileges
end

function Permissions:listUsersRanks(id)
	local temp = {}
	for k, v in pairs(self.namespace.files) do
		if self:hasrank(k, id) or not id then
			table.insert(temp, k)
		end
	end
	return temp
end

function Permissions:listUsersRanksFiles(id)
	local temp = {}
	for k, v in pairs(self.namespace.files) do
		if self:hasrank(k, id) or not id then
			table.insert(temp, v)
		end
	end
	return temp
end

function Permissions:getRankValue(id, val)
	local ranks = self:listUsersRanksFiles(id)
	table.sort(ranks, function(a,b) return a.power<b.power end)
	for _, v in pairs(ranks) do
		if v[val] then return v[val] end
	end
end

function Permissions:__call(namespace)
	self.namespace = namespace
	self.loadorder = 2
	self.namespace.hasrank = function(rank, id) return self:hasrank(rank, id) end
	self.namespace.hasPrivilege = function(id, ...) return self:checkList("privileges", id, ...) end
	self.namespace.canCommand = function(id, ...) return self:checkList("commands", id, ...) end
	self.namespace.hasPowerOverWithRank = function(...) return self:hasPowerOverWithRank(...) end
	self.namespace.listPlayerPrivileges = function(...) return self:listPlayerPrivileges(...) end
	self.namespace.listUsersRanks = function(...) return self:listUsersRanks(...) end
	self.namespace.getRankValue = function(...) return self:getRankValue(...) end
end

return setmetatable({}, {__index = Permissions, __call = Permissions.__call})
