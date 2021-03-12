
local is_hub -- upvalue containing entity of hub if there is one, else nil
local old_funcs = {} --storing the old functions replaced in hub_funcs
-- copying huge chunks of code to change one line am i rite haha i love lua
local hub_funcs = { --the list of functions to overwrite, wrote in assumption that there is a hub
	initializeTrading = function(self, boughtGoodsIn, soldGoodsIn, policiesIn)
		local entity = Entity()

		self.policies = policiesIn or self.policies

		-- generate goods only once, this adds physical goods to the entity
		local generated = entity:getValue("goods_generated")
		if not generated or generated ~= 1 then
			entity:setValue("goods_generated", 1)
			generated = false
		else
			generated = true
		end

		boughtGoodsIn = boughtGoodsIn or {}
		soldGoodsIn = soldGoodsIn or {}

		self.numBought = #boughtGoodsIn
		self.numSold = #soldGoodsIn

		if not generated then
			local boughtStock, soldStock = self:getInitialGoods(boughtGoodsIn, soldGoodsIn)

			for good, amount in pairs(boughtStock) do
				is_hub:addCargo(good, amount) -- only change
			end

			for good, amount in pairs(soldStock) do
				is_hub:addCargo(good, amount) -- only change
			end
		end

		self.boughtGoods = {}

		local resourceAmount = math.random(1, 3)

		for i, v in ipairs(boughtGoodsIn) do
			table.insert(self.boughtGoods, v)
		end

		self.soldGoods = {}

		for i, v in ipairs(soldGoodsIn) do
			table.insert(self.soldGoods, v)
		end

		self.numBought = #self.boughtGoods
		self.numSold = #self.soldGoods
	end,
	simulatePassedTime = function(self, timeSinceLastSimulation)
		local boughtStock, soldStock = self:getInitialGoods(self.boughtGoods, self.soldGoods)
		local entity = is_hub -- only change

		local factor = math.max(0, math.min(1, (timeSinceLastSimulation - 10 * 60) / (100 * 60)))

		-- interpolate to new stock
		for good, amount in pairs(boughtStock) do
			local curAmount = entity:getCargoAmount(good)
			local diff = math.floor((amount - curAmount) * factor)

			if diff > 0 then
				self:increaseGoods(good.name, diff)
			elseif diff < 0 then
				self:decreaseGoods(good.name, -diff)
			end
		end

		for good, amount in pairs(soldStock) do
			local curAmount = entity:getCargoAmount(good)
			local diff = math.floor((amount - curAmount) * factor)

			if diff > 0 then
				self:increaseGoods(good.name, diff)
			elseif diff < 0 then
				self:decreaseGoods(good.name, -diff)
			end
		end
	end,
	increaseGoods = function(self, name, delta)
		local entity = is_hub -- only change
		local added = false

		for i, good in pairs(self.soldGoods) do
			if good.name == name then
				-- increase
				local current = entity:getCargoAmount(good)
				delta = math.min(delta, self:getMaxStock(good.size) - current)
				delta = math.max(delta, 0)

				if not added then
					entity:addCargo(good, delta)
					added = true
				end

				broadcastInvokeClientFunction("updateSoldGoodAmount", good.name)
			end
		end

		for i, good in pairs(self.boughtGoods) do
			if good.name == name then
				-- increase
				local current = entity:getCargoAmount(good)
				delta = math.min(delta, self:getMaxStock(good.size) - current)
				delta = math.max(delta, 0)

				if not added then
					entity:addCargo(good, delta)
					added = true
				end

				broadcastInvokeClientFunction("updateBoughtGoodAmount", good.name)
			end
		end
	end,
	decreaseGoods = function(self, name, amount)
		local entity = is_hub -- only change
		local removed = false

		for i, good in pairs(self.soldGoods) do
			if good.name == name then
				if not removed then
					entity:removeCargo(good, amount)
					removed = true
				end

				broadcastInvokeClientFunction("updateSoldGoodAmount", good.name)
			end
		end

		for i, good in pairs(self.boughtGoods) do
			if good.name == name then
				if not removed then
					entity:removeCargo(good, amount)
					removed = true
				end

				broadcastInvokeClientFunction("updateBoughtGoodAmount", good.name)
			end
		end

		return removed
	end,
	getNumGoods = function(self, name)
		local entity = is_hub -- only change

		local g = goods[name]
		if not g then return 0 end

		local good = g:good()
		if not good then return 0 end

		local amount = entity:getCargoAmount(good)
		return amount
	end,
	getMaxStock = function(self, goodSize, goodName) -- goodName is only used in cra
		local entity = is_hub -- only change

		local space = entity.maxCargoSpace
		local slots = self.numBought + self.numSold

		if slots > 0 then space = space / slots end

		if space / goodSize > 100 then
			if goodName and string.find("Iron,Titanium,Naonite,Trinium,Xanion,Ogonite,Avorion", goodName) then
				return math.min(round(space / goodSize / 100) * 100, rsmConfig and rsmConfig.maxStock or math.huge)
			end
			-- round to 100
			return math.min(25000, round(space / goodSize / 100) * 100)
		else
			-- not very much space already, don't round
			return math.floor(space / goodSize)
		end
	end
}

-- Handling if a hub exists or not, to fall back on the original function
for k, v in pairs(TradingManager) do
	if hub_funcs[k] then
		old_funcs[k] = v
		TradingManager[k] = function(self, ...)
			local entity = Entity()
			is_hub = entity:getValue("station_hub_id") -- if no hub then nil and fail the following
			if is_hub then
				local ent = Entity(is_hub)
				is_hub = valid(ent) and (ent.factionIndex == entity.factionIndex) and ent or nil -- replacing id with actual value for use in functions
			end
			if is_hub then
				return hub_funcs[k](self, ...)
			else
				return old_funcs[k](self, ...)
			end
		end
	end
end