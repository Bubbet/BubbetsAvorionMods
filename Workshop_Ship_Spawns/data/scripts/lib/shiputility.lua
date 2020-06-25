local workshop_ship_spawns_shadow_addTurretsToCraft = ShipUtility.addTurretsToCraft
function ShipUtility.addTurretsToCraft(entity, turret, numTurrets, maxNumTurrets)
	workshop_ship_spawns_shadow_addTurretsToCraft(entity, turret, numTurrets, maxNumTurrets)
	local turretDesign = LoadTurretDesignFromFile(entity:getValue('TurretDesign'))
	print('inadd', turretDesign)
	if turretDesign then
		print('doing custom add turrets')
		local id = entity.id
		local blocks = Plan(id):getBlocksByType(BlockType.TurretBase)
		for _, block in pairs(blocks) do
			TurretBases(id):setDesign(block, turretDesign)
		end
	end

	--[[
	local maxNumTurrets = maxNumTurrets or 10
	if maxNumTurrets == 0 then return end

	turret = copy(turret)
	turret.coaxial = false

	local wantedTurrets = math.max(1, round(numTurrets / turret.slots))

	local values = {entity:getTurretPositionsLineOfSight(turret, numTurrets)}
	while #values == 0 and turret.size > 0.5 do
		turret.size = turret.size - 0.5
		values = {entity:getTurretPositionsLineOfSight(turret, numTurrets)}
	end

	local c = 1;
	numTurrets = tablelength(values) / 2 -- divide by 2 since getTurretPositions returns 2 values per turret

	-- limit the turrets of the ships to maxNumTurrets
	numTurrets = math.min(numTurrets, maxNumTurrets)

	local strengthFactor = wantedTurrets / numTurrets
	if numTurrets > 0 and strengthFactor > 1.0 then
		entity.damageMultiplier = math.max(entity.damageMultiplier, strengthFactor)
	end

	for i = 1, numTurrets do
		local position = values[c]; c = c + 1;
		local part = values[c]; c = c + 1;

		if part ~= nil then
			entity:addTurret(turret, position, part)
		else
			-- print("no turrets added, no place for turret found")
		end
	end]]
end