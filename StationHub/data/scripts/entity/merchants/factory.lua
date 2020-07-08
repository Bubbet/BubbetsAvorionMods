
Factory.update = Factory.updateParallelSelf -- I dont know what the preformance implications of this will be, but
Factory.updateParallelSelf = nil -- it probably had to be done to securely handle transactions without two factories using the same exact cargo

function Factory.setHub(newHub)
	hub = Entity(newHub)
end

function Factory.updateProduction(timeStep)
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
			-- TODO try for stationhub's inventory and set flag for use below else:
			if hub and valid(hub) then
				_, usingHub = hub:invokeFunction('data/scripts/entity/merchants/stationhub.lua', 'hasCargo', ingredient)
			end
			if not usingHub then
				canProduce = false
				newProductionError = "Factory can't produce because ingredients are missing!"%_T
				-- print("can't produce due to missing ingredients: " .. ingredient.amount .. " " .. ingredient.name .. ", have: " .. Factory.getNumGoods(ingredient.name))
				break
			end
		end
	end

	local station = Entity()
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
			-- TODO use flag from above to tell if we're invoking a resource reduction in the stationhub
			local removed
			if hub and valid(hub) and usingHub then
				_, removed = hub:invokeFunction('data/scripts/entity/merchants/stationhub.lua', 'removeCargo', ingredient)
			else
				removed = Factory.decreaseGoods(ingredient.name, ingredient.amount)
			end

			if ingredient.optional == 1 and removed then
				boosted = true
			end
		end

		newProductionError = ""
		-- print("start production")

		-- start production
		Factory.startProduction(timeStep, boosted)
	end
end
