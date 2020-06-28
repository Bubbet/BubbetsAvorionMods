package.path = package.path .. ";data/scripts/lib/?.lua"

include('refineutility')
include('goods')
include('callable')

-- namespace BuildingResourcesAsGoods
BuildingResourcesAsGoods = {}

function BuildingResourcesAsGoods.onMaterialLootCollected(collector, lootIndex, materialType, value)
	local resource_out = {}
	for k, v in pairs(nameByMaterial) do
		resource_out[k] = 0
		if materialType == (k-1) then
			resource_out[k] = value
			Entity(collector):addCargo(goods[v]:good(), value)
		end
	end
	BuildingResourcesAsGoods.owner:invokeFunction('data/scripts/player/buildingresourcesasgoods.lua', 'setSetting', true)
	BuildingResourcesAsGoods.owner:pay('', 0, unpack(resource_out))
end

function BuildingResourcesAsGoods.initialize()
	local entity = Entity()
	BuildingResourcesAsGoods.owner = Player(entity.factionIndex) or Alliance(entity.factionIndex)
	if onServer() then
		entity:registerCallback('onMaterialLootCollected', 'onMaterialLootCollected')
	end
end