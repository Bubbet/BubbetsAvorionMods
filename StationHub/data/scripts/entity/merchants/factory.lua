
local is_hub -- upvalue containing entity of hub if there is one, else nil
local old_funcs = {} --storing the old functions replaced in hub_funcs
local hub_funcs = { --the list of functions to overwrite, wrote in assumption that there is a hub
	onRestoredFromDisk = function(timeSinceLastSimulation) -- indexed with . might behave weird
		local boughtStock, soldStock = Factory.getInitialGoods(Factory.trader.boughtGoods, Factory.trader.soldGoods)
		local entity = is_hub -- only change

		local factor = math.max(0, math.min(1, (timeSinceLastSimulation - 10 * 60) / (100 * 60)))

		-- simulate deliveries to factory
		local faction = Faction()

		if faction and faction.isAIFaction then
			for good, amount in pairs(boughtStock) do
				local curAmount = entity:getCargoAmount(good)
				local diff = math.floor((amount - curAmount) * factor)

				if diff > 0 then
					Factory.increaseGoods(good.name, diff)
				end
			end
		end

		-- calculate production
		-- limit by time
		local maxAmountProduced = math.floor(timeSinceLastSimulation / Factory.timeToProduce) * Factory.maxNumProductions

		-- limit by goods
		for _, ingredient in pairs(production.ingredients) do
			if ingredient.optional == 0 then
				maxAmountProduced = math.min(maxAmountProduced, math.floor(Factory.getNumGoods(ingredient.name) / ingredient.amount))
			end
		end

		-- limit by space
		local productSpace = 0
		for _, ingredient in pairs(production.ingredients) do
			if ingredient.optional == 0 then
				local size = Factory.getGoodSize(ingredient.name)
				productSpace = productSpace - ingredient.amount * size
			end
		end

		for _, garbage in pairs(production.garbages) do
			local size = Factory.getGoodSize(garbage.name)
			productSpace = productSpace + garbage.amount * size
		end

		for _, result in pairs(production.results) do
			local size = Factory.getGoodSize(result.name)
			productSpace = productSpace + result.amount * size
		end

		if productSpace > 0 then
			maxAmountProduced = math.min(maxAmountProduced, math.floor(entity.freeCargoSpace / productSpace))
		end

		-- do production
		for _, ingredient in pairs(production.ingredients) do
			Factory.decreaseGoods(ingredient.name, ingredient.amount * maxAmountProduced)
		end

		for _, garbage in pairs(production.garbages) do
			Factory.increaseGoods(garbage.name, garbage.amount * maxAmountProduced)
		end

		for _, result in pairs(production.results) do
			Factory.increaseGoods(result.name, result.amount * maxAmountProduced)
		end

		-- simulate goods bought from the factory
		if faction and faction.isAIFaction then
			for good, amount in pairs(soldStock) do
				local curAmount = entity:getCargoAmount(good)
				local diff = math.floor((amount - curAmount) * factor)

				if diff < 0 then
					Factory.decreaseGoods(good.name, -diff)
				end
			end
		end
	end,
	updateProduction = function(timeStep)
		-- if the result isn't there yet, don't produce
		if not production then return end

		-- if not yet fully used, start producing
		local numProductions = tablelength(currentProductions)
		local canProduce = true

		if numProductions >= Factory.maxNumProductions then
			canProduce = false
			-- print("can't produce as there are no more slots free for production")
		end

		-- only start if there are actually enough ingredients for producing
		for i, ingredient in pairs(production.ingredients) do
			if ingredient.optional == 0 and Factory.getNumGoods(ingredient.name) < ingredient.amount then
				canProduce = false
				newProductionError = "Factory can't produce because ingredients are missing!"%_T
				-- print("can't produce due to missing ingredients: " .. ingredient.amount .. " " .. ingredient.name .. ", have: " .. Factory.getNumGoods(ingredient.name))
				break
			end
		end

		local station = is_hub -- only change
		for i, garbage in pairs(production.garbages) do
			local newAmount = Factory.getNumGoods(garbage.name) + garbage.amount
			local size = Factory.getGoodSize(garbage.name)

			if newAmount > Factory.getMaxStock(size) or station.freeCargoSpace < garbage.amount * size then
				canProduce = false
				newProductionError = "Factory can't produce because there is not enough cargo space for products!"%_T
				-- print("can't produce due to missing room for garbage")
				break
			end
		end

		for _, result in pairs(production.results) do
			local newAmount = Factory.getNumGoods(result.name) + result.amount
			local size = Factory.getGoodSize(result.name)

			if newAmount > Factory.getMaxStock(size) or station.freeCargoSpace < result.amount * size then
				canProduce = false
				newProductionError = "Factory can't produce because there is not enough cargo space for products!"%_T
				-- print("can't produce due to missing room for result")
				break
			end
		end

		if canProduce then
			local boosted
			for i, ingredient in pairs(production.ingredients) do
				local removed = Factory.decreaseGoods(ingredient.name, ingredient.amount)

				if ingredient.optional == 1 and removed then
					boosted = true
				end
			end

			newProductionError = ""
			-- print("start production")

			-- start production
			Factory.startProduction(timeStep, boosted)
		end
	end,
	refreshConfigErrors = function(self)
		if not Factory.trader.guiInitialized then return end

		for _, labels in pairs({deliveringStationsErrorLabels, deliveredStationsErrorLabels}) do
			for _, label in pairs(labels) do
				label.caption = ""
				label.color = ColorRGB(1, 1, 0)
			end
		end

		for index, error in pairs(deliveredStationsErrors) do
			if index and error then
				deliveredStationsErrorLabels[index].caption = GetLocalizedString(error)
			end
		end

		for index, error in pairs(deliveringStationsErrors) do
			if index and error then
				deliveringStationsErrorLabels[index].caption = GetLocalizedString(error)
			end
		end

		if not productionError or productionError == "" then
			productionErrorSign:show()
			productionErrorSign.label.caption = "Factory appears to be working as intended."%_t .. " - Linked To Hub: " .. is_hub.name
			productionErrorSign.label.color = ColorRGB(0, 1, 0)
			productionErrorSign.icon.color = ColorRGB(0, 1, 0)
			productionErrorSign.icon.picture = "data/textures/icons/checkmark.png"
		else
			productionErrorSign:show()
			productionErrorSign.label.caption = (productionError or "") .. " - Linked To Hub: " .. is_hub.name
			productionErrorSign.label.color = ColorRGB(1, 1, 0)
			productionErrorSign.icon.color = ColorRGB(1, 1, 0)
			productionErrorSign.icon.picture = "data/textures/icons/hazard-sign.png"
		end
	end
}

function Factory.getSizeAndSpeed()
	return Factory.maxNumProductions, Factory.timeToProduce, productionError
end

Factory.update = Factory.updateParallelSelf -- I dont know what the preformance implications of this will be, but
Factory.updateParallelSelf = nil -- it probably had to be done to securely handle transactions without two factories using the same exact cargo

-- Handling if a hub exists or not, to fall back on the original function
for k, v in pairs(Factory) do
	if hub_funcs[k] then
		old_funcs[k] = v
		Factory[k] = function(...)
			local entity = Entity()
			is_hub = entity:getValue("station_hub_id") -- if no hub then nil and fail the following
			if is_hub then
				local ent = Entity(is_hub)
				is_hub = valid(ent) and (ent.factionIndex == entity.factionIndex) and ent or nil -- replacing id with actual value for use in functions
			end
			if is_hub then
				return hub_funcs[k](...)
			else
				return old_funcs[k](...)
			end
		end
	end
end
