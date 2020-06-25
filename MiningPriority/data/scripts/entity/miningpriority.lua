package.path = package.path .. ";data/scripts/lib/?.lua"
include('callable')
include("UIDragList")

-- namespace MiningPriority
MiningPriority = {}

function MiningPriority.interactionPossible(playerIndex, option)
	callingPlayer = Player().index
	if not checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FlyCrafts) then
		return false
	end

	return true
end

function MiningPriority.getMiningList() -- invoked via mineAI
	return MiningPriority.material_list
end

function MiningPriority.getMaterialList() -- client
	MiningPriority.material_list = {}
	local temp = {}
	for k, v in pairs(dragList.elements) do
		if v.check_box.checked then
			temp[v.list_pos] = v.material
		end
	end
	for k, v in pairs(temp) do
		table.insert(MiningPriority.material_list, v)
	end
	return MiningPriority.material_list
end

function MiningPriority.secure()
	local sec_mat_list = {}
	for k, v in pairs(MiningPriority.material_list or {}) do -- Materials cannot be sterilized and must be turned to a table of integers
		table.insert(sec_mat_list, v.value)
	end
	return {dragList = MiningPriority.dragList, material_list = sec_mat_list}
end

function MiningPriority.restore(data)
	MiningPriority.dragList = data.dragList
	MiningPriority.material_list = {}
	for k, v in pairs(data.material_list or {}) do
		table.insert(MiningPriority.material_list, Material(v))
	end
	if not MiningPriority.dragList or not MiningPriority.material_list then MiningPriority.fetch() end
end

function MiningPriority.fetch(data) -- from client to server
	if onServer() then
		if data then
			MiningPriority.dragList = data.dragList
			MiningPriority.material_list = data.material_list
		else
			broadcastInvokeClientFunction('fetch')
		end
	else
		invokeServerFunction('fetch', {dragList = dragList:secure(), material_list = MiningPriority.getMaterialList()})
	end
end
callable(MiningPriority, 'fetch')

function MiningPriority.sync(data) -- from server to client
	if onClient() then
		if data then
			dragList:restore(data)
		else
			invokeServerFunction('sync')
		end
	else
		if not MiningPriority.dragList then
			MiningPriority.fetch()
		end
		invokeClientFunction(Player(callingPlayer), 'sync', MiningPriority.dragList)
	end
end
callable(MiningPriority, 'sync')

function MiningPriority.onShowWindow()
	MiningPriority.sync()
end

function MiningPriority.onCloseWindow()
	if dragList.check_box_initialized then
		MiningPriority.fetch() -- stripping all the checkbox params out
	end
end

function MiningPriority.initUI()

	local res = getResolution()
	local size = vec2(150, 220)

	local menu = ScriptUI()
	local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	menu:registerWindow(window, "Mining Priority")

	window.caption = "Mining P."
	window.showCloseButton = true
	window.moveable = true

	dragList = UIDragList(MiningPriority, window, window)

	for k, v in pairs({Node(window.size):pad(10):rows({20,20,20,20,20,20,20}, 10, 10)}) do
		dragList:createDragElement(v.rect, function(this)
			local checkbox_rect, contents_rect = this.contents_rect:cols({20, 1}, 10)
			this.check_box = this.container:createCheckBox(checkbox_rect:centeredrect(20).rect, "", "onCloseWindow")
			this.check_box.checked = true
			this.material = Material(this.id < 8 and 7 - this.id or 0)
			this.label = this.container:createLabel(vec2(contents_rect.rect.lower.x, contents_rect.rect.center.y - 10), this.material.name, 16)
			this.label.color = this.material.color
			this.label_frame = this.container:createFrame(contents_rect:pad(-5,0,-5,0).rect)
			this.onRelease = MiningPriority.onCloseWindow
			this.onSecure = function(self) -- defining onSecure and restore for custom contents of element
				return self.check_box.checked -- only need info related to the contents defined above
			end
			this.onRestore = function(self, data) -- don't need to set pos because the draglist does it for us
				self._parent.check_box_initialized = false
				self.check_box.checked = data
				self._parent.check_box_initialized = true
			end
		end)
	end

	dragList.check_box_initialized = true
	--MiningPriority.onShowWindow()
	MiningPriority.sync()
end

return MiningPriority
