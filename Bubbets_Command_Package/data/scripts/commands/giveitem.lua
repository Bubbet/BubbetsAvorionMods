package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
    local args = {...}
    local player = Player(sender)
    local item
    if args[2] then
        player = chf.findUser(args[1])
        item = chf.findItem(args[2])
    else
        item = chf.findItem(args[1])
    end

    if not item then return 0, "", "No item found." end

    player:getInventory():add(item)

    local name = item.__avoriontype == "SystemUpgradeTemplate" and item.name or item.weaponName

    return 1, "", "Giving " .. player.name .. " a " .. name
end

function getDescription()
    return "Give a player a item"
end

function getHelp()
    return "Usage: /giveitem player_name(optional)/item_name item_name(optional)"
end
