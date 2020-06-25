
function Insurance.initialize()
	if onServer() then
		if not _restoring then --and GameSettings().permaDestructionEnabled then
			terminate()
			return
		end

		local entity = Entity()

		-- new: remove insurance from scripts and replace with a Reconstruction Token
		-- this is mainly for backwards compatibility, for when ships still had insurances
		if entity.type == EntityType.Ship then
			local faction = Faction()
			if faction and (faction.isPlayer or faction.isAlliance) then
				faction:getInventory():add(createReconstructionToken(entity))
			end
			terminate()
			return
		end

		entity:registerCallback("onDestroyed" , "onDestroyed")
		entity:registerCallback("onPlanModifiedByBuilding" , "onBuild")
	end

end
