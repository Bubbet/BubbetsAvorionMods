local Config = {
	seedsBuyable = true,				-- If true, more seeds can be bought. If false, there are unlimited seeds as in earlier mod versions. Possible values: true, false
	sample_size = 500, -- only used when seedsBuyable = false dont set too high or you'll experience hangs/crashes
	upgradeBasePrice = 30000000,		-- Base price per upgraded seed. Possible values: higher then 0
	upgradeAmount = 5, -- Amount of seeds bought by one upgrade process. Possible values: 1 or higher
	max_buyable = 1000, -- max amount of buyable seeds per factory

	ui_size = vec2(1050, 500), --change these two at your own risk, the ui might not be happy when scaled smaller larger should probably be fine?
	ui_offset = vec2(-195,0),
    ignore_tooltips = { --Used to remove tooltip lines from being displayed as stats.
        -- "Velo", -- A part/the full word found in the left hand side of the tooltip
        "Gunner"
    }
}

return Config
