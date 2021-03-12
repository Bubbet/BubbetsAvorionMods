

-- namespace PlayerCommandHelperFunctions
PlayerCommandHelperFunctions = {}

function PlayerCommandHelperFunctions.sendCraft(player, x, y, tries)
	local galaxy = Galaxy()
	tries = tries or 0
	if tries > 15 then return end -- after 15 seconds the sector is unloaded anyways and the teleport has failed
	if galaxy:sectorLoaded(x, y) then
		--galaxy:transferEntity(entity, x, y, 0) removed from modding api
		Sector():transferEntity(player.craft, x, y, SectorChangeType.Forced)
	else
		deferredCallback(1,'sendCraft', player, x, y, tries)
	end
end

function PlayerCommandHelperFunctions.moveEntity(player, x, y)
	Galaxy():loadSector(x, y)
	deferredCallback(1,'sendCraft', player, x, y)
end
