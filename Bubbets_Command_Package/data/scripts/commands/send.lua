package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    if not args[1] or not args[2] then return 0, "", "Missing arguments." end
    local splayer = chf.findUser(args[1])
    local x, y = splayer:getSectorCoordinates()
    splayer:setValue("commands_back_pos_x", x)
    splayer:setValue("commands_back_pos_y", y)
    local player = chf.findUser(args[2])
    local x, y = player:getSectorCoordinates()
    Player():invokeFunction('data/scripts/player/playercommandhelperfunctions.lua', 'moveEntity', splayer, x, y)

    return 1, "", "Teleporting " .. splayer.name .. " to " .. player.name
end

function getDescription()
    return "Teleport a player to another player."
end

function getHelp()
    return "Usage: /send sent_player_name to_player_name"
end
