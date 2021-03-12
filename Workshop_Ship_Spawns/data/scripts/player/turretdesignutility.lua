package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
include('ElementToTable')
Node = include('node')

-- namespace TurretDesignUtility
BuildMenuEnhancements = {}
self = BuildMenuEnhancements

if onClient() then
	function BuildMenuEnhancements.initialize()
		local player = Player()
		player:registerCallback("onStateChanged", "onPlayerStateChanged")
		BuildMenuEnhancements.initUI()
	end

	function BuildMenuEnhancements.initUI()
		local res = getResolution()
		local size = vec2(147, 192.5)
		local position = vec2(0, res.y - size.y - 20)

		self.nodes = {container = Node(size)}
		self.window = ElementToTable(Hud():createWindow(Rect(position, position + size)))
		self.window.moveable = true
		---@type UIContainer
		self.container = self.window:createContainer(self.nodes.container.rect)
		self.nodes.grid = {self.nodes.container:pad(5):grid(4, 3, 5, 5)}

		local button = self.container:createButton(self.nodes.grid[1][1].rect, '', 'applyAll')
		button.icon = 'data/textures/icons/transfer-to-turret-part.png'
		button.tooltip = 'Apply Turret Design'
		self.nodes.apply_root = Node(vec2(400, 540))
		self.apply_window = self.container:createWindow(self.nodes.apply_root.rect)
		self.apply_window.caption = 'Apply'
		self.apply_window.moveable = true
		self.apply_window.showCloseButton = true
		self.nodes.apply_container = self.nodes.apply_root:pad(10)
		self.apply_container = self.apply_window:createContainer(self.nodes.apply_root.rect)
		local top, bot = self.nodes.apply_container:rows({1, 50}, 10)
		self.design_selection = self.apply_container:createSavedDesignsSelection(top.rect, 5)
		--self.design_selection.onSelectedFunction = 'design_selection_plan_select'
		local _, bot_r = bot:cols({1, bot.rect.height}, 10)
		self.design_button = self.apply_container:createButton(bot_r.rect, '', 'design_selected')
		self.design_button.icon = 'data/textures/icons/apply-design.png'

		local button = self.container:createButton(self.nodes.grid[1][2].rect, '', 'exportAll')
		button.icon = 'data/textures/icons/turret-build-mode.png'
		--[[
		self.nodes.container.element = self.window:createContainer(self.nodes.container.rect)
		local container = self.nodes.container.element
		--[[self.nodes.cols = {self.nodes.container:pad(5):cols(3, 5)}
		for k, v in pairs(self.nodes.cols) do
			v.rows = {v:rows({v.rect.width, v.rect.width, v.rect.width, v.rect.width}, 5)}
			for k, v in pairs(v.rows) do
				self.container:createFrame(v.rect)
			end
		end]
		self.nodes.grid = {self.nodes.container:pad(5):grid(4, 3, 5, 5)}
		--- @type Button
		self.nodes.grid[1][1].element = container:createButton(self.nodes.grid[1][1].rect, '', 'applyAll')
		self.nodes.grid[1][1].element.icon = 'data/textures/icons/transfer-to-turret-part.png'
		self.nodes.grid[1][1].element.tooltip = 'Apply Turret Design'
		]]
		--[[
		for k, v in pairs(self.nodes.grid) do
			for k, v in pairs(v) do
				self.container:createFrame(v.rect)
			end
		end
		]]

		self.window:hide()
		self.apply_window:hide()
	end

	function BuildMenuEnhancements.onPlayerStateChanged(new, old)
		if new == PlayerStateType.BuildCraft then
			self.window:show()
		else
			self.window:hide()
			self.apply_window:hide()
		end
	end


	function BuildMenuEnhancements.applyAll()
		self.apply_window:show()
		self.design_selection:refreshTopLevelFolder()
	end

	function BuildMenuEnhancements.design_selected()
		local selected = self.design_selection.selected
		if selected then -- and selected.type == SavedDesignType.TurretDesign then
			if selected.type ~= SavedDesignType.TurretDesign then
				selected = {design = LoadTurretDesignFromFile(selected.path)} -- craft designs are not able to be loaded by turretdesign function resulting in no change
				print(selected.design)
			end
			local id = Player().craft.id
			for _, block in pairs(Plan(id):getBlocksByType(BlockType.TurretBase)) do
				TurretBases(id):setDesign(block, selected.design)
			end
		end
		self.apply_window:hide()
	end

	function BuildMenuEnhancements.exportAll()
		local id = Player().craft.id
		print(CraftDesign().numTurrets)
		print(TurretDesign())
		--[[for _, block in pairs(Plan(id):getBlocksByType(BlockType.TurretBase)) do
			TurretBases(id):setDesign(block, selected.design)
		end
		]]
	end
end