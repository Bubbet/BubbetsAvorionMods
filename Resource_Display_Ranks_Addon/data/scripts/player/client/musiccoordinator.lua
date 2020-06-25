if onClient() then
    function MusicCoordinator.delayedInit()
        local player = Player()
        local err, val = player:invokeFunction("data/scripts/player/ranks.lua", "hasPrivilege", player.index, "resource_display")
        if val then
            player:registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
        end
    end

    function MusicCoordinator.initialize(...)
        resourceDisplay_initialize(...)

        -- load config
        local configOptions = {
            _version = { default = "1.0", comment = "Config version. Don't touch." },
            ShowCargoCapacity = { default = true, comment = "Show current ship cargo capacity" },
            ShowInventoryCapacity = { default = true, comment = "Show currently used and total inventory slots" },
            InventoryCapacityShowBothAlways = { default = false, comment = "Show both player and alliance inventory capacity no matter the ship" }
        }
        local isModified
        ResourceDisplayConfig, isModified = Azimuth.loadConfig("ResourceDisplay", configOptions)
        if isModified then
            Azimuth.saveConfig("ResourceDisplay", ResourceDisplayConfig, configOptions)
        end

        resourceDisplay_hud = Hud()

        deferredCallback(0.5,"delayedInit")
    end
end