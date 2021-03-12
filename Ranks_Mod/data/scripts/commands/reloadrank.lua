function execute(sender, _, ...)
    local success
    local args = {...}

    local err, rank = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)

    local output = "Failed to" .. (rank and "" or " find rank, ")

    --if rank == "default" then return 0, "", "You cannot reset default welcome mail.(it'd be a ton of extra work to integrate this)" end
    if not rank then rank = args[1] end
    if rank then
        err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "reloadRank", rank)
        if err then
            output = "Reloaded " .. rank
        end
    end

    return success, "", output
end

function getDescription()
    return "Force the reload of a rank. Useful for updating changes to rank files during runtime. Can only be used with ranks located in your moddata."
end

function getHelp()
    return "Force the reload of a rank. Useful for updating changes to rank files during runtime. Usage: /reloadrank rank"
end
