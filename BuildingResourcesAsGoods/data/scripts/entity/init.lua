if onServer() then
	local entity = Entity()
	if entity.playerOwned or entity.allianceOwned then
		entity:addScriptOnce("buildingresourcesasgoods.lua")
	end
end