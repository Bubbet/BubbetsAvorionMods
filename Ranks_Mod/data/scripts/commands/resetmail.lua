function execute(sender, _, ...)
  local success

  local err, rank = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)

  local output = "Failed to" .. (rank and "" or " find rank, ")

  if rank == "default" then return 0, "", "You cannot reset default welcome mail.(it'd be a ton of extra work to integrate this)" end

  if rank then
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "resetMail", rank)
    if success then
      output = "Reset the " .. rank .. " mail deliver state."
    end
  end

  return success, "", output
end

function getDescription()
    return "Force the redeliver of mail to group over time"
end

function getHelp()
    return "Force the redeliver of mail to group over time. Usage: /resetmail rank"
end
