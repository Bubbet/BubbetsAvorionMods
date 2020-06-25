package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    local player = Player(sender)
    if args[1] then player = chf.findUser(args[1]) end
    local x, y = player:getSectorCoordinates()

    return x~=nil, "", player.name .. " is in sector: (" .. x .. ":" .. y .. ")"
end

function getDescription()
    return "Fetch a players coordinates."
end

function getHelp()
    return "Usage: /coords player_name(optional)"
end
