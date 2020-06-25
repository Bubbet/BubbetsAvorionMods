package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
if onServer() then
  local entity = Entity()
  if entity:hasScript("claimresource.lua") or entity:hasScript("resourceminefounder.lua") then
    entity.type = EntityType.Asteroid
  end

  if ModManager():findEnabled("1691539727") then
    if entity.isAsteroid then
      if entity:hasComponent(ComponentType.Owner) then
        if entity:hasScript("resourceminefounder.lua") then
          entity:addScriptOnce("entity/moveAsteroid.lua")
        end
      end
    end
  end
  --[[
  if entity.invincible and entity.playerOwned then
    local x, y = Sector():getCoordinates()
    print(x .. ":" .. y)
    printTable(Sector():getScripts())
  end
  --]]
end
