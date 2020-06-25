Config = {}
Config.upgradeCostMul = 1.5 -- material cost multiplier for upgrade button in mine
Config.defaultproductionsize = 20 -- amount of resource produced per productions
Config.averageasteroidsize = 150000 -- average amount of resources in an asteroid, used in hand with the production size to balance the production amount also used to balance founding price
Config.enablenpcautoprocessing = true -- allow your cargo ships to process the resources for you by bringing them to resource depots
Config.processAmount = 200 -- how much the resource depot refinery can automatically process per second
Config.updateInterval = 5 -- how often the automatic refinery processes, does not affect how much per second
Config.maxStock = nil -- Set to a number to limit how much stock resource mines can generate else it will use cargo hold
Config.productionCapacity = 250 -- Higher to make assemblers less effective at raising production rate of autorefinery
return Config
