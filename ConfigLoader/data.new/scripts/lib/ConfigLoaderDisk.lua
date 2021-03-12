package.path = package.path .. ";data/scripts/lib/?.lua"
local disk = include("tabletofile")
--include("utility")

--namespace ConfigLoaderDisk
ConfigLoaderDisk = {configs = {}}

function ConfigLoaderDisk:mergeConfigs(base, new)
    if new then
        for k, v in pairs(new) do
            if type(v) ~= type(base[k]) then
                --print('overwriting value', k, (type(v) == 'table') and 'table' or v, (type(base[k]) == 'table') and 'table' or base[k], type(v), type(base[k]))
                base[k] = v
            elseif type(v) == 'table' then
                --print('table found', k)
                base[k] = self:mergeConfigs(base[k], v)
            end
        end
    end
    return base
end

--[[
function ConfigLoaderDisk:mergeConfigs(modconfig, defaultconfig) -- Recursive function for when it finds tables
    if defaultconfig then
        for k, v in pairs(defaultconfig) do
            if type(v) ~= type(modconfig[k]) then --modconfig == nil then copy
                modconfig[k] = v
            elseif type(v) == "table" then -- fix table nesting
                modconfig[k] = self:mergeConfigs(v, modconfig[k])
            end
        end
    end
    return modconfig
end
]]

function getfunctions(dir, m) -- for some reason this wouldn't import from tabletofile
    local ifile = io.open(dir, 'r')
    local sfile = ifile:read('*all')
    local meta = getmetatable(m) or {}
    for k, v in pairs(m) do
        if type(v) == 'table' then
            for k1, v1 in pairs(getfunctions(dir, v)) do
                meta[k1] = v1 -- Rough recursion fix
            end
        end
        if type(v) == 'function' then
            local _, s = string.find(sfile, k..'%W')
            local _, e = string.find(sfile, "end,", s)
            local subs = string.sub(sfile, s, e)
            meta[k] = string.match(subs, 'function.*end')
        end
    end
    ifile:close()
    return meta
end

function ConfigLoaderDisk:getLocalConfig(mod) -- gets all the files in scripts/config/ for a mod and merges them into one array
    local config = {}
    local meta = {}
    for k, v in pairs({listFilesOfDirectory(mod.folder:gsub("\\","/") .. "data/scripts/config/")}) do
        local file = dofile(v)
        self:mergeConfigs(meta, getfunctions(v, file))
        self:mergeConfigs(config, file)
    end
    setmetatable(config, meta)
    return config
end

function ConfigLoaderDisk:getConfigFromDisk(dir, mod)
    if onClient() then return self:getLocalConfig(mod) end -- Should only ever be called for locals anyways, and this avoids saving the compiled modconfig on the clients moddata
    if not self.configs[mod.name] then
        createDirectory(dir)
        local file = dir .. "/" .. mod.name .. ".lua"
        local defaultconfig = self:getLocalConfig(mod)
        local defaultmeta = getmetatable(defaultconfig)
        --print('__default')
        --printTable(defaultmeta)
        --print('path = ', file)
        self.configs[mod.name] = disk.load(file)
        if not self.configs[mod.name] then self.configs[mod.name] = {} end -- TODO investigate why this is nil or {} -- or defaultconfig or {}
        local modmeta = getmetatable(self.configs[mod.name]) or {}
        --print('__modmeta')
        --printTable(modmeta)
        --print('__enddone')
        self:mergeConfigs(modmeta, defaultmeta)
        self:mergeConfigs(self.configs[mod.name], defaultconfig)
        setmetatable(self.configs[mod.name], modmeta)
        --print('saving table')
        --printTable(modmeta)
        disk.save(self.configs[mod.name], file)
        self.configs[mod.name].___funcs = modmeta
    end
    return self.configs[mod.name]
end

function ConfigLoaderDisk:getAllConfigs(dir)
    if onServer() then
        local manager = ModManager()
        for _, id in pairs({manager:getEnabledMods()}) do
            local mod = manager:find(id)
            if listFilesOfDirectory(mod.folder:gsub("\\","/") .. "data/scripts/config/") then
                print('found configs for', mod.name, 'preloading them')
                self:getConfigFromDisk(dir, mod)
            end
        end
    end
end

function ConfigLoaderDisk:getConfig(dir, path)
    local manager = ModManager()
    local config = {}
    local meta = {}
    for _, id in pairs(manager:getModsModifyingFile(path)) do
        local fromdisk = self:getConfigFromDisk(dir, manager:find(id))
        local metadisk = getmetatable(fromdisk)
        self:mergeConfigs(meta, metadisk)
        self:mergeConfigs(config, fromdisk)
    end
    setmetatable(config, meta)
    --[[
    print(onClient(), '_config')
    printTable(config)
    print('_meta')
    printTable(meta)
    print('_finish')
    ]]
    config.___funcs = meta
    return config
end

return ConfigLoaderDisk