package.path = package.path .. ";data/scripts/lib/?.lua"

local SystemIngredients = {}
--[[
ingredient cost rarity function:
ingredient.amount = ingredient.amount * math.ceil(1.0 + rarity.value * (ingredient.rarityFactor or 1.0))

SystemIngredients["data/scripts/systems/arbitrarytcs.lua"] = { -- path to system
    {name = "Servo",                        amount = 15, rarityFactor = 0.75}, --optional additional scaling for rarity
    {name = "Steel Tube",                   amount = 6},
    {name = "Ammunition S",                 amount = 5},
    {name = "Steel",                        amount = 5},
    {name = "Aluminium",                    amount = 7},
    {name = "Lead",                         amount = 10}
}
--]]

SystemIngredients["data/scripts/systems/arbitrarytcs.lua"] = {
    {name = "Targeting System",             amount = 5},
    {name = "Fusion Core",                  amount = 3},
    {name = "Servo",                        amount = 4},
    {name = "Copper",                       amount = 7},
    {name = "Metal Plate",                  amount = 7},
    {name = "Computation Mainframe",        amount = 6}, probability = {p = 2.5, d = 0.5}
}

SystemIngredients["data/scripts/systems/batterybooster.lua"] = {
    {name = "Energy Cell",                  amount = 5},
    {name = "Energy Container",             amount = 4},
    {name = "Conductor",                    amount = 5},
    {name = "Energy Inverter",              amount = 7},
    {name = "Copper",                       amount = 6},
    {name = "Computation Mainframe",        amount = 5}
}

SystemIngredients["data/scripts/systems/cargoextension.lua"] = {
    { name = "Steel",                       amount = 11 },
    { name = "Targeting System",            amount = 6 },
    { name = "Electro Magnet",              amount = 7 },
    { name = "Drone",                       amount = 3 },
    { name = "Servo",                       amount = 4 },
    { name = "Computation Mainframe",       amount = 7 }
}

SystemIngredients["data/scripts/systems/civiltcs.lua"] = {
    {name = "Targeting System",             amount = 4},
    {name = "Fusion Generator",             amount = 5},
    {name = "Fusion Core",                  amount = 4},
    {name = "Copper",                       amount = 6},
    {name = "Coolant",                      amount = 5},
    {name = "Energy Tube",                  amount = 4},
    {name = "Energy Generator",             amount = 3},
    {name = "Computation Mainframe",        amount = 5}
}

SystemIngredients["data/scripts/systems/defensesystem.lua"] = {
    {name = "Steel",                        amount = 6},
    {name = "Targeting System",             amount = 4},
    {name = "Fusion Generator",             amount = 5},
    {name = "Copper",                       amount = 6},
    {name = "Coolant",                      amount = 5},
    {name = "Energy Tube",                  amount = 4},
    {name = "Energy Generator",             amount = 3},
    {name = "Computation Mainframe",        amount = 9}
}

SystemIngredients["data/scripts/systems/energybooster.lua"] = {
    {name = "Energy Cell",                  amount = 7},
    {name = "Energy Generator",             amount = 5},
    {name = "Energy Tube",                  amount = 5},
    {name = "Fusion Core",                  amount = 4},
    {name = "Conductor",                    amount = 6},
    {name = "Steel",                        amount = 3},
    {name = "Computation Mainframe",        amount = 7}
}

SystemIngredients["data/scripts/systems/energytoshieldconverter.lua"] = {
    {name = "Force Generator",              amount = 9},
    {name = "Energy Inverter",              amount = 5},
    {name = "Energy Tube",                  amount = 6},
    {name = "Energy Container",             amount = 7},
    {name = "Electromagnetic Charge",       amount = 4},
    {name = "Conductor",                    amount = 6},
    {name = "Computation Mainframe",        amount = 6}
}

SystemIngredients["data/scripts/systems/enginebooster.lua"] = {
    {name = "Antigrav Generator",           amount = 6},
    {name = "Turbine",                      amount = 7},
    {name = "Energy Inverter",              amount = 4},
    {name = "High Pressure Tube",           amount = 5},
    {name = "Electromagnetic Charge",       amount = 5},
    {name = "Coolant",                      amount = 8},
    {name = "Steel",                        amount = 9},
    {name = "Computation Mainframe",        amount = 5}
}

SystemIngredients["data/scripts/systems/hyperspacebooster.lua"] = {
    {name = "Fusion Generator",             amount = 5},
    {name = "Neutron Accelerator",          amount = 4},
    {name = "Targeting System",             amount = 7},
    {name = "Teleporter",                   amount = 6},
    {name = "Electromagnetic Charge",       amount = 6},
    {name = "Energy Tube",                  amount = 3},
    {name = "Energy Cell",                  amount = 6},
    {name = "Energy Container",             amount = 5},
    {name = "Computation Mainframe",        amount = 5}
}

SystemIngredients["data/scripts/systems/lootrangebooster.lua"] = {
    {name = "Antigrav Generator",           amount = 3},
    {name = "Energy Inverter",              amount = 4},
    {name = "Energy Generator",             amount = 4},
    {name = "High Pressure Tube",           amount = 5},
    {name = "Servo",                        amount = 3},
    {name = "Drone",                        amount = 4},
    {name = "Steel",                        amount = 4},
    {name = "Computation Mainframe",        amount = 6}
}

SystemIngredients["data/scripts/systems/militarytcs.lua"] = {
    {name = "Targeting System",             amount = 5},
    {name = "Antigrav Generator",           amount = 3},
    {name = "Coolant",                      amount = 6},
    {name = "Steel",                        amount = 4},
    {name = "Copper",                       amount = 5},
    {name = "Energy Tube",                  amount = 3},
    {name = "Energy Generator",             amount = 5},
    {name = "Computation Mainframe",        amount = 3}
}

SystemIngredients["data/scripts/systems/miningsystem.lua"] = {
    {name = "Targeting System",             amount = 4},
    {name = "Targeting Card",               amount = 4},
    {name = "Processor",                    amount = 7},
    {name = "Steel",                        amount = 5},
    {name = "Copper",                       amount = 5},
    {name = "Computation Mainframe",        amount = 3}
}

SystemIngredients["data/scripts/systems/radarbooster.lua"] = {
    {name = "Targeting System",             amount = 6},
    {name = "Processor",                    amount = 5},
    {name = "Energy Generator",             amount = 3},
    {name = "Energy Tube",                  amount = 4},
    {name = "Steel",                        amount = 3},
    {name = "Copper",                       amount = 4},
    {name = "Computation Mainframe",        amount = 6}
}

SystemIngredients["data/scripts/systems/scannerbooster.lua"] = {
    {name = "Targeting System",             amount = 5},
    {name = "High Capacity Lens",           amount = 4},
    {name = "Energy Generator",             amount = 3},
    {name = "Energy Tube",                  amount = 4},
    {name = "Steel",                        amount = 3},
    {name = "Conductor",                    amount = 3},
    {name = "Computation Mainframe",        amount = 5}
}

SystemIngredients["data/scripts/systems/shieldbooster.lua"] = {
    {name = "Fusion Generator",             amount = 5},
    {name = "Fusion Core",                  amount = 4},
    {name = "Servo",                        amount = 4},
    {name = "Energy Generator",             amount = 3},
    {name = "Energy Tube",                  amount = 4},
    {name = "Proton Accelerator",           amount = 5},
    {name = "Steel",                        amount = 3},
    {name = "Copper",                       amount = 7},
    {name = "Computation Mainframe",        amount = 6}
}

SystemIngredients["data/scripts/systems/shieldimpenetrator.lua"] = {
    {name = "Fusion Generator",             amount = 4},
    {name = "Fusion Core",                  amount = 3},
    {name = "Electron Accelerator",         amount = 3},
    {name = "Steel",                        amount = 4},
    {name = "Nanobot",                      amount = 5},
    {name = "Electro Magnet",               amount = 3},
    {name = "Plasma Cell",                  amount = 4},
    {name = "Computation Mainframe",        amount = 4}
}

SystemIngredients["data/scripts/systems/tradingoverview.lua"] = {
    {name = "Targeting System",             amount = 4},
    {name = "Processor",                    amount = 5},
    {name = "Copper",                       amount = 4},
    {name = "Drone",                        amount = 3},
    {name = "Display",                      amount = 5}
}

SystemIngredients["data/scripts/systems/transportersoftware.lua"] = {
    {name = "Steel",                        amount = 4},
    {name = "Copper",                       amount = 4},
    {name = "Display",                      amount = 4},
    {name = "Energy Cell",                  amount = 3},
    {name = "Energy Tube",                  amount = 5},
    {name = "Computation Mainframe",        amount = 3}
}

SystemIngredients["data/scripts/systems/valuablesdetector.lua"] = {
    {name = "Targeting System",             amount = 5},
    {name = "Processor",                    amount = 4},
    {name = "Copper",                       amount = 5},
    {name = "Drone",                        amount = 3},
    {name = "Display",                      amount = 4},
    {name = "Energy Cell",                  amount = 2}
}

SystemIngredients["data/scripts/systems/velocitybypass.lua"] = {
    {name = "Antigrav Generator",           amount = 3},
    {name = "Turbine",                      amount = 7},
    {name = "High Pressure Tube",           amount = 5},
    {name = "Electromagnetic Charge",       amount = 6},
    {name = "Energy Tube",                  amount = 5},
    {name = "Energy Container",             amount = 5},
    {name = "Steel",                        amount = 4},
    {name = "Computation Mainframe",        amount = 3}
}

SystemIngredients["data/scripts/systems/resistancesystem.lua"] = {
    {name = "Antigrav Generator",           amount = 3},
    {name = "Turbine",                      amount = 7},
    {name = "High Pressure Tube",           amount = 5},
    {name = "Electromagnetic Charge",       amount = 6},
    {name = "Energy Tube",                  amount = 5},
    {name = "Energy Container",             amount = 5},
    {name = "Steel",                        amount = 4},
    {name = "Computation Mainframe",        amount = 3}
}

SystemIngredients["data/scripts/systems/weaknesssystem.lua"] = {
    {name = "Antigrav Generator",           amount = 3},
    {name = "Turbine",                      amount = 7},
    {name = "High Pressure Tube",           amount = 5},
    {name = "Electromagnetic Charge",       amount = 6},
    {name = "Energy Tube",                  amount = 5},
    {name = "Energy Container",             amount = 5},
    {name = "Steel",                        amount = 4},
    {name = "Computation Mainframe",        amount = 3}
}


return SystemIngredients
