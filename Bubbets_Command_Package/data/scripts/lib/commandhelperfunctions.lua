package.path = package.path .. ";data/scripts/lib/?.lua"

-- namespace CommandHelperFunctions
CommandHelperFunctions = {items = {}}

local SectorTurretGenerator = include ("sectorturretgenerator")
local UpgradeGenerator = include("upgradegenerator")
for k, v in pairs(WeaponType) do
    CommandHelperFunctions.items[k] = "weapon"
end
for k, v in pairs(getmetatable(UpgradeGenerator()).scripts) do
    CommandHelperFunctions.items[k] = "system"
end

function CommandHelperFunctions.findUser(instring)
    if not instring then return end
    for k, v in pairs({Server():getOnlinePlayers()}) do
       if string.lower(v.name):find(string.lower(instring)) then return v end
    end
end

function CommandHelperFunctions.findItem(instring)
    local v = CommandHelperFunctions.items[instring]
    if v then
        if v == "weapon" then
            return SectorTurretGenerator():generate(0, 0, _, _, WeaponType[instring])
        else
            return SystemUpgradeTemplate(instring, Rarity(math.floor(math.random(-1,6))), Seed(math.floor(math.random(1,100))))
        end
    end
    instring = string.lower(instring)
    for k, v in pairs(CommandHelperFunctions.items) do
        if string.lower(k):find(instring) then
            print("found", k)
            if v == "weapon" then
                return SectorTurretGenerator():generate(0, 0, _, _, WeaponType[k])
            else
                return SystemUpgradeTemplate(k, Rarity(math.floor(math.random(-1,6))), Seed(math.floor(math.random(1,100))))
            end
        end
    end
end

return CommandHelperFunctions