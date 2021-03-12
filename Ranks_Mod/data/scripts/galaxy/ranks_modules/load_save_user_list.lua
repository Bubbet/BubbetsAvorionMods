package.path = package.path .. ";data/scripts/lib/?.lua"
include("tabletofile")
Load_Save_User_List = {} -- Yes, this could be handled by the galaxy scripts secure and restore, but i'd much rather still have it on disk so external programs can look at it.

function Load_Save_User_List:forceload(rank)
	self.namespace.rank[rank] = table.load(Server().folder.. "/moddata/Ranks/" .. rank .. ".lua") or {}
	return self.namespace.rank[rank]
end

function Load_Save_User_List:load(rank)
	if not self.namespace.rank[rank] then self:forceload(rank) end
	return self.namespace.rank[rank]
end

function Load_Save_User_List:save(rank)
	return table.save(self.namespace.rank[rank], Server().folder.. "/moddata/Ranks/" .. rank .. ".lua")
end

function Load_Save_User_List:initialize()
	for k, _ in pairs(self.namespace.files) do
		self:load(k)
	end
end

function Load_Save_User_List:__call(namespace)
	self.namespace = namespace
	self.loadorder = 1
	self.namespace.forceload = function(rank) return self:forceload(rank) end -- forward the function to the main module
	self.namespace.load = function(rank) return self:load(rank) end
	self.namespace.save = function(rank) return self:save(rank) end
end

return setmetatable({}, {__index = Load_Save_User_List, __call = Load_Save_User_List.__call})
