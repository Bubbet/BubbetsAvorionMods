
function RepairDock.onShowWindow(option)
	-- this could get called by the server at seemingly random times, so we must check that the UI was initialized
	if not window then return end

	-- repairing
	RepairDock.refreshRepairUI()
	-- reconstruction site & tokens
	RepairDock.refreshReconstructionTokens()

	-- reconstructing ships
	RepairDock.refreshReconstructionLines()

end

function RepairDock.reconstruct(shipName, allianceShip)

	if not CheckFactionInteraction(callingPlayer, RepairDock.interactionThreshold) then return end

	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.ManageShips, AlliancePrivilege.SpendItems)
	if not buyer then return end

	-- if we're requesting an alliance ship to be rebuilt and the buyer is a player, then switch the buyer to be the alliance instead
	if allianceShip == true and buyer.isPlayer and buyer.alliance then
		local alliance = buyer.alliance

		-- we still have to check for privileges
		local requiredPrivileges = {AlliancePrivilege.ManageShips, AlliancePrivilege.SpendItems}
		for _, privilege in pairs(requiredPrivileges) do
			if not alliance:hasPrivilege(callingPlayer, privilege) then
				player:sendChatMessage("", 1, "You don't have permission to do that in the name of your alliance."%_t)
				return
			end
		end

		buyer = player.alliance
	elseif allianceShip == false and buyer.isAlliance then
		buyer = player
	end

	if RepairDock.isShipyardRepairDock() then
		player:sendChatMessage(Entity(), ChatMessageType.Error, "Shipyards don't offer these kinds of services."%_T)
		return
	end

	-- reconstructing stations is not possible
	if buyer:getShipType(shipName) ~= EntityType.Ship then
		player:sendChatMessage(Entity(), ChatMessageType.Error, "Can only reconstruct ships."%_T)
		return
	end

	-- reconstructing non-destroyed ships is impossible
	if not buyer:getShipDestroyed(shipName) then
		player:sendChatMessage(Entity(), ChatMessageType.Error, "Ship wasn't destroyed."%_T)
		return
	end

	-- check if we can pay with tokens
	local paidWithToken = false
	local tokens, item, idx = countReconstructionTokens(buyer, shipName)
	if tokens > 0 then
		local taken = buyer:getInventory():take(idx)
		if not taken then
			player:sendChatMessage(Entity(), ChatMessageType.Error, "Token for this ship not found."%_T)
		else
			paidWithToken = true
			player:sendChatMessage(Entity(), ChatMessageType.Information, "Used a Reconstruction Token to reconstruct '%s'."%_T, shipName)
		end
	end

	if not paidWithToken then
		-- if we can't, use the (higher) reconstruction price
		local price = RepairDock.getReconstructionPrice(buyer, shipName)
		local canPay, msg, args = buyer:canPay(price)

		if not canPay then
			player:sendChatMessage(Entity(), ChatMessageType.Error, msg, unpack(args))
			return
		end

		buyer:pay("Paid %1% Credits to reconstruct a ship."%_T, price)
	end

	-- find a position to put the craft
	local position = Matrix()
	local station = Entity()
	local box = buyer:getShipBoundingBox(shipName)

	-- try putting the ship at a dock
	local docks = DockingPositions(station)
	local dockIndex = docks:getFreeDock()
	if dockIndex then
		local dock = docks:getDockingPosition(dockIndex)
		local pos = vec3(dock.position.x, dock.position.y, dock.position.z)
		local dir = vec3(dock.direction.x, dock.direction.y, dock.direction.z)

		pos = station.position:transformCoord(pos)
		dir = station.position:transformNormal(dir)

		pos = pos + dir * (box.size.z / 2 + 10)

		local up = station.position.up

		position = MatrixLookUpPosition(-dir, up, pos)
	else
		-- if all docks are occupied, place it near the station
		-- use the same orientation as the station
		position = station.orientation

		local sphere = station:getBoundingSphere()
		position.translation = sphere.center + random():getDirection() * (sphere.radius + length(box.size) / 2 + 50);
	end


	local craft = buyer:restoreCraft(shipName, position, true)
	if not craft then
		player:sendChatMessage(Entity(), ChatMessageType.Error, "Error reconstructing craft."%_t)
		return
	end

	CargoBay(craft):clear()
	craft:setValue("untransferrable", nil) -- tutorial could have broken this

	if ship.isDrone then
		player.craft = craft
		invokeClientFunction(player, "transactionComplete")
	end

	Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "Insta-Reconstruction complete! Your ship may have suffered some minor structural damages due to the reconstruction process."%_t)
	Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "If you buy a new Reconstruction Token, we'll fix her up for free!"%_t)

	invokeClientFunction(player, "onShowWindow", 0)
end

function RepairDock.refreshReconstructionTokens()

	if RepairDock.isShipyardRepairDock() then
		tabbedWindow:deactivateTab(tokensTab)
		tokensTab.description = "Only available at Repair Docks, not Shipyards!"%_t
		return
	else
		tabbedWindow:activateTab(tokensTab)
		tokensTab.description = "Buy Reconstruction Tokens"%_t
	end

	local player = Player()
	local buyer = Galaxy():getPlayerCraftFaction()
	local ship = player.craft

	reconstructionPriceLabel.caption = "Price: ¢${money}"%_t % {money = createMonetaryString(RepairDock.getReconstructionSiteChangePrice())}

	if buyer.isAlliance then
		setReconstructionSiteButton.active = false
		setReconstructionSiteButton.tooltip = "Alliances don't have reconstruction sites."%_t
	elseif RepairDock.isReconstructionSite() then
		setReconstructionSiteButton.active = false
		setReconstructionSiteButton.tooltip = "This sector is already your reconstruction site."%_t
	else
		setReconstructionSiteButton.active = true
		setReconstructionSiteButton.tooltip = nil
	end

	local tokens = countReconstructionTokens(player, ship.name, buyer.index)
	local atokens = 0

	local alliance = player.alliance
	if alliance then
		atokens = countReconstructionTokens(alliance, ship.name, buyer.index)
	end

	local price = RepairDock.getReconstructionTokenPrice(buyer, ship)

	if price and price > 0 then
		buyTokenAmountLabel.caption = tostring(tokens)
		buyTokenNameLabel.caption = ship.name
		buyTokenPriceLabel.caption = createMonetaryString(price)

		if atokens > 0 then
			buyTokenButton.active = false
			buyTokenButton.tooltip = "Your alliance already owns a Reconstruction Token for this ship."%_t
			buyTokenAmountLabel.active = false
		elseif tokens > 0 then
			buyTokenButton.active = false
			buyTokenButton.tooltip = "You already own a Reconstruction Token for this ship."%_t
			buyTokenAmountLabel.active = false
		else
			buyTokenButton.active = true
			buyTokenAmountLabel.active = true
			buyTokenButton.tooltip = "Buy a token and get your ship repaired FOR FREE!"%_t
		end

		if buyer.isPlayer and RepairDock.isReconstructionSite() then
			buyTokenPriceLabel.color = ColorRGB(0, 1, 0)
			buyTokenPriceLabel.tooltip = "You get a 30% discount for tokens at your Reconstruction Site!"%_t
		else
			buyTokenPriceLabel.color = ColorRGB(1, 1, 1)
			buyTokenPriceLabel.tooltip = nil
		end
	else
		buyTokenAmountLabel.caption = ""
		buyTokenNameLabel.caption = ""
		buyTokenPriceLabel.caption = ""

		buyTokenButton.active = false
		buyTokenButton.tooltip = nil
	end

	freeRepairLabel:show()

	local malus, reason = ship:getMalusFactor()
	if reason and reason == MalusReason.Boarding then
		priceDescriptionLabel:hide()
	else
		priceDescriptionLabel:show()
	end
end
