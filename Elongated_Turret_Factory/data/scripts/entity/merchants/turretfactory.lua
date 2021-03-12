package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
Node = include("node")
include("ElementToTable")
include("UISortList")

--region Initialisation
local old_initialize = TurretFactory.initialize
function TurretFactory.initialize()
	TurretFactory.numSeeds = 1
	old_initialize()
end

function TurretFactory.initUI()
	local res = getResolution()
	local size = vec2(780 + 200, 580)--+ 150
	local menu = ElementToTable(ScriptUI())
	local node = Node(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	window = menu:createWindow(node)
	window.node = node
	window.element.caption = "Turret Factory"%_t
	window.element.showCloseButton = 1
	window.element.moveable = 1
	menu:registerWindow(window.element, "Build Turrets /*window title*/"%_t);
	local node = window.node:child(Rect(window.node.rect.size)):pad(10)
	tabbedWindow = window:createTabbedWindow(node)
	tabbedWindow.node = node

	buildTurretsTab = tabbedWindow:createTab("", "data/textures/icons/turret-build-mode.png", "Build customized turrets from parts"%_t)
	buildTurretsTab.d.node = node:child(Rect(buildTurretsTab.element.size))
	TurretFactory.initBuildTurretsUI(buildTurretsTab)

	--local tab = tabbedWindow:createTab("", "data/textures/icons/turret-blueprint.png", "Create new blueprints from turrets"%_t)
	--makeBlueprintsTab = setmetatable({tab = tab}, getmetatable(tab))
	--TurretFactory.initMakeBlueprintsUI(makeBlueprintsTab)
	makeBlueprintsTab = tabbedWindow:createTab("", "data/textures/icons/turret-blueprint.png", "Create new blueprints from turrets"%_t)
	TurretFactory.initMakeBlueprintsUI(makeBlueprintsTab.element)

	TurretFactory.initWarnWindow(menu.element, res)
end

function TurretFactory.initWarnWindow(menu, res)
	local size = vec2(550, 290)
	local warnWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	TurretFactory.warnWindow = warnWindow
	warnWindow.caption = "Confirm Seed Buying"%_t
	warnWindow.showCloseButton = 1
	warnWindow.moveable = 1
	warnWindow.visible = false

	local hsplit = UIHorizontalSplitter(Rect(vec2(), warnWindow.size), 10, 10, 0.5)
	hsplit.bottomSize = 40

	warnWindow:createFrame(hsplit.top)

	local ihsplit = UIHorizontalSplitter(hsplit.top, 10, 10, 0.5)
	ihsplit.topSize = 20

	local label = warnWindow:createLabel(ihsplit.top.lower, "Warning"%_t, 16)
	label.size = ihsplit.top.size
	label.bold = true
	label.color = ColorRGB(0.8, 0.8, 0)
	label:setTopAligned();

	local warnWindowLabel = warnWindow:createLabel(ihsplit.bottom.lower, "Text"%_t, 14)
	TurretFactory.warnWindowLabel = warnWindowLabel
	warnWindowLabel.size = ihsplit.bottom.size
	warnWindowLabel:setTopAligned();
	warnWindowLabel.wordBreak = true
	warnWindowLabel.fontSize = 14


	local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
	warnWindow:createButton(vsplit.left, "OK"%_t, "onBuySeedsButtonConfirm")
	warnWindow:createButton(vsplit.right, "Cancel"%_t, "onBuySeedsButtonCancel")
end

---@param tab Tab
function TurretFactory.initBuildTurretsUI(tab)
	tab.element.onSelectedFunction = "getData"
	tab.element.onShowFunction = "getData"
	tab.d.left, tab.d.middle, tab.d.right = tab.d.node:cols({0.4, 200, 0.6}, 10)

	tab.d.left.top, tab.d.left.bottom = tab.d.left:rows({0.25,0.75}, 10)

	tab.d.left.top.frame = tab:createFrame(tab.d.left.top)

	local currentSeedLabelNode = tab.d.left.top:child(Rect(vec2(150, 20)))
	currentSeedLabelNode.rect.position = currentSeedLabelNode.rect.position + vec2(5, tab.d.left.top.rect.height - 20)
	currentSeedLabel = tab:createLabel(currentSeedLabelNode, 'Current Seed:', 14)
	currentSeedLabel:setLeftAligned()

	selectedBlueprintSelection = tab:createSelection(tab.d.left.top:centeredrect(75, 75), 1)
	selectedBlueprintSelection.element.dropIntoEnabled = 1
	selectedBlueprintSelection.element.entriesSelectable = 0
	selectedBlueprintSelection.element.onReceivedFunction = "onBlueprintReceived"

	tab.d.left.bottom.top, tab.d.left.bottom.bottom = tab.d.left.bottom:rows({25, 1}, 10)

	tab.d.left.bottom.top.combo = tab:createComboBox(tab.d.left.bottom.top, 'onBlueprintTypeSelected')
	tab.d.left.bottom.top.combo:addEntry("Factory Blueprints"%_t)
	tab.d.left.bottom.top.combo:addEntry("Inventory Blueprints"%_t)
	tab.d.left.bottom.top.combo.element.layer = 4
	TurretFactory.blueprintCombo = tab.d.left.bottom.top.combo

	tab.d.left.bottom.bottom.top, tab.d.left.bottom.bottom.bottom = tab.d.left.bottom.bottom:rows({1, 60}, 10)

	inventoryBlueprintSelection = tab:createInventorySelection(tab.d.left.bottom.bottom.top, 5)
	inventoryBlueprintSelection.element.dragFromEnabled = 1
	inventoryBlueprintSelection.element.onClickedFunction = "onBlueprintSelectionClicked"
	inventoryBlueprintSelection:hide()

	predefinedBlueprintSelection = tab:createInventorySelection(tab.d.left.bottom.bottom.top, 5)
	predefinedBlueprintSelection.element.dragFromEnabled = 1
	predefinedBlueprintSelection.element.onClickedFunction = "onBlueprintSelectionClicked"
	--predefinedBlueprintSelection.element.borderCombo:hide() -- TODO uncomment these when the devs fix borderCombo not being valid
	--predefinedBlueprintSelection.element.sortCombo:hide()
	predefinedBlueprintSelection.element.filterTextBox:hide()
	--local newTextBoxRect = tab.d.node:child(Rect(predefinedBlueprintSelection.element.filterTextBox.size+vec2(50, 0))):offset(predefinedBlueprintSelection.element.filterTextBox.localPosition.x-50, predefinedBlueprintSelection.element.localPosition.y)
	local filterBoxRect = tab.d.node:child(Rect(vec2(tab.d.left.bottom.bottom.top.rect.width, predefinedBlueprintSelection.element.filterTextBox.height))):offset(0, predefinedBlueprintSelection.element.localPosition.y)
	local noGoRect, newTextBoxRect = filterBoxRect:cols(2, 10)
	noGoButton = tab:createButton(noGoRect, 'Disabled, use middle', '')
	noGoButton.element.layer = 3
	newFilterBox = tab:createTextBox(newTextBoxRect, "")

	tab:createFrame(tab.d.left.bottom.bottom.bottom)
	local upgradeSeedsNode, seedsLabelNode, turretCountLabelNode = tab.d.left.bottom.bottom.bottom:pad(5):cols(3, 10)
	increaseSeedsButton = tab:createButton(upgradeSeedsNode, "Increase\nSeeds", "onBuySeedsButtonPressed")
	increaseSeedsButton.textSize = 14
	seedsLabel = tab:createLabel(seedsLabelNode, "# of seeds: ", 14)
	seedsLabel:setCenterAligned()
	seedsLabel.element.wordBreak = true
	turretCountLabel = tab:createLabel(turretCountLabelNode, "# of turrets: ", 14)
	turretCountLabel:setCenterAligned()
	turretCountLabel.element.wordBreak = true
	--tab:createButton(tab.d.left.bottom.bottom.bottom, "giveIngredients", "giveIngredients")
	--TODO create seed buttons

	tab.d.middle.sortlist = UISortList(TurretFactory, tab.element, tab.d.middle.rect, predefinedBlueprintSelection.element, true)
	TurretFactory.SortList = tab.d.middle.sortlist
	TurretFactory.SortList.cloneInv = function(self)
		if self._turrets then return end
		self._turrets = {}
	end
	TurretFactory.SortList.search = function(self)
		SortList.search(self)
		TurretFactory.currentSeed = TurretFactory.SortList._turrets[1].seed
		TurretFactory.placeBlueprint(self._turrets[1].InventoryReference, ConfigurationMode.FactoryTurret) -- TODO overwrite this to not generate a new turret
	end
	TurretFactory.SortList.fillInventory = function(self)
		local text = string.lower(newFilterBox.text)
		local i = 0
		self._inventory:clear()
		self._currentTurrets = {}
		for k, v in ipairs(self._turrets) do
			if text == "" then
				if self.inventory_limit and k >= self.inventory_limit then return end
				self._inventory:add(v.InventoryReference)
				table.insert(self._currentTurrets, v)
			else
				if string.find(v.Tooltip_As_String, text) then
					if self.inventory_limit and i >= self.inventory_limit then return end
					self._inventory:add(v.InventoryReference)
					table.insert(self._currentTurrets, v)
					i = i + 1
				end
			end
		end
	end
	TurretFactory.SortList.inventory_limit = 2000

	TurretFactory.hiddenSortListFrame = tab:createFrame(tab.d.middle.rect)
	TurretFactory.hiddenSortListLabel = tab:createLabel(tab.d.middle.rect, "SortList not enabled for inventory turrets.", 20)
	TurretFactory.hiddenSortListLabel.element.wordBreak = true
	TurretFactory.hiddenSortListLabel:setCenterAligned()

	TurretFactory.hiddenSortListLabel:hide()
	TurretFactory.hiddenSortListFrame:hide()

	-- Right Side
	tab.d.right = tab.d.right:pad(10)
	tab:createFrame(tab.d.right.parentNode)

	tab.d.right.splits = {tab.d.right:rows({30, 30,30,30,30,30, 30,30,30, 1, 50}, 10)}
	tab.d.right.top = table.remove(tab.d.right.splits, 1)
	tab.d.right.bottom = table.remove(tab.d.right.splits, #tab.d.right.splits)
	table.remove(tab.d.right.splits, #tab.d.right.splits) -- removing spacer between rows and bottom

	tab.d.right.top.parts, tab.d.right.top.req, tab.d.right.top.you = tab.d.right.top:pad(5):cols({1, 50, 50}, 10)
	tab.d.right.top.parts.label = tab:createLabel(tab.d.right.top.parts, "Parts"%_t, 14):setLeftAligned()
	tab.d.right.top.req.label = tab:createLabel(tab.d.right.top.req, "Req"%_t, 14):setLeftAligned()
	tab.d.right.top.you.label = tab:createLabel(tab.d.right.top.you, "You"%_t, 14):setLeftAligned()

	local old_tab = tab -- I hate that the devs still havent suppressed pcall errors so i cant use ElementToTable fully
	tab = tab.element
	for _, v in pairs(old_tab.d.right.splits) do
		local frame = tab:createFrame(v.rect)
		v.splits = {v:pad(5):cols({20,1,27,27,50,50}, 10)}--[[
		for k1, v1 in pairs(v.splits) do
			local ta = tab:createFrame(v1)
			ta.backgroundColor = ColorHSV(0,1,1)
		end]]
		local i = 1

		local icon = tab:createPicture(v.splits[i].rect, ""); i = i + 1
		local materialLabel = tab:createLabel(v.splits[i].rect, "", 14); i = i + 1
		materialLabel:setLeftAligned()
		local plus = tab:createButton(v.splits[i].rect, "+", "onPlus"); i = i + 1
		local minus = tab:createButton(v.splits[i].rect, "-", "onMinus"); i = i + 1
		local requiredLabel = tab:createLabel(v.splits[i].rect, "", 14); i = i + 1
		requiredLabel:setLeftAligned()
		local youLabel = tab:createLabel(v.splits[i].rect, "", 14); i = i + 1
		youLabel:setLeftAligned()

		icon.isIcon = 1
		minus.textSize = 12
		plus.textSize = 12

		local hide = function(self)
			self.icon:hide()
			self.frame:hide()
			self.material:hide()
			self.plus:hide()
			self.minus:hide()
			self.required:hide()
			self.you:hide()
		end

		local show = function(self)
			self.icon:show()
			self.frame:show()
			self.material:show()
			self.plus:show()
			self.minus:show()
			self.required:show()
			self.you:show()
		end

		local line = {frame = frame, icon = icon, plus = plus, minus = minus, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
		line:hide()

		v.line = line
		table.insert(lines, line)
	end
	tab = old_tab

	tab.d.right.bottom.left, tab.d.right.bottom.right = tab.d.right.bottom:cols({0.9, 0.1}, 10)
	buildButton = tab:createButton(tab.d.right.bottom.left, "Build /*Turret Factory Button*/"%_t, "onBuildTurretPressed")
	saveButton = tab:createButton(tab.d.right.bottom.right, "", "onTrackIngredientsButtonPressed") -- "giveIngredients")
	saveButton.icon = "data/textures/icons/checklist.png"
	saveButton.tooltip = "Track ingredients in mission log"%_t
	priceLabel = tab:createLabel(vec2(tab.d.right.bottom.left.rect.lower.x, tab.d.right.bottom.left.rect.upper.y) + vec2(0, -75), "Manufacturing Price: Too Much"%_t, 16).element
end
--endregion

--region Balancing
function TurretFactory.getSeedUpgradeAmount()
	return 1
end

function TurretFactory.getSeedUpgradeCost()
	return 45000000 -- 1.5 * 30000000(the cost of a turret factory)
end

function TurretFactory.getRarities(buyer)
	local rarities = {Rarity(RarityType.Common), Rarity(RarityType.Uncommon), Rarity(RarityType.Rare)}
	if buyer:getRelations(Faction().index) >= 80000 then
		table.insert(rarities, Rarity(RarityType.Exceptional))
	end
	return rarities
end

--endregion

--region UI Functions
function TurretFactory.onBlueprintTypeSelected(combo, selectedIndex)
	if selectedIndex == 1 then
		TurretFactory.hiddenSortListLabel:show()
		TurretFactory.hiddenSortListFrame:show()
		TurretFactory.SortList:hide()
		inventoryBlueprintSelection:show()
		predefinedBlueprintSelection:hide()
		newFilterBox:hide()
		noGoButton:hide()
	else
		TurretFactory.hiddenSortListLabel:hide()
		TurretFactory.hiddenSortListFrame:hide()
		TurretFactory.SortList:show()
		inventoryBlueprintSelection:hide()
		predefinedBlueprintSelection:show()
		newFilterBox:show()
		noGoButton:show()
	end
	TurretFactory.refreshBuildTurretsUI()
end

local old_onBlueprintReceived = TurretFactory.onBlueprintReceived
function TurretFactory.onBlueprintReceived(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)
	TurretFactory.selectedTurret = fky*5 + fkx + 1
	TurretFactory.currentSeed = TurretFactory.SortList._currentTurrets[TurretFactory.selectedTurret].seed -- TODO replace these with proper references
	old_onBlueprintReceived(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)
end

local old_onBlueprintSelectionClicked = TurretFactory.onBlueprintSelectionClicked
function TurretFactory.onBlueprintSelectionClicked(selectionIndex, kx, ky, item, button)
	TurretFactory.selectedTurret = ky*5 + kx + 1
	--print(TurretFactory.SortList._currentTurrets[TurretFactory.selectedTurret].manufacturingPrice)
	TurretFactory.currentSeed = TurretFactory.SortList._currentTurrets[TurretFactory.selectedTurret].seed
	old_onBlueprintSelectionClicked(selectionIndex, kx, ky, item, button)
end

local old_onShowWindow = TurretFactory.onShowWindow
function TurretFactory.onShowWindow()
	invokeServerFunction("getData")
end

function TurretFactory.onBuySeedsButtonPressed()
	local amount = TurretFactory.getSeedUpgradeAmount()
	TurretFactory.warnWindowLabel.caption = "Buying ${amount} seed${plural} will cost ¢${cost} are you sure you want to continue?"%_T % {amount = amount, plural = amount > 1 and "s" or "", cost = createMonetaryString(TurretFactory.getSeedUpgradeCost())}
	TurretFactory.warnWindow:show()
end

function TurretFactory.onBuySeedsButtonCancel()
	TurretFactory.warnWindow:hide()
end

function TurretFactory.onBuySeedsButtonConfirm()
	if onClient() then
		invokeServerFunction("onBuySeedsButtonConfirm")
		TurretFactory.warnWindow:hide()
	else
		local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems)
		if not buyer then return end
		if length(vec2(Sector():getCoordinates())) > length(vec2(TurretFactory.getCoordinates())) then
			TurretFactory.sendError(player, "Too far away from \\s(${x}:${y}) to upgrade seeds, please move closer to the core."%_T % TurretFactory.coords)
			return
		end
		local price = TurretFactory.getSeedUpgradeCost()
		local canPay, msg, args = buyer:canPay(price)
		if not canPay then
			TurretFactory.sendError(player, msg, unpack(args))
			return
		end
		buyer:pay(price)
		TurretFactory.numSeeds = TurretFactory.numSeeds + TurretFactory.getSeedUpgradeAmount()
		TurretFactory.getData()
	end
end
callable(TurretFactory, "onBuySeedsButtonConfirm")

function TurretFactory.onBuildTurretPressed(button)
	if configurationMode == ConfigurationMode.InventoryTurret then
		local item = selectedBlueprintSelection:getItem(ivec2(0, 0))
		invokeServerFunction("buildTurretDuplicate", item.index)
	else
		invokeServerFunction("buildNewTurret", TurretFactory.getUIWeaponType(), TurretFactory.getUIRarity(), TurretFactory.getUIIngredients(), TurretFactory.currentSeed)
	end
end

function TurretFactory.getMaxIngredients()
	for k, v in pairs(configuredIngredients) do
		if v.name ~= "Targeting System" then
			v.amount = v.maximum
		end
	end
	return configuredIngredients
end

local old_renderUI = TurretFactory.renderUI
function TurretFactory.renderUI()
	if not TurretFactory.getUIIngredients() then return end
	old_renderUI()
end

--endregion

--region Server Exclusive Code

function TurretFactory.secure()
	local data = {}
	local x, y = TurretFactory.getCoordinates()
	data.x = x
	data.y = y
	data.numSeeds = TurretFactory.numSeeds
	return data
end
function TurretFactory.restore(data)
	if data.x and data.y then
		TurretFactory.coords = {x = data.x, y = data.y}
	end
	if data.numSeeds then TurretFactory.numSeeds = data.numSeeds end
end

function TurretFactory.getData(_, data) -- Also for client, syncs the data to client
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "getData", _, TurretFactory.secure())
	else
		if data then
			if TurretFactory.numSeeds < data.numSeeds then
				for i = TurretFactory.numSeeds, data.numSeeds do
					TurretFactory.addTurrets(TurretFactory.getRarities(Galaxy():getPlayerCraftFaction()), i)
				end
				TurretFactory.SortList:updateInfo()
				TurretFactory.SortList:search()
			end
			--print("data has been received")
			TurretFactory.coords = {x = data.x, y = data.y}
			TurretFactory.numSeeds = data.numSeeds
			old_onShowWindow()
		else
			invokeServerFunction("getData")
		end
	end
end
callable(TurretFactory, "getData")

--endregion

--region Turret Construction

function TurretFactory.makeTurretBase(weaponType, rarity, material)
	local x, y = TurretFactory.getCoordinates()

	local station = Entity()
	local seed = station.index.number + 123 + x + y * 300 -- TODO replace the whole thing with somethign secured/restored also secure distance to core at found so seeds bought have to be within that range

	local generator = SectorTurretGenerator(seed)
	generator.old_getTurretSeed = generator.getTurretSeed
	function generator:getTurretSeed(x, y, weaponType, rarity)
		if TurretFactory.currentSeed == 1 then
			return self:old_getTurretSeed(x, y, weaponType, rarity)
		end
		local seedString = tostring(GameSeed().int32) .. tostring(x) .. tostring(y) .. tostring(weaponType) .. tostring(rarity.type) .. tostring(TurretFactory.currentSeed)
		return Seed(seedString), x, y
	end

	local turret = generator:generate(x, y, 0, rarity, weaponType, material)

	-- automatic turrets must get automatic property removed and damage rebuffed
	-- we don't want the base turrets to have independent targeting since that can mess up the rest of the stats calculation, especially for damage
	if turret.automatic then
		turret.automatic = false

		local weapons = {turret:getWeapons()}
		turret:clearWeapons()

		for _, weapon in pairs(weapons) do
			weapon.damage = weapon.damage * 2.0
			if weapon.hullRepair > 0.0 then
				weapon.hullRepair = weapon.hullRepair * 2.0
			end
			if weapon.shieldRepair > 0.0 then
				weapon.shieldRepair = weapon.shieldRepair * 2.0
			end

			turret:addWeapon(weapon)
		end
	end

	return turret
end

function TurretFactory.addTurrets(rarities, seed)
	local buyer = Galaxy():getPlayerCraftFaction()
	for _, weaponType in pairs(TurretFactory.getPossibleWeaponTypes()) do
		for _, rarity in pairs(rarities) do
			local item = InventorySelectionItem()
			TurretFactory.currentSeed = seed
			configuredIngredients, manufacturingPrice = TurretFactory.getNewTurretIngredientsAndTax(weaponType, rarity, TurretFactory.getMaterial(), buyer)
			item.item = TurretFactory.makeTurret(weaponType, rarity, TurretFactory.getMaterial(), TurretFactory.getMaxIngredients())
			--item.item = TurretFactory.makeTurretBase(weaponType, rarity, TurretFactory.getMaterial())
			local tooltip = makeTurretTooltip(item.item, nil, 2)
			local tooltip_as_string = ""
			for k, v in pairs({tooltip:getLines()}) do
				tooltip_as_string = tooltip_as_string .. v.ltext .. v.ctext .. v.rtext
			end
			tooltip_as_string = string.lower(tooltip_as_string)
			table.insert(TurretFactory.SortList._turrets, {InventoryReference = item, Tooltip = tooltip, Tooltip_As_String = tooltip_as_string, seed = seed, manufacturingPrice = manufacturingPrice})
		end
	end
end

function TurretFactory.refreshBuildTurretsUI()
	local buyer = Galaxy():getPlayerCraftFaction()
	inventoryBlueprintSelection:fill(buyer.index, InventoryItemType.TurretTemplate)

	local rarities = TurretFactory.getRarities(buyer)

	if #TurretFactory.SortList._turrets == 0 then
		--print("adding Turrets")
		for i = 1, TurretFactory.numSeeds do
			TurretFactory.addTurrets(rarities, i)
		end
		TurretFactory.SortList:updateInfo()
		TurretFactory.SortList:search()
	end

	--TurretFactory.SortList:cloneInv()
	--TurretFactory.SortList:fillLines()

	selectedBlueprintSelection:clear()
	selectedBlueprintSelection:addEmpty()

	local first, mode
	if TurretFactory.blueprintCombo.element.selectedIndex == 1 then
		first = inventoryBlueprintSelection:getItem(ivec2())
		if not first then first = InventorySelectionItem() end
		mode = ConfigurationMode.InventoryTurret
	else
		first = predefinedBlueprintSelection:getItem(ivec2())
		mode = ConfigurationMode.FactoryTurret
	end

	TurretFactory.placeBlueprint(first, mode)

	local x, y = TurretFactory.getCoordinates()
	seedsLabel.element.caption = "# of seeds: " .. TurretFactory.numSeeds .. "\nFrom (" .. x .. ":" .. y .. ")"
	turretCountLabel.element.caption = "# of turrets: " .. #TurretFactory.SortList._turrets
end

local old_buildNewTurret = TurretFactory.buildNewTurret
function TurretFactory.buildNewTurret(weaponType, rarity, clientIngredients, seed)
	TurretFactory.currentSeed = math.min(TurretFactory.numSeeds, math.max(seed, 1))
	old_buildNewTurret(weaponType, rarity, clientIngredients)
end

local old_placeBlueprint = TurretFactory.placeBlueprint
function TurretFactory.placeBlueprint(...)
	currentSeedLabel.caption = 'Current Seed: ' .. TurretFactory.currentSeed
	old_placeBlueprint(...)
end

--endregion

--region GiveIngredients Dev function
function TurretFactory.giveIngredients(sender, ingredients)
	if onServer() then
		if not ingredients then
			invokeClientFunction(Player(sender or callingPlayer), "giveIngredients")
		else
			local entity = Entity()
			for k, v in pairs(ingredients) do
				entity:addCargo(goods[v.name]:good(), v.amount)
			end
		end
	else
		invokeServerFunction("giveIngredients", _,TurretFactory.getUIIngredients())
	end
end
--callable(TurretFactory, "giveIngredients")
--endregion
