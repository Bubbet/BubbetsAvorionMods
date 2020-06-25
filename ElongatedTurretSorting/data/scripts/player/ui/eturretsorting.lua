package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
include("UISortList")

-- namespace ETurretSorting
ETurretSorting = {}
if onClient() then
    function ETurretSorting.initialize()
        local ui = {}
        ui.tab = PlayerWindow():createTab("Elongated Turret Sorting"%_t, "data/textures/icons/turret.png", "Elongated Turret Sorting"%_t)
        ui.tab.onShowFunction = "onShowTab"

        ui.vsplit = UIVerticalSplitter(Rect(vec2(0, 0), ui.tab.size), 10, 0, 0.3)

        ui.turrets = ui.tab:createInventorySelection(ui.vsplit.right, 8)
        local player = Galaxy():getPlayerCraftFaction()
        ui.turrets:fill(player.index, InventoryItemType.Turret)
        ui.sortlist = UISortList(ETurretSorting, ui.tab, ui.vsplit.left, ui.turrets)

        ETurretSorting.ui = ui
    end
end

function ETurretSorting.onShowTab()
    ETurretSorting.ui.sortlist:onShowWindow()
end
    --[[
    local buyer = Galaxy():getPlayerCraftFaction()
    local inventory = buyer:getInventory()
    for k, v in pairs(inventory:getItems()) do
        --local selectionitem = InventorySelectionItem()
        --selectionitem.item = v.item
        --selectionitem.uvalue = k
        printTable(v)
        local item = v.item
        dbg(item)
        item.trash = true
        ETurretSorting.ui.turrets:add(item)--selectionitem,k)
    end
end
]]