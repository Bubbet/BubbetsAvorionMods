package.path = package.path .. ";data/scripts/lib/?.lua"
local ConfigLoaderDisk = include("ConfigLoaderDisk")
include("callable")
include("utility")

-- namespace ConfigDownloader
ConfigDownloader = {}

function ConfigDownloader.recieveConfigs(mods)
  for name, config in pairs(mods) do
    ConfigLoaderDisk:setConfig("/moddata/ConfigLoader", name, config)
  end
end

function ConfigDownloader:requestConfigs()
  local mods = {}
  for _, v in pairs(ModManager():getDetectedMods()) do
    local p = ConfigLoaderDisk:getLocalConfig(v) --v.folder:gsub("\\","/") .. "data/scripts/config/config.lua" -- TODO replace with new system
    if tablelength(p) > 0 then mods[v.name] = ConfigLoaderDisk:getConfigFromDisk(Server().folder.. "/moddata/ConfigLoader", v) end
  end
  invokeClientFunction(Player(callingPlayer), "recieveConfigs", mods)
end
callable(ConfigDownloader,"requestConfigs")

function ConfigDownloader:initialize()
  if onClient() then
    invokeServerFunction("requestConfigs")
  end
end
