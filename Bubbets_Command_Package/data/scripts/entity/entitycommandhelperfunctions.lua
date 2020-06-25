
-- namespace EntityCommandHelperFunctions
EntityCommandHelperFunctions = {}

function EntityCommandHelperFunctions.initialize()
    if onServer() then
        local e = Entity()
        e:registerCallback("onDestroyed" , "onDestroyed")
    end
end

function EntityCommandHelperFunctions.onDestroyed(index, lastDamageInflictor)
    local controlUnit = ControlUnit(index)
    for k, v in pairs(controlUnit:getSeats()) do
        local player = Player(v.playerIndex)
        if not player then return end
        local sx, sy = player:getSectorCoordinates()
        player:setValue("commands_back_pos_x", sx)
        player:setValue("commands_back_pos_y", sy)
    end
end

return EntityCommandHelperFunctions