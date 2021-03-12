package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"
local Config
if ModManager():findEnabled("2003555597") then Config = include("ConfigLoader") else
    if onServer() and not Server():getValue('CRA_LocalAlert') then
        print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
        Server():setValue('CRA_LocalAlert', true)
    end
    Config = include("resourcemineconfig")
end

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ResourceMineFounder
ResourceMineFounder = include("minefounder")
local self = ResourceMineFounder

ResourceMineFounder.balratio = Config.defaultproductionsize/Config.averageasteroidsize -- amount per production / average size of asteroid(higher for generally weaker factories)

-- create all required UI elements for the client side
ResourceMineFounder.UI = {}
function ResourceMineFounder.initUI()

    ResourceMineFounder.UI.res = getResolution()
    ResourceMineFounder.UI.size = vec2(300, 255)

    ResourceMineFounder.UI.menu = ScriptUI()
    ResourceMineFounder.UI.window = ResourceMineFounder.UI.menu:createWindow(Rect(ResourceMineFounder.UI.res * 0.5 - ResourceMineFounder.UI.size * 0.5, ResourceMineFounder.UI.res * 0.5 + ResourceMineFounder.UI.size * 0.5))

    ResourceMineFounder.UI.window.caption = "Transform to Mine"
    ResourceMineFounder.UI.window.showCloseButton = 1
    ResourceMineFounder.UI.window.moveable = 1
    ResourceMineFounder.UI.menu:registerWindow(ResourceMineFounder.UI.window, "Found Mine");

    ResourceMineFounder.UI.container = ResourceMineFounder.UI.window:createContainer(Rect(vec2(0,0),ResourceMineFounder.UI.size))

    ResourceMineFounder.UI.lister = UIVerticalLister(Rect(vec2(0,0),ResourceMineFounder.UI.size), 10, 10)

    local goodName = materials[Entity():getMineableMaterial().value + 1] .. " Ore"
    local production = {factory="Resource Mine ${size}", ingredients={}, results={{name=goodName, amount=Entity().volume * ResourceMineFounder.balratio}}, garbages={}}

    ResourceMineFounder.UI.label = ResourceMineFounder.UI.container:createLabel(ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,15)).lower, "Enter station name:", 14)
    ResourceMineFounder.UI.textbox = ResourceMineFounder.UI.container:createTextBox(ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,30)),"")
    ResourceMineFounder.UI.costlabel = ResourceMineFounder.UI.container:createLabel(ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,15)).lower, "Cost: " .. createMonetaryString(ResourceMineFounder.getFactoryCost(production)), 14)
    ResourceMineFounder.UI.yieldlabel = ResourceMineFounder.UI.container:createLabel(ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,15)).lower, "Expected Resource/Cycle: " .. round(production.results[1].amount) , 14)
    ResourceMineFounder.UI.infoBoxRect = ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,80))
    ResourceMineFounder.UI.infoBox = ResourceMineFounder.UI.container:createTextField(ResourceMineFounder.UI.infoBoxRect, "After founding a mine you can get your own resource depot and configure the mine to sell to it for automatic resource production.")
    ResourceMineFounder.UI.infoBoxFrame = ResourceMineFounder.UI.container:createFrame(ResourceMineFounder.UI.infoBoxRect)
    ResourceMineFounder.UI.button = ResourceMineFounder.UI.container:createButton(ResourceMineFounder.UI.lister:placeCenter(vec2(ResourceMineFounder.UI.lister.inner.width,30)),"Confirm","onNameEntered")

end

function ResourceMineFounder.onNameEntered(window)
    invokeServerFunction("foundFactory", _, _, self.UI.textbox.text)
end

local rsmoldfoundFactory = ResourceMineFounder.foundFactory
function ResourceMineFounder.foundFactory(goodName, productionIndex, name)
    local buyer, asteroid, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FoundStations)
    if not buyer then return end

    goodName = materials[asteroid:getMineableMaterial().value + 1] .. " Ore"
    productionIndex = #productions + 1

    productionsByGood[goodName] = {}
    productionsByGood[goodName][productionIndex] = {factory="Resource Mine ${size}", ingredients={}, results={{name=goodName, amount=asteroid.volume * ResourceMineFounder.balratio}}, garbages={}}

    name = name or ""
    if name == "" then
        name = "${good} Mine"%_t % {good = goodName}
    end
    if buyer:ownsShip(name) then -- Really shouldnt be needed, but vanilla only calls for player and not alliances leading to crashes when founding same named ships in alliance ships
        player:sendChatMessage("", 1, "You already own an object called ${name}."%_t % {name = name})
        return
    end
    --[[
    local entity = Entity()
    local plan = entity:getMovePlan()
    for n = 0, plan.numBlocks - 1 do
        local block = plan:getNthBlock(n)
        local typ = block.box.type
        --print("Type", typ)
        local ctyp = BlockType.Stone
        if typ == BoxType.Corner then
            ctyp = BlockType.StoneCorner
        end
        if typ == BoxType.Edge then
            ctyp = BlockType.StoneEdge
        end
        plan:setBlockType(n, ctyp)
    end
    entity:setMovePlan(plan)
    ]]
    rsmoldfoundFactory(goodName, productionIndex, name)
    asteroid:setValue("map_marker", nil)
    --entity:setValue("factory_type", "resource_mine") -- This isnt doing anything at this point as the entity is cleaned up by now

    productionsByGood[goodName][productionIndex] = nil -- failsafe to keep resources out of regular mine founding
    productionsByGood[goodName] = nil
end
callable(ResourceMineFounder, "foundFactory")

local oldgetFactoryCost = ResourceMineFounder.getFactoryCost
function ResourceMineFounder.getFactoryCost(production)
    return oldgetFactoryCost(production) * Entity().volume / Config.averageasteroidsize
end

function ResourceMineFounder.onCloseWindow() end