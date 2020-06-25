package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")

local Config = include("ConfigLoader")

local numTurrets, planstats, stat = "Unknown"
local installed = false

FixedEnergyRequirement = false

function onBlockPlanChanged()
    planstats = Plan():getStats()
end

function getWeightedAverage()
    if not planstats then onBlockPlanChanged() end
    local sum, total = 0, 0

    for k, v in pairs(Config.stats) do
        sum = sum + planstats[k] * v
        total = total + 1
    end

    local val = sum/total
    val = Config.scalingfunction(val)

    return val
end

function getNumTurrets(rarity, permanent)
    local average = getWeightedAverage()
    average = average * (rarity.value + 2) / 10
    if permanent then average = average * 1.25 end
    return math.floor(average)
end

function onInstalled(seed, rarity, permanent)
    local entity = Entity()
    installed = true
    entity:registerCallback("onBlockPlanChanged", "onBlockPlanChanged")
    onBlockPlanChanged()
    stat = stat or getValueFromDistribution(Config.probabilities, Random(seed))
    numTurrets = getNumTurrets(rarity, permanent)
    addMultiplyableBias(stat, numTurrets) -- test for random buff every reload or static?
end

function onUninstalled(seed, rarity, permanent)
    local entity = Entity()
    installed = false
    entity:unregisterCallback("onBlockPlanChanged", "onBlockPlanChanged")
end

function getEnergy(seed, rarity, permanent)
    stat = stat or getValueFromDistribution(Config.probabilities, Random(Seed(seed)))
    local num = 0
    if installed then num = numTurrets * ((permanent and 1 or 0) * 0.25 + 1) end
    return num * 300 * 1000 * 1000 / (1.2 ^ rarity.value)
end

function getPrice(_, rarity)
    local num = math.max(1, rarity.value + 1) * 2
    local price = 6000 * num;
    return price * 4.5 ^ rarity.value
end

function getIcon(_, _)
    return "data/textures/icons/turret.png"
end

function getName(seed, rarity, permanent, otherSeed, otherRarity)
    return "Scaling " .. Config.stattypes[getValueFromDistribution(Config.probabilities, Random(Seed(seed)))] ..  " Control System "
end

function getTooltipLines(seed, rarity, permanent)
    local sum = 0
    local length = tablelength(Config.stats)
    local stattype = Config.stattypes[getValueFromDistribution(Config.probabilities, Random(Seed(seed)))]
    local lines = {{icon = "data/textures/icons/turret.png", ltext = stattype .. " Slots", rtext = "+??", boosted = permanent},
                   {},
                   {icon = "data/textures/icons/anchor.png", ltext = permanent and "Permanent Installation Bonuses Active" or "Permanent Installation Possible", iconColor = ColorRGB(0.9, 0.9, 0.9), lcolor = ColorRGB(0.9, 0.9, 0.9), litalic = true},
                   {},
                   {ltext = stattype .. " Slots:"}}
    for k, v in pairs(Config.stats) do
        local display = v * (rarity.value + 2) / 10
        if permanent then display = display * 1.25 end
        display = display/length
        display = math.floor(1/display)
        table.insert(lines, {ltext = "x+1 per " .. display .. Config.units[k] .. " " .. k:firstToUpper(), lcolor = permanent and ColorRGB(0, 1, 0)})
        sum = sum + v
    end
    local energy = ((permanent and 1 or 0) * 0.25 + 1) * 300 * 1000 * 1000 / (1.2 ^ rarity.value)
    energy = toReadableValue(energy, "W")
    table.insert(lines, {ltext = "Add the sum of the above, then plug into scaling function."})
    --print('is player valid yet', valid(Player()))
    table.insert(lines, {ltext = "Scaling Function:", rtext = Config.scalingfunction.__tostring})
    --table.insert(lines, {ltext = stattype .. "s increase by 1 per " .. average .. " of above"})
    table.insert(lines, {})
    table.insert(lines, {ltext = "Energy Consumption"%_t, icon = "data/textures/icons/electric.png", rtext = energy .. " per Slot"})
    return lines
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Buffs ship stats based on other ship stats"},
        {ltext = "Adds slots for " .. Config.stattypes[getValueFromDistribution(Config.probabilities, Random(Seed(seed)))] .. "s"},
    }
end