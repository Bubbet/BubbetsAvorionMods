
User_Info = {}

function User_Info:findUser(...)
	local players = {self.namespace.server:getOnlinePlayers()}
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
		for k, _ in pairs(self.namespace.files) do
			if string.find(k, args[1]) then rank = k end
		end
	end

	return rank, player, id
end

function User_Info:__call(namespace)
	self.namespace = namespace
	self.loadorder = 3
	self.namespace.findUser = function(...) return self:findUser(...) end
end

return setmetatable({}, {__index = User_Info, __call = User_Info.__call})
