function execute(sender, _, ...)
  local success = 0

  local err, rank, player, id = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findUser", ...)
  local splayer = Player(sender)
  local sid = splayer and splayer.id.id
  local err2, canpreform = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPowerOverWithRank", sid, id, rank)
  canpreform = canpreform or not splayer or Server():hasAdminPrivileges(splayer)

  local output = "Failed to" .. (rank and "" or " find rank, ") .. (id and "" or " find id, ") .. (canpreform and "" or " pass permission check, ")

  if id and rank and canpreform then
    local name = player and player.name or id
    err, success = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "adduser", rank, name, id) -- which ranks can be indexed
    if success then
      output = "Added " .. (name or id) .." to " .. rank
    end
  end

  return success, "", output
end

function getDescription()
    return "Add a user to a rank"
end

function getHelp()
    return "Adds a user to a rank. Usage: /adduser rank in_game_name/steamid64"
end
