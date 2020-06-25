package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
Node = include("node")
include("ElementToTable")

function TurretFactory.initUI()
	local res = getResolution()
	local size = vec2(780 + 150, 580)
	local menu = ScriptUI()
	root_node = Node(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	window = menu:createWindow(root_node.rect)
	window.caption = "Turret Factory"%_t
	window.showCloseButton = 1
	window.moveable = 1
	menu:registerWindow(window, "Build Turrets /*window title*/"%_t);
	tab_node = root_node:pad(10)
	tabbedWindow = window:createTabbedWindow(tab_node.rect)

	buildTurretsTab = ElementToTable(tabbedWindow:createTab("", "data/textures/icons/turret-build-mode.png", "Build customized turrets from parts"%_t))
	TurretFactory.initBuildTurretsUI(buildTurretsTab)

	--local tab = tabbedWindow:createTab("", "data/textures/icons/turret-blueprint.png", "Create new blueprints from turrets"%_t)
	--makeBlueprintsTab = setmetatable({tab = tab}, getmetatable(tab))
	--TurretFactory.initMakeBlueprintsUI(makeBlueprintsTab)
end

---@param tab Tab
function TurretFactory.initBuildTurretsUI(tab)
	tab.onSelectedFunction = "refreshBuildTurretsUI"
	tab.onShowFunction = "refreshBuildTurretsUI"
	tab.left, tab.right = tab_node:cols({0.4}, 10)
	tab:createFrame(tab.right.rect)
end