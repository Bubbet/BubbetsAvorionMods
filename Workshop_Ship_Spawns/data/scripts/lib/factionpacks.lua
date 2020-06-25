
local workshop_ship_spawns_shadow_initialize = FactionPacks.initialize
function FactionPacks.initialize()
    workshop_ship_spawns_shadow_initialize()
	local packs = getGlobal("faction_packs")
	printTable(packs)
	for k, v in pairs(packs) do
		for k, v in pairs(v.ships) do
			print(LoadTurretDesignFromFile(v))
		end
		--LoadTurretDesignFromFile(path)
	end

    --[[for _, mod in pairs(Mods()) do
        if mod.type == "factionpack" then
            local turretPack = dofile(mod.folder .. "turretpack.lua")
            if turretPack then
                local pack = {}

            end
        end
    end]]
end

function FactionPacks.getPlan(plansTable, volume, material)
	if not plansTable then return end
	if #plansTable == 0 then return end

	local path = plansTable[random():getInt(1, #plansTable)]
	if not path then return end

	--    print("load path: " .. path)
	local plan = LoadPlanFromFile(path)
	if not valid(plan) then
		printlog("failed to load plan from faction pack: " .. path .. "'")
		return
	end

	-- change material
	plan:setMaterialTier(material)

	-- scale
	if volume then
		local factor = math.pow(volume / plan.volume, 1 / 3)
		plan:scale(vec3(factor))
	end

	return plan, path
end

function FactionPacks.getPack()
	print('getting pack')
	local factionPacks = getGlobal("faction_packs") or {}
	printTable(factionPacks)
	return factionPacks['Example_Faction_Pack']
end

function FactionPacks.getShipPlan(faction, volume, material)
	print('trying to get ship plan')
	local usedPack = FactionPacks.getPack(faction)
	if not usedPack then return end
	print('getting ship plan')
	return FactionPacks.getPlan(usedPack.ships, volume, material)
end

--[[
function FactionPacks.initialize()
    factionPacks = {}

    for _, mod in pairs(Mods()) do
        if mod.type == "factionpack" then
--            print("faction pack found: '" .. mod.name .. "'")

            local factionPack = dofile(mod.folder .. "factionpack.lua")

            local pack = {}
            pack.settings = factionPack.settings or {}

            -- gather plan paths for all types
            local typeNames =
            {
                "ships",
                "freighters",
                "carriers",
                "miners",
                "fighters",

                "stations",
                "shipyards",
                "repairdocks",
                "resourcedepots",
                "tradingposts",
                "equipmentdocks",
                "smugglersmarkets",
                "scrapyards",
                "mines",
                "factories",
                "fighterfactories",
                "turretfactories",
                "solarpowerplants",
                "farms",
                "ranches",
                "collectors",
                "biotopes",
                "casinos",
                "habitats",
                "militaryoutposts",
                "headquarters",
                "researchstations",
            }

            for _, typeName in pairs(typeNames) do
                local pathTable = factionPack[typeName]

                if type(pathTable) == "table" and #pathTable > 0 then
                    pack[typeName] = pathTable
                end
            end

            factionPacks[mod.id] = pack
        end
    end

    local oldFactionPacks = getGlobal("faction_packs") or {}

    -- get factions that already have a faction pack
    local factions = {}
    for id, pack in pairs(oldFactionPacks) do
        if pack.factionIndex then
            factions[id] = pack.factionIndex
        end
    end

    for id, pack in pairs(factionPacks) do
        if factions[id] then
            pack.factionIndex = factions[id]
        end
    end

    setGlobal("faction_packs", factionPacks)
end

function FactionPacks.tryApply(faction)
--    print("try apply faction pack for '" .. faction.name .. "'")

    if faction.homeSectorUnknown then return end

    if factionPacks == nil then
        factionPacks = getGlobal("faction_packs") or {}
    end

    local availableIDs = {}
    for id, pack in pairs(factionPacks) do
        if not pack.factionIndex then
            local distanceOK = true

            if pack.settings.minDist ~= nil or pack.settings.maxDist ~= nil then
                local hx, hy = faction:getHomeSectorCoordinates()
                local dist2 = hx * hx + hy * hy

                if pack.settings.minDist then
                    if dist2 < pack.settings.minDist * pack.settings.minDist then
                        distanceOK = false
                    end
                end

                if pack.settings.maxDist then
                    if dist2 > pack.settings.maxDist * pack.settings.maxDist then
                        distanceOK = false
                    end
                end
            end

            if distanceOK then
                table.insert(availableIDs, id)
            end
        end
    end

    if #availableIDs == 0 then
--        print("no faction packs left")
        return
    end

    local id = availableIDs[random():getInt(1, #availableIDs)]
    factionPacks[id].factionIndex = faction.index

    faction:setValue("faction_pack", id)
    setGlobal("faction_packs", factionPacks)
end


function FactionPacks.getStationPlan(faction, volume, material, styleName)
    local usedPack = FactionPacks.getPack(faction)
    if not usedPack then return end

    local styleTable
    if styleName == "Default" then
        -- use fallback
    elseif styleName == "Shipyard" then
        styleTable = usedPack.shipyards
    elseif styleName == "RepairDock" then
        styleTable = usedPack.repairdocks
    elseif styleName == "ResourceDepot" then
        styleTable = usedPack.resourcedepots
    elseif styleName == "TradingPost" then
        styleTable = usedPack.tradingposts
    elseif styleName == "EquipmentDock" then
        styleTable = usedPack.equipmentdocks
    elseif styleName == "SmugglersMarket" then
        styleTable = usedPack.smugglersmarkets
    elseif styleName == "Scrapyard" then
        styleTable = usedPack.scrapyards
    elseif styleName == "Mine" then
        styleTable = usedPack.mines
    elseif styleName == "Factory" then
        styleTable = usedPack.factories
    elseif styleName == "FighterFactory" then
        styleTable = usedPack.fighterfactories
    elseif styleName == "TurretFactory" then
        styleTable = usedPack.turretfactories
    elseif styleName == "SolarPowerPlant" then
        styleTable = usedPack.solarpowerplants
    elseif styleName == "Farm" then
        styleTable = usedPack.farms
    elseif styleName == "Ranch" then
        styleTable = usedPack.ranches
    elseif styleName == "Collector" then
        styleTable = usedPack.collectors
    elseif styleName == "Biotope" then
        styleTable = usedPack.biotopes
    elseif styleName == "Casino" then
        styleTable = usedPack.casinos
    elseif styleName == "Habitat" then
        styleTable = usedPack.habitats
    elseif styleName == "MilitaryOutpost" then
        styleTable = usedPack.militaryoutposts
    elseif styleName == "Headquarters" then
        styleTable = usedPack.headquarters
    elseif styleName == "ResearchStation" then
        styleTable = usedPack.researchstations
    end

    local plan
    if styleTable then
        plan = FactionPacks.getPlan(styleTable, volume, material)
    end

    if not valid(plan) then
--        print("no special style available, fallback to stations")
        plan = FactionPacks.getPlan(usedPack.stations, volume, material)
    end

    return plan
end


function FactionPacks.getPack(faction)
    if type(faction) == "number" then
        if Faction then
            faction = Faction(faction)
        else
            faction = nil
        end
    end

    if not faction then return end

    local usedID = faction:getValue("faction_pack")
    if not usedID then return end

    if factionPacks == nil then
        factionPacks = getGlobal("faction_packs") or {}
    end

    return factionPacks[usedID]
end

function FactionPacks.getPlan(plansTable, volume, material)
    if not plansTable then return end
    if #plansTable == 0 then return end

    local path = plansTable[random():getInt(1, #plansTable)]
    if not path then return end

--    print("load path: " .. path)
    local plan = LoadPlanFromFile(path)
    if not valid(plan) then
        printlog("failed to load plan from faction pack: " .. path .. "'")
        return
    end

    -- change material
    plan:setMaterialTier(material)

    -- scale
    if volume then
        local factor = math.pow(volume / plan.volume, 1 / 3)
        plan:scale(vec3(factor))
    end

    return plan
end

return FactionPacks
]]