package.path = package.path .. ";data/scripts/config/?.lua"
local rsmConfig
if ModManager():findEnabled("2003555597") then rsmConfig = include("ConfigLoader") else
    print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
    rsmConfig = include("resourcemineconfig")
end

local rsmgetMaxStockold = Factory.trader.getMaxStock
function Factory.trader.getMaxStock(sself, goodSize)
    if type(goodSize) ~= "number" then
        if type(sself) == "number" then
            goodSize = sself
        else
            goodSize = self
        end
    end-- fallback for when stuff doesn't behave right
    local space = Entity().maxCargoSpace
    if string.find(table.concat(materials), string.split(production.results[1].name, " ")[1]) and (space / goodSize > 100) then
        --print(math.min(round(space / goodSize / 100) * 100, rsmConfig.maxStock or math.huge))
        return math.min(round(space / goodSize / 100) * 100, rsmConfig.maxStock or math.huge)
    else
        return rsmgetMaxStockold(Factory.trader, goodSize)
    end
end

local rsmgetFactoryUpgradeCostold = getFactoryUpgradeCost
function getFactoryUpgradeCost(production, size)
    local costs = rsmgetFactoryUpgradeCostold(production, size)
    if string.find(table.concat(materials), string.split(production.results[1].name, " ")[1]) then costs = costs * rsmConfig.upgradeCostMul end
    return costs
end