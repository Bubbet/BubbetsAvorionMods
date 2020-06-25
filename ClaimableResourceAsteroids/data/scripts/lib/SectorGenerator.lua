local curSector = Sector()
function SectorGenerator:createBigAsteroidEx(position, size, resources)

    local desc = AsteroidDescriptor()
    --desc:removeComponent(ComponentType.MineableMaterial)
    desc:addComponents(
       ComponentType.Owner,
       ComponentType.FactionNotifier,
       ComponentType.Crew -- for good measure?
       )

    desc.position = position or self:getPositionInSector()
    local typ = self:getAsteroidType()
    desc:setMovePlan(PlanGenerator.makeBigAsteroidPlan(size, resources, typ))
    local curVal = curSector:getValue('highest_material')
    if curVal and curVal < typ or not curVal then curSector:setValue('highest_material', typ) end

    if resources then
        --local x, y = Sector():getCoordinates()
        --print(self:getAsteroidType().name .. ": " .. desc.volume .. " Sector: " .. x .. ":" .. y)
        desc.isObviouslyMineable = true
        desc:setValue("valuable_object", RarityType.Petty)
        desc:addScript("claimresource.lua")
    end

    local entity = Sector():createEntity(desc)
    entity.type = 5
    entity.title = "Asteroid"

    return entity

end
