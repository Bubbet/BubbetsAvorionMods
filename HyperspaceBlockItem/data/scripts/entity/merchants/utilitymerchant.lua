package.path = package.path .. ";data/scripts/lib/?.lua"

local UpgradeGenerator = include("upgradegenerator")

local HyperBlockItem_addItems = UtilityMerchant.shop.addItems
function UtilityMerchant.shop:addItems()
	HyperBlockItem_addItems()
	local x, y = Sector():getCoordinates()
	local item = UsableInventoryItem("hyperspaceblocker.lua", Rarity(getValueFromDistribution(UpgradeGenerator():getSectorRarityDistribution(x, y))))
	local amount = getInt(-3, 2)
	if amount > 0 then UtilityMerchant.add(item, amount) end
end