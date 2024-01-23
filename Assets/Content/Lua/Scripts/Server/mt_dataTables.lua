

-- -------------------------------------------------------------------------- --
--                        MECHTRAUMA UPDATER FUNCTIONS                        --
-- -------------------------------------------------------------------------- --
-- these functions are the backbone of the MT updater that runs every 2 seconds
MT.UF = {}

MT.C = {}
MT.C.HD = {}
---------------------------------------------- --
--                            MECHTRAUMA ITEM CACHE                           --
-- -------------------------------------------------------------------------- --
MT.itemCache = {}
MT.itemCacheCount = 0
MT.priorityItemCache = {}
MT.priorityItemCacheCount = 0

MT.inventoryCache = {parts={}} -- used for parts report prototype
MT.inventoryCacheCount = 0 -- used for parts report prototype

-- -------------------------------------------------------------------------- --
--                           MECHTRAUMA MISC GLOBALS                          --
-- -------------------------------------------------------------------------- --
MT.ambientTemperature = 60
MT.oxygenVentCount = 0

-- ----------------------------
-- -------------------------------------------------------------------------- --
--                        MECHTRAUMA ITEM UPDATE EVENTS                       --
-- -------------------------------------------------------------------------- --
--table of tag functions - this is for mapping items to update functions


-- -------------------------------------------------------------------------- --
--                        MECHTRAUMA ITEM SPWAN EVENTS                        --
-- -------------------------------------------------------------------------- --
