
Welcome_Mail = {}

function Welcome_Mail:addToDeliver(rank, id)
	if not self.toDeliver[rank] then
		self.toDeliver[rank] = {}
	end
	id = id .. 'string'
	self.toDeliver[rank][id] = true
end

function Welcome_Mail:resetMail(rank)
	for k, _ in pairs(self.namespace.rank[rank]) do
		self:addToDeliver(rank, k)
	end
end

function Welcome_Mail:inToDeliver(rank, player)
	if not self.toDeliver[rank] then return end
	local id = player.id.id .. 'string'
	local ret = self.toDeliver[rank][id]
	self.toDeliver[rank][id] = nil
	return ret
end

function Welcome_Mail:giveWelcome(rank, mail, player)
	if not player:getValue(rank..'_mail') or self:inToDeliver(rank, player) then
		player:setValue(rank..'_mail', true)
		mail.sender = rank .. ' package'
		player:addMail(mail)
	end
end

function Welcome_Mail:onPlayerLogIn(playerIndex)
	local player = Player(playerIndex)
	for k, v in pairs(self.namespace.files) do
		if v.mail and self.namespace.hasrank(k, player.id.id) then
			self:giveWelcome(k, v.mail, player)
		end
	end
end

function Welcome_Mail:secure()
	return self.toDeliver
end

function Welcome_Mail:restore(data)
	self.toDeliver = data
end

function Welcome_Mail:initialize()
	self.toDeliver = {}
	self.namespace.server:registerCallback('onPlayerLogIn', 'onPlayerLogIn_Welcome_Mail')
end

function Welcome_Mail:__call(namespace)
	self.namespace = namespace
	self.namespace.onPlayerLogIn_Welcome_Mail = function(...) self:onPlayerLogIn(...) end
	self.namespace.resetMail = function(...) self:resetMail(...) end
	self.namespace.giveMail = function(rank, player)
		local mail = self.namespace.files[rank].mail
		if not mail then return end
		self:addToDeliver(rank, player.id.id)
		self:giveWelcome(rank, mail, player)
	end
end

return setmetatable({}, {__index = Welcome_Mail, __call = Welcome_Mail.__call})
