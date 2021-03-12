package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)
	local args = {...}
	local player = Player(sender)
	local newowner = chf.findUser(args[1]) or player
	if player.craft.selectedObject then player.craft.selectedObject.factionIndex = newowner.index end
end

function getDescription()
	return "Take ownership of target, or give a parameter to assign ownership to the target"
end

function getHelp()
	return "Usage: /own new_owners_name(optional)"
end
