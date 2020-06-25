package.path = package.path .. ";data/scripts/config/?.lua"
local rsmConfig
if ModManager():findEnabled("2003555597") then rsmConfig = include("ConfigLoader") else
  print("[ClaimableResourceAsteroids] ConfigLoader not installed, falling back on local config.")
  rsmConfig = include("resourcemineconfig")
end
if rsmConfig.enablenpcautoprocessing then
  local rsm_old_init = Refinery.initialize
  function Refinery.initialize()
    rsm_old_init()
    local station = Entity()
    if station.type == EntityType.Station then
        station:addScriptOnce("data/scripts/entity/merchants/npcautorefinery.lua")
    end
  end
end
