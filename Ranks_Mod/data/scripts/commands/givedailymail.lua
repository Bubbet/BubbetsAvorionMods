function execute(sender, _, ...)
  local success

  local err, rank, player, id = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)

  local output = "Failed to" .. (rank and "" or " find rank, ") .. (player and "" or " find player, ")

  if player and rank then
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "giveDaily", rank, player)
    if err then
      output = "Attempted to give " .. player.name .. " a " .. rank .. " daily mail package."
    else
      output = "Failed to properly invoke function."
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
