function SectorTurretGenerator:generateMoreRandom(x, y, offset_in, rarity_in, type_in, material_in, seed_in)

    local offset = offset_in or 0
    local dps = 0

    local rarities = self.rarities or self:getSectorRarityDistribution(x, y)
    local rarity = rarity_in or Rarity(getValueFromDistribution(rarities, self.random))

    local sector = math.max(0, math.floor(length(vec2(x, y))) + offset)

    local weaponDPS, weaponTech = Balancing_GetSectorWeaponDPS(sector, 0)
    local miningDPS, miningTech = Balancing_GetSectorMiningDPS(sector, 0)
    local materialProbabilities = Balancing_GetTechnologyMaterialProbability(sector, 0)
    local material = material_in or Material(getValueFromDistribution(materialProbabilities, self.random))
    local weaponType = type_in or getValueFromDistribution(Balancing_GetWeaponProbability(sector, 0), self.random)

    local tech = 0
    if weaponType == WeaponType.MiningLaser then
        dps = miningDPS
        tech = miningTech
    elseif weaponType == WeaponType.RawMiningLaser then
        dps = miningDPS * 2
        tech = miningTech
    elseif weaponType == WeaponType.ForceGun then
        dps = 1200
        tech = weaponTech
    else
        dps = weaponDPS
        tech = weaponTech
    end

    return TurretGenerator.generateSeeded(seed_in or self.seed, weaponType, dps, tech, rarity, material)
end