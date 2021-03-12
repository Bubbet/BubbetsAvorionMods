package.path = package.path .. ";data/scripts/?.lua"

--include ("reconstructiontoken")

-- namespace InsaneReconstructionTokens
InsaneReconstructionTokens = {dropTurrets = false, dropSystems = false}

--[[
function InsaneReconstructionTokens.onDestroyed(index)
	local entity = Entity(index)
	local faction = Player(entity.factionIndex) or Alliance(entity.factionIndex)
	local amount = countReconstructionTokens(faction, entity.name)
	amount = 1
	if amount > 0 then
		local sector = Sector()
		local sphere = Sphere(entity.position.position, 200)
		local entities = {sector:getEntitiesByLocation(sphere)}
		for k, v in pairs(entities) do
			if v.type == EntityType.Loot then
				--faction:getInventory():add(v)
				sector:deleteEntity(v)
			end
		end
		local inventory = faction:getInventory()
		for k, v in pairs({entity:getTurrets()}) do
			--local turret = CreateTemplateFromTurret(v) --TurretTemplate(v.index)
			--print(turret)
			--inventory:add(turret) -- Wont work, TODO store all turrets attached to craft using
		end
		-- Pickup turrets near death
	end
end]]

function InsaneReconstructionTokens.onTurretDestroyed(turretIndex, shipIndex, lastDamageInflictor)
	local entity = Entity(shipIndex)
	local faction = Player(entity.factionIndex) or Alliance(entity.factionIndex)
	local inventory = faction:getInventory()
	local turret = CreateTemplateFromTurret(Entity(turretIndex)) --TurretTemplate(turretIndex)
	local last_inflictor = Entity(lastDamageInflictor)
	if InsaneReconstructionTokens.dropTurrets and valid(last_inflictor) and last_inflictor.playerOwned and (math.random() > InsaneReconstructionTokens.dropTurrets) then
		local sector = Sector()
		sector:dropTurret(entity.translationf, _, _, turret)
	else
		inventory:add(InventoryTurret(turret))
	end
end

function InsaneReconstructionTokens.onDestroyed(index, lastDamageInflictor)
	local last_inflictor = Entity(lastDamageInflictor)
	if InsaneReconstructionTokens.dropSystems and valid(last_inflictor) and last_inflictor.playerOwned then
		local buyer, ship = getInteractingFactionByShip(index)
		local inventory = buyer:getInventory()
		local systems = ShipSystem(ship):getUpgrades()
		local sector = Sector()
		local references = {}
		for k, v in pairs({inventory:getItemsByType(InventoryItemType.SystemUpgrade)}) do
			for k1, v1 in pairs(systems) do
				if v1 == v then
					table.insert(references, {key = k, syskey = k1, iitem = v, sitem = v1})
				end
			end
		end
		for k, v in pairs(references) do
			if math.random() > InsaneReconstructionTokens.dropSystems then
				inventory:remove(v.key)
				sector:dropUpgrade(ship.translationf, _, _, v.sitem)
			end
		end
	end
end

function InsaneReconstructionTokens.initialize()
	if GameSettings().difficulty <= Difficulty.Expert then return end
	--Entity():registerCallback('onDestroyed', 'onDestroyed')
	local entity = Entity()
	entity:registerCallback('onTurretDestroyed', 'onTurretDestroyed')
	if InsaneReconstructionTokens.dropSystems then
		entity:registerCallback('onDestroyed', 'onDestroyed')
	end
end
