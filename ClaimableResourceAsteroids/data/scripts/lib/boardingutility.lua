forbidden["data/scripts/entity/claimresource.lua"] = true
--vanilla line 60: add something to restore to resource mine founder after board

local rsmupdateScripts = BoardingUtility.updateScripts
function BoardingUtility.updateScripts(entity)
    if entity.type == EntityType.Station then
        AddDefaultStationScripts(entity)
        SetBoardingDefenseLevel(entity)

        local type = entity:getValue("factory_type")
        if type and type == "resource_mine" then
            --entity:addScript("data/scripts/entity/derelictresourcemine.lua")
        end
    end
    rsmupdateScripts(entity)
end