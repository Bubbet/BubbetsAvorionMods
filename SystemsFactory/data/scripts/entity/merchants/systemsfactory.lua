package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"

local Config
if ModManager():findEnabled("2003555597") then Config = include("ConfigLoader") else
	if onServer() and not Server():getValue('CRA_LocalAlert') then
		print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
		Server():setValue('CRA_LocalAlert', true)
	end
	Config = include("systemfactoryconfig")
end

include('ElementToTable')
local Node = include('gravyui/node')
local systemIngredients = include('systemingredients')

-- namespace SystemFactory
SystemFactory = {}

local ConfigurationMode =
{
	InventorySystem = 1,
	FactorySystem = 2,
}
local configurationMode

function SystemFactory:initialize()

end

function SystemFactory:interactionPossible()
	return true
end

local lines = {}

function SystemFactory:initUI()
	local res = getResolution()
	local size = vec2(780, 580)

	local menu = ElementToTable(ScriptUI())
	window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

	window.caption = "System Factory"%_t
	window.showCloseButton = 1
	window.moveable = 1
	menu:registerWindow(window.element, "Build Systems /*window title*/"%_t);

	local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))
	buildSystemsTab = tabbedWindow:createTab("", "data/textures/icons/circuitry.png", "Build Systems")
	buildSystemsTab.node = Node(Rect(buildSystemsTab.size))
	SystemFactory.initBuildSystemsUI(buildSystemsTab)

end

---@param tab Tab
function SystemFactory.initBuildSystemsUI(tab)
	tab.left, tab.right = tab.node:cols({0.3, 0.7}, 10)

	tab.left.top, tab.left.bottom = tab.left:rows({0.25, 0.75}, 10)
	tab.left.top.frame = tab:createFrame(tab.left.top)

	selectedBlueprintSelection = tab:createSelection(tab.left.top:centeredrect(75, 75), 1)
	selectedBlueprintSelection.dropIntoEnabled = 1
	selectedBlueprintSelection.entriesSelectable = 0
	selectedBlueprintSelection.onReceivedFunction = "onBlueprintReceived"

	tab.left.bottom.top, tab.left.bottom.bottom = tab.left.bottom:rows({25, 1}, 10)

	tab.left.bottom.top.combo = tab:createComboBox(tab.left.bottom.top, '') -- 'onBlueprintTypeSelected'
	tab.left.bottom.top.combo:addEntry("Factory Blueprints"%_t)
	tab.left.bottom.top.combo:addEntry("Inventory Blueprints"%_t)

	inventoryBlueprintSelection = tab:createInventorySelection(tab.left.bottom.bottom, 5)
	inventoryBlueprintSelection.dragFromEnabled = 1
	inventoryBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"
	inventoryBlueprintSelection:hide()

	predefinedBlueprintSelection = tab:createInventorySelection(tab.left.bottom.bottom, 5)
	predefinedBlueprintSelection.dragFromEnabled = 1
	predefinedBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"

	-- Right Side
	tab.right = tab.right:pad(10)
	tab:createFrame(tab.right.parentNode)

	tab.right.splits = {tab.right:rows({30, 30,30,30,30,30, 30,30,30, 30,30, 1, 50}, 10)}
	tab.right.top = table.remove(tab.right.splits, 1)
	tab.right.bottom = table.remove(tab.right.splits, #tab.right.splits)
	table.remove(tab.right.splits, #tab.right.splits) -- removing spacer between rows and bottom

	tab.right.top.parts, tab.right.top.req, tab.right.top.you = tab.right.top:pad(5):cols({1, 50, 50}, 10)
	tab.right.top.parts.label = tab:createLabel(tab.right.top.parts, "Parts"%_t, 14):setLeftAligned()
	tab.right.top.req.label = tab:createLabel(tab.right.top.req, "Req"%_t, 14):setLeftAligned()
	tab.right.top.you.label = tab:createLabel(tab.right.top.you, "You"%_t, 14):setLeftAligned()

	for _, v in pairs(tab.right.splits) do
		local frame = tab:createFrame(v)
		v.splits = {v:pad(5):cols({20,1,50,50}, 10)}--[[
		for k1, v1 in pairs(v.splits) do
			local ta = tab:createFrame(v1)
			ta.backgroundColor = ColorHSV(0,1,1)
		end--]]
		local i = 1

		local icon = tab:createPicture(v.splits[i], ""); i = i + 1
		local materialLabel = tab:createLabel(v.splits[i], "", 14); i = i + 1
		materialLabel:setLeftAligned()
		local requiredLabel = tab:createLabel(v.splits[i], "", 14); i = i + 1
		requiredLabel:setLeftAligned()
		local youLabel = tab:createLabel(v.splits[i], "", 14); i = i + 1
		youLabel:setLeftAligned()

		icon.isIcon = 1

		local hide = function(self)
			self.icon:hide()
			self.frame:hide()
			self.material:hide()
			self.required:hide()
			self.you:hide()
		end

		local show = function(self)
			self.icon:show()
			self.frame:show()
			self.material:show()
			self.required:show()
			self.you:show()
		end

		local line =  {frame = frame, icon = icon, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
		line:hide()

		v.line = line
		table.insert(lines, line)
	end

	tab.right.bottom.left, tab.right.bottom.right = tab.right.bottom:cols({0.9, 0.1}, 10)
	buildButton = tab:createButton(tab.right.bottom.left, "Build /*Turret Factory Button*/"%_t, "onBuildSystemPressed")
	saveButton = tab:createButton(tab.right.bottom.right, "", "onTrackIngredientsButtonPressed")
	saveButton.icon = "data/textures/icons/checklist.png"
	saveButton.tooltip = "Track ingredients in mission log"%_t
	priceLabel = tab:createLabel(vec2(tab.right.bottom.left.rect.lower.x, tab.right.bottom.left.rect.upper.y) + vec2(0, -75), "Manufacturing Price: Too Much"%_t, 16)
end

function SystemFactory.getPossibleSystemTypes()
	local temp = {}
	for k, v in pairs(systemIngredients) do
		table.insert(temp, k)
	end
	return temp
end

function SystemFactory.getTechLevel()
	return 30
end

function SystemFactory.getUIItem()
	return selectedBlueprintSelection:getItem(ivec2(0)).item
end

function SystemFactory.getUIIngredients()
	return systemIngredients[SystemFactory.getUIItem().script]
end

function SystemFactory.getUIRarity()
	return SystemFactory.getUIItem().rarity
end

function SystemFactory.getUIPrice()
	return SystemFactory.getUIItem().price
end

function SystemFactory.refreshIngredientsUI()
	local ingredients = SystemFactory.getUIIngredients()
	local rarity = SystemFactory.getUIRarity()

	for i, line in pairs(lines) do
		line:hide()
	end

	local ship = Entity(Player().craftIndex)
	if not ship then return end

	for i, ingredient in pairs(ingredients) do
		local line = lines[i]
		line:show()

		local good = goods[ingredient.name]:good()

		local needed = ingredient.amount
		local have = ship:getCargoAmount(good) or 0

		line.icon.picture = good.icon
		line.material.caption = good:displayName(needed)
		line.required.caption = needed
		line.you.caption = have

		if have < needed then
			line.you.color = ColorRGB(1, 0, 0)
		else
			line.you.color = ColorRGB(1, 1, 1)
		end
	end

	priceLabel.caption = "Manufacturing Cost: ¢${money}"%_t % {money = createMonetaryString(SystemFactory.getUIPrice())}--manufacturingPrice)}
end

function SystemFactory.onBlueprintSelected()
	local buyer = Galaxy():getPlayerCraftFaction()

	if configurationMode == ConfigurationMode.InventorySystem then
		--configuredIngredients, manufacturingPrice = SystemFactory.getDuplicatedTurretIngredientsAndTax(SystemFactory.getUIBlueprint(), buyer)
	else
		--configuredIngredients, manufacturingPrice = SystemFactory.getNewTurretIngredientsAndTax(TurretFactory.getUIWeaponType(), TurretFactory.getUIRarity(), TurretFactory.getMaterial(), buyer)
	end

	SystemFactory.refreshIngredientsUI()
end

function SystemFactory.placeBlueprint(item, mode)
	item.amount = 1

	selectedBlueprintSelection:clear()
	selectedBlueprintSelection:add(item)

	configurationMode = mode

	SystemFactory.onBlueprintSelected()
end

function SystemFactory.onBlueprintSelectionClicked(selectionIndex, kx, ky, item, button)
	local mode = ConfigurationMode.InventorySystem
	if selectionIndex == predefinedBlueprintSelection.selection.index then
		mode = ConfigurationMode.FactorySystem
	end

	SystemFactory.placeBlueprint(item, mode)
end

function SystemFactory.refreshBuildSystemsUI()
	local buyer = Galaxy():getPlayerCraftFaction()

	local rarities = {Rarity(RarityType.Common), Rarity(RarityType.Uncommon), Rarity(RarityType.Rare)}
	if buyer:getRelations(Faction().index) >= 80000 then
		table.insert(rarities, Rarity(RarityType.Exceptional))
	end

	local seed = Seed()
	local first
	predefinedBlueprintSelection:clear()
	for _, systemType in pairs(SystemFactory.getPossibleSystemTypes()) do
		---@param rarity Rarity
		for _, rarity in pairs(rarities) do
			local item = InventorySelectionItem()
			print('value', rarity.name, systemType)
			item.item = SystemUpgradeTemplate(systemType, rarity, seed)
			predefinedBlueprintSelection:add(item)
			if not first then first = item end
		end
	end

	selectedBlueprintSelection:clear()
	selectedBlueprintSelection:addEmpty()

	SystemFactory.placeBlueprint(first, ConfigurationMode.FactorySystem)
end

function SystemFactory.onShowWindow()
	window.caption = "Tech ${level} - System Factory"%_t % {level = SystemFactory.getTechLevel()}

	SystemFactory.refreshBuildSystemsUI()
end
