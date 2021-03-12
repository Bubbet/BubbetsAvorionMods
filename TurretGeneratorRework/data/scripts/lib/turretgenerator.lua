Specialties = { -- You might want to modify this if you've got lots of weapons that will be using a new specialty as every turret will try to index it
	HighDamage = function(self)
		local maxIncrease = 1.2
		local increase = 0.3 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		for _, weapon in pairs(self.weapons) do
			weapon.damage = weapon.damage * (1 + increase)
		end

		local addition = math.floor(increase * 100 + 0.00001) -- TODO rounding
		self.descriptions["Damage"] = {priority = 0, str = "%s%% Damage"%_T, value = string.format("%+i", addition)}
	end,
	HighRange = function(self)
		local maxIncrease = 0.3
		local increase = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		for _, weapon in pairs(self.weapons) do
			weapon.reach = weapon.reach * (1 + increase)
		end

		local addition = math.floor(increase * 100)
		self.descriptions["Range"] = {priority = 2, str = "%s%% Range"%_T, value = string.format("%+i", addition)}
	end,
	HighFireRate = function(self) end,
	BurstFireEnergy = function(self)
		local fireRate = self.turret.fireRate
		local fireDelay = 1 / fireRate

		local increase = self.rand:getFloat(2, 3)
		fireRate = math.max(fireRate * increase, 6)

		for _, weapon in pairs(self.weapons) do
			weapon.fireRate = fireRate / #self.weapons
		end

		self:reAddWeapons()

		TurretGenerator.createBatteryChargeCooling(self.turret, fireRate * fireDelay, 1)
	end,
	BurstFire = function(self)
		local fireRate = self.turret.fireRate
		local fireDelay = 1 / fireRate

		local increase = self.rand:getFloat(2, 3)
		fireRate = math.max(fireRate * increase, 6)

		local coolingTime = fireRate * fireDelay

		for _, weapon in pairs(self.weapons) do
			weapon.fireRate = fireRate / #self.weapons
			weapon.damage = weapon.damage * coolingTime
		end

		self:reAddWeapons()

		TurretGenerator.createStandardCooling(self.turret, coolingTime, 1)
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
		self.descriptions["Efficiency"] = {priority = 3, str = "%s%% Efficiency"%_T, value = string.format("%+i", addition)}
	end, -- only applicable to salvage and mining laser
	HighShootingTime = function(self)
		local maxIncrease = 2.9
		local increase = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxIncrease

		TurretGenerator.createStandardCooling(self.turret, self.turret.coolingTime, self.turret.shootingTime * (1 + increase))

		local percentage = math.floor(increase * 100)
		self.descriptions["ShootUntilOverheated"] = {priority = 4, str = "%s%% Shooting Until Overheated"%_T, value = string.format("%+i", percentage)}
	end,
	LessEnergyConsumption = function(self)
		local maxDecrease = 0.6
		local decrease = 0.1 + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * maxDecrease

		TurretGenerator.createBatteryChargeCooling(self.turret, self.turret.coolingTime * (1 - decrease), self.turret.shootingTime)

		local percentage = math.floor(decrease * 100)
		self.descriptions["LessEnergy"] = {priority = 5, str = "%s%% Less Energy Consumption"%_T, value = string.format("%+i", percentage)}
	end,
	IonizedProjectile = function(self)
		local chance = self.rand:getFloat(0.7, 0.8)
		local varChance = 1 - chance
		chance = chance + self.rand:getFloat(0, self.rarity.value / HighestRarity().value) * varChance

		for _, weapon in pairs(self.weapons) do
			weapon.shieldPenetration = chance
		end

		local percentage = math.floor(chance * 100 + 0.0000001) -- TODO rounding
		self.descriptions["IonizedProjectiles"] = {priority = 6, str = "Ionized Projectiles"%_T}
		self.descriptions["ShieldPen"] = {priority = 6.1, str = "%s%% Chance of penetrating shields"%_T, value = string.format("%+i", percentage)}
	end,
	Penetration = function(self) end,
	Explosive = function(self) end, -- AOE damage
	SimultaneousShooting = function(self)
		self.turret.simultaneousShooting = true
	end,
}

--TODO split each turret into its own file like the upgrade generator does
TurretConstructor = {}

--region Base Turret
TurretConstructor.baseTurret = {}

-- Define crewAmount, crewType to use it instead.
function TurretConstructor.baseTurret:addCrew()
	self.crew = Crew()
	self.crew:add(self.crewAmount or TurretGenerator.dpsToRequiredCrew(self.dps), CrewMan(self.crewType or CrewProfessionType.Gunner))
	self.turret.crew = self.crew
end

function TurretConstructor.baseTurret:getNumWeapons()
	return {1, 2, 4}
end

function TurretConstructor.baseTurret:getWeapon()
	return WeaponGenerator.generateWeapon(self.rand, self.type, self.dps, self.tech, self.material, self.rarity) -- Replace this later?
end

function TurretConstructor.baseTurret:generateWeapons()
	local weapons = self:getNumWeapons()
	local numWeapons = weapons[self.rand:getInt(1, #weapons)]
	local weapon = self:getWeapon()
	weapon.fireDelay = weapon.fireDelay * numWeapons
	self.weapons = {}
	for _ = 1, numWeapons do
		table.insert(self.weapons, weapon)
	end
end

function TurretConstructor.baseTurret:reAddWeapons()
	self.turret:clearWeapons()
	for _, weapon in pairs(self.weapons) do
		self.turret:addWeapon(weapon)
	end
end

function TurretConstructor.baseTurret:attachWeapons()
	self.turret:clearWeapons()
	local places = {TurretGenerator.createWeaponPlaces(self.rand, #self.weapons)}
	for k, v in pairs(self.weapons) do
		v.localPosition = places[k] * self.turret.size -- * self.turret.size --* self.scale.size or 1 causes really disjointed turrets
		--v.localPosition = v.localPosition * self.scale.size
		self.turret:addWeapon(v)
	end
end

function TurretConstructor.baseTurret:getWeaponScaleTable()
	return scales[self.type] or {
		{from = 0, to = 18, size = 0.5, usedSlots = 1},
		{from = 19, to = 33, size = 1.0, usedSlots = 2},
		{from = 34, to = 45, size = 1.5, usedSlots = 3},
		{from = 46, to = 52, size = 2.0, usedSlots = 4},
	}
end

function TurretConstructor.baseTurret:getTurningSpeed()
	return lerp(self.turret.size, 0.5, 3, 1, 0.3) * self.rand:getFloat(0.8, 1.2) * (self.turnSpeedFactor or 1)
end

function TurretConstructor.baseTurret:generateScale()
	local size, usedSlots = 1, 1

	local scaleTech = self.tech
	if self.rand:test(0.5) then
		scaleTech = math.floor(math.max(1, scaleTech * self.rand:getFloat(0, 1)))
	end

	for _, scale in pairs(self:getWeaponScaleTable()) do
		if scaleTech >= scale.from and scaleTech <= scale.to then
			size = scale.size
			usedSlots = scale.usedSlots
		end
	end

	self.turret.coaxial = (usedSlots >= 5) and (self.rand:test(0.25) or not self.coaxialImpossible) -- replaces coaxialPossible being the inverse, its easier to write this way

	self.turret.size = size
	self.turret.slots = usedSlots
	self.turret.turningSpeed = self:getTurningSpeed()
end

function TurretConstructor.baseTurret:getReachFactor()
	return (self.turret.slots - 1) * 0.15
end

function TurretConstructor.baseTurret:getShotSizeFactor()
	return self.turret.size * 2
end

function TurretConstructor.baseTurret:scaleWeapons()
	for _, weapon in pairs(self.weapons) do
		if self.turret.slots > 1 then
			self.coaxialScale = (self.turret.coaxial and (self.coaxialDamageScale or 3) or 1) -- for use in hullRepair, shieldRepair etc
			weapon.damage = weapon.damage * self.turret.slots * self.coaxialScale
			weapon.reach = weapon.reach * self:getReachFactor()
			if weapon.isProjectile then weapon.psize = weapon.psize * self:getShotSizeFactor() end
			if weapon.isBeam then weapon.bwidth = weapon.bwidth * self:getShotSizeFactor() end
		end
	end
end

function TurretConstructor.baseTurret:getPossibleSpecialties()
	return possibleSpecialties[self.type] -- Ideally the possibleSpecialties would have its entry here instead
end

function SpecialtyKeyFromValue(value)
	for k, v in pairs(Specialty) do
		if v == value then return k end
	end
end

function TurretConstructor.baseTurret:getSpecialtiesTable() -- You can overload this function to change how specialties act for a weapon
	local tab = {}
	for _, v in pairs(self:getPossibleSpecialties()) do
		local key = SpecialtyKeyFromValue(v.specialty)
		table.insert(tab, {name = key, func = Specialties[key], probability = v.probability})
	end
	return tab
end

function TurretConstructor.baseTurret:getSpecialties()
	local specialties = {}

	local simultaneousShooting
	for _, v in pairs(self:getSpecialtiesTable()) do
		if v.name == 'SimultaneousShooting' then
			simultaneousShooting = v.func
		end
		if not ( self.turret.coaxial and v.name == 'AutomaticFire' ) then
			if self.rand:test(v.probability * (self.rarity.value + 0.2)) then
				table.insert(specialties, v.func)
			end
		end
	end

	local maxNumSpecialties = self.rand:getInt(0, 1 + math.modf(self.rarity.value / 2)) -- round to zero

	for _=1, math.max(0, maxNumSpecialties - #specialties) do
		table.remove(specialties, self.rand:getInt(1, #specialties))
	end

	if self.getGuaranteedSpecialtiesTable then
		for _, v in pairs(self:getGuaranteedSpecialtiesTable()) do
			table.insert(specialties, v)
		end
	end

	if simultaneousShooting and self.simultaneousShootingProbability and self.rand:test(self.simultaneousShootingProbability) then
		table.insert(specialties, simultaneousShooting)
	end

	return specialties
end

function TurretConstructor.baseTurret:addSpecialities()
	self.turret:updateStaticStats()

	self.descriptions = {}

	for _, v in pairs(self:getSpecialties()) do
		v(self)
	end

	self:reAddWeapons()

	local sortedDescriptions = {}
	for _, desc in pairs(self.descriptions) do
		table.insert(sortedDescriptions, desc)
	end

	table.sort(sortedDescriptions, function(a, b) return a.priority < b.priority end)

	for _, desc in pairs(sortedDescriptions) do
		self.turret:addDescription(desc.str or "", desc.value or "")
	end
end

function TurretConstructor.baseTurret:build(_type, rand, dps, tech, material, rarity)
	self.type = _type
	self.rand = rand
	self.dps = dps
	self.tech = tech
	self.material = material
	self.rarity = rarity
	self.turret = TurretTemplate()
	self:addCrew()
	self:generateWeapons()
	self:generateScale()
	self:scaleWeapons()
	self:attachWeapons()
	if self.applyCooling then self:applyCooling() end
	if self.extraDescriptions then self:extraDescriptions() end
	self:addSpecialities()
	self.turret:updateStaticStats()
	return self.turret
end

--endregion

function function_from_object(_type, object)
	if not _type or not object then return end
	generatorFunction[_type] = function(rand, dps, tech, material, rarity)
		setmetatable(object, {__index = TurretConstructor.baseTurret})
		return object:build(_type, rand, dps, tech, material, rarity)
	end
end

function get_specialty_by_name(name)
	for k, v in pairs(Specialties) do
		if k == name then
			return v
		end
	end
end

--region Vanilla Guns
TurretConstructor.ChainGun = {
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 1.2
}
function TurretConstructor.ChainGun:getNumWeapons() return {self.rand:getInt(1,3)} end
function_from_object(WeaponType.ChainGun, TurretConstructor.ChainGun)

TurretConstructor.PointDefenseChainGun = {
	turnSpeedFactor = 2
}
function TurretConstructor.PointDefenseChainGun:getNumWeapons() return {self.rand:getInt(2,3)} end
function TurretConstructor.PointDefenseChainGun:getGuaranteedSpecialtiesTable()
	return {get_specialty_by_name('AutomaticFire')}
end
function_from_object(WeaponType.PointDefenseChainGun, TurretConstructor.PointDefenseChainGun)

TurretConstructor.PointDefenseLaser = {
	turnSpeedFactor = 2
}
function TurretConstructor.PointDefenseLaser:getNumWeapons() return {1} end
function TurretConstructor.PointDefenseLaser:getGuaranteedSpecialtiesTable()
	return {get_specialty_by_name('AutomaticFire')}
end
function_from_object(WeaponType.PointDefenseLaser, TurretConstructor.PointDefenseLaser)

TurretConstructor.Laser = {}
function TurretConstructor.Laser:getNumWeapons() return {self.rand:getInt(1,2)} end
function TurretConstructor.Laser:applyCooling()
	local rechargeTime = 30 * self.rand:getFloat(0.8, 1.2)
	local shootingTime = 20 * self.rand:getFloat(0.8, 1.2)
	TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
end
function_from_object(WeaponType.Laser, TurretConstructor.Laser)

TurretConstructor.MiningLaser = {
	crewType = CrewProfessionType.Miner
}
function TurretConstructor.MiningLaser:getNumWeapons() return {self.rand:getInt(1, 2)} end
function TurretConstructor.MiningLaser:extraDescriptions()
	local percentage = math.floor(self.weapons[1].stoneDamageMultiplier * 100)
	self.turret:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))
end
function_from_object(WeaponType.MiningLaser, TurretConstructor.MiningLaser)

TurretConstructor.RawMiningLaser = {
	crewType = CrewProfessionType.Miner
}
function TurretConstructor.RawMiningLaser:getNumWeapons() return {self.rand:getInt(1, 2)} end
function TurretConstructor.RawMiningLaser:extraDescriptions()
	local percentage = math.floor(self.weapons[1].stoneDamageMultiplier * 100)
	self.turret:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))
end
function_from_object(WeaponType.RawMiningLaser, TurretConstructor.RawMiningLaser)

TurretConstructor.SalvagingLaser = {
	crewType = CrewProfessionType.Miner
}
function TurretConstructor.SalvagingLaser:getNumWeapons() return {self.rand:getInt(1, 2)} end
function_from_object(WeaponType.SalvagingLaser, TurretConstructor.SalvagingLaser)

TurretConstructor.RawSalvagingLaser = {
	crewType = CrewProfessionType.Miner
}
function TurretConstructor.RawSalvagingLaser:getNumWeapons() return {self.rand:getInt(1, 2)} end
function_from_object(WeaponType.RawSalvagingLaser, TurretConstructor.RawSalvagingLaser)

-- A different way of doing the same thing from here on:
TurretConstructor.PlasmaGun = {
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 0.9,
	getNumWeapons = function(self) return {self.rand:getInt(1, 4)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end
}
function_from_object(WeaponType.PlasmaGun, TurretConstructor.PlasmaGun)

TurretConstructor.RocketLauncher = {
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
	getGuaranteedSpecialtiesTable = function(self)
		return {get_specialty_by_name('Explosive')}
	end,
	applyCooling = function(self)
		local shootingTime = 20 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.5,
	turnSpeedFactor = 0.6,
}
function_from_object(WeaponType.RocketLauncher, TurretConstructor.RocketLauncher)

TurretConstructor.Cannon = {
	getNumWeapons = function(self) return {self.rand:getInt(1, 4)} end,
	applyCooling = function(self)
		local shootingTime = 25 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.5,
	turnSpeedFactor = 0.6,
}
function_from_object(WeaponType.Cannon, TurretConstructor.Cannon)

TurretConstructor.RailGun = {
	getNumWeapons = function(self) return {self.rand:getInt(1, 3)} end,
	getGuaranteedSpecialtiesTable = function(self) return {get_specialty_by_name('Penetration')} end,
	applyCooling = function(self)
		local shootingTime = 27.5 * self.rand:getFloat(0.8, 1.2)
		local coolingTime = 10 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 0.75,
}
function_from_object(WeaponType.RailGun, TurretConstructor.RailGun)

TurretConstructor.RepairBeam = {
	crewType = CrewProfessionType.Repair,
	applyCooling = function(self)
		local rechargeTime = 15 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 10 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	attachWeapons = function(self)
		if self.rand:test(0.125) == true then
			local weapon = self:getWeapon()
			weapon.localPosition = vec3(0.1, 0, 0) --* self.scale.size
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

			weapon.localPosition = vec3(-0.1, 0, 0) --* self.scale.size

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
			TurretConstructor.baseTurret.attachWeapons(self)
		end
	end,
}
function_from_object(WeaponType.RepairBeam, TurretConstructor.RepairBeam)

TurretConstructor.Bolter = {
	applyCooling = function(self)
		local shootingTime = 7 * self.rand:getFloat(0.9, 1.3)
		local coolingTime = 5 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createStandardCooling(self.turret, coolingTime, shootingTime)
	end,
	getNumWeapons = function(self) return {1, 2, 4} end,
	turnSpeedFactor = 0.9,
}
function_from_object(WeaponType.Bolter, TurretConstructor.Bolter)

TurretConstructor.LightningGun = {
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.15,
	turnSpeedFactor = 0.75,
}
function_from_object(WeaponType.LightningGun, TurretConstructor.LightningGun)

TurretConstructor.TeslaGun = {
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	applyCooling = function(self)
		local rechargeTime = 20 * self.rand:getFloat(0.8, 1.2)
		local shootingTime = 15 * self.rand:getFloat(0.8, 1.2)
		TurretGenerator.createBatteryChargeCooling(self.turret, rechargeTime, shootingTime)
	end,
	simultaneousShootingProbability = 0.15,
	turnSpeedFactor = 1.2,
}
function_from_object(WeaponType.TeslaGun, TurretConstructor.TeslaGun)

TurretConstructor.ForceGun = {
	getCrew = function(self)
		local requiredCrew = math.floor(1 + math.sqrt(self.dps / 2000))
		local crew = Crew()
		crew:add(requiredCrew, CrewMan(CrewProfessionType.Engine))
		return crew
	end,
	getNumWeapons = function(self) return {self.rand:getInt(1, 2)} end,
	generateWeapons = function(self) -- Might result in offset beams, overwrite applyWeapons if so
		TurretConstructor.baseTurret.generateWeapons(self)
		local weapons = self.weapons
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
}
function_from_object(WeaponType.ForceGun, TurretConstructor.ForceGun)

TurretConstructor.PulseCannon = {
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
	getGuaranteedSpecialtiesTable = function(self) return {get_specialty_by_name('IonizedProjectile')} end,
	simultaneousShootingProbability = 0.25,
	turnSpeedFactor = 1.2,
}
function_from_object(WeaponType.PulseCannon, TurretConstructor.PulseCannon)

TurretConstructor.AntiFighter = {
	getNumWeapons = function(self) return {self.rand:getInt(1,3)} end,
	getGuaranteedSpecialtiesTable = function(self) return {get_specialty_by_name('Explosive'), get_specialty_by_name('AutomaticFire')} end,
	turnSpeedFactor = 1.2,
}
function_from_object(WeaponType.AntiFighter, TurretConstructor.AntiFighter)
--endregion
