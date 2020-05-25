TurretConstructor = {} -- Default TurretConstructor object, do not touch unless you really know what you're doing. It will change every turret that hasn't overwrote these functions.
TurretConstructor.Specialties = { -- You might want to modify this if you've got lots of weapons that will be using a new specialty as every turret will try to index it
	HighDamage = function(self)
		local maxIncrease = 1.2
		local increase = 0.3 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		for _, weapon in pairs(self.weapons) do
			weapon.damage = weapon.damage * (1 + increase)
		end

		local addition = math.floor(increase * 100 + 0.00001) -- TODO rounding
		self.turret:addDescription("%s%% Damage"%_T, string.format("%+i", addition))
	end,
	HighRange = function(self)
		local maxIncrease = 0.3
		local increase = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		for _, weapon in pairs(self.weapons) do
			weapon.reach = weapon.reach * (1 + increase)
		end

		local addition = math.floor(increase * 100)
		self.turret:addDescription("%s%% Range"%_T, string.format("%+i", addition))
	end,
	HighFireRate = function(self) end,
	BurstFireEnergy = function(self)
		for _, weapon in pairs(self.weapons) do
			self.turret:addWeapon(weapon)
		end

		local fireRate = self.turret.fireRate
		local fireDelay = 1 / fireRate

		local increase = self.rand:getFloat(2, 3)
		fireRate = math.max(fireRate * increase, 6)

		for _, weapon in pairs(self.weapons) do
			weapon.fireRate = fireRate / #self.weapons
		end

		self.turret:clearWeapons()
		for _, weapon in pairs(self.weapons) do
			self.turret:addWeapon(weapon)
		end

		TurretGenerator.createBatteryChargeCooling(self.turret, fireRate * fireDelay, 1)

		self.turret:clearWeapons()
	end,
	BurstFire = function(self)
		for _, weapon in pairs(self.weapons) do
			self.turret:addWeapon(weapon)
		end

		local fireRate = self.turret.fireRate
		local fireDelay = 1 / fireRate

		local increase = self.rand:getFloat(2, 3)
		fireRate = math.max(fireRate * increase, 6)

		local coolingTime = fireRate * fireDelay

		for _, weapon in pairs(self.weapons) do
			weapon.fireRate = fireRate / #self.weapons
			weapon.damage = weapon.damage * coolingTime
		end

		self.turret:clearWeapons()
		for _, weapon in pairs(self.weapons) do
			self.turret:addWeapon(weapon)
		end

		TurretGenerator.createStandardCooling(turret, coolingTime, 1)

		self.turret:clearWeapons()
	end,
	AutomaticFire = function(self)
		if not self.turret.coaxial then
			self.turret.automatic = true

			local factor = 0.5

			for _, weapon in pairs(self.weapons) do
				weapon.damage = weapon.damage * factor

				if weapon.shieldRepair ~= 0 then
					weapon.shieldRepair = weapon.shieldRepair * factor
				end

				if weapon.hullRepair ~= 0 then
					weapon.hullRepair = weapon.hullRepair * factor
				end
			end
		end
	end,
	HighEfficiency = function(self)
		local maxIncrease = 0.4
		local increase = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		for _, weapon in pairs(self.weapons) do
			if weapon.stoneRefinedEfficiency ~= 0 then
				weapon.stoneRefinedEfficiency = math.min(0.9, weapon.stoneRefinedEfficiency * (1 + increase))
			end

			if weapon.metalRefinedEfficiency ~= 0 then
				weapon.metalRefinedEfficiency = math.min(0.9, weapon.metalRefinedEfficiency * (1 + increase))
			end

			if weapon.stoneRawEfficiency ~= 0 then
				weapon.stoneRawEfficiency = math.min(0.9, weapon.stoneRawEfficiency * (1 + increase))
			end

			if weapon.metalRawEfficiency ~= 0 then
				weapon.metalRawEfficiency = math.min(0.9, weapon.metalRawEfficiency * (1 + increase))
			end
		end

		local addition = math.floor(increase * 100)
		self.turret:addDescription("%s%% Efficiency"%_T, string.format("%+i", addition))
	end, -- only applicable to salvage and mining laser
	HighShootingTime = function(self)
		local maxIncrease = 2.9
		local increase = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		TurretGenerator.createStandardCooling(self.turret, self.turret.coolingTime, self.turret.shootingTime * (1 + increase))

		local percentage = math.floor(increase * 100)
		self.turret:addDescription("%s%% Shooting Until Overheated"%_T, string.format("%+i", percentage))
	end,
	LessEnergyConsumption = function(self)
		local maxDecrease = 0.6
		local decrease = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxDecrease

		TurretGenerator.createBatteryChargeCooling(self.turret, self.cooling.coolingTime * (1 - decrease), self.cooling.shootingTime)

		local percentage = math.floor(decrease * 100)
		self.turret:addDescription("%s%% Less Energy Consumption"%_T, string.format("%+i", percentage))
	end,
	IonizedProjectile = function(self)
		local chance = self.rand:getFloat(0.7, 0.8)
		local varChance = 1 - chance
		chance = chance + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * varChance

		for _, weapon in pairs(self.weapons) do
			weapon.shieldPenetration = chance
		end

		local percentage = math.floor(chance * 100 + 0.0000001) -- TODO rounding
		self.turret:addDescription("Ionized Projectiles"%_T, "")
		self.turret:addDescription("%s%% Chance of penetrating shields"%_T, string.format("%i", percentage))
	end,
	Penetration = function(self) end,
	Explosive = function(self) end, -- AOE damage
	SimultaneousShooting = function(self)
		self.turret.simultaneousShooting = true
	end,
}
function TurretConstructor:getCrew()
	local requiredCrew = self.crewAmount or TurretGenerator.dpsToRequiredCrew(self.dps)
	local crew = Crew()
	crew:add(requiredCrew, CrewMan(self.crewType or CrewProfessionType.Gunner))
	return crew
end
function TurretConstructor:getWeapon()
	return WeaponGenerator.generateWeapon(self.rand, self.type, self.dps, self.tech, self.material, self.rarity) -- Replace this later?
end
function TurretConstructor:getNumWeapons()
	return {1, 2, 4}
end
function TurretConstructor:getWeapons()
	local weapons = self:getNumWeapons()
	local numWeapons = weapons[self.rand:getInt(1, #weapons)]
	local weapon = self:getWeapon()
	weapon.fireDelay = weapon.fireDelay * numWeapons
	weapons = {}
	for _ = 1, numWeapons do
		table.insert(weapons, weapon)
	end
	return weapons
end
function TurretConstructor:applyCooling()
	--local shootingTime = 7 * self.rand:getFloat(0.9, 1.3)
	--local coolingTime = 5 * self.rand:getFloat(0.8, 1.2)
	--TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
end
function TurretConstructor:getWeaponScaleTable()
	return scales[self.type] or {
		{from = 0, to = 18, size = 0.5, usedSlots = 1},
		{from = 19, to = 33, size = 1.0, usedSlots = 2},
		{from = 34, to = 45, size = 1.5, usedSlots = 3},
		{from = 46, to = 52, size = 2.0, usedSlots = 4},
	}
end
function TurretConstructor:getScale()
	local scaleTech = self.tech
	if self.rand:test(0.5) then
		scaleTech = math.floor(math.max(1, scaleTech * self.rand:getFloat(0, 1)))
	end

	local scale = {from = 0, to = 0, size = 1, usedSlots = 1}
	for _, _scale in pairs(self:getWeaponScaleTable()) do
		if self.tech >= _scale.from and self.tech <= _scale.to then scale = _scale end
	end

	scale.coaxial = (scale.usedSlots >= 5)
	scale.turningSpeed = lerp(scale.size, 0.5, 3, 1, 0.3) * self.rand:getFloat(0.8, 1.2) * self.turnSpeedFactor or 1
	scale.coaxialDamageScale = self.turret.coaxial and 3 or 1
	scale.shotSizeFactor = scale.size * 2

	scale.reachFactor = (1 + (scale.usedSlots - 1) * 0.15)

	return scale
end
function TurretConstructor:applyWeaponScale()
	for _, weapon in pairs(self.weapons) do
		if self.scale.usedSlots > 1 then
			-- scale damage, etc. linearly with amount of used slots
			weapon.damage = weapon.damage * self.scale.usedSlots * self.scale.coaxialDamageScale
			weapon.reach = weapon.reach * self.scale.reachFactor
			weapon.psize = weapon.psize * self.scale.shotSizeFactor
		end
	end
end
function TurretConstructor:applyScale()
	local scale = self:getScale()
	self.scale = scale -- Needed inside applyWeaponScale and applyWeapons
	self.turret.size = scale.size
	self.turret.coaxial = scale.coaxial
	self.turret.slots = scale.usedSlots
	self.turret.turningSpeed = scale.turningSpeed
	self:applyWeaponScale()
end
function TurretConstructor:getSpecialtiesTable()
	local tab = {}
	for _, v in pairs(possibleSpecialties[self.type]) do
		for k1, v1 in pairs(Specialty) do
			if v.specialty == v1 then
				table.insert(tab, {specialty = k1, probability = v.probability})
			end
		end
	end
	return tab
end
function TurretConstructor:getGuaranteedSpecialtiesTable()
	return {}
end
function TurretConstructor:getSpecialties()
	local probabilities = self:getSpecialtiesTable()
	local specialties = {}
	for _, v in pairs(probabilities) do
		if not ( self.turret.coaxial and v.specialty == 'AutomaticFire' ) then
			if self.rand:test(v.probability * (self.rarity.value + 0.2)) then
				table.insert(specialties, v.specialty)
			end
		end
	end
	local maxNumSpecialties = self.rand:getInt(0, 1 + math.modf(self.rarity.value / 2)) -- round to zero
	for _=1, math.max(0, maxNumSpecialties - #specialties) do
		table.remove(specialties, self.rand:getInt(1, #specialties))
	end
	for _, v in pairs(self:getGuaranteedSpecialtiesTable()) do
		table.insert(specialties, v)
	end
	if self.simultaneousShootingProbability and self.rand:test(self.simultaneousShootingProbability) then
		table.insert(specialties, 'SimultaneousShooting')
	end
	return specialties
end
function TurretConstructor:applySpecialties()
	local specialties = self:getSpecialties()
	for _, v in pairs(specialties) do
		self.Specialties[v](self)
	end
end
function TurretConstructor:applyWeapons()
	local places = {TurretGenerator.createWeaponPlaces(self.rand, #self.weapons)}
	for k, v in pairs(self.weapons) do
		v.localPosition = places[k] * self.turret.size * self.scale.size or 1
		self.turret:addWeapon(v)
	end
end
function TurretConstructor:extraDescriptions() end

---@class TurretConstructor
---@return TurretTemplate
---@param rand Random
---@param dps number
---@param tech number
---@param material Material
---@param rarity Rarity
---@param _type string
function TurretConstructor:new(rand, dps, tech, material, rarity, _type)
	self.rand, self.type, self.dps, self.tech, self.material, self.rarity = rand, _type, dps, tech, material, rarity  -- setting base values of table
	self.turret = TurretTemplate()
	self.turret.crew = self:getCrew()
	self.weapons = self:getWeapons()
	self:applyScale() -- before attaching to prevent getting, removing, then re-adding turrets
	self:applyCooling()
	self:applySpecialties() -- before attaching to prevent getting, removing, then re-adding turrets
	self:applyWeapons()
	self:extraDescriptions()
	self.turret:updateStaticStats()
	local meta = getmetatable(self.turret) --[
	meta.generationTable = self -- Adding the Turret table to the metatable for future reference; probably not required
	setmetatable(self.Specialties, {__index = TurretConstructor.Specialties}) -- Probably needed to overwrite values in the specialties table
	return setmetatable(self.turret, meta) --]
end

function TurretGenerator.populateGeneratorFunction() -- In its own function so it can be overwrote before runtime you should probably avoid doing that though
	for _, v in pairs(WeaponType) do
		generatorFunction[v] = setmetatable({}, {__call = TurretConstructor.new, __index = TurretConstructor}) -- function(rand, dps, tech, material, rarity) end
	end
end
TurretGenerator.populateGeneratorFunction()

---@return TurretTemplate
---@param rand Random
---@param dps number
---@param tech number
---@param material Material
---@param rarity Rarity
---@param _type string
function TurretGenerator.generateTurret(rand, _type, dps, tech, material, rarity)
	if rarity == nil then
		local index = rand:getValueOfDistribution(32, 32, 16, 8, 4, 1)
		rarity = Rarity(index - 1)
	end
	return generatorFunction[_type](rand, dps, tech, material, rarity, _type)
end

---@param weaponType string
---@param tab table
function TurretGenerator.replaceFunctions(weaponType, tab)
	for k, v in pairs(tab) do
		generatorFunction[weaponType][k] = v
	end
end
--[[
TurretGenerator.replaceFunctions(WeaponType.ChainGun, { -- Example 1
	getCrew = function(self)
		local oldcrew = TurretConstructor.getCrew(self)
		oldcrew:add(1, CrewMan(CrewProfessionType.Miner))
		return oldcrew
	end,
})

generatorFunction[WeaponType.ChainGun].getCrew = function(self)  -- Example 2
	local oldcrew = TurretConstructor.getCrew(self)
	oldcrew:add(1, CrewMan(CrewProfessionType.Miner))
	return oldcrew
end
]]

TurretGenerator.replaceFunctions(WeaponType.ChainGun,{
	getNumWeapons = function(self) return {self.rand:getInt(1,3)} end,
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 1.2,
})
TurretGenerator.replaceFunctions(WeaponType.PointDefenseChainGun,{
	getNumWeapons = function(self) return {self.rand:getInt(2,3)} end,
	getGuaranteedSpecialtiesTable = {'AutomaticFire'},
	turnSpeedFactor = 2,
})
TurretGenerator.replaceFunctions(WeaponType.PointDefenseLaser,{
	getNumWeapons = function(self) return {1} end,
	getGuaranteedSpecialtiesTable = {'AutomaticFire'},
	turnSpeedFactor = 2,
})
TurretGenerator.replaceFunctions(WeaponType.Laser, {
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyCooling = function(self)
		local rechargeTime = 30 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 20 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
})
TurretGenerator.replaceFunctions(WeaponType.MiningLaser,{
	crewType = CrewProfessionType.Miner,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	extraDescriptions = function(self)
		local percentage = math.floor(self.weapons[1].stoneDamageMultiplier * 100)
		self.turret:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))
	end,
})
TurretGenerator.replaceFunctions(WeaponType.RawMiningLaser,{
	crewType = CrewProfessionType.Miner,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	extraDescriptions = function(self)
		local percentage = math.floor(self.weapons[1].stoneDamageMultiplier * 100)
		self.turret:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))
	end,
})
TurretGenerator.replaceFunctions(WeaponType.SalvagingLaser,{
	crewType = CrewProfessionType.Miner,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
})
TurretGenerator.replaceFunctions(WeaponType.RawSalvagingLaser,{
	crewType = CrewProfessionType.Miner,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
})
TurretGenerator.replaceFunctions(WeaponType.PlasmaGun,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 4)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 0.9,
})
TurretGenerator.replaceFunctions(WeaponType.RocketLauncher,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyWeapons = function(self)
		local positions = {}
		if self.rand:getBool() then
			table.insert(positions, vec3(0, 0.3, 0))
		else
			table.insert(positions, vec3(0.4, 0.3, 0))
			table.insert(positions, vec3(-0.4, 0.3, 0))
		end

		-- attach
		for _, position in pairs(positions) do
			self.weapons[1].localPosition = position * self.turret.size * self.scale.size
			self.turret:addWeapon(self.weapons[1])
		end
	end,
	getGuaranteedSpecialtiesTable = {'Explosive'},
	applyCooling = function(self)
		local shootingTime = 20 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.5,
	turnSpeedFactor = 0.6,
})
TurretGenerator.replaceFunctions(WeaponType.Cannon,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 4)} end,
	applyCooling = function(self)
		local shootingTime = 25 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.5,
	turnSpeedFactor = 0.6,
})
TurretGenerator.replaceFunctions(WeaponType.RailGun,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 3)} end,
	getGuaranteedSpecialtiesTable = {'Penetration'},
	applyCooling = function(self)
		local shootingTime = 27.5 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 10 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 0.75,
})
TurretGenerator.replaceFunctions(WeaponType.RepairBeam,{
	crewType = CrewProfessionType.Repair,
	applyCooling = function(self)
		local rechargeTime = 15 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 10 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	applyWeapons = function(self)
		if self.rand:test(0.125) == true then
			local weapon = self:getWeapon()
			weapon.localPosition = vec3(0.1, 0, 0) * self.scale.size
			if weapon.shieldRepair > 0 then
				weapon.bouterColor = ColorRGB(0.1, 0.2, 0.4)
				weapon.binnerColor = ColorRGB(0.2, 0.4, 0.9)
				weapon.shieldPenetration = 0
			else
				weapon.bouterColor = ColorARGB(0.5, 0, 0.5, 0)
				weapon.binnerColor = ColorRGB(1, 1, 1)
				weapon.shieldPenetration = 1
			end
			self.turret:addWeapon(weapon)

			weapon.localPosition = vec3(-0.1, 0, 0) * self.scale.size

			-- swap the two properties
			local shieldRepair = weapon.shieldRepair
			weapon.shieldRepair = weapon.hullRepair
			weapon.hullRepair = shieldRepair
			if weapon.shieldRepair > 0 then
				weapon.bouterColor = ColorRGB(0.1, 0.2, 0.4)
				weapon.binnerColor = ColorRGB(0.2, 0.4, 0.9)
				weapon.shieldPenetration = 0
			else
				weapon.bouterColor = ColorARGB(0.5, 0, 0.5, 0)
				weapon.binnerColor = ColorRGB(1, 1, 1)
				weapon.shieldPenetration = 1
			end
			self.turret:addWeapon(weapon)

		else
			-- just attach normally
			TurretConstructor.attachWeapons(self)
		end
	end,
})
TurretGenerator.replaceFunctions(WeaponType.Bolter,{
	applyCooling = function(self)
		local shootingTime = 7 * self.rand:getFloat(0.9, 1.3)
		local coolingTime = 5 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	getNumWeapons = function(self) return {1, 2, 4} end,
	turnSpeedFactor = 0.9,
})
TurretGenerator.replaceFunctions(WeaponType.LightningGun,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.15,
	turnSpeedFactor = 0.75,
})
TurretGenerator.replaceFunctions(WeaponType.TeslaGun,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.15,
	turnSpeedFactor = 1.2,
})
TurretGenerator.replaceFunctions(WeaponType.ForceGun,{
	getCrew = function(self)
		local requiredCrew = math.floor(1 + math.sqrt(self.dps / 2000))
		local crew = Crew()
		crew:add(requiredCrew, CrewMan(CrewProfessionType.Engine))
		return crew
	end,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	getWeapons = function(self) -- Might result in offset beams, overwrite applyWeapons if so
		local weapons = TurretConstructor.getWeapons(self)
		local empty = self:getWeapon()
		empty.selfForce = 0
		empty.otherForce = 0
		empty.bshape = BeamShape.Swirly
		empty.bshapeSize = 1.25
		empty.appearance = WeaponAppearance.Invisible
		for _, weapon in pairs(weapons) do
			if weapon.otherForce ~= 0 then weapon.otherForce = weapon.otherForce / #weapons end
			if weapon.selfForce ~= 0 then weapon.selfForce = weapon.selfForce / #weapons end
		end
		for _=1, #weapons do
			table.insert(weapons, empty)
		end
		return weapons
	end,
	applyCooling = function(self)
		local forceToEnergy = self.rand:getFloat(1, 4)
		local rechargeTime = self.dps / 1000 * forceToEnergy
		local shootingTime = rechargeTime * self.rand:getFloat(0.7, 0.9)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
})
TurretGenerator.replaceFunctions(WeaponType.PulseCannon,{
	getNumWeapons = function(self) return {self.rand:getInt(1, 3)} end,
	applyCooling = function(self)
		local shootingTime = 15 * self.rand:getFloat(1, 1.5)
		local coolingTime = 5 * self.rand:getFloat(1, 1.5)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
		-- adjust damage since pulse guns' DPS only decreases with cooling introduced
		-- pulse guns have no other damage boost like rockets, cannons or railguns
		for _, weapon in pairs(self.weapons) do
			weapon.damage = weapon.damage * ((coolingTime + shootingTime) / shootingTime)
		end
	end,
	getGuaranteedSpecialtiesTable = {'IonizedProjectile'},
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 1.2,
})
TurretGenerator.replaceFunctions(WeaponType.AntiFighter,{
	getNumWeapons = function(self) return {self.rand:getInt(1,3)} end,
	getGuaranteedSpecialtiesTable = {'Explosive', 'AutomaticFire'},
	turnSpeedFactor = 1.2,
})