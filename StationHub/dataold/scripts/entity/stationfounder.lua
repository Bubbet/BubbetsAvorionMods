table.insert(StationFounder.stations, {
	name = "Station Hub"%_t,
	tooltip = "Used to 'combine' the cargo hold of your stations."%_t,
	scripts = {
		{script = "data/scripts/entity/merchants/stationhub.lua"}
	},
	price = 105000000
})