function PlanGenerator.makeAsyncShipPlan(callback, values, faction, volume, styleName, material, sync)
	local seed = math.random(0xffffffff)

	if not material then
		material = PlanGenerator.selectMaterial(faction)
	end

	local code = [[
        package.path = package.path .. ";data/scripts/lib/?.lua"
        package.path = package.path .. ";data/scripts/?.lua"

        local FactionPacks = include ("factionpacks")
        local PlanGenerator = include ("plangenerator")

        function run(styleName, seed, volume, material, factionIndex, ...)

            local faction = Faction(factionIndex)
            if not volume then
                volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());
                local deviation = Balancing_GetShipVolumeDeviation();
                volume = volume * deviation
            end

            local plan, turret = FactionPacks.getShipPlan(faction, volume, material)
            if plan then return {ship = plan, turret = turret}, ... end

            local style = PlanGenerator.getShipStyle(faction, styleName)

            plan = GeneratePlanFromStyle(style, Seed(seed), volume, 6000, 1, material)
            return plan, ...
        end
    ]]

	if sync then
		return execute(code, styleName, seed, volume, material, faction.index)
	else
		values = values or {}
		async(callback, code, styleName, seed, volume, material, faction.index, unpack(values))
	end
end