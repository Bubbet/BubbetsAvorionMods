package.path = package.path .. ";data/scripts/lib/?.lua"
include("tabletofile")

--namespace ConfigLoaderDisk
ConfigLoaderDisk = {}

function ConfigLoaderDisk:mergeConfigs(defaultconfig, modconfig) -- Recursive function for when it finds tables
  for k, v in pairs(defaultconfig) do
    if type(v) ~= type(modconfig[k]) then --modconfig == nil then copy
      modconfig[k] = v
    elseif type(v) == "table" then -- fix table nesting
      modconfig[k] = self:mergeConfigs(v, modconfig[k])
    end
  end
  return modconfig
end

function ConfigLoaderDisk:getLocalConfig(mod) -- gets all the files in scripts/config/ for a mod and merges them into one array
  local config = {}
  for k, v in pairs({listFilesOfDirectory(mod.folder:gsub("\\","/") .. "data/scripts/config/")}) do
    self:mergeConfigs(dofile(v), config)
  end
  return config
end

function ConfigLoaderDisk:getConfigFromDisk(path, mod) -- merges local and galaxy configs then returns the array for a single mod
  createDirectory(path)
  local file = path .. "/" .. mod.name .. ".lua"
  local defaultconfig = self:getLocalConfig(mod) --dofile(mod.folder.."data/scripts/config/config.lua") -- TODO replace with listFilesOfDirectory()
  -- load file from disk compare whats there with what isnt and add values that arent then save to file
  local modconfig = table.load(file) or defaultconfig or {}
  modconfig = self:mergeConfigs(defaultconfig, modconfig)

  table.save(modconfig, file)
  return modconfig
end

function ConfigLoaderDisk:getConfig(path, file) -- merges all configs that touch the file in question into a array that is passed to the include
  local manager = ModManager()
  local config = {}
  for _, v in pairs(manager:getModsModifyingFile(file)) do
    config = self:mergeConfigs(config, self:getConfigFromDisk(path, manager:find(v)))
  end
  return config
end

function ConfigLoaderDisk:setConfig(path, modname, config) -- writes config to galaxy/client
  createDirectory(path)
  table.save(config, path .. "/" .. modname .. ".lua")
end

function ConfigLoaderDisk:backupConfig(mod) -- copies config with current time
  local path = Server().folder.. "/moddata/ConfigLoader/"
  createDirectory(path.."Backups/")
  table.save(self:getConfigFromDisk(path, mod), path .. "Backups/" .. mod.name .. "-BACKUP-" .. math.floor(os.date()) .. ".lua")
end

function ConfigLoaderDisk.resetConfig(modname, version) -- function for mod authors to reset configs of servers manually
  if onServer() then
    local resetList = table.load(Server().folder.. "/moddata/ConfigLoader/ConfigLoaderConfigResets.lua") or {}
    if version == resetList[modname] then return end
    local mod
    local self = ConfigLoaderDisk
    local manager = ModManager()
    for k, v in pairs({manager:getEnabledMods()}) do
      v = manager:find(v)
      if v.name == modname then mod = v end
    end
    if not mod then return print("[ConfigLoader] Mod config not found for reset: " .. modname) end
    self:backupConfig(mod)
    self:setConfig(Server().folder.. "/moddata/ConfigLoader/", mod.name, self:getLocalConfig(mod))
    resetList[modname] = version
    table.save(resetList, Server().folder.. "/moddata/ConfigLoader/ConfigLoaderConfigResets.lua")
  end
end

return ConfigLoaderDisk
