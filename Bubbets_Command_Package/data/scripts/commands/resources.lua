package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
	local args = {...}
	local player = Player(sender)
	local item
	if args[1] then
		player = chf.findUser(args[1])
	end

	player:pay("",-100000000000, -10000000000, -10000000000, -10000000000, -10000000000, -10000000000, -10000000000, -10000000000)

	return 1, "", "Giving " .. player.name .. " a developer resource pack."
end

function getDescription()
	return "Give a player a developer resource pack"
end

function getHelp()
	return "Usage: /resources player_name(optional)"
end
