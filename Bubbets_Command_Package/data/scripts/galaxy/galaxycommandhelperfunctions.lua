

-- namespace GalaxyCommandHelperFunctions
GalaxyCommandHelperFunctions = {}

function GalaxyCommandHelperFunctions.sendCraft(entity, x, y, tries)
	local galaxy = Galaxy()
	tries = tries or 0
	if tries > 15 then return end -- after 15 seconds the sector is unloaded anyways and the teleport has failed
	if galaxy:sectorLoaded(x, y) then
		galaxy:transferEntity(entity, x, y, 0)
	else
		deferredCallback(1,'sendCraft', entity, x, y, tries)
	end
end

function GalaxyCommandHelperFunctions.moveEntity(player, x, y)
	Galaxy():loadSector(x, y)
	deferredCallback(1,'sendCraft', player.craft, x, y)
end
