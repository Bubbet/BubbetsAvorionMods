function execute(sender, _, ...)
  local success = 0

  local err, rank, player, id = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)
  local splayer = Player(sender)
  local sid = splayer.id.id
  local err2, canpreform = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPowerOverWithRank", sid, id, rank)
  canpreform = canpreform or Server():hasAdminPrivileges(splayer) or not splayer

  local output = "Failed to" .. (rank and "" or " find rank, ") .. (id and "" or " find id, ") .. (canpreform and "" or " pass permission check, ")

  if id and rank and canpreform then
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "removeuser", rank, id) -- which ranks can be indexed
    if success > 1 then
      output = (name or id) .." not found in " .. rank
    elseif success > 0 then
      output = "Removed " .. (player.name or id) .." from " .. rank
    end
  end
  return success, "", output
end

function getDescription()
    return "Remove user from rank"
end

function getHelp()
    return "Remove user from rank. Usage: /removeuser rank in_game_name/steamid64"
end
