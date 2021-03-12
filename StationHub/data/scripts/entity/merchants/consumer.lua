
function Consumer.initUI()

	local tabbedWindow = TradingAPI.CreateTabbedWindow()

	-- create buy tab
	local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/bag.png", "Buy from station"%_t)
	Consumer.buildBuyGui(buyTab)

	-- create sell tab
	local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/sell.png", "Sell to station"%_t)
	Consumer.buildSellGui(sellTab)

	Consumer.toggleBuyButton = sellTab:createButton(Rect(sellTab.size.x - 30, -5, sellTab.size.x, 25), "", "onToggleBuyPressed")
	Consumer.toggleBuyButton.icon = "data/textures/icons/sell.png"

	Consumer.toggleConsumeButton = sellTab:createButton(Rect(sellTab.size.x - 70, -5, sellTab.size.x-40, 25), "", "onToggleConsumePressed")
	Consumer.toggleConsumeButton.icon = "data/textures/icons/checked.png"
	Consumer.toggleConsumeButton.tooltip = "This station will consume goods from its inventory."%_t

	tabbedWindow:deactivateTab(buyTab)

	Consumer.trader.guiInitialized = 1

	if TradingAPI.window.caption ~= "" then
		invokeServerFunction("sendName")
	end

	Consumer.requestGoods()
end

function Consumer.onToggleConsumePressed(button, contains_info, value)
	if onClient() then
		if contains_info then
			if value then
				Consumer.toggleConsumeButton.icon = "data/textures/icons/unchecked.png"
				Consumer.toggleConsumeButton.tooltip = "This station won't consume goods from its inventory."%_t
			else
				Consumer.toggleConsumeButton.icon = "data/textures/icons/checked.png"
				Consumer.toggleConsumeButton.tooltip = "This station will consume goods from its inventory."%_t
			end
		else
			invokeServerFunction("onToggleConsumePressed")
		end
	else
		local buyer, ship, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageStations)
		if not buyer then return end
		Consumer.dontConsumeGoods = not Consumer.dontConsumeGoods
		Consumer.tellClientAboutConsume(buyer)
	end
end
callable(Consumer, "onToggleConsumePressed")

function Consumer.tellClientAboutConsume(buyer)
	invokeClientFunction(buyer or Player(callingPlayer), "onToggleConsumePressed", _, true, Consumer.dontConsumeGoods)
end
callable(Consumer, "tellClientAboutConsume")

local old_onShowWindow = Consumer.onShowWindow
function Consumer.onShowWindow()
	old_onShowWindow()
	invokeServerFunction("tellClientAboutConsume")
end

function Consumer.updateServer(timeStep)
	if Consumer.dontConsumeGoods then return end
	Consumer.useUpBoughtGoods(timeStep)
	Consumer.updateOrganizeGoodsBulletins(timeStep)
end

local old_secure = Consumer.secure
function Consumer.secure()
	local data = old_secure()
	data.dontConsumeGoods = Consumer.dontConsumeGoods
	return data
end

local old_restore = Consumer.restore
function Consumer.restore(data)
	Consumer.dontConsumeGoods = data.dontConsumeGoods
	data.dontConsumeGoods = nil
	old_restore(data)
end
