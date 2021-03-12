package.path = package.path .. ";data/scripts/lib/?.lua"

include('refineutility')
include('goods')
include('callable')

-- namespace BuildingResourcesAsGoods
BuildingResourcesAsGoods = {}
--[[
function BuildingResourcesAsGoods.secure()
	local data = {}
	data.old = BuildingResourcesAsGoods.old
	return data
end

function BuildingResourcesAsGoods.restore(data)
	BuildingResourcesAsGoods.old = data.old
end
]]

--[[
	if not BuildingResourcesAsGoods.setting then
		local player = Player()
		local entity = player.craft
		local cargoBay = CargoBay(entity)
		for k, v in pairs(resources) do
			local name = nameByMaterial[k]
			local delta = v - (entity:getCargoAmount(name) or 0)
			local good = goods[name]:good()
			if delta > 0 then
				print('adding', delta)

				local goodamount = delta * good.size
				local val = cargoBay.freeSpace - goodamount
				local cond = (val > 0)
				if not cond then
					local ret = {}
					for k1, v in pairs(nameByMaterial) do
						ret[k1] = 0
						if k1 == k then
							ret[k1] = math.ceil(math.abs(val) / good.size)
						end
					end
					BuildingResourcesAsGoods.setting = true
					player:payWithoutNotify('OverCargo', 0, unpack(ret))
				end
				local amount = cond and delta or math.ceil(cargoBay.freeSpace/good.size)
				cargoBay:addCargo(good, amount)

			elseif delta ~= 0 then
				print('removing', delta)
				entity:removeCargo(good, math.abs(delta))
			end
		end
	else
		BuildingResourcesAsGoods.setting = false
	end]]
--[[
		for k, v in pairs(resources) do
			local name = nameByMaterial[k]
			local good = goods[name]:good()
			local amount = player.craft:getCargoAmount(name)
			local delta = v - amount --cargoBay.freeSpace
			if delta > 0 then
				print('added', delta)
				cargoBay:addCargo(good, math.min(cargoBay.freeSpace, delta*good.size)/good.size)
			elseif delta < 0 then
				print('removed', delta)
				cargoBay:removeCargo(good, math.max(cargoBay.freeSpace, math.abs(delta)*good.size)/good.size)
			end
		end
		]]

function BuildingResourcesAsGoods.setSetting(value)
	BuildingResourcesAsGoods.setting = value
end

function BuildingResourcesAsGoods.onResourcesChanged(_, resources)
	if onClient() then
		invokeServerFunction('onResourcesChanged', _, resources)
		return
	end

	local player = Player()
	if not player.craft.playerOwned then return end
	print(BuildingResourcesAsGoods.setting)
	if BuildingResourcesAsGoods.setting then
		deferredCallback(0, 'setSetting', false) --BuildingResourcesAsGoods.setting) = false
	else
		local cargoBay = CargoBay(player.craft)
		for k, v in pairs(resources) do
			local name = nameByMaterial[k]
			local good = goods[name]:good()
			local amount = player.craft:getCargoAmount(name) or 0
			local delta = v - amount --cargoBay.freeSpace
			if delta > 0 then
				cargoBay:addCargo(good, delta)
			elseif delta < 0 then
				cargoBay:removeCargo(good, math.abs(delta))
			end
		end

		BuildingResourcesAsGoods.onShipChanged(player.index, player.craft.index)
	end
end
callable(BuildingResourcesAsGoods, 'onResourcesChanged')


function BuildingResourcesAsGoods.onShipChanged(playerIndex, craftId)
	local entity = Entity(craftId)
	if not entity.playerOwned then return end
	local resources = {}
	for k, v in pairs(nameByMaterial) do
		resources[k] = entity:getCargoAmount(v) or 0
	end
	BuildingResourcesAsGoods.setting = true
	Player(playerIndex):setResources(unpack(resources))
end

--[[
function BuildingResourcesAsGoods.onCargoChanged(craftId, delta, good)
	local is_resource = false
	for k, v in pairs(nameByMaterial) do
		if good.name == v then is_resource = true end
	end
	if is_resource then
		BuildingResourcesAsGoods.onShipChanged(Player().index, craftId)
	end
end
]]

function BuildingResourcesAsGoods.initialize()
	local player = Player()
	if onClient() then
		player:registerCallback('onResourcesChanged', 'onResourcesChanged')
	else
		player:registerCallback('onShipChanged', 'onShipChanged')
		--player.craft:registerCallback('onCargoChanged', 'onCargoChanged')
	end
end