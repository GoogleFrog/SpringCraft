--Wiki: http://springrts.com/wiki/Modrules.lua

local modRules = {
	movement = {
		allowDirectionalPathing    = false, -- Defaults to true. False removes asymmetric speed mods for walking up or down ramps.
		allowAircraftToLeaveMap    = true,
		allowAircraftToHitGround   = true,
		allowPushingEnemyUnits     = false,
		allowCrushingAlliedUnits   = false,
		allowUnitCollisionDamage   = false,
		allowUnitCollisionOverlap  = false, -- Defaults to true.
		allowSepAxisCollisionTest  = false,
		allowGroundUnitGravity     = false, -- Defaults to true. False prevents units from getting stuck on cliffs.
		allowHoverUnitStrafing     = true,
	},
	system = {
		pathFinderSystem = 0, -- legacy
		pfRawDistMult = 1.25,
		pfUpdateRate = 0.007,
	},
	sensors = {
		los = {
			losMipLevel = 2,  -- defaults to 1
			losMul      = 1,  -- defaults to 1
			airMipLevel = 2,  -- defaults to 2
		},
	},
	flankingBonus = {
		-- defaults to 1
		-- 0: no flanking bonus  
		-- 1: global coords, mobile  
		-- 2: unit coords, mobile  
		-- 3: unit coords, locked 
		defaultMode = 0,
	},
}

return modRules
