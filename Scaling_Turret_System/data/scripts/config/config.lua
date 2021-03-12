local config = {
    stats = { -- stat followed by weight for weighted average
        volume = 0.0025 -- can be anything that returns double in BlockStatistics
    },
    units = {
        volume = "k m³"
    },
    probabilities = {
        [StatsBonuses.ArmedTurrets] = 1,
        [StatsBonuses.UnarmedTurrets] = 1,
        [StatsBonuses.ArbitraryTurrets] = 0.75,
    },
    stattypes = {
        [StatsBonuses.ArbitraryTurrets] = "Arbitrary Turret",
        [StatsBonuses.UnarmedTurrets] = "Unarmed Turret",
        [StatsBonuses.ArmedTurrets] = "Armed Turret",
    },
}

return config