package.path = package.path .. ";data/scripts/config/?.lua"
local rsmConfig
if ModManager():findEnabled("2003555597") then rsmConfig = include("ConfigLoader") else
    if onServer() and not Server():getValue('CRA_LocalAlert') then
        print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
        Server():setValue('CRA_LocalAlert', true)
    end
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
    if not production then return rsmgetMaxStockold(Factory.trader, goodSize) end
    local material = string.split(production.results[1].name, " ")[1]
    if string.find(table.concat(materials), material) and (space / goodSize > 100) then
        --print(math.min(round(space / goodSize / 100) * 100, rsmConfig.maxStock or math.huge))
        return math.min(round(space / goodSize / 100) * 100, rsmConfig.maxStock or math.huge)
    else
        return rsmgetMaxStockold(Factory.trader, goodSize, material)
    end
end

local rsmgetFactoryUpgradeCostold = getFactoryUpgradeCost
function getFactoryUpgradeCost(production, size)
    local costs = rsmgetFactoryUpgradeCostold(production, size)
    if string.find(table.concat(materials), string.split(production.results[1].name, " ")[1]) then costs = costs * rsmConfig.upgradeCostMul end
    return costs
end

Factory.old_getProduction = Factory.getProduction
function Factory.getProduction()
    if production and string.match(production.factory, "Resource Mine") then
        return {factory="Resource Mine Empty Production", ingredients={}, results={}, garbages={}}
    end
    return production
end

local rsm_updateTitle = Factory.updateTitle
function Factory.updateTitle()
    rsm_updateTitle()
    local material = string.split(production.results[1].name, " ")[1]
    if not string.find(table.concat(materials), material) then return end
    local station = Entity()
    if station:hasScript("data/scripts/entity/rsm_merge.lua") then return end
    station:addScriptOnce("data/scripts/entity/rsm_merge.lua")
end
