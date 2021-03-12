
--namespace TurretDesignUtility
BuildMenuEnhancements = {}

--[[
	for _, block in pairs(Plan():getBlocksByType(BlockType.TurretBase)) do
	end
]]

function BuildMenuEnhancements.interactionPossible()
	return Player().state == PlayerStateType.BuildCraft
end

function BuildMenuEnhancements.initUI()
	local res = getResolution()
	local size = vec2(780, 580)

	local menu = ScriptUI()
	window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

	window.caption = "Turret Design Utility"
	window.showCloseButton = 1
	window.moveable = 1
	menu:registerWindow(window, "Turret Design Utility");
end

function BuildMenuEnhancements.onPostRenderHud(state)
	if state ~= PlayerStateType.BuildCraft then
		if BuildMenuEnhancements.visible then
			BuildMenuEnhancements.visible = false
			window:hide()
		end
		return
	end
	if not BuildMenuEnhancements.visible then
		BuildMenuEnhancements.visible = true
		window:show()
	end
end

function BuildMenuEnhancements.initialize()
	if onClient() then
		--Player():registerCallback('onPostRenderHud','onPostRenderHud')
	end
end