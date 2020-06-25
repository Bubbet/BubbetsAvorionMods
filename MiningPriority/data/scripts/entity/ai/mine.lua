---@param ship Entity
function MineAI.instance.findObject(ship, sector, harvestMaterial, depth)
	local objectToHarvest
	local higherMaterialPresent
	depth = depth or 1

	local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
	local nearest = math.huge
	local hasMiningSystem = ship:hasScript("systems/miningsystem.lua")
	local _, temp = ship:invokeFunction("entity/miningpriority.lua", "getMiningList")
	MineAI.instance.resource_list = temp or MineAI.instance.resource_list
	if not MineAI.instance.resource_list then
		MineAI.instance.resource_list = {}
		for i=1, 7 do
			table.insert(MineAI.instance.resource_list, Material(7-i))
		end
	end
	for _, a in pairs(mineables) do
		if a.type == EntityType.Asteroid and (a.isObviouslyMineable or hasMiningSystem) then
			local material = a:getLowestMineableMaterial()
			local resources = a:getMineableResources()
			if material == MineAI.instance.resource_list[depth] then

				if resources ~= nil and resources > 0 and material ~= nil then
					-- only try to mine objects that are mineable by the available mining lasers
					if material.value <= harvestMaterial + 1 then
						local dist = distance2(a.translationf, ship.translationf)
						if dist < nearest then
							nearest = dist
							objectToHarvest = a
						end
					else
						higherMaterialPresent = true
					end
				end
			end
		end
	end

	if not objectToHarvest and depth < 7 then
		--print('going deeper, nothing found', depth)
		depth = depth + 1
		objectToHarvest, higherMaterialPresent = MineAI.instance.findObject(ship, sector, harvestMaterial, depth)
	end

	return objectToHarvest, higherMaterialPresent
end