function execute(sender, _, ...)
  local success

  local err, rank, player = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)

  local output = "Failed to" .. (rank and "" or " find rank, ") .. (player and "" or " find player, ")

  if player and rank then
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "giveMail", rank, player)
    if success then
      output = "Gave " .. player.name .. " a " .. rank .. " mail package."
    end
  end

  return success, "", output
end

function getDescription()
    return "Force deliver mail of group to player"
end

function getHelp()
    return "Force deliver mail of group to player. Usage: /givemail rank in_game_name"
end
