local ranks_oldinteraction = SectorOverview.interactionPossible
function SectorOverview.interactionPossible(playerIndex)
    print("sectoroverview Interaction possible")
    local player = Player(playerIndex)
    local err, val = player:invokeFunction("data/scripts/player/ranks.lua", "hasPrivilege", playerIndex, "sectoroverview")
    if val then
        return ranks_oldinteraction(playerIndex)
    else
        return false
    end
end