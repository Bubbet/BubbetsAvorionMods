local Announcer = include("avorionannouncer")
local Config = include("ConfigLoader")
local playerConnectionTimes = {}

function resKick(player)
	Announcer.sendMessage("server", {"execute", '/kick ' .. player.name .. ' "Reason: Making room for vips"'})
end

function Reserved_Slots_OnPlayerLogin( playerIndex )
	local server = Server()
	local player = Player(playerIndex)
	if not Config or Config.singleslot then
		local succ, val = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPrivilege", player.id.id, "slot_reserved")
		if succ == 0 and not val then -- add to list if they dont have the reserved slot
			playerConnectionTimes[playerIndex] = curTime()
		end
		if server.players > server.maxPlayers-1 then
			if succ == 0 then
				if val then -- If the invoke succeeded and the player does have the permission
					local ind
					if not Config or Config.kicknewest then
						local low = math.huge
						for k, v in pairs(playerConnectionTimes) do
							if v < low then
								low = v
								ind = k
							end
						end
					else
						local high = 0
						for k, v in pairs(playerConnectionTimes) do
							if v > high then
								high = v
								ind = k
							end
						end
					end
					local kicked = Player(ind)
					kicked:sendChatMessage('(Reserved Slots)', 2, 'You will be kicked in 2 minutes to make room for vips.')
					deferredCallback(2*60, 'resKick', kicked)
				else -- success on the invoke, but not on the permission at saturation kick the fresh player
					Announcer.sendMessage("server", {"execute", '/kick ' .. player.name .. ' "Reason: Slot Reserved"'})
				end
			end
		end
	else
		if (server.players / server.maxPlayers) > (Config.ratio or 0.8) then
			local succ, val = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPrivilege", player.id.id, "slot_reserved")
			if succ == 0 and not val then -- If the invoke succeeded and the player does not have the permission
				Announcer.sendMessage("server", {"execute", '/kick ' .. player.name .. ' "Reason: Slot Reserved"'})
			end
		end
	end
end

function Reserved_Slots_OnPlayerLogin( playerIndex )
	if not Config or Config.singleslot then
		table.remove(playerConnectionTimes, playerIndex) -- might throw no value at index or something
	end
end

local super_initialize = initialize
function initialize()
	super_initialize()
	local server = Server()
	server:registerCallback("onPlayerLogIn", "Reserved_Slots_OnPlayerLogin")
	server:registerCallback("onPlayerLogOff", "Reserved_Slots_OnPlayerLogoff")
end