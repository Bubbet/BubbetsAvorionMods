package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender)
	local player = Player(sender)
	player.craft.selectedObject:destroy(Uuid(), 0, DamageType.Physical)
end

function getDescription()
	return "Destorys the selected craft, no confirmation BE CAREFUL"
end

function getHelp()
	return "Usage: /delete; no confirmation BE CAREFUL"
end
