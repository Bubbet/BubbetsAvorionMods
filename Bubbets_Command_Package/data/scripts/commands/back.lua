package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    local player = Player(sender)
    if args[1] then player = chf.findUser(args[1]) end
    local x, y = player:getValue("commands_back_pos_x"), player:getValue("commands_back_pos_y")
    local sx, sy = player:getSectorCoordinates()
    player:setValue("commands_back_pos_x", sx)
    player:setValue("commands_back_pos_y", sy)
    Player():invokeFunction('data/scripts/player/playercommandhelperfunctions.lua', 'moveEntity', player, x, y)

    return val~=nil, "", "Sending " .. player.name .. " back."
end

function getDescription()
    return "Return to position from previous teleport command or death."
end

function getHelp()
    return "Usage: /back player_name(optional)"
end
