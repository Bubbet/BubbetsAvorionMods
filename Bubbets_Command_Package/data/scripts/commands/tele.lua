package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    local player, x, y
    if args[3] then
        player = chf.findUser(args[1])
        x = tonumber(args[2])
        y = tonumber(args[3])
    else
        player = Player(sender)
        x = tonumber(args[1])
        y = tonumber(args[2])
    end
    if #args < 2 then return 0, "", "Too few arguments." end

    local sx, sy = player:getSectorCoordinates()
    player:setValue("commands_back_pos_x", sx)
    player:setValue("commands_back_pos_y", sy)

    -- TODO fails on sector generation and would need to be called again after the sector has been generated(test for generated? and fail if not)
    Galaxy():invokeFunction('data/scripts/galaxy/galaxycommandhelperfunctions.lua', 'moveEntity', player, x, y)

    return 1, "", "Teleporting " .. player.name .. " to (" .. x .. ":" .. y .. ")"
end

function getDescription()
    return "Teleport player to sector"
end

function getHelp()
    return "Usage: /tele player_name(optional) x y"
end
