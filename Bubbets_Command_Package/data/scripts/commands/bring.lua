package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    if not args[1] then return 0, "", "No target player." end
    local splayer = chf.findUser(args[1])
    local x, y = splayer:getSectorCoordinates()
    splayer:setValue("commands_back_pos_x", x)
    splayer:setValue("commands_back_pos_y", y)
    local player = Player(sender)
    local x, y = player:getSectorCoordinates()
    Galaxy():transferEntity(splayer.craft, x, y, 0)

    return 1, "", "Teleporting " .. splayer.name .. " to " .. player.name
end

function getDescription()
    return "Teleport another player to you."
end

function getHelp()
    return "Usage: /bring player_name"
end
