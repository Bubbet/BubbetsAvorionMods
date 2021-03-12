if onServer() then
	local entity = Entity()
	if entity.playerOwned then -- or entity.allianceOwned then
		entity:addScriptOnce("buildingresourcesasgoods.lua")
	end
end