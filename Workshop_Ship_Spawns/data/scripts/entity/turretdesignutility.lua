
--namespace TurretDesignUtility
TurretDesignUtility = {}

--[[
	for _, block in pairs(Plan():getBlocksByType(BlockType.TurretBase)) do
	end
]]

function TurretDesignUtility.interactionPossible()
	return Player().state == PlayerStateType.BuildCraft
end

function TurretDesignUtility.initUI()
	local res = getResolution()
	local size = vec2(780, 580)

	local menu = ScriptUI()
	window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

	window.caption = "Turret Design Utility"
	window.showCloseButton = 1
	window.moveable = 1
	menu:registerWindow(window, "Turret Design Utility");
end

function TurretDesignUtility.onPostRenderHud(state)
	if state ~= PlayerStateType.BuildCraft then
		if TurretDesignUtility.visible then
			TurretDesignUtility.visible = false
			window:hide()
		end
		return
	end
	if not TurretDesignUtility.visible then
		TurretDesignUtility.visible = true
		window:show()
	end
end

function TurretDesignUtility.initialize()
	if onClient() then
		--Player():registerCallback('onPostRenderHud','onPostRenderHud')
	end
end