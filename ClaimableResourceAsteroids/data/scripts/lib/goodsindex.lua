--package.path = package.path .. ";data/scripts/config/?.lua"
--Config = include("resourcemineconfig") or {}
--Config.goods = Config.goods or {}
materials = {"Iron","Titanium","Naonite","Trinium","Xanion","Ogonite","Avorion"}
for i = 1, NumMaterials() do
  --local good = Material(i).name -- Getting translated which is messing  things up for clients TODO FIX THIS
  local good = materials[i]
  goods[good .. " Ore"].level = i-1
  goods["Scrap " .. good].level = i-1
  --goods[good].price = Config.goods[i] or goods[good].price * 100
  --goods[good].importance = 8
end
