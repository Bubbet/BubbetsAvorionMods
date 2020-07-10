package.path = package.path .. ";data/scripts/lib/?.lua"
include('callable')

-- namespace HyperSpaceBlocker
HyperSpaceBlocker = {}

function HyperSpaceBlocker.getUpdateInterval()
	if onClient() then
		return 0
	else
		return 1
	end
end

function HyperSpaceBlocker.delete()
	if not callingPlayer or callingPlayer == HyperSpaceBlocker.owner.index then
		if HyperSpaceBlocker.owner then HyperSpaceBlocker.sector:broadcastChatMessage('Server', 0, HyperSpaceBlocker.owner.name .. "'s hyperspace jammer has expired.") end
		HyperSpaceBlocker.sector:deleteEntity(HyperSpaceBlocker.entity)
	end
end
callable(HyperSpaceBlocker, 'delete')

function HyperSpaceBlocker.getRange()
	if not HyperSpaceBlocker.range then
		local rarity = HyperSpaceBlocker.rarity.value
		HyperSpaceBlocker.range = (200 + (rarity + 2) * 500 + math.random() * (rarity * 100))/2 -- these are the exact default values from rinarts mod
		HyperSpaceBlocker.range = HyperSpaceBlocker.range^2 -- squaring for distance2
	end
	return HyperSpaceBlocker.range
end

function HyperSpaceBlocker.getTimeToDie()
	return 600
end

function HyperSpaceBlocker.getPlayers()
	local ret = {}
	for _, v in pairs({HyperSpaceBlocker.sector:getPlayers()}) do
		if distance2(v.craft.translationf, HyperSpaceBlocker.entity.translationf) < HyperSpaceBlocker.getRange() then
			table.insert(ret, v)
		end
	end
	return ret
end

function HyperSpaceBlocker.updateServer(timeStep)
	for _, v in pairs(HyperSpaceBlocker.getPlayers()) do
		_ = v.craft and v.craft:blockHyperspace(2)
	end

	local rounded_time = math.floor(HyperSpaceBlocker.timeToDie)
	HyperSpaceBlocker.entity.title = HyperSpaceBlocker.title .. ': ' .. rounded_time

	local segments = 6
	HyperSpaceBlocker.next_target = HyperSpaceBlocker.next_target or segments
	if rounded_time < HyperSpaceBlocker.totalTime/segments*HyperSpaceBlocker.next_target then
		HyperSpaceBlocker.sector:broadcastChatMessage('Server', 0, HyperSpaceBlocker.owner.name .. "'s hyperspace jammer is " .. 100-math.ceil(HyperSpaceBlocker.next_target/segments * 10000)/100 .. "% depleted. (".. rounded_time .." seconds left)")
		HyperSpaceBlocker.next_target = HyperSpaceBlocker.next_target - 1
	end

	HyperSpaceBlocker.timeToDie = HyperSpaceBlocker.timeToDie - timeStep
	if HyperSpaceBlocker.timeToDie < 0 or HyperSpaceBlocker.entity.durability < HyperSpaceBlocker.entity.maxDurability * 0.05 then
		HyperSpaceBlocker.delete()
	end
end

function HyperSpaceBlocker.onPlayerLeft()
	if #{HyperSpaceBlocker.sector:getPlayers()} == 0 then
		HyperSpaceBlocker.delete()
	end
end

function HyperSpaceBlocker.initialize(rarity, owner)
	if onServer() then
		HyperSpaceBlocker.sector = Sector()
		HyperSpaceBlocker.entity = Entity()

		if not rarity then -- from a restore
			HyperSpaceBlocker.delete()
		end

		HyperSpaceBlocker.rarity = rarity
		HyperSpaceBlocker.owner = owner

		HyperSpaceBlocker.title = HyperSpaceBlocker.entity.title
		HyperSpaceBlocker.timeToDie = HyperSpaceBlocker.getTimeToDie()
		HyperSpaceBlocker.totalTime = HyperSpaceBlocker.timeToDie
		HyperSpaceBlocker.sector:broadcastChatMessage('Server', 2, owner.name .. ' deployed a hyperspace jammer!')
		HyperSpaceBlocker.sector:registerCallback('onPlayerLeft', 'onPlayerLeft')
	end
end

-- Client
function HyperSpaceBlocker.interactionPossible()
	return true
end

function HyperSpaceBlocker.initUI()
	ScriptUI():registerInteraction('Deactivate Jammer', "clientDelete")
end

function HyperSpaceBlocker.clientDelete()
	invokeServerFunction('delete')
end


function HyperSpaceBlocker.updateClient(timeStep)
	local sector = Sector()
	local entity = Entity()
	HyperSpaceBlocker.aliveTime = HyperSpaceBlocker.aliveTime and HyperSpaceBlocker.aliveTime < 3.14*2 and HyperSpaceBlocker.aliveTime or 0
	HyperSpaceBlocker.aliveTime = HyperSpaceBlocker.aliveTime + timeStep
	local size = math.sin(HyperSpaceBlocker.aliveTime) + 1
	sector:createGlow(entity.translationf, 10 + size*10, ColorHSV(1, 1, 1))
end