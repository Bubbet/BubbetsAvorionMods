package.path = package.path .. ";data/scripts/ranks/?.lua"
Load_Rank_From_Disk = {}

function Load_Rank_From_Disk:reloadRank(path)
	local err, file = pcall(function(this, rank) return dofile(this.path .. rank .. ".lua") end, self, path)
	if err then self.namespace.files[path] = file else
		print('[Ranks] Failed to reload rank file: ', path, file)
	end
	return file ~= nil
end

function Load_Rank_From_Disk:initialize()
	self.path = self.namespace.server.folder .. '/moddata/Ranks/Ranks/'

	for _, id in pairs({self.namespace.manager:getEnabledMods()}) do
		for k, v in pairs({listFilesOfDirectory(self.namespace.manager:find(id).folder:gsub("\\","/") .. "data/scripts/ranks/")}) do
			local temp = {}
			for value, _ in v:gmatch("%w+") do -- Really wish there was a method in lua to do this for me
				table.insert(temp, value)
			end
			self.namespace.files[temp[#temp-1]] = include(temp[#temp-1])
		end
	end

	for _, v in pairs({listFilesOfDirectory(self.path)}) do
		local tar = string.sub(v, #self.path+1, -5)
		--print('trying', tar)
		local err, val = pcall(dofile, v)
		--printTable(type(val) =='table' and val or {empty=true}, (err and 'true ' or 'false ') .. tar)
		if err then self.namespace.files[tar] = val else
			print('[Ranks] Failed to load rank file: ', v, val)
		end
	end
end

function Load_Rank_From_Disk:__call(namespace)
	self.namespace = namespace
	self.loadorder = 0
	self.namespace.reloadRank = function(rank) return self:reloadRank(rank) end -- forward the function to the main module
end

return setmetatable({}, {__index = Load_Rank_From_Disk, __call = Load_Rank_From_Disk.__call})
