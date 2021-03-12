package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("faction")
include ("callable")
include ("utility")

--namespace ClaimResource
ClaimResource = {}
ClaimResource.UI = {}

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function ClaimResource.interactionPossible(playerIndex, option)

    local player = Player(playerIndex)
    local self = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(self)

    if dist > 20 then
        return false, "You are not close enough to claim the object!"
    end

    if self.factionIndex ~= 0 then
        return false
    end

    return true
end

-- create all required UI elements for the client side
function ClaimResource.initUI()
    ClaimResource.UI.res = getResolution()
    ClaimResource.UI.size = vec2(800, 600)

    ClaimResource.UI.menu = ScriptUI()
    ClaimResource.UI.window = ClaimResource.UI.menu:createWindow(Rect(vec2(0, 0), vec2(0, 0)))

    ClaimResource.UI.menu:registerWindow(ClaimResource.UI.window, "Claim");
end

function ClaimResource.onShowWindow()
    invokeServerFunction("claim")
    ScriptUI():stopInteraction()
end

function ClaimResource.initialize()
    local entity = Entity()
    if entity.factionIndex ~= 0 then return end
    entity:setValue("valuable_object", RarityType.Petty)
    entity.type = EntityType.Asteroid
end

function ClaimResource.claim()
    local ok, msg = ClaimResource.interactionPossible(callingPlayer)
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
    if entity.factionIndex ~= 0 then
        return false
    end

    --printTable(entity:getMineableResources())
    --print(entity:getMineableResources())

    entity.factionIndex = faction.index
    entity:addScriptOnce("resourceminefounder.lua")
    entity:addScriptOnce("unclaimresource.lua")
    entity:setValue("valuable_object", nil)
    entity:setValue("map_marker", "Claimed " .. entity:getMineableMaterial().name .. " Asteroid")
    entity.type = EntityType.Unknown
    --entity:addScriptOnce("sellobject.lua")
    if ModManager():findEnabled("1691539727") then
      entity:addScriptOnce("data/scripts/entity/moveAsteroid.lua")
    end

    --terminate()
end
callable(ClaimResource, "claim")
