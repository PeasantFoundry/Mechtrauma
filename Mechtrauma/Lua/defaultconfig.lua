
-- DO NOT EDIT THIS CONFIG, THIS IS JUST A TEMPLATE

local config = {}

config.dieselDrainRate = 1 -- NYI
config.pumpGateDeteriorateRate = 1
config.divingSuitServiceLife = 60
config.divingSuitEPP = 2
config.fusBoxDeterioration = 0.12
config.fuseOvervoltDamage = 5
config.disableElectrocution = false
config.ventSpawnRate = 0
config.bearingServiceLife = 13
config.bearingDPS = .255
config.dieselGeneratorEfficiency = 0.3
config.dieselHorsePowerRatioL = 0.2 -- 0.2:1 - HP:liter:HP
config.dieselHorsePowerRatioDL = 2.0 -- 2.0:1 - HP:deciliter:HP 
config.dieselHorsePowerRatioCL = 20.0 -- 20:1 - centiliter:HP
config.dieselOxygenRatioL = 7.0 -- 7:1 air:fuel liter
config.dieselOxygenRatioDL = 0.7 -- 70:10 air:fuel deciliter
config.dieselOxygenRatioCL = 0.07 -- 700:100 air:fuel centiliter
config.circulatorServiceLife = 13
config.circulatorDPS = 0.255 -- calculated from config (100 / circulatorServiceLife * Deltatime)
config.oilFilterServiceLife = 6.5
config.oilFilterDPS = 0.255 -- calculated from config (100 / oilFilterServiceLife * Deltatime)
config.oilFiltrationEP = 25 -- oil filtration efficiency percentage
config.oilFiltrationM = 0.25 -- JSON ONLY - oil filtration multiplier for detirioration 
config.oilBaseDPS = 1.0 -- centiliters
config.frictionBaseDPS = 1.0
return config