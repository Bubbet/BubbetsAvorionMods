function execute(sender, commandName, entityId)
    local player = Player(sender) -- Fixing vanilla command
    if not player then
        return 1, "", "You as a player do not exist!"
    end

    local self = player.craft
    if not self then
        return 1, "", "You're not in a ship!"
    end

    local craft = self.selectedObject or self

    if not craft.crew then
        return 1, "", "This craft doesn't have a crew!"
    end

    craft.crew = craft.minCrew
    craft:addCrew(1, CrewMan(CrewProfessionType.Captain))

    return 0, "", "Added crew to craft."
end