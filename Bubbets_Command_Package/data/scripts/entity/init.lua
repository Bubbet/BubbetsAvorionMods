if onServer() then

    package.path = package.path .. ";data/scripts/lib/?.lua"
    include("faction")

    local e = Entity()

    if (e.isShip) or (e.isStation) then
        if e.isDrone or e.isFighter then return end  -- ignore Fighters and Drones(as ondestroyed callback doesn't work on drones anyways).

        local faction = Faction()

        if valid(faction) and not faction.isAIFaction then
            e:addScriptOnce("entitycommandhelperfunctions.lua")
        end
    end

end