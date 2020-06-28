--[[
goods["Avorion"] = {name="Avorion", plural="Scrap Avorion", description="Scrap Avorion that can be refined into Avorion.", icon="data/textures/icons/rock.png", price=24, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Iron"] = {name="Iron", plural="Scrap Iron", description="Scrap Iron that can be refined into Iron.", icon="data/textures/icons/rock.png", price=4, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Metal"] = {name="Metal", plural="Scrap Metal", description="A container full of metal junk.", icon="data/textures/icons/scrap-metal.png", price=25, size=3, level=0, importance=1, illegal=false, dangerous=false, tags={basic=true}, chains={basic=true,consumer=true,industrial=true,military=true,technology=true}, }
goods["Naonite"] = {name="Naonite", plural="Scrap Naonite", description="Scrap Naonite that can be refined into Naonite.", icon="data/textures/icons/rock.png", price=7, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Ogonite"] = {name="Ogonite", plural="Scrap Ogonite", description="Scrap Ogonite that can be refined into Ogonite.", icon="data/textures/icons/rock.png", price=18, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Titanium"] = {name="Titanium", plural="Scrap Titanium", description="Scrap Titanium that can be refined into Titanium.", icon="data/textures/icons/rock.png", price=5, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Trinium"] = {name="Trinium", plural="Scrap Trinium", description="Scrap Trinium that can be refined into Trinium.", icon="data/textures/icons/rock.png", price=10, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
goods["Xanion"] = {name="Xanion", plural="Scrap Xanion", description="Scrap Xanion that can be refined into Xanion.", icon="data/textures/icons/rock.png", price=13, size=0.04, level=nil, importance=0, illegal=false, dangerous=false, tags={basic=true}, chains={}, }
]]

package.path = package.path .. ";data/scripts/lib/?.lua"
include("refineutility")

for k, v in pairs(nameByMaterial) do
	local material = Material(k-1)
	goods[v] = {name = v, plural = v, description = 'Refined ' .. v .. ' that is used in building.', icon = 'data/textures/icons/rock.png', material.costFactor, size = 0.04, importance = 0, illegal = false, dangerous = false, tags = {basic = true}, chains = {}}
end