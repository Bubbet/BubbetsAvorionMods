package.path = package.path .. ";data/scripts/ranks/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

include("tabletofile")
include("utility")
local AvorionAnnouncer

if ModManager():find("2032319866") then
	AvorionAnnouncer = include("avorionannouncer")
end

-- namespace Ranks
Ranks = {files = {}, rank = {}, mail = {}, daily = {}}

function Ranks.addrankfile(path)
	local file = dofile(Server().folder .. "/moddata/Ranks/Ranks/" .. path .. ".lua")
	if file then Ranks.files[path] = file end
	return file ~= nil
end

function Ranks:forceload(rank)
	self.rank[rank] = table.load(Server().folder.. "/moddata/Ranks/" .. rank .. ".lua") or {}
	return self.rank[rank]
end

function Ranks:load(rank)
	if not self.rank[rank] then self.rank[rank] = table.load(Server().folder.. "/moddata/Ranks/" .. rank .. ".lua") or {} end
	return self.rank[rank]
end

function Ranks:save(rank)
	return table.save(self.rank[rank], Server().folder.. "/moddata/Ranks/" .. rank .. ".lua")
end

function Ranks:hasrank(rank, id)
	if rank == "default" then return true end
	local exists = false
	self:load(rank)
	for k, _ in pairs(self.rank[rank]) do
		if k == id then exists = true end
	end
	return exists
end

function Ranks.adduser(rank, name, id)
	local self = Ranks
	self:load(rank)
	self.rank[rank][id] = name

	local save = self:save(rank)
	return not save and self.rank[rank][id] and true or false -- success or fail
end

function Ranks.removeuser(rank, id)
	local self = Ranks
	local output = 0
	if self:hasrank(rank, id) then
		local temp = {}
		for k, v in pairs(self.rank[rank]) do
			if k ~= id then
				temp[k] = v
			end
		end
		self.rank[rank] = temp

		local save = self:save(rank)

		output = not save and not self.rank[rank][id] and 1 or 0 -- success or fail
	else
		output = 2
	end -- TODO here and adduser update their permissions with invoke if they're in-game
	return output
end

function Ranks.checkFor_(list, id, check)
	local self = Ranks
	for rank, v in pairs(self.files) do
		if self:hasrank(rank, id) then
			for k, privilege in pairs(v[list]) do
				if privilege == check then return true
				end
			end
		end
	end
	return false
end

function Ranks.checkList(check, id, ...)
	local self = Ranks
	local args = {...}
	local temp = {}
	local haspermission = false
	for rank, v in pairs(self.files) do -- ["rank"] should already be initalized by this point
		if self:hasrank(rank, id) then
			if #v[check] > 0 then haspermission = true end
			for _, privilege in pairs(v[check]) do
				temp[privilege] = true
			end
		end
	end
	for _, privilege in pairs(args) do
		if not temp[privilege] then
			haspermission = false
		end
	end
	return haspermission
end

function Ranks.listPlayerPrivileges(id)
	local self = Ranks
	local privileges = {}
	for rank, v in pairs(self.files) do -- ["rank"] should already be initalized by this point
		if self:hasrank(rank, id) then
			if not v.privileges then print('no privileges in rank', rank) end
			for _, privilege in pairs(v.privileges) do
				privileges[privilege] = true
			end
		end
	end
	return privileges
end

function Ranks.hasPrivilege(id, ...)
	return Ranks.checkList("privileges", id, ...)
end

function Ranks.canCommand(id, ...)
	return Ranks.checkList("commands", id, ...)
end

function Ranks.findUser(...) --move to own file to prevent looping get self.files from rank definitions
	local self = Ranks
	local players = {Server():getOnlinePlayers()}
	local rank, player, id
	local args = {...}
	--args[1] = tostring(args[1])
	--args[2] = tostring(args[2])
	id = args[2]
	if tonumber(args[2]) then
		id = args[2] -- tonumber is a destructive function in this case
		for _, v in pairs(players) do
			if v.id.id == id then
				player = v
			end
		end
	elseif args[2] then
		for _, v in pairs(players) do
			if string.find(string.lower(v.name), string.lower(args[2])) then
				player = v
				id = v.id.id
			end
		end
	end

	if args[1] then
		for k, _ in pairs(self.files) do
			if string.find(k, args[1]) then rank = k end
		end
	end

	return rank, player, id
end

function Ranks.listUsersRanks(id)
	local self = Ranks
	local temp = {}
	for k, _ in pairs(self.files) do
		if self:hasrank(k, id) or not id then
			table.insert(temp, k)
		end
	end
	return temp
end

function Ranks.getRankValue(id, val)
	local self = Ranks
	local ranks = self.listUsersRanks(id)
	table.sort(ranks, function(a,b) return a.power<b.power end)
	for _, v in pairs(ranks) do
		if v[val] then return v[val] end
	end
end

function Ranks:findBestPower(id)
	local bestrank = math.huge
	for k, v in pairs(self.files) do
		if self:hasrank(k, id) then
			if v.power < bestrank then bestrank = v.power end
		end
	end
	return bestrank -- returns highest power level
end

function Ranks.hasPowerOver(id1, id2)
	local self = Ranks
	return self:findBestPower(id1) < self:findBestPower(id2)
end

function Ranks.hasPowerOverWithRank(sender, target, rank)
	local self = Ranks
	if not target then
		return self:findBestPower(sender) < self.files[rank or "default"].power
	else
		return self.hasPowerOver(sender, target) and (self:findBestPower(sender) < self.files[rank or "default"].power)
	end
end

function Ranks:fillRanks()
	local manager = ModManager()
	for _, id in pairs({manager:getEnabledMods()}) do
		for k, v in pairs({listFilesOfDirectory(manager:find(id).folder:gsub("\\","/") .. "data/scripts/ranks/")}) do
			local temp = {}
			for value, _ in v:gmatch("%w+") do -- Really wish there was a method in lua to do this for me
				table.insert(temp, value)
			end
			Ranks.files[temp[#temp-1]] = include(temp[#temp-1])
		end
	end
	for k, v in pairs({listFilesOfDirectory(Server().folder .. "/moddata/Ranks/Ranks/")}) do
		local temp = {}
		for value, _ in v:gmatch("%w+") do -- Really wish there was a method in lua to do this for me
			table.insert(temp, value)
		end
		local err, ret = pcall(dofile, v)
		if ret then
			Ranks.files[temp[#temp-1]] = ret
		end
	end
end

function Ranks.getCommands(id)
	local self = Ranks
	local commands = {}
	for k, file in pairs(self.files) do
		if self:hasrank(k, id) or not id then
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

function Ranks:initialize()
	local self = Ranks -- Have to do this because avorion hates : and puts values as the invisible self when invoking
	--load ranks into memory from disk
	createDirectory(Server().folder.. "/moddata/Ranks/")
	createDirectory(Server().folder.. "/moddata/Ranks/Ranks/")
	self:fillRanks()
	for k, _ in pairs(self.files) do
		self:load(k)
	end
	Server():registerCallback("onPlayerLogIn", "onPlayerLogIn")
	Server():registerCallback("onChatMessage", "onChatMessage")
	self.uptime = os.time()
end
initialize = Ranks.initialize

function Ranks.giveMail(rank, player)
	local self = Ranks
	local mail = self.files[rank].mail
	mail.sender = rank .. " package"
	return player:addMail(mail)
end

function Ranks:mailDelivered(rank, id)
	local temp = {}
	local mailList = table.load(Server().folder.. "/moddata/Ranks/MailToDeliver/" .. rank .. ".lua") -- TODO Move into own table to prevent loading every time
	for k, v in pairs(mailList) do
		if k ~= id then temp[k] = v end
	end
	table.save(temp,Server().folder.. "/moddata/Ranks/MailToDeliver/" .. rank .. ".lua")
end

function Ranks.resetMail(rank)
	local self = Ranks
	createDirectory(Server().folder.. "/moddata/Ranks/MailToDeliver")
	self:load(rank)
	return table.save(self.rank[rank],Server().folder.. "/moddata/Ranks/MailToDeliver/" .. rank .. ".lua") == nil
end

function Ranks:loadMail(rank)
	if not self.mail[rank] then self.mail[rank] = table.load(Server().folder.. "/moddata/Ranks/MailToDeliver/" .. rank .. ".lua") or {} end
	return self.mail[rank]
end

function Ranks.giveDaily(rank, id)
	local self = Ranks
	if not self.files[rank].daily then return end
	local function give(grank, gid)
		local rank, player = self.findUser(_, gid)
		local mail = self.files[grank].daily.mail
		mail.sender = grank .. " daily package"
		mail.text = (mail.text.text or "") .. " (Collect your next on " .. os.date("%c", os.time() + self.files[grank].daily.seconds) .. ".)"
		return player:addMail(mail)
	end

	createDirectory(Server().folder.. "/moddata/Ranks/DailyMail/")
	if not self.files[rank].daily then return false end
	if not self.daily[rank] then self.daily[rank] = table.load(Server().folder.. "/moddata/Ranks/DailyMail/" .. rank .. ".lua") or {} end

	local currentTime = os.time()

	if not self.daily[rank][id] then
		self.daily[rank][id] = currentTime
		give(rank, id)
	else
		if currentTime-self.daily[rank][id] > self.files[rank].daily.seconds then
			self.daily[rank][id] = currentTime
			give(rank, id)
		end
	end

	return table.save(self.daily[rank],Server().folder.. "/moddata/Ranks/DailyMail/" .. rank .. ".lua") == nil
end

function Ranks.onPlayerLogIn(playerIndex)
	local self = Ranks
	local player = Player(playerIndex)
	local id = player.id.id -- Returns steamid64

	for k, _ in pairs(self.files) do
		if self:hasrank(k, id) then
			self.giveDaily(k, id)
			if not k.mail then return end
			self:loadMail(k)
			if self.mail[k][id] then
				player:setValue(k.."_mail", false)
				self:mailDelivered(k,id)
			end
			if not player:getValue(k.."_mail") then
				--Give player mail
				self.giveMail(k, player)
				player:setValue(k.."_mail", true)
			end
		end
	end
end



local Commands = {}

function string:split(delimiter)
	result = {};
	for match in self:gmatch(delimiter) do
		table.insert(result, match);
	end
	return result;
end

function Commands.uptime()
	local time = os.time()-Ranks.uptime
	local seconds = math.floor(time)
	local hours = math.floor(seconds / 3600)
	seconds = seconds - hours * 3600
	local minutes = math.floor(seconds / 60)
	seconds = seconds - minutes * 60
	Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "Server has been up for " .. string.format("%02d:%02d:%02d", hours, minutes, seconds))
end

function Commands.help(playerIndex, ...)
	local sender = Player(playerIndex)
	local args = {...}
	local commandName = args[1]
	local val = ""
	local commands = Ranks.getCommands(sender.id.id)
	if commandName then
		val = "You don't have permission to use " .. commandName or "INVALID_COMMAND"
		if commands[commandName] then
			val = "Desc: " .. commands[commandName].desc .. "\n Help: " .. commands[commandName].help:gsub(": /", ": !")
		else
			if Server():hasAdminPrivileges(sender) then
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

function Commands.onChatMessage(playerIndex, text, _)
	local textarray = text:split("(%S+)")
	if not textarray[1] then return end
	if string.find(textarray[1], "^!") then
		local sender = Player(playerIndex)
		local commandName = textarray[1]:sub(2)
		table.remove(textarray, 1)
		if commandName == "help" then
			Commands.help(playerIndex, unpack(textarray))
		elseif commandName == "uptime" then
			Commands.uptime()
		else
			if Ranks.canCommand(sender.id.id, commandName) or Server():hasAdminPrivileges(sender) or not sender then -- TODO if first argument is player in server/steamid then check perms on them
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
					if AvorionAnnouncer then
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

Ranks.onChatMessage = Commands.onChatMessage

return Ranks, Commands
