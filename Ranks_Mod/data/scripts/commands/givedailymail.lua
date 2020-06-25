function execute(sender, _, ...)
  local success

  local err, rank, player, id = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)

  local output = "Failed to" .. (rank and "" or " find rank, ") .. (player and "" or " find player, ")

  if player and rank then
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "giveDaily", rank, id)
    if success then
      output = "Gave " .. player.name .. " a " .. rank .. " daily mail package."
    else
      output = "Failed to properly invoke function."
    end
    if success == nil then
      output = rank .. " doesn't have a daily mail package."
    end
  end

  return success, "", output
end

function getDescription()
    return "Force deliver daily mail of group to player"
end

function getHelp()
    return "Force deliver daily mail of group to player. Usage: /givedailymail rank in_game_name"
end
