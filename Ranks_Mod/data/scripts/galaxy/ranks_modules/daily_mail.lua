
Daily_Mail = {}

function Daily_Mail:getsDaily(rank, mail, id)
	id = id .. 'string' -- required because secure was corrupting galaxies by pushing std::stoi past the integer limit
	if not self.toDeliver[rank] then
		self.toDeliver[rank] = {}
	end
	local currentTime = os.time()
	if not self.toDeliver[rank][id] or (currentTime-self.toDeliver[rank][id] > mail.seconds) then
		self.toDeliver[rank][id] = currentTime
		return true
	end
	return false
end

function Daily_Mail:giveDaily(rank, _mail, player)
	if self:getsDaily(rank, _mail, player.id.id) or self.mailForce then
		local mail = copy(_mail.mail)
		mail.sender = rank .. " daily package"
		mail.text = (mail.text.text or "") .. " (Collect your next on " .. os.date("%c", os.time() + _mail.seconds) .. ".)"
		player:addMail(mail)
	end
end

function Daily_Mail:onPlayerLogIn(playerIndex)
	local player = Player(playerIndex)
	for k, v in pairs(self.namespace.files) do
		if v.daily and self.namespace.hasrank(k, player.id.id) then
			self:giveDaily(k, v.daily, player)
		end
	end
end

function Daily_Mail:secure()
	return self.toDeliver
end

function Daily_Mail:restore(data)
	self.toDeliver = data
end

function Daily_Mail:initialize()
	self.toDeliver = {}
	self.namespace.server:registerCallback('onPlayerLogIn', 'onPlayerLogIn_Daily_Mail')
end

function Daily_Mail:__call(namespace)
	self.namespace = namespace
	self.namespace.onPlayerLogIn_Daily_Mail = function(...) self:onPlayerLogIn(...) end
	self.namespace.giveDaily = function(rank, player)
		local mail = self.namespace.files[rank].daily
		if not mail then return end
		self.mailForce = true
		self:giveDaily(rank, mail, player)
		self.mailForce = false
	end
end

return setmetatable({}, {__index = Daily_Mail, __call = Daily_Mail.__call})
