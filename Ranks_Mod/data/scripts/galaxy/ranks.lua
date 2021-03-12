package.path = package.path .. ";data/scripts/galaxy/ranks_modules/?.lua"

-- namespace Ranks
Ranks = {files = {}, rank = {}, mail = {}, daily = {}, data = {}, modules = {}}

-- Load modules
local dir = string.sub(scriptPath(), 0, -10) .. 'ranks_modules'
for _, v in pairs({listFilesOfDirectory(dir)}) do
	local tar = string.sub(v, #dir+2, -5) -- name of module
	local ind = #Ranks.modules + 1
	Ranks.modules[ind] = {module = include(tar), name = tar}
	if Ranks.modules[ind] then
		local err, val = pcall(Ranks.modules[ind].module.__call, Ranks.modules[ind].module, Ranks)
		if not err then print('[Ranks] Failed to set namespace of module: ', tar, val) end
	end
end
table.sort(Ranks.modules, function(a, b)
	return ((a.module.loadorder and b.module.loadorder) and (a.module.loadorder < b.module.loadorder)) or (a.module.loadorder and not b.module.loadorder)
end)
print('[Ranks] Modules loaded in order: ')
for k, v in pairs(Ranks.modules) do
	print(k, v.name)
end

function Ranks.secure()
	Ranks.data.modules_data = {}
	for _, _v in pairs(Ranks.modules) do
		local k, v = _v.name, _v.module
		if v.secure then
			local err, val = pcall(v.secure, v)
			if err then
				Ranks.data.modules_data[k] = val
			else
				print('[Ranks] Failed to secure(save data of) module: ', k, val)
			end
		end
	end
	return Ranks.data
end

function Ranks.restore(data)
	Ranks.data = data
	for _, _v in pairs(Ranks.modules) do
		local k, v = _v.name, _v.module
		if v.restore and Ranks.data.modules_data[k] then
			local err, val = pcall(v.restore, v, Ranks.data.modules_data[k])
			if not err then print('[Ranks] Failed to restore(load data of) module: ', k, val) end
		end
	end
end

function Ranks.initialize()
	Ranks.server = Server()
	Ranks.galaxy = Galaxy()
	Ranks.manager = ModManager()
	for _, _v in pairs(Ranks.modules) do
		local k, v = _v.name, _v.module
		if v.initialize then
			local err, val = pcall(v.initialize, v)
			if not err then print('[Ranks] Failed to initialize module: ', k, val) end
		end
	end
	print("RANKS \n\n\nINITIALIZE \n\n\nFINISHED")
end
