local ranks_oldinteraction = sectorManager.interactionPossible
function sectorManager.interactionPossible(playerIndex)
    local player = Player(playerIndex)
    local err, val = player:invokeFunction("data/scripts/player/ranks.lua", "hasPrivilege", playerIndex, "sectormanager")
    if val then
        return ranks_oldinteraction(playerIndex)
    else
        return false
    end
end
