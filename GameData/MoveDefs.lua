-- Wiki: http://springrts.com/wiki/Movedefs.lua
-- See also; http://springrts.com/wiki/Units-UnitDefs#Tag:movementClass

local GAME_SPEED = 30

local moveDefs  =    {
	{
		name            = "SMALL_UNIT",
		
		-- Slowdown for wading through water.
		depthmod = 0,
		--depthModParams  = {
		--	minHeight = 0,
		--	maxHeight = 10000, -- std::numeric_limits<float>::max()
		--	maxScale = 10000, -- std::numeric_limits<float>::max()
		--	quadraticCoeff = 0,
		--	linearCoeff = 0,
		--	constantCoeff = 1,
		--},
		
		-- Blocking unit multipliers for trying to move through a square with a unit in it.
		speedModMults = {
			mobileBusyMult = 1,
			mobileIdleMult = 1,
			mobileMoveMult = 1,
		},
		
		avoidMobilesOnPath     = true,
		allowTerrainCollisions = false, -- Defaults to true,
		allowRawMovement       = false, -- Defaults to false.
		heatMapping            = false,
		flowMapping            = true,
		heatMod                = (1 / (GAME_SPEED * 2)) * 0.25,
		flowMod                = 1,
		heatProduced           = GAME_SPEED * 2,
		
		maxSlope = 30, -- Degrees = maxSlope*1.5
		slopeMod = 0,
		
		footprintX    = 2,
		footprintZ    = 2,
		crushStrength = 0, -- For running over features.
		
		subMarine     = false, -- For ships
		minWaterDepth = 0, -- For ships
		maxWaterDepth = 20,
	},
}

return moveDefs