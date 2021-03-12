function execute(sender, _, ...)
	local rank = {}

	local args = {...}

	local splayer = Player(sender)
	local err2, canpreform = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "canCommand", splayer and splayer.id.id, "listusers")
	canpreform = canpreform or  not splayer or Server():hasAdminPrivileges(splayer)

	local output = ""

	if canpreform then
		local err, rank = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "findRank", args[1])
		if err == 0 then
			if rank then
				for k, _ in pairs(rank) do
					output = output .. k .. ';'
				end
			end
		end
	end

	return rank and (#rank > 0), "", output
end

function getDescription()
	return "Lists the users of a rank, for usage with the bot."
end

function getHelp()
	return "Lists the users of a rank. Usage: /listusers in_game_name/steamid64"
end
