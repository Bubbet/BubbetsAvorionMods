package.path = package.path .. ";data/scripts/lib/?.lua"
local ConfigLoaderDisk = include("ConfigLoaderDisk")
include("callable")
-- namespace ConfigLoaderPlayerHelper
ConfigLoaderPlayerHelper = {}
ConfigLoaderPlayerHelper.configs = {}
ConfigLoaderPlayerHelper.compiled_configs = {}
--[[
function mergeTables(baseTable, newTable)
    if newTable then
        for k, v in pairs(newTable) do
            if type(v) == "table" then
                v = mergeTables(baseTable[k], v)
            end
            baseTable[k] = v
        end
    end
    return baseTable
end
]]
function ConfigLoaderPlayerHelper.invokedByServer(configs)
    --print('setting configs from server')
    --printTable(configs)
    ConfigLoaderPlayerHelper.configs = configs
end

function ConfigLoaderPlayerHelper.invokedByGalaxy(callingPlayer, configs)
    --print('settings from galaxy')
    --printTable(configs)
    invokeClientFunction(Player(callingPlayer), "invokedByServer", configs)
end

function ConfigLoaderPlayerHelper.getConfigsFromGalaxy()
    --print('invoking galaxy for settings')
    Galaxy():invokeFunction("data/scripts/galaxy/ConfigLoaderGalaxy.lua", "sendConfigsToPlayer", callingPlayer)
end
callable(ConfigLoaderPlayerHelper, "getConfigsFromGalaxy")

function ConfigLoaderPlayerHelper.initialize()
    if onClient() then
        --print('invoking server to invoke galaxy')
        invokeServerFunction("getConfigsFromGalaxy")
    end
end

function ConfigLoaderPlayerHelper.getConfig(path)
    printTable(ConfigLoaderPlayerHelper.configs)
    if not ConfigLoaderPlayerHelper.compiled_configs[path] then
        local manager = ModManager()
        local tab = {}
        for _, v in pairs(manager:getModsModifyingFile(path)) do
            local mod = manager:find(v)
            local modconfig = ConfigLoaderPlayerHelper.configs[mod.name]
            if not modconfig then return end -- Catch for invokes that somehow manage to beat the configs being sent from server
            --printTable(modconfig)
            ConfigLoaderDisk:mergeConfigs(tab, modconfig)
        end
        ConfigLoaderPlayerHelper.compiled_configs[path] = tab
    end

    return ConfigLoaderPlayerHelper.compiled_configs[path]
end