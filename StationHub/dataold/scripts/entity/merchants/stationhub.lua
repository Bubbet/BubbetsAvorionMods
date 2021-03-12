package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
local Node = include('node')
local Placer = include('placer')
include('callable')
include('ElementToTable')

-- namespace StationHub
StationHub = {}

local arrangeTypes = {
	['Multi-Ring'] = function(matrix)
		local ring = 0
		local outerRing = 0
		local n = 0
		while n do
			outerRing = n
			if 3*2^(n+2)-5 > #StationHub.sector_stations then
				break
			end
			n = n+1
		end
		for i = 1, #StationHub.sector_stations do
			local n = 0
			while n do
				ring = n
				if 3*2^(n+2)-5 > i then
					break
				end
				n = n+1
			end
			local angle
			if i<=6 then
				angle = 2*math.pi * (i-1) / 6
			elseif ring == outerRing then
				local numstations = (#StationHub.sector_stations - (3*2^(ring+1)-5))
				local stationnum = (i - (3*2^(ring+1)-5))
				angle = 2*math.pi*stationnum/numstations
				--print(i, angle, numstations, stationnum, ring, outerRing)
			else
				local numstations = ((6*2*(2^ring)-1)-(6*2*(2^(ring-1))-1))
				local stationnum = (i - (3*2^(ring+1)-5))
				angle = ((2*math.pi)/numstations)*stationnum
				--print(i, angle, numstations, stationnum, ring, outerRing)
			end
			--print(i, angle, ring)
			local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
			local cultistMatrix = MatrixLookUpPosition(-cultistLook, matrix.up,
					matrix.pos + cultistLook * 600 * (ring+1))
			table.insert(StationHub.ringPositions, cultistMatrix)
			--[[
			local angle = 2 * math.pi * i / #StationHub.sector_stations -- 2 * math.pi * i / 6 --/ step --2 * math.pi * (#StationHub.sector_stations - i) / #StationHub.sector_stations --
			if (i-old)>step then
				step = step*2
				old = old+step
				spacing = spacing + 1
			end

			if 6*2^n >= i then
				ring = i-1
			end
			local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
			local cultistMatrix = MatrixLookUpPosition(-cultistLook, matrix.up,
					matrix.pos + cultistLook * radius )--* spacing )--* cultistRadius * i ^ 0.4)
			table.insert(StationHub.ringPositions, {mat = cultistMatrix})
			]]
		end
	end,
	['Ring'] = function(matrix)
		local radius = 100 * #StationHub.sector_stations + 50
		for i=1, #StationHub.sector_stations do
			local angle = 2*math.pi * i / #StationHub.sector_stations
			local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
			local cultistMatrix = MatrixLookUpPosition(-cultistLook, matrix.up,
					matrix.pos + cultistLook * radius)
			table.insert(StationHub.ringPositions, cultistMatrix)
		end
	end,
	['Spiral'] = function(matrix)
		for i=1, #StationHub.sector_stations do
			local angle = 2*math.pi * i * 4 / #StationHub.sector_stations
			local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
			local cultistMatrix = MatrixLookUpPosition(-cultistLook, matrix.up,
					matrix.pos + cultistLook * i * 100 + 600 )
			table.insert(StationHub.ringPositions, cultistMatrix)
		end
	end,
	['Cube'] = function(matrix)
		local gridSize = (#StationHub.sector_stations+1)^(1/3)
		local gridSize = math.ceil(gridSize)
		local gridSize = gridSize + (gridSize%2 == 0 and 1 or 0)
		local half = math.ceil(gridSize/2) - 1
		for x=0, gridSize-1 do
			for y=0, gridSize-1 do
				for z=0, gridSize-1 do
					if not (x==half and y==half and z==half) then
						local cultistMatrix = MatrixLookUpPosition(matrix.look, matrix.up, matrix.pos + vec3(x,y,z) * 800 - vec3(half) * 400)
						table.insert(StationHub.ringPositions, cultistMatrix)
					end
				end
			end
		end
	end,
	['Square'] = function(matrix)
		local gridSize = (#StationHub.sector_stations+1)^0.5
		local gridSize = math.ceil(gridSize)
		local gridSize = gridSize + (gridSize%2 == 0 and 1 or 0)
		local half = math.ceil(gridSize/2) - 1
		for x=0, gridSize-1 do
			for y=0, gridSize-1 do
				if not (x==half and y==half) then
					local cultistMatrix = MatrixLookUpPosition(matrix.look, matrix.up, matrix.pos + vec3(x,y,0) * 800 - vec3(half) * 400)
					table.insert(StationHub.ringPositions, cultistMatrix)
				end
			end
		end
	end
}

-- Client
function StationHub.receiveCargos(cargos)
	local sorted = {}
	local temp = {}
	for k, v in pairs(cargos or {}) do
		temp[k.name] = temp[k.name] and temp[k.name] + v or v
	end
	for k, v in pairs(temp or {}) do
		table.insert(sorted, {key = k, val = v})
	end
	table.sort(sorted, function(a, b) return a.val > b.val end)
	local offset = (StationHub.page-1)*#StationHub.rows
	if #sorted > 0 then StationHub.cargo = sorted else StationHub.cargo = StationHub.cargo or {} end
	for k, v in pairs(StationHub.rows) do
		local val = StationHub.cargo[k+offset]
		if val then
			v.good_label.caption = val.key
			v.amount_label.caption = val.val
		else
			v.good_label.caption = ''
			v.amount_label.caption = ''
		end
	end
	if StationHub.pageUITable.label.caption == '' then StationHub.updatePage() end
end

function StationHub.onShowWindow()
	invokeServerFunction('fetchCargos', true)
end

function StationHub.updatePage() StationHub.pageUITable.label.caption = StationHub.page .. '/' .. math.ceil(#StationHub.cargo/#StationHub.rows); StationHub.receiveCargos() end
function StationHub.button_skipleft() StationHub.page = 1; StationHub.updatePage() end
function StationHub.button_skipright() StationHub.page = math.ceil(#StationHub.cargo/#StationHub.rows); StationHub.updatePage() end
function StationHub.button_left() StationHub.page = math.max(StationHub.page-1, 1); StationHub.updatePage() end
function StationHub.button_right() StationHub.page = math.min(StationHub.page+1, math.ceil(#StationHub.cargo/#StationHub.rows)); StationHub.updatePage() end
function StationHub.showLines()
	if StationHub.showLinesBox.checkBox.checked then
		local entity = Entity()
		local sector = Sector()
		local color = ClientSettings().uiColor
		for _, v in pairs(StationHub.sector_stations) do
			v.laser = sector:createLaser(entity.translationf, v.station.translationf, color, 5.0)
			v.laser.collision = false
		end
	else
		StationHub.onDelete()
	end
end

function StationHub.initUI()
	local res = getResolution()
	local size = vec2(400, 350)

	---@type ScriptUI
	StationHub.menu = ElementToTable(ScriptUI()) -- Because of the element to table all of the following elements can be accessed via children table of menu
	local window = StationHub.menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	StationHub.menu:registerWindow(window.element, "Station Hub")

	window.caption = "Station Hub"
	window.showCloseButton = true
	window.moveable = true

	StationHub.page = 1

	StationHub.rootNode = Node(window.size)
	local container = window:createContainer(StationHub.rootNode.rect)
	StationHub.rows = {StationHub.rootNode:pad(10):rows(10, 10)}
	local top, almostbottom, bottom = StationHub.rows[1], StationHub.rows[#StationHub.rows-1], StationHub.rows[#StationHub.rows]
	table.remove(StationHub.rows, 1)
	table.remove(StationHub.rows, #StationHub.rows-1)
	table.remove(StationHub.rows, #StationHub.rows)

	local topleft, topright = top:cols({0.5, 0.5}, 10)
	topleft.frame = container:createFrame(topleft.rect)
	topleft.label = container:createLabel(topleft:pad(10,0,0,0).rect,'Good:',14)
	topleft.label:setLeftAligned()


	local topmiddleleft, topmiddle, aligndropdown, topmiddleright = almostbottom:cols(4, 10) -- Actually second row from bottom despite var names

	topmiddleleft.checkBox = container:createCheckBox(topmiddleleft:pad(5):centeredrect(20).rect, 'Show Lines?', 'showLines')
	topmiddleleft.frame = container:createFrame(topmiddleleft.rect)
	StationHub.showLinesBox = topmiddleleft

	topmiddleright.button = container:createButton(topmiddleright, 'Re-Link', 'onRelink')

	topmiddle.checkBox = container:createCheckBox(topmiddle:pad(5):centeredrect(20), 'Reposition', 'onReposition')
	topmiddle.frame = container:createFrame(topmiddle)
	topmiddle.created = true
	StationHub.repositionBox = topmiddle

	aligndropdown.comboBox = container:createComboBox(aligndropdown, 'updateAlignType')
	for k, _ in pairs(arrangeTypes) do
		aligndropdown.comboBox:addEntry(k)
	end
	StationHub.alignCombo = aligndropdown

	topright.frame = container:createFrame(topright.rect)
	topright.label = container:createLabel(topright:pad(0,0,10,0).rect,'Amount:',14)
	topright.label:setRightAligned()

	container:createLine(top.rect.upper-vec2(top.rect.width, -5), top.rect.upper+vec2(0, 5))
	container:createLine(top.rect.position+vec2(0, top.rect.height*0.5+5), almostbottom.rect.position-vec2(0, bottom.rect.height*0.5 + 10))

	local bottomleft, bottommiddle, bottomright = bottom:cols({0.25,0.5,0.25}, 10)
	bottommiddle.frame = container:createFrame(bottommiddle.rect)
	bottommiddle.label = container:createLabel(bottommiddle:pad(10,0,10,0).rect, '', 14)
	bottommiddle.label:setCenterAligned()
	StationHub.pageUITable = bottommiddle

	local skipleft, left = bottomleft:cols(2, 10)
	skipleft.button = container:createButton(skipleft.rect, '<<', 'button_skipleft')
	left.button = container:createButton(left.rect, '<', 'button_left')
	local right, skipright = bottomright:cols(2, 10)
	right.button = container:createButton(right.rect, '>', 'button_right')
	skipright.button = container:createButton(skipright.rect, '>>', 'button_skipright')

	for _, v in pairs(StationHub.rows) do
		v.rects = {v:cols({0.5, 0.5}, 10)}
		v.good_label = container:createLabel(v.rects[1]:pad(10,0,0,0).rect, '', 14)
		v.good_label:setLeftAligned()
		v.good_frame = container:createFrame(v.rects[1].rect)
		v.amount_label = container:createLabel(v.rects[2]:pad(0,0,10,0).rect, '', 14)
		v.amount_label:setRightAligned()
		v.amount_frame = container:createFrame(v.rects[2].rect)
	end
end

-- Server
function StationHub.interactionPossible(playerIndex, option)
	if checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FoundStations, AlliancePrivilege.ManageStations) then
		return true, ""
	end

	return false
end

function factorial(n)
	if (n <= 0) then
		return 1
	else
		return n * factorial(n - 1)
	end
end

function StationHub.updateAlignType(typ)
	if onClient() then
		invokeServerFunction('updateAlignType', StationHub.alignCombo.comboBox.selectedEntry)
	else
		StationHub.alignType = typ
		StationHub.delayedInitialize()
	end
end
callable(StationHub, 'updateAlignType')

function StationHub.delayedInitialize()
	StationHub.onDelete()
	local entity = Entity()
	StationHub.sector_stations = {}
	for _, v in pairs({Sector():getEntitiesByType(EntityType.Station)}) do
		if v.factionIndex == entity.factionIndex and entity.id ~= v.id then
			--local laser
			if onServer() then
				v:invokeFunction('data/scripts/entity/merchants/factory.lua', 'setHub', entity.index)
				v:invokeFunction('data/scripts/entity/merchants/npcautorefinery.lua', 'setHub', entity.index)
				--	else
				--laser = sector:createLaser(entity.translationf, v.translationf, color, 5.0)
				--laser.collision = false
			end
			table.insert(StationHub.sector_stations, {station = v})--, laser = laser})
		end
	end

	StationHub.alignType = StationHub.alignType or 'Ring'

	StationHub.ringPositions = {}
	local matrix = entity.position
	--print(matrix.position.x, matrix.position.y, matrix.position.z)
	arrangeTypes[StationHub.alignType](matrix)
	--print('num', #StationHub.sector_stations)
end

function StationHub.onRelink()
	if onClient() then
		StationHub.delayedInitialize()
		invokeServerFunction('onRelink')
	else
		StationHub.delayedInitialize()
		Player(callingPlayer):sendChatMessage('StationHub', 0, 'Re-Linked Stations')
	end
end
callable(StationHub, 'onRelink')

function StationHub.onReposition(val)
	if onClient() and StationHub.repositionBox.created then
		invokeServerFunction('onReposition', StationHub.repositionBox.checkBox.checked)
	else
		StationHub.alignFactories = val -- I'm not going to bother securing and restoring this
	end
end
callable(StationHub, 'onReposition')

function StationHub.initialize()
	deferredCallback(0.01, 'delayedInitialize')
end

function StationHub.removeFact()
	deferredCallback(0.01, 'delayedInitialize')
end

function StationHub.onDelete()
	if onClient() then
		local sector = Sector()
		for _, v in pairs(StationHub.sector_stations or {}) do
			if v.laser then
				sector:removeLaser(v.laser)
			end
		end
	end
end

function StationHub.fetchCargos(toClient)
	StationHub.cargo = {}
	---@param v Entity
	for _, v in pairs(StationHub.sector_stations) do
		if valid(v.station) then
			v.cargo = v.station:getCargos()
		end
		for k1, v1 in pairs(v.cargo or {}) do
			StationHub.cargo[k1] = StationHub.cargo[k1] and StationHub.cargo[k1] + v1 or v1 -- TODO fix the potentially fucky stuff happening because trading goods count as different indexes ie multiple silicons will be in this list
		end -- TODO maybe store by name, then reconstruct good after for key to keep compatibility
	end
	if toClient then
		broadcastInvokeClientFunction('receiveCargos', StationHub.cargo)
	end
end
callable(StationHub, 'fetchCargos')

function StationHub.hasCargo(ingredient)
	StationHub.fetchCargos()
	local ret = false
	---@param k Cargo
	for k, v in pairs(StationHub.cargo) do
		if k.name == ingredient.name and v > ingredient.amount then
			ret = true
		end
	end
	--print('hascargo')
	-- update the list of cargos
	-- test for cargo in said list
	return ret -- true if we have enough cargo based on the amount etc
end

function StationHub.findCargos(name)
	StationHub.fetchCargos()
	for k, v in pairs(StationHub.cargo) do
		if k.name == name then
			return v
		end
	end
end

function StationHub.removeCargo(ingredient)
	local remaining = ingredient.amount
	for k, v in pairs(StationHub.sector_stations) do
		if remaining > 0 then
			for good, amount in pairs(v.cargo) do
				if good.name == ingredient.name then
					local reduce = math.min(remaining, amount)
					v.station:removeCargo(good, reduce)
					remaining = remaining - reduce
				end
			end
		end
	end
	--print('removecargo')
	return remaining == 0, remaining -- true if the cargo has been removed
end

function StationHub.getUpdateInterval()
	return 5
end

function StationHub.moveToPos(_entity, pos)
	--[[
	print(_entity.name)
	local velocity = Velocity(_entity.id)
	local mat = _entity.position
	--mat.position = vec3(0,0,6000)
	--entity.position = mat
	--physics.driftDecrease = 0.2
	--print(mat.position.x, mat.position.y, mat.position.z)
	local velvec = vec3(velocity.velocity.x, velocity.velocity.y, velocity.velocity.z)
	local dist = distance(pos,mat.position)
	local dir = pos-mat.position--normalize(pos-mat.position)*math.min(dist*0.1, 200)-velvec*0.5
	print('dir', dir.x, dir.y, dir.z)
	if dist > 0 then
		_entity:moveBy(dir)
	end
	--[[
	local mat = _entity.position
	mat.position = pos
	_entity.position = mat
	]]
	_entity.position = pos
end

function StationHub.updateServer()
	if not StationHub.alignFactories then return end
	--local entity = Entity()
	--StationHub.moveToPos(entity, vec3(1000,0,0))
	--physics:applyImpulse(dvec3(mat.position.x, mat.position.y, mat.position.z), dir, 1000)


	for k, _station in pairs(StationHub.sector_stations) do
		if not _station.targetpos then
			local pos = _station.station.position.position
			table.sort(StationHub.ringPositions, function(a, b)
				return distance2(pos, a.position) < distance2(pos, b.position)
			end)
			local position = StationHub.ringPositions[1]
			_station.targetpos = position
			table.remove(StationHub.ringPositions, 1)
		end
		StationHub.moveToPos(_station.station, _station.targetpos)
	end
	Placer.resolveIntersections()
		--physics:applyLocalForce(vec3(), dir, 10, 10)
	--physics:applyGlobalForce(vec3(0), vec3(0) - mat.position, entity.mass(physics.kineticEnergy*0.5)*150, 10)
	--[[
	for i, v in pairs(StationHub.sector_stations or {}) do
		local angle = 2 * math.pi * i / #StationHub.sector_stations
		local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
		local pos = vec3(CultistBehavior.center.x, CultistBehavior.center.y, CultistBehavior.center.z)
		ai:setFly(pos + cultistLook * cultistRadius, 0)
	end
	]]
end
