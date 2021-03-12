package.path = package.path .. ";data/scripts/lib/?.lua"

include("utility")
Commands = {}

function Commands:getCommands(id)
	local commands = {}
	for k, file in pairs(self.namespace.files) do
		if self.namespace.hasrank(k, id) or not id then
			for _, v in pairs(file.commands) do
				table.insert(commands, v)
			end
		end
	end
	local output = {}
	for _, v in pairs(commands) do
		local ok1, desc = run("data/scripts/commands/"..v..".lua", "getDescription")
		local ok2, help = run("data/scripts/commands/"..v..".lua", "getHelp")
		if ok1 and ok2 then
			output[v] = {desc = desc, help = help}
		end
	end
	return output
end

function Commands:help(playerIndex, ...)
	local sender = Player(playerIndex)
	local args = {...}
	local commandName = args[1]
	local val = ""
	local commands = self:getCommands(sender.id.id)
	if commandName then
		val = "You don't have permission to use " .. commandName or "INVALID_COMMAND"
		if commands[commandName] then
			val = "Desc: " .. commands[commandName].desc .. "\n Help: " .. commands[commandName].help:gsub(": /", ": !")
		else
			if self.namespace.server:hasAdminPrivileges(sender) then
				local ok1, desc = run("data/scripts/commands/"..commandName..".lua", "getDescription")
				local ok2, help = run("data/scripts/commands/"..commandName..".lua", "getHelp")
				if ok1 then
					val = "\nDesc: " .. desc
				end
				if ok2 then
					val = val .. "\nHelp: " .. help:gsub(": /", ": !")
				end
			end
		end
	else
		local temp = {"Commands you are able to issue:"}
		for k, v in pairs(commands) do
			local line = "!" .. k
			if v.desc then line = line .. "\n    Desc: " .. v.desc end
			if v.help then line = line .. "\n    Help: " .. v.help:gsub(": /", ": !") end
			table.insert(temp, line)
		end
		val = table.concat(temp, "\n")--string.char(0x2))
	end
	sender:sendChatMessage("Ranks Mod", 0, val)
end

function Commands:getUptime()
	local time = os.time()-self.uptime
	local seconds = math.floor(time)
	local hours = math.floor(seconds / 3600)
	seconds = seconds - hours * 3600
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60
	self.namespace.server:broadcastChatMessage("Server", ChatMessageType.ServerInfo, "Server has been up for " .. string.format("%02d:%02d:%02d", hours, minutes, seconds))
end

function Commands:split(text, split)
	local result = {};
	for match in text:gmatch(split) do
		table.insert(result, match);
	end
	return result;
end

function Commands:onChatMessage(playerIndex, text, _)
	local textarray = self:split(text, "(%S+)")
	if not textarray[1] then return end
	if string.find(textarray[1], "^!") then
		local sender = Player(playerIndex)
		local commandName = textarray[1]:sub(2)
		table.remove(textarray, 1)
		if commandName == "help" then
			self:help(playerIndex, unpack(textarray))
		elseif commandName == "uptime" then
			self:getUptime()
		else
			if self.namespace.canCommand(sender.id.id, commandName) or self.namespace.server:hasAdminPrivileges(sender) or not sender then -- TODO if first argument is player in server/steamid then check perms on them
				--[[ set Player() Entity() etc before executing DOES NOT WORK unfortunately
				local pmeta = {__call = function () return sender end}
				Player = {}
				setmetatable(Player, pmeta) -- this works, but not in the run
				local emeta = {__call = function () return sender.craft end}
				Entity = {}
				setmetatable(Entity, emeta)
				  print(Player().name, Entity().index)]]
				local ok,_,_,output = run("data/scripts/commands/"..commandName..".lua", "execute", playerIndex, commandName, unpack(textarray))
				if ok == 0 then
					sender:sendChatMessage("Ranks Mod", 0, output)
				else
					if AvorionAnnouncer then -- TODO replace this with the new command file
						-- TODO do permission checks on the first argument (prevent moderators from kicking admins)
						sender:sendChatMessage("Ranks Mod", 0, "Issued command to Avorion Announcer.")
						AvorionAnnouncer.sendMessage("Ranks Mod("..sender.name..")", {"execute", "/" .. commandName .. " " .. table.concat(textarray," ")})
					else
						sender:sendChatMessage("Ranks Mod", 1, "Command does not exist on server.")
					end
				end
			else
				sender:sendChatMessage("Ranks Mod", 1, "You don't have permission for that.")
			end
		end
	end
end

function Commands:initialize()
	self.namespace.server:registerCallback('onChatMessage', 'onChatMessage_Commands')
end

function Commands:__call(namespace)
	self.namespace = namespace
	self.uptime = os.time()
	self.namespace.onChatMessage_Commands = function(...) self:onChatMessage(...) end
end

return setmetatable({}, {__index = Commands, __call = Commands.__call})
