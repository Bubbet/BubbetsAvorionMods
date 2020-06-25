package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("faction")
include ("callable")
include ("utility")

--namespace UnclaimResource
UnclaimResource = {}
UnclaimResource.UI = {}

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
--[[
function UnclaimResource.interactionPossible(playerIndex, option)

    local player = Player(playerIndex)
    local self = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(self)

    if dist > 20 then
        return false, "You are not close enough to un-claim the object!"
    end

    if self.factionIndex ~= 0 then
        return false
    end

    return true
end
]]

function UnclaimResource.interactionPossible(playerIndex, option)

    if checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FoundStations) then
        return true, ""
    end

    return false
end

-- create all required UI elements for the client side
function UnclaimResource.initUI()
    UnclaimResource.UI.res = getResolution()
    UnclaimResource.UI.size = vec2(800, 600)

    UnclaimResource.UI.menu = ScriptUI()
    UnclaimResource.UI.window = UnclaimResource.UI.menu:createWindow(Rect(vec2(0, 0), vec2(0, 0)))

    UnclaimResource.UI.menu:registerWindow(UnclaimResource.UI.window, "Un-Claim");
end

function UnclaimResource.onShowWindow()
    invokeServerFunction("unclaim")
    ScriptUI():stopInteraction()
end
--[[
function UnclaimResource.initialize()
    Entity():setValue("valuable_object", nil)
end]]

function UnclaimResource.unclaim()
    local ok, msg = UnclaimResource.interactionPossible(callingPlayer)
    if not ok then

        if msg then
            local player = Player(callingPlayer)
            if player then
                player:sendChatMessage("", 1, msg)
            end
        end

        return
    end

    local faction, ship, player = getInteractingFaction(callingPlayer)
    if not faction then return end

    local entity = Entity()
    if entity.factionIndex == 0 then
        return false
    end

    --printTable(entity:getMineableResources())
    --print(entity:getMineableResources())

    entity.factionIndex = 0
    --entity:removeScript("resourceminefounder.lua")
    --if ModManager():findEnabled("1691539727") then
    --    entity:removeScript("data/scripts/entity/moveAsteroid.lua")
    --end

    --entity:addScriptOnce("claimresource.lua")
    entity:setValue("valuable_object", RarityType.Petty)

    --terminate()
end
callable(UnclaimResource, "unclaim")
