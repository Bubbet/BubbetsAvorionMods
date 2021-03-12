package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"

UpgradeGenerator = include("upgradegenerator")
SystemIngredients = include("systemingredients")
include("galaxy")
include("systemupgradeblueprint")
include("callable")

local Config
if ModManager():findEnabled("2003555597") then Config = include("ConfigLoader") else
    if onServer() and not Server():getValue('CRA_LocalAlert') then
        print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
        Server():setValue('CRA_LocalAlert', true)
    end
    Config = include("systemfactoryconfig")
end

-- namespace SystemFactory
SystemFactory = {}

function SystemFactory.initUI()
    local res = getResolution()
    local size = vec2(780, 580)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "System Factory"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Build Systems /*window title*/"%_t);

    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local buildSystemsTabExtra = {}
    buildSystemsTab = tabbedWindow:createTab("", "data/textures/icons/circuitry.png", "Build Systems")
    SystemFactory.initBuildSystemsUI(buildSystemsTab, buildSystemsTabExtra)

    --makeBlueprintsTab = tabbedWindow:createTab("", "data/textures/icons/system-blueprint.png", "Blueprint your systems")
    --SystemFactory.initBlueprintsUI(makeBlueprintsTab)

    SystemFactory.ui = {res=res, size=size, menu=menu, tabbedWindow=tabbedWindow, buildSystemsTabExtra=buildSystemsTabExtra}
end

function SystemFactory.initialize()
    print("test")
    SystemUpgradeBlueprint("data/scripts/systems/arbitrarytcs.lua", Rarity(1), Seed(1))
end

---@param tab Tab
---@param extra table
function SystemFactory.initBuildSystemsUI(tab, extra)
    tab.onSelectedFunction = "refreshBuildSystemsUI"
    tab.onShowFunction = "refreshBuildSystemsUI"
    extra.vertical_split = UIVerticalSplitter(Rect(vec2(),tab.size), 10, 0, 0.4)
    extra.right_frame = tab:createFrame(extra.vertical_split.right)
    extra.horizontal_split = UIHorizontalSplitter(extra.vertical_split.left, 10, 0, 0.25)
    extra.horizontal_split_top_rect = extra.horizontal_split.top
    extra.horizontal_split_top_rect.size = vec2(75)
    selectedBlueprintSelection = tab:createSelection(extra.horizontal_split_top_rect, 1)
    selectedBlueprintSelection.dropIntoEnabled = 1
    selectedBlueprintSelection.entriesSelectable = 0
    selectedBlueprintSelection.onReceivedFunction = "onBlueprintReceived"
    extra.bottom_horizontal_split = UIHorizontalSplitter(extra.horizontal_split.bottom, 10, 0, 0.5)
    extra.bottom_horizontal_split.topSize = 25
    extra.blueprint_type_combo = tab:createComboBox(extra.bottom_horizontal_split.top,"onBlueprintTypeSelected")
    extra.blueprint_type_combo:addEntry("Factory Blueprints"%_t)
    extra.blueprint_type_combo:addEntry("Inventory Blueprints"%_t)
    inventoryBlueprintSelection = tab:createInventorySelection(extra.bottom_horizontal_split.bottom, 5)
    inventoryBlueprintSelection.dragFromEnabled = 1
    inventoryBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"
    inventoryBlueprintSelection:hide()
    predefinedBlueprintSelection = tab:createInventorySelection(extra.bottom_horizontal_split.bottom, 5)
    predefinedBlueprintSelection.dragFromEnabled = 1
    predefinedBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"
    extra.lister = UIVerticalLister(extra.vertical_split.right, 10, 10)
    extra.right_vertical_split_rect = extra.lister:placeCenter(vec2(extra.lister.inner.width, 30))
    extra.right_vertical_split = UIArbitraryVerticalSplitter(extra.right_vertical_split_rect, 10, 5, 320, 370)
    extra.right_parts_label = tab:createLabel(extra.right_vertical_split:partition(0).lower, "Parts"%_t, 14)
    extra.right_req_label = tab:createLabel(extra.right_vertical_split:partition(1).lower, "Req"%_t, 14)
    extra.right_you_label = tab:createLabel(extra.right_vertical_split:partition(2).lower, "You"%_t, 14)
    extra.right_lines = {}
    for i = 1, 15 do
        local rect = extra.lister:placeCenter(vec2(extra.lister.inner.width, 30))
        local vsplit = UIArbitraryVerticalSplitter(rect, 10, 7, 20, 250, 280, 310, 320, 370)
        local frame = tab:createFrame(rect)
        local i = 0
        local icon = tab:createPicture(vsplit:partition(i), ""); i = i + 1
        local materialLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local plus = tab:createButton(vsplit:partition(i), "+", "onPlus"); i = i + 1
        local minus = tab:createButton(vsplit:partition(i), "-", "onMinus"); i = i + 2
        local requiredLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local youLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
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
        local line =  {rect = rect, vsplit = vsplit, frame = frame, icon = icon, plus = plus, minus = minus, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
        line:hide()
        table.insert(extra.right_lines, line)
    end
    extra.right_organizer = UIOrganizer(extra.vertical_split.right)
    extra.right_rect = extra.right_organizer:getBottomRect(Rect(vec2(extra.vertical_split.right.width,60)))
    extra.right_bottom_vertical_split = UIVerticalSplitter(extra.right_rect, 10, 10, 0.9)
    buildButton = tab:createButton(extra.right_bottom_vertical_split.left, "Build /*Turret Factory Button*/"%_t, "onBuildSystemPressed")
    saveButton = tab:createButton(extra.right_bottom_vertical_split.right, "", "onTrackIngredientsButtonPressed")
    saveButton.icon = "data/textures/icons/checklist.png"
    saveButton.tooltip = "Track ingredients in mission log"%_t
    priceLabel = tab:createLabel(vec2(extra.vertical_split.right.lower.x, extra.vertical_split.right.upper.y) + vec2(12, -75), "Manufacturing Price: Too Much"%_t, 16)
    return tab, extra
end

function SystemFactory.getCoordinates()
    if not SystemFactory.coords then
        SystemFactory.coords = {}
        SystemFactory.coords.x, SystemFactory.coords.y = Sector():getCoordinates()
    end

    return SystemFactory.coords.x, SystemFactory.coords.y
end

function SystemFactory.getPossibleSystemTypes()
    local systemTypes = {}
    local probabilities = Balancing_GetSystemProbability(SystemFactory.getCoordinates())
    for type, probability in pairs(probabilities) do

        for k, t in pairs(SystemIngredients) do
            if k == type then
                systemTypes[k] = k
            end
        end
    end

    return systemTypes
end

function SystemFactory.refreshBuildSystemsUI()
    local buyer = Galaxy():getPlayerCraftFaction()
    --inventoryBlueprintSelection:fill(buyer.index, InventoryItemType.TurretTemplate)

    local rarities = {Rarity(RarityType.Common), Rarity(RarityType.Uncommon), Rarity(RarityType.Rare)}
    if buyer:getRelations(Faction().index) >= 80000 then
        table.insert(rarities, Rarity(RarityType.Exceptional))
    end

    local first = nil
    predefinedBlueprintSelection:clear()
    for _, systemType in pairs(SystemFactory.getPossibleSystemTypes()) do
        for _, rarity in pairs(rarities) do
            local item = InventorySelectionItem()
            item.item = SystemUpgradeBlueprint(systemType, rarity, Seed(1))--SystemFactory.getMaterial())
            predefinedBlueprintSelection:add(item)

            if not first then first = item end
        end
    end

    selectedBlueprintSelection:clear()
    selectedBlueprintSelection:addEmpty()

    --TurretFactory.placeBlueprint(first, ConfigurationMode.FactoryTurret)
end

function SystemFactory.onShowWindow()
    --window.caption = "Tech ${level} - Turret Factory"%_t % {level = TurretFactory.getTechLevel()}
    ---@type vec3
    local velocity_a = ReadOnlyVelocity(Player().craft.id).velocity
    velocity_a
    if buildSystemsTab.isActiveTab then
        SystemFactory.refreshBuildSystemsUI()
    else
        --TurretFactory.refreshMakeBlueprintsUI()
    end
end

function SystemFactory.onBlueprintTypeSelected(combo, selectedIndex)
    predefinedBlueprintSelection.visible = (selectedIndex == 0)
    --inventoryBlueprintSelection.visible = (selectedIndex == 1)
end

function SystemFactory.onBlueprintSelected()
end

function SystemFactory.placeBlueprint(item, mode)
    item.amount = 1

    selectedBlueprintSelection:clear()
    selectedBlueprintSelection:add(item)

    --configurationMode = mode

    SystemFactory.onBlueprintSelected()
end

function SystemFactory.onBlueprintSelectionClicked(selectionIndex, kx, ky, item, button)
    --local mode = ConfigurationMode.InventoryTurret
    --if selectionIndex == predefinedBlueprintSelection.selection.index then
        --mode = ConfigurationMode.FactoryTurret
    --end

    SystemFactory.placeBlueprint(item)--, mode)
end

function SystemFactory.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, 30000)
end

function SystemFactory.give()
    Player(callingPlayer):getInventory():add(SystemUpgradeBlueprint("data/scripts/systems/arbitrarytcs.lua", Rarity(1), Seed(1)))
    Player(callingPlayer):getInventory():add(SystemUpgradeBlueprint("data/scripts/systems/batterybooster.lua", Rarity(1), Seed(1)))
end
callable(SystemFactory, "give")