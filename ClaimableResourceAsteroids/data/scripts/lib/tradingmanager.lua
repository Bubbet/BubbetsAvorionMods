local rsm_old_buy = TradingManager.isBoughtBySelf
function TradingManager.isBoughtBySelf(slf, good)
  --[[for i = 0, NumMaterials()-1 do
    local mat = Material(i).name
    if string.find(good.name or "", mat) or string.find(good.name or "", materials[i+1]) then return true end
  end]]
  if string.find(table.concat(materials), string.split(good.name, " ")[1]) then return true end
  return rsm_old_buy(slf, good) -- failed for some odd reason i didn't feel like investigating.
end
