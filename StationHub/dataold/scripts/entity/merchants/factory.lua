
Factory.update = Factory.updateParallelSelf -- I dont know what the preformance implications of this will be, but
Factory.updateParallelSelf = nil -- it probably had to be done to securely handle transactions without two factories using the same exact cargo

-- delaying the restore from disk to wait for stationhub
local stationhub_onRestoredFromDisk = Factory.onRestoredFromDisk
function Factory.onRFD()
	if Factory.onRestored then
		stationhub_onRestoredFromDisk(Factory.onRestored)
		Factory.onRestored = nil
	end
end

function Factory.onRestoredFromDisk(timeStep)
	if not Factory.onRestored then
		Factory.onRestored = timeStep
		deferredCallback(1, 'onRFD')
	end
end
--

function Factory.setHub(newHub)
	hub = Entity(newHub)
	if Factory.onRestored then
		Factory.onRFD()
	end
	Entity():registerCallback('onDestroyed', 'hub_onDestroyed')
end

function Factory.hub_onDestroyed()
	if not valid(hub) then return end
	hub:invokeFunction('data/scripts/entity/merchants/stationhub.lua', 'removeFact')
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

local oldgetNumGoods = Factory.getNumGoods
function Factory.getHubNumGoods(name)
	--print(hub, valid(hub))
	if hub and valid(hub) then
		local ok, amount = hub:invokeFunction('data/scripts/entity/merchants/stationhub.lua', 'findCargos', name)
		--print('ok', ok, amount)
		if (amount or 0) > 0 then
			return amount
		end
	end
	return oldgetNumGoods(name)
end
--Factory.getNumGoods = Factory.getHubNumGoods

function Factory.trySpawnSeller(self, good, immediate) -- needed to prevent spawning of sellers when they dont actually need to buy goods
	local have = Factory.getHubNumGoods(good.name)
	--print('have', have)
	if have < good.amount then
		local maximum = Factory.getMaxGoods(good.name)

		maximum = math.min(maximum, 500)

		local amount = maximum - have
		if immediate then amount = round(amount * 0.3) end

		TradingUtility.spawnSeller(self.id, getScriptPath(), good.name, amount, Factory, immediate)
		return true
	end
end

--[[
function Factory.getSellerProbability()
	return 1
end

Factory.traderRequestCooldown = 10
]]

local stationhub_buyFromShip = Factory.trader.buyFromShip
function Factory.trader:buyFromShip(shipIndex, goodName, amount, noDockCheck) -- needed to prevent the station from actually buying garbage we dont need because its in the station hub
	if hub and valid(hub) then
		local shipFaction, ship = getInteractingFactionByShip(shipIndex, callingPlayer, AlliancePrivilege.SpendResources)
		if not shipFaction then return end

		if callingPlayer then noDockCheck = nil end

		local stationFaction = Faction()

		-- check if it even buys
		if self.buyFromOthers == false and stationFaction.index ~= shipFaction.index then
			self:sendError(shipFaction, "This object doesn't buy goods from others."%_t)
			return
		end

		-- check if the good can be bought
		if not self:getBoughtGoodByName(goodName) == nil then
			self:sendError(shipFaction, "%s isn't bought."%_t, goodName)
			return
		end

		if ship.freeCargoSpace == nil then
			self:sendError(shipFaction, "Your ship has no cargo bay!"%_t)
			return
		end

		local station = Entity()

		-- check if the relations are ok
		if self.relationsThreshold then
			local relations = stationFaction:getRelations(shipFaction.index)
			if relations < self.relationsThreshold then
				self:sendError(shipFaction, "Relations aren't good enough to trade!"%_t)
				return
			end
		end

		-- check if the specific good from the player can be bought (ie. it's not illegal or something like that)
		local cargos = ship:findCargos(goodName)
		local good = nil
		local msg = "You don't have any %s to sell!"%_t
		local args = {goodName}

		for g, amount in pairs(cargos) do
			local ok
			ok, msg = self:isBoughtBySelf(g)
			args = {}
			if ok then
				good = g
				break
			end
		end

		if not good then
			self:sendError(shipFaction, msg, unpack(args))
			return
		end

		-- make sure the ship can not sell more than the station can have in stock
		local maxAmountPlaceable = self:getMaxStock(good.size) - Factory.getHubNumGoods(good.name); -- lmao shadowing a whole function to change one line am i rite

		if maxAmountPlaceable < amount then
			amount = maxAmountPlaceable

			if maxAmountPlaceable == 0 then
				self:sendError(shipFaction, "This station is not able to take any more %s."%_t, good:pluralForm(0))
			end
		end

		-- make sure the player does not sell more than he has in his cargo bay
		local amountOnShip = ship:getCargoAmount(good)

		if amountOnShip < amount then
			amount = amountOnShip

			if amountOnShip == 0 then
				self:sendError(shipFaction, "You don't have any %s on your ship."%_t, good:pluralForm(0))
			end
		end

		if amount <= 0 then
			return
		end

		-- begin transaction
		-- calculate price. if the seller is the owner of the station, the price is 0
		local price = self:getBuyPrice(good.name, shipFaction.index) * amount

		local canPay, msg, args = stationFaction:canPay(price * self.factionPaymentFactor);
		if not canPay then
			self:sendError(shipFaction, "This station's faction doesn't have enough money."%_t)
			return
		end

		if not noDockCheck then
			-- test the docking last so the player can know what he can buy from afar already
			local errors = {}
			errors[EntityType.Station] = "You must be docked to the station to trade."%_T
			errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
			if not CheckShipDocked(shipFaction, ship, station, errors) then
				return
			end
		end

		local x, y = Sector():getCoordinates()
		local fromDescription = Format("\\s(%1%:%2%) %3% bought %4% %5% for ¢%6%."%_T, x, y, station.name, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))
		local toDescription = Format("\\s(%1%:%2%) %3% sold %4% %5% for ¢%6%."%_T, x, y, ship.name, math.floor(amount), good:pluralForm(math.floor(amount)), createMonetaryString(price))

		-- give money to ship faction
		self:transferMoney(stationFaction, stationFaction, shipFaction, price, fromDescription, toDescription)

		-- remove goods from ship
		ship:removeCargo(good, amount)

		if callingPlayer then
			Player(callingPlayer):sendCallback("onTradingmanagerBuyFromPlayer", self.soldGoods[goodIndex])
		end
		Entity():sendCallback("onTradingmanagerBuyFromPlayer", self.soldGoods[goodIndex])

		-- trading (non-military) ships get higher relation gain
		local relationsChange = GetRelationChangeFromMoney(price)
		if (ship:getNumArmedTurrets()) <= 1 then
			relationsChange = relationsChange * 1.5
		end

		changeRelations(shipFaction, stationFaction, relationsChange, RelationChangeType.GoodsTrade)

		-- add goods to station, do this last so the UI update that comes with the sync already has the new relations
		self:increaseGoods(good.name, amount)
	else
		return stationhub_buyFromShip(Factory.trader, shipIndex, goodName, amount, noDockCheck)
	end
end
