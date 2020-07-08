package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
local Node = include('node')
include('callable')
include('ElementToTable')

-- namespace StationHub
StationHub = {}

-- Client
function StationHub.receiveCargos(cargos)
	local sorted = {}
	for k, v in pairs(cargos or {}) do
		table.insert(sorted, {key = k, val = v})
	end
	table.sort(sorted, function(a, b) return a.val > b.val end)
	local offset = (StationHub.page-1)*#StationHub.rows
	if #sorted > 0 then StationHub.cargo = sorted else StationHub.cargo = StationHub.cargo or {} end
	for k, v in pairs(StationHub.rows) do
		local val = StationHub.cargo[k+offset]
		if val then
			v.good_label.caption = val.key.name
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
	local top, bottom = StationHub.rows[1], StationHub.rows[#StationHub.rows]
	table.remove(StationHub.rows, 1)
	table.remove(StationHub.rows, #StationHub.rows)

	local topleft, topmiddle, topright = top:cols({1/3, 1/3, 1/3}, 10)
	topleft.frame = container:createFrame(topleft.rect)
	topleft.label = container:createLabel(topleft:pad(10,0,0,0).rect,'Good:',14)
	topleft.label:setLeftAligned()
	topmiddle.checkBox = container:createCheckBox(topmiddle:pad(5):centeredrect(20).rect, 'Show Lines?', 'showLines')
	topmiddle.frame = container:createFrame(topmiddle.rect)
	StationHub.showLinesBox = topmiddle
	topright.frame = container:createFrame(topright.rect)
	topright.label = container:createLabel(topright:pad(0,0,10,0).rect,'Amount:',14)
	topright.label:setRightAligned()

	container:createLine(top.rect.upper-vec2(top.rect.width, -5), top.rect.upper+vec2(0, 5))
	container:createLine(top.rect.position+vec2(0, top.rect.height*0.5+5), bottom.rect.position-vec2(0, bottom.rect.height*0.5 + 10))

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

function StationHub.initialize()
	local entity = Entity()
	StationHub.sector_stations = {}
	for _, v in pairs({Sector():getEntitiesByType(EntityType.Station)}) do
		if v.factionIndex == entity.factionIndex then
			--local laser
			if onServer() then
				v:invokeFunction('data/scripts/entity/merchants/factory.lua', 'setHub', entity.index)
			else
				--laser = sector:createLaser(entity.translationf, v.translationf, color, 5.0)
				--laser.collision = false
			end
			table.insert(StationHub.sector_stations, {station = v})--, laser = laser})
		end
	end
end

function StationHub.onDelete()
	if onClient() then
		local sector = Sector()
		for _, v in pairs(StationHub.sector_stations) do
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
		v.cargo = v.station:getCargos()
		for k1, v1 in pairs(v.cargo) do
			StationHub.cargo[k1] = StationHub.cargo[k1] and StationHub.cargo[k1] + v1 or v1
		end
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
	return remaining == 0 -- true if the cargo has been removed
end
