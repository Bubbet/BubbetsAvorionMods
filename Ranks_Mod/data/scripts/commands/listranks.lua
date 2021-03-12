function execute(sender, _, ...)
    local success = 0

    local args = {...}

    local err, rank, player, id = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", "", args[1])
    local splayer = Player(sender)
    local sid = splayer and splayer.id.id
    local err2, canpreform = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPowerOverWithRank", sid, id, rank)
    canpreform = canpreform or  not splayer or Server():hasAdminPrivileges(splayer)

    local output = "Failed to" .. (rank and "" or " find rank, ") .. (id and "" or " find id, ") .. (canpreform and "" or " pass permission check, ")

    if canpreform then
        err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "listUsersRanks", id) -- which ranks can be indexed
        if success then
            if id then
                local name = player.name
                output = (name or id) .." has these ranks: " .. table.concat(success, ", ")
            else
                output = "Server has these ranks: " .. table.concat(success, ", ")
            end
        end
    end

    return success and (#success > 0), "", output
end

function getDescription()
    return "Lists the ranks of a user"
end

function getHelp()
    return "Lists the ranks of a user or all the ranks if no args. Usage: /listranks in_game_name/steamid64"
end
