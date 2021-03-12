if onServer() then
	local entity = Entity()
	if (entity.playerOwned or entity.allianceOwned) and not entity.isDrone then
		entity:addScriptOnce("entity/insanereconstructiontokens.lua")
	end
end