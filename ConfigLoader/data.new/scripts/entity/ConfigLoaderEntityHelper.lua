package.path = package.path .. ";data/scripts/lib/?.lua"
-- namespace ConfigLoaderEntityHelper
ConfigLoaderEntityHelper = {}

function ConfigLoaderEntityHelper.getConfig(path)
    local err, val = Galaxy():invokeFunction("ConfigLoaderGalaxy.lua", "getConfig", path)
    if not val and false then -- TODO set to true when debugging
        print('Server galaxy invoke inside entity failed with error:', err, 'for path', path)
    end
    return val
end