if onServer() then
	local entity = Entity()
	if entity.isDrone then
		entity:addScriptOnce("data/scripts/lib/ElementToTable.lua")--entity/merchants/turretfactory.lua")
	end
end