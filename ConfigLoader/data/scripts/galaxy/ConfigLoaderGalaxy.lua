package.path = package.path .. ";data/scripts/galaxy/?.lua"
local ConfigLoaderDisk = include("ConfigLoaderDisk")

-- namespace ConfigLoaderGalaxy
ConfigLoaderGalaxy = {}

function ConfigLoaderGalaxy:initialize()
    ConfigLoaderDisk:getAllConfigs(Server().folder.. "/moddata/ConfigLoader")
    ConfigLoaderGalaxy.initalized = true
end

function ConfigLoaderGalaxy.getConfig(path)
    --print(path)
    --printTable(ConfigLoaderDisk.configs)
    return ConfigLoaderDisk:getConfig(Server().folder.. "/moddata/ConfigLoader", path)
end

function ConfigLoaderGalaxy.sendConfigsToPlayer(playerIndex)
    if not ConfigLoaderGalaxy.initalized then
        ConfigLoaderDisk:getAllConfigs(Server().folder.. "/moddata/ConfigLoader")
        ConfigLoaderGalaxy.initalized = true
    end
    --print('before sent to player')
    --printTable(ConfigLoaderDisk.configs)
    --print('sending to player now')
    invokeFactionFunction(playerIndex, true, "data/scripts/player/ConfigLoaderPlayerHelper.lua", "invokedByGalaxy", playerIndex, ConfigLoaderDisk.configs)
    --Player(playerIndex):invokeFunction(, "invokedByGalaxy", playerIndex, ConfigLoaderDisk.configs)
end