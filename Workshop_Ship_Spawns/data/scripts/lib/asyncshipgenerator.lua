local function onMilitaryPlanFinished(plan, generatorId, position, factionIndex)
	print('args', plan.plan, plan.path, generatorId, position, factionIndex)
	local self = generators[generatorId] or {}

	local faction = Faction(factionIndex)
	local ship = Sector():createShip(faction, "", plan.plan, position, self.arrivalType)
	--ship:setValue('TurretDesign', plan.path)

	ShipUtility.addMilitaryEquipment(ship, 1, 0)

	finalizeShip(ship)
	onShipCreated(generatorId, ship)

	local turretDesign = LoadTurretDesignFromFile(plan.path)
	if turretDesign then
		local id = ship.id
		local blocks = Plan(id):getBlocksByType(BlockType.TurretBase)
		local bases = TurretBases(ship)
		printTable(blocks, '', 10)
		print(bases)
		for _, block in pairs(blocks) do
			bases:setDesign(block, turretDesign)
		end
	end
end

local workshop_ship_spawns_shadow_new = new
local function new(namespace, onGeneratedCallback)
	local old = workshop_ship_spawns_shadow_new(namespace, onGeneratedCallback)
	if namespace then
		namespace._ship_generator_on_military_plan_generated = onMilitaryPlanFinished
	else
		_ship_generator_on_military_plan_generated = onMilitaryPlanFinished
	end
	return old
end