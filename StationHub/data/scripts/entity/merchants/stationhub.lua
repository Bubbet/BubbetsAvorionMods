package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
local Node = include('node')
local Placer = include('placer')
include('callable')
include('ElementToTable')
include('goods')

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
						local cultistMatrix = MatrixLookUpPosition(matrix.look, matrix.up, matrix.pos + vec3(x,y,z) * 800 - vec3(half) * 800)
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
					--print(matrix.look.x, matrix.look.y, matrix.look.z)
					local cultistMatrix = MatrixLookUpPosition(matrix.look, matrix.up, matrix.pos + vec3(x,y,0) * 800 - vec3(half, half, 0) * 800)
					table.insert(StationHub.ringPositions, cultistMatrix)
				end
			end
		end
	end
}

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

StationHub.tabs = {
	main = {
		name = "Graph",
		icon = "",
		desc = "Main page, containing a graph of goods."
	},
	overview = {
		name = "Production Overview",
		icon = "",
		desc = "Production Overview containing produced, consumed and net."
	}
}
function StationHub.tabs.main:init()
	local container = self.tab:createContainer(self.rootNode.rect)
	local top, linkedline, almostbottom, bottom = self.rootNode:pad(10, 0, 10, 10):rows({1, 30, 30, 30}, 10)

	local top, topbottom = top:rows({110, 1}, 10)
	container:createTextField(top, 'Station hub no longer needs the overview of goods inside it as all goods from all factories are now networked through the hub itself and not the factories. \n\nSorry for the inconvenience.')
	container:createFrame(top)
	local left, graph = topbottom:cols({300, 1}, 10)
	local legend_root, update_node = left:rows({1,20},10)
	local legend_left, graph_legend = legend_root:cols(2, 10)
	StationHub.graph = container:createGraph(graph)
	StationHub.graph.sorting_disabled = true
	StationHub.graph:createLegend(graph_legend)
	StationHub.updateSlider = container:createSlider(update_node, 1, 60, 30, "Update Speed (Client)", "")
	StationHub.updateSlider.value = StationHub.updateSlider.max
	StationHub.graph.slider.value = 30

	enabled_list = container:createScrollFrame(legend_left)
	enabled_lister = UIVerticalLister(Rect(legend_left:pad(0,0,20,0).rect.size), 10, 10)

	container:createFrame(linkedline)
	StationHub.linkedline = container:createLabel(linkedline, "Stations Linked:", 14)
	StationHub.linkedline:setCenterAligned()

	local topmiddleleft, topmiddle = almostbottom:cols(2, 10)
	local aligndropdown, topmiddleright = bottom:cols(2, 10)

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
end

function StationHub.tabs.overview:init()
	local container = self.tab:createContainer(self.rootNode.rect)
	self.container = container

	--[[
	local left, middle, right = self.rootNode:pad(10,0,10,10):cols(3, 10)
	self.parts = {left = left, middle = middle, right = right}
	self.left, self.middle, self.right = left, middle, right
	for k, v in pairs(self.parts) do
		v.frame = container:createScrollFrame(v)
		v.lister = UIVerticalLister(Rect(v:pad(-10,0,30,0).rect.size), 10, 10)
	end
	]]

	local topNode, frameNode, errors = self.rootNode:rows({20, 0.8, 0.2}, 10)
	self.errors = errors

	container:createFrame(topNode)
	local _, name, _produced, _required, _net, need = topNode:pad(10,0,30,0):cols({20, 0.25, 0.25, 0.25, 0.25}, 10)
	name.label = container:createLabel(name, "Good Name", 14)
	name.label:setLeftAligned()
	_produced.label = container:createLabel(_produced, "Produced", 14)
	_required.label = container:createLabel(_required, "Consumed", 14)
	_net.label = container:createLabel(_net, "Net", 14)
	_produced.label:setRightAligned()
	_required.label:setRightAligned()
	_net.label:setRightAligned()

	self.frame = container:createScrollFrame(frameNode)
	self.lister = UIVerticalLister(Rect(frameNode:pad(-10,0,30,0).rect.size), 10, 10)

	self.errors.field = container:createTextField(errors, "")
	self.errors.frame = container:createFrame(errors)

	StationHub.overviewRefresh = function(...) self:refresh(...) end
	self.tab.onSelectedFunction = "overviewRefresh"
	self.tab.onShowFunction = "overviewRefresh"

end

function StationHub.tabs.overview:refresh(tab_index)
	local produced, required, net = {}, {}, {}
	local factories = StationHub.getLinked()
	local errors = "Production Errors:\n"
	for k, v in pairs(factories) do
		if v:hasScript("data/scripts/entity/merchants/factory.lua") then
			local fact = v
			v = {}
			local ok1, tier, timeToProduce, error = fact:invokeFunction("data/scripts/entity/merchants/factory.lua", "getSizeAndSpeed")
			if error and error ~= "" then
				errors = errors .. "\n" .. fact.title % fact:getTitleArguments()  .. ", " .. fact.name .. ": " .. error
			elseif ok1 ~= 0 and not error then
				errors = errors .. "\nInvoke failed on entity " .. fact.title % fact:getTitleArguments() .. " with error: " .. ok1
			end
			local factor = (tier or 2) / (timeToProduce or 15)
			local ok, production = fact:invokeFunction("data/scripts/entity/merchants/factory.lua", "getProduction")
			if ok == 0 then
				v.production = production
				for k, v in pairs(production.ingredients) do
					required[v.name] = (required[v.name] or 0) + v.amount * factor
					net[v.name] = (net[v.name] or 0) - v.amount * factor
				end
				for k, v in pairs(production.results) do
					produced[v.name] = (produced[v.name] or 0) + v.amount * factor
					net[v.name] = (net[v.name] or 0) + v.amount * factor
				end
				for k, v in pairs(production.garbages) do
					produced[v.name] = (produced[v.name] or 0) + v.amount * factor
					net[v.name] = (net[v.name] or 0) + v.amount * factor
				end
			else
				print("Production not found for station", fact.title % fact:getTitleArguments(), "with error: ", ok)
			end
		end
	end
	local targets = {produced = produced, required = required, net = net}
	self.rows = self.rows or {}
	for k, v in pairsByKeys(net) do
		if not self.rows[k] then
			local node = self.rootNode:child(self.lister:nextRect(20))
			---@type ScrollFrame
			local frame = self.frame
			--frame:createFrame(node)
			local icon, name, _produced, _required, _net = node:cols({20, 0.25, 0.25, 0.25, 0.25}, 10)
			local _targets = {produced = _produced, required = _required, net = _net}
			for k1, v1 in pairs(_targets) do
				frame:createFrame(v1)
				local amount = targets[k1][k]
				v1.label = frame:createLabel(v1, amount or 0, 14)
				if k1 == "net" then
					if amount < 0 then
						v1.label.element.color = ColorRGB(1,0,0)
					end
				end
				v1.label:setRightAligned()
			end
			name.frame = frame:createFrame(name)
			local good = goods[k]
			icon.pic = good.icon
			icon.icon = frame:createPicture(icon, icon.pic)
			name.label = frame:createLabel(name, k, 14)
			name.label:setLeftAligned()
			self.rows[k] = {node = node, icon = icon, name = name, _targets = _targets, good = good}
		end
		for k1, v1 in pairs(self.rows[k]._targets) do
			local amount = targets[k1][k]
			v1.label.element.caption = amount and string.format("%.5f/hour", amount*60*60) or "N/A"
			if k1 == "net" then
				if amount < 0 then
					v1.label.element.color = ColorRGB(1,0,0)
				else
					v1.label.element.color = ColorRGB(1,1,1)
				end
			end
		end
	end
	self.errors.field.element.text = errors
end

function StationHub.initUI() -- TODO gut half of this
	local res = getResolution()
	local size = vec2(1000, 900)

	---@type ScriptUI
	StationHub.menu = ElementToTable(ScriptUI()) -- Because of the element to table all of the following elements can be accessed via children table of menu
	local window = StationHub.menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	StationHub.menu:registerWindow(window.element, "Station Hub")

	window.caption = "Station Hub"
	window.showCloseButton = true
	window.moveable = true
	StationHub.window = window

	StationHub.rootNode = Node(window.size)
	StationHub.tabbedWindow = StationHub.window:createTabbedWindow(StationHub.rootNode.rect)

	for k, v in pairsByKeys(StationHub.tabs) do
		local tab = StationHub.tabbedWindow:createTab(v.name, v.icon, v.desc)
		v.rootNode = StationHub.rootNode:child(Rect(tab.size))
		v.tab = tab
		v:init()
	end

	if StationHub.sync then StationHub.sync() end
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
		StationHub.initialize()
	end
end
callable(StationHub, 'updateAlignType')

function StationHub.initialize()
	StationHub.onDelete()
	--print("hub init")
	local entity = Entity()
	StationHub.sector_stations = {}
	for _, v in pairs({Sector():getEntitiesByType(EntityType.Station)}) do
		if v.factionIndex == entity.factionIndex and entity.id ~= v.id then
			v:setValue("station_hub_id", tostring(entity.id))
			table.insert(StationHub.sector_stations, {station = v})
		end
	end

	StationHub.alignType = StationHub.alignType or 'Ring'
	--StationHub.alignFactories = true -- TODO remove this

	StationHub.ringPositions = {}
	local matrix = entity.position
	arrangeTypes[StationHub.alignType](matrix)
end

function StationHub.getLinked()
	return {Sector():getEntitiesByScriptValue("station_hub_id", tostring(Entity().id))}--#StationHub.sector_stations
end

function StationHub.onRelink()
	if onClient() then
		StationHub.initialize()
		StationHub.linkedline.caption = "Stations Linked:" .. #StationHub.getLinked()
		invokeServerFunction('onRelink')
	else
		StationHub.initialize()
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
	Velocity(_entity.index).velocity = dvec3(0, 0, 0)
	_entity.desiredVelocity = 0
	DockingPositions(_entity.index).docksEnabled = true
end

--[[region Securing the graph -- Skipped because it causes a ton of lag to save big databases
function StationHub.receiveData(data)
	local i = 1
	local len = tablelength(data)
	for k, v in pairs(data) do
		StationHub.graph:createEntry(k, ColorHSV(i/len*255, 1, 1))
		StationHub.graph:addData(k, v)
		i = i + 1
	end
end

function StationHub.secure()
	local data = {}
	data.graph = StationHub.graph_data
	return data
end

function StationHub.restore(data)
	StationHub.graph = data.graph
end

function StationHub.fetch(data) -- from client to server
	if onServer() then
		if data then
			StationHub.graph_data = data.graph_data
		else
			broadcastInvokeClientFunction('fetch')
		end
	else
		invokeServerFunction('fetch', {graph_data = StationHub.graph:secure()})
	end
end
callable(StationHub, 'fetch')

function StationHub.sync(data) -- from server to client
	if onClient() then
		if tablelength(data) > 0 then
			StationHub.graph:restore(data.graph)
		else
			invokeServerFunction('sync')
		end
	else
		if not StationHub.graph then
			StationHub.fetch()
		end
		invokeClientFunction(Player(callingPlayer), 'sync', {graph = StationHub.graph_data})
	end
end
callable(StationHub, 'sync')

function StationHub.onShowWindow()
	StationHub.linkedline.caption = "Stations Linked:" .. #StationHub.sector_stations
	StationHub.sync()
end

function StationHub.onCloseWindow()
	StationHub.fetch()
end
--endregion]]
function StationHub.onShowWindow()
	StationHub.linkedline.caption = "Stations Linked:" .. #StationHub.getLinked()
	window_opened = true
	StationHub.updateClient()
end

function StationHub.onCloseWindow()
	StationHub.graph:clearValues()
end

function StationHub.getUpdateInterval()
	return onServer() and 5 or 0.5
end

---@param checkBox CheckBox
function StationHub.updateEnabled(checkBox, checked)
	enabled = enabled or {}
	enabled[checkBoxes[checkBox.index]] = checked
	if checked then
		window_opened = true
		StationHub.updateClient()
	end
end

function StationHub.addRow(good)
	rows = rows or {}
	checkBoxes = checkBoxes or {}
	if rows[good.name] then return end
	rows[good.name] = enabled_list:createCheckBox(enabled_lister:nextRect(20), good.name, "updateEnabled")
	checkBoxes[rows[good.name].index] = good.name
end

function StationHub.updateClient(timeStep)
	if not window_opened then
		if not StationHub.window or not StationHub.window.visible then return end
		last_update = (last_update or 0) + (timeStep or 0)
		if StationHub.updateSlider then
			StationHub.updateSlider.value = math.max(0.5, StationHub.updateSlider.value)
		end
		if last_update > StationHub.updateSlider.value then last_update = 0 else return end
	else
		window_opened = false
	end



	local cargos = Entity():getCargos() --TODO have a list of checkboxes for the user to enable the tracking for

	local keys = {}
	for n in pairs(cargos) do table.insert(keys, n) end
	table.sort(keys, function(a,b) return a.name < b.name end)
	for k, v in pairs(keys) do
		StationHub.addRow(v)
	end

	enabled = enabled or {}
	--local len = tablelength(cargos)
	for k, v in pairs(cargos) do
		if enabled[k.name] then
			StationHub.graph:createEntry(k.name)
			StationHub.graph:addData(k.name, v)
		end
	end
	--broadcastInvokeClientFunction("receiveData", to_send) -- wonky behavior resulting in info being added to the client but only securing the data when updated via a client closing the window
end

function StationHub.updateServer()
	if not StationHub.alignFactories then return end
	--local entity = Entity()
	--StationHub.moveToPos(entity, vec3(1000,0,0))
	--physics:applyImpulse(dvec3(mat.position.x, mat.position.y, mat.position.z), dir, 1000)


	local ePos = Entity().translationf
	table.sort(StationHub.ringPositions, function(a,b) return distance2(a.position, ePos) < distance2(b.position, ePos) end)
	table.sort(StationHub.sector_stations, function(a,b) return distance2(a.station.translationf, ePos) < distance2(b.station.translationf, ePos) end)
	for k, _station in pairs(StationHub.sector_stations) do
		if not _station.targetpos then
			local pos = _station.station.position.position
			--table.sort(StationHub.ringPositions, function(a, b)
			--	return distance2(pos, a.position) < distance2(pos, b.position)
			--end)
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
