function onInstalled(seed_, rarity_, permanent_)
	if not permanent_ then return end
	local energy = getBonuses(seed_, rarity_, permanent_)
	seed, rarity, permanent = seed_, rarity_, permanent_

	bonuses = {addAbsoluteBias(StatsBonuses.Velocity, 10000000.0), addBaseMultiplier(StatsBonuses.GeneratedEnergy, -energy)}
end

function getUpdateInterval()
	return 1
end

function updateServer()
	local entity = Entity()
	if entity:hyperspaceBlocked() then
		for k, v in pairs(bonuses or {}) do
			removeBonus(v)
		end
		hasBeenBlocked = true
	elseif hasBeenBlocked then
		hasBeenBlocked = false
		onInstalled(seed, rarity, permanent)
	end
end