package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/config/?.lua"
include ("randomext")
include ("galaxy")
include ("faction")
include ("utility")
include ("stringutility")
include ("stationextensions")
local Config
if ModManager():findEnabled("2003555597") then Config = include("ConfigLoader") else
    print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
    Config = include("resourcemineconfig")
end
local TradingAPI = include ("tradingmanager")
local Dialog = include("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace NpcAutoRefinery
NpcAutoRefinery = {}
NpcAutoRefinery = TradingAPI:CreateNamespace()

--NpcAutoRefinery.toggleBuyButton = nil
NpcAutoRefinery.trader.relationsThreshold = -45000
NpcAutoRefinery.speed = 1

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function NpcAutoRefinery.interactionPossible(playerIndex, option)
    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -45000)
end

function NpcAutoRefinery.restore(data)
    --data = data or {buytoggle = Config.buyFromOthers or false}
    NpcAutoRefinery.restoreTradingGoods(data.goods)
    NpcAutoRefinery.trader.buyFromOthers = false
    --NpcAutoRefinery.togglevalue = data.buytoggle
    --NpcAutoRefinery.trader.buyFromOthers = Config.buyFromOthers and NpcAutoRefinery.togglevalue or 0
end

function NpcAutoRefinery.secure()
    local data = {goods = NpcAutoRefinery.secureTradingGoods()}--, buytoggle = NpcAutoRefinery.togglevalue}
    return data
end

function NpcAutoRefinery.setProcessSpeed()
  local entity = Entity()
  local plan = entity:getFullPlanCopy()
  NpcAutoRefinery.speed = math.max(plan:getStats().productionCapacity/(Config.productionCapacity or 250), 1)
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function NpcAutoRefinery.initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Refinery"

        if onServer() and planet then
            local count = getInt(2, 3)
            addCargoStorage(station, count)
        end
    end
    NpcAutoRefinery.trader.buyFromOthers = false
    --NpcAutoRefinery.togglevalue = Config.buyFromOthers and 1 or 0
    if onServer() then
        local sector = Sector()
        local x, y = sector:getCoordinates()
        local highest_material = sector:getValue('highest_material')
        local probabilities
        if not highest_material then probabilities = Balancing_GetMaterialProbability(x, y) end

        sector:addScriptOnce("sector/traders.lua")

        math.randomseed(sector.seed + sector.numEntities);

        -- make lists of all items that will be sold/bought
        local bought = {}
        for i=0,NumMaterials()-1 do
            if (highest_material and (i <= highest_material)) or (probabilities and (probabilities[i] ~= 0)) then
                local good = materials[i+1]
                table.insert(bought, goods["Scrap " .. good]:good())
                table.insert(bought, goods[good .. " Ore"]:good())
            end
        end

        NpcAutoRefinery.trader.buyPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1
        NpcAutoRefinery.trader.sellPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1

        Entity():setValue("goods_generated", 1)
        NpcAutoRefinery.initializeTrading(bought, {})

        if Faction().isAIFaction then
          sector:registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
        end

        math.randomseed(appTimeMs())

        Entity():registerCallback("onPlanModifiedByBuilding","setProcessSpeed")
        NpcAutoRefinery.setProcessSpeed()

    else
        NpcAutoRefinery.requestGoods()

        if EntityIcon().icon == "" then
            EntityIcon().icon = "data/textures/icons/pixel/trade.png"
            InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
        end

    end
    --station:addScriptOnce("data/scripts/entity/merchants/cargotransportlicensemerchant.lua")
end

function NpcAutoRefinery.processResources(timeStep)
  local entity = Entity()
  local faction, craft, player = getInteractingFactionByShip(entity.id, callingPlayer, AlliancePrivilege.AddResources)
  local materialcount = (Config.processAmount or 200) * timeStep * NpcAutoRefinery.speed
  for i=0,NumMaterials()-1 do
    if materialcount == 0 then return end
    local resource = Material(i).name
    local ore = entity:findCargos(resource .. " Ore")
    local scrap = entity:findCargos("Scrap " .. resource)
    for good, amount in pairs(ore) do
      if materialcount == 0 then return end
      local subtracts = math.min(materialcount, amount)
      materialcount = materialcount - subtracts
      entity:removeCargo(good, subtracts)
      faction:receiveResource("", Material(i), subtracts)
    end
    for good, amount in pairs(scrap) do
      if materialcount == 0 then return end
      local subtracts = math.min(materialcount, amount)
      materialcount = materialcount - subtracts
      entity:removeCargo(good, subtracts)
      faction:receiveResource("", Material(i), subtracts)
    end
  end
end

function NpcAutoRefinery.onRestoredFromDisk(timeSinceLastSimulation)
    NpcAutoRefinery.processResources(timeSinceLastSimulation)
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function NpcAutoRefinery.initUI()
    local tabbedWindow = TradingAPI.CreateTabbedWindow("Refinery")

    -- create buy tab
    --local buyTab = tabbedWindow:createTab("Buy", "data/textures/icons/bag.png", "Buy from station")
    --NpcAutoRefinery.buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell", "data/textures/icons/sell.png", "Sell to refinery")
    NpcAutoRefinery.buildSellGui(sellTab)

    --NpcAutoRefinery.toggleBuyButton = sellTab:createButton(Rect(sellTab.size.x - 30, -5, sellTab.size.x, 25), "", "onToggleBuyPressed")
    --NpcAutoRefinery.toggleBuyButton.icon = "data/textures/icons/sell.png"

    NpcAutoRefinery.trader.guiInitialized = true

    NpcAutoRefinery.requestGoods()
end

function NpcAutoRefinery.onShowWindow(_,enabled)
    NpcAutoRefinery.requestGoods()
    --[[
    local faction = Faction()
    local player = Player()

    if (player.index == faction.index or player.allianceIndex == faction.index) and Config.buyFromOthers then
        NpcAutoRefinery.toggleBuyButton:show()
    else
        NpcAutoRefinery.toggleBuyButton:hide()
    end

    if type(enabled) == "nil" then invokeServerFunction("getToggle") return end
    print(enabled)

    if enabled == 1 then -- enabled = 1 on first open but displays 0 anyways??? i give up
        NpcAutoRefinery.toggleBuyButton.icon = "data/textures/icons/sell-enabled.png"
        NpcAutoRefinery.toggleBuyButton.tooltip = "This station buys consumer goods from traders."
    else
        NpcAutoRefinery.toggleBuyButton.icon = "data/textures/icons/sell-disabled.png"
        NpcAutoRefinery.toggleBuyButton.tooltip = "This station doesn't buy consumer goods from traders."
    end
    ]]
end
--[[
function NpcAutoRefinery.getToggle()
  invokeClientFunction(Player(callingPlayer), "onShowWindow", _, NpcAutoRefinery.trader.buyFromOthers)
end
callable(NpcAutoRefinery, "getToggle")

function NpcAutoRefinery.onToggleBuyPressed()
  if onClient() then
    invokeServerFunction("onToggleBuyPressed")
  else
    if not Config.buyFromOthers then return end
    local faction, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.ManageStations)
    if player then
      NpcAutoRefinery.togglevalue = not NpcAutoRefinery.togglevalue
      NpcAutoRefinery.trader.buyFromOthers = Config.buyFromOthers and NpcAutoRefinery.togglevalue and true or false
      invokeClientFunction(player, "onShowWindow", _, NpcAutoRefinery.trader.buyFromOthers and 1 or 0)
    end
  end
end
callable(NpcAutoRefinery, "onToggleBuyPressed")
]]

function NpcAutoRefinery.getUpdateInterval()
    return Config.updateInterval or 5
end

---- this function gets called each tick, on server only
function NpcAutoRefinery.updateServer(timeStep)
  NpcAutoRefinery.processResources(timeStep)
end
