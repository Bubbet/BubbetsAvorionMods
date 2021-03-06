local Config = {
    maxseeds = 50,				-- set to 0 to disable seed functionality
    upgradeBasePrice = 3000000,		-- Base price per upgraded seed. Possible values: higher then 0
    tax = 0.2, -- this is likely the value you'll want to change if you're looking to make the systems more expensive
    pricescale = 2, -- setting this too low will also lower the cost of ingredients

    spawns = { -- set to -1 to disable tier;  x:500,y:0 = 1; x:500,y:500 = ~1.4
        uncommon = 1.3,
        rare = 0.7,
        exceptional = 0.5,
        exotic = 0.3,
        legendary = 0.1
    },

    disabledsystems = {
        --"data/scripts/systems/cargoextension.lua"
    }
}

return Config
