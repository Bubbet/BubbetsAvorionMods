package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
local Node = include('node')
include('callable')
include('ElementToTable')
include ("reconstructiontoken")
include ("productions")

--namespace ResourceMerge
ResourceMerge = {}

function ResourceMerge.interactionPossible(playerIndex, option)
	if checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FoundStations, AlliancePrivilege.ManageStations) then
		return true, ""
	end

	return false
end

function ResourceMerge.initUI()
	local res = getResolution()
	local size = vec2(300, 300)
	---@type ScriptUI
	ResourceMerge.menu = ElementToTable(ScriptUI())
	local window = ResourceMerge.menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	ResourceMerge.menu:registerWindow(window.element, "Merge Resource Mines")
	window.element.caption = "Merge Resource Mines"
	window.element.showCloseButton = true
	window.element.moveable = true
	ResourceMerge.window = window

	local rootNode = Node(window.size)
	ResourceMerge.rootNode = rootNode

	local container = window:createContainer(rootNode)
	ResourceMerge.container = container

	local top, mid, bot = rootNode:pad(10):rows({1, 30, 30}, 10)
	ResourceMerge.label = container:createTextField(top, "")
	container:createFrame(top)
	ResourceMerge.combo = container:createComboBox(mid, "")
	ResourceMerge.stations = {}

	local left, right = bot:cols(2, 10)
	container:createButton(left, "Merge!", "onMergePressed")
	container:createButton(right, "Cancel", "onCancelButtonPress")
end


function ResourceMerge.getCost()
	return getFactoryUpgradeCost(ResourceMerge.local_production, 6) * 1.5 -- from rsm cost mul
end

function ResourceMerge.onShowWindow()
	ResourceMerge.stations = {}
	ResourceMerge.combo:clear()
	local entity = Entity()
	local ok, local_production = entity:invokeFunction("data/scripts/entity/merchants/factory.lua", "old_getProduction")
	ResourceMerge.local_production = local_production
	ResourceMerge.label.element.text = "Merging resource mines together will give you nothing for the upgrades you've given your mine, it only combines the production per cycle.\n\nMerging costs ${cost} and is permanent. Crew and Goods are deleted in the target mine."%_T % {cost = createMonetaryString(ResourceMerge.getCost())}
	---@param v Entity
	for k, v in pairs({Sector():getEntitiesByScript("data/scripts/entity/merchants/factory.lua")}) do
		local ok, production = v:invokeFunction("data/scripts/entity/merchants/factory.lua", "old_getProduction")
		if v.index ~= entity.index and v.factionIndex == entity.factionIndex and production.results[1].name == local_production.results[1].name then
			table.insert(ResourceMerge.stations, v)
			ResourceMerge.combo:addEntry(v.name)
		end
	end
end

function ResourceMerge.onMergePressed(id)
	if onClient() then
		if not ResourceMerge.stations[ResourceMerge.combo.selectedIndex+1] then return end
		invokeServerFunction("onMergePressed", ResourceMerge.stations[ResourceMerge.combo.selectedIndex+1].index)
		ResourceMerge.onCancelButtonPress()
	else
		if not id then return end
		local buyer, _, _ = getInteractingFaction(callingPlayer, AlliancePrivilege.FoundStations, AlliancePrivilege.ManageStations)
		if not buyer then return end
		local entity = Entity()
		local target = Entity(id)
		if entity.index == target.index then return end
		if entity.factionIndex ~= target.factionIndex then return end
		local ok1, local_production = entity:invokeFunction("data/scripts/entity/merchants/factory.lua", "old_getProduction")
		local ok2, production = target:invokeFunction("data/scripts/entity/merchants/factory.lua", "old_getProduction")
		if ok1 ~= 0 or ok2 ~= 0 then return end
		ResourceMerge.local_production = local_production
		local cost = ResourceMerge.getCost()
		if not buyer:canPay(cost) then
			buyer:sendChatMessage(entity, ChatMessageType.Error, "You cannot afford to merge this asteroid."%_T)
			return
		end
		if target ~= entity and production.results[1].name == local_production.results[1].name then
			buyer:pay(cost)
			local_production.results[1].amount = local_production.results[1].amount + production.results[1].amount
			local ok1, val1 = entity:invokeFunction("data/scripts/entity/merchants/factory.lua", "setProduction", local_production)
			local ok2, val2 = entity:invokeFunction("data/scripts/entity/merchants/factory.lua", "sync")

			target:setPlan(BlockPlan())
			buyer:setShipDestroyed(target.name, true)
			target:destroy(Uuid(), 0, DamageType.Physical)
			buyer:removeDestroyedShipInfo(target.name)
			removeReconstructionTokens(buyer, target.name)

			local sector = Sector()
			sector:deleteEntity(target) -- TODO this isnt properly cleaning up the entity in some cases
			--sector:deleteEntityJumped(target)
			-- entity.crew = entity.crew + target.crew TODO fix this as there is no add method for crew
		end
	end
end
callable(ResourceMerge, "onMergePressed")

function ResourceMerge.onCancelButtonPress() ResourceMerge.menu:stopInteraction() end
