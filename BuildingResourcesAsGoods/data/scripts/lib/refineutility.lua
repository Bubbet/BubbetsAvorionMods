
nameByMaterial = {}
for k, v in pairs(oreNameByMaterial) do
	nameByMaterial[k] = string.split(v, ' ')[1]
end
