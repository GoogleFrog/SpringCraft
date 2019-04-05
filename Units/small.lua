unitDef = {
	unitname               = [[small]],
	name                   = [[Bandit]],
	description            = [[Small unit]],
	
	-- Abilities
	canGuard               = true,
	canMove                = true,
	canPatrol              = true,
	canAttack              = true,
	sightDistance          = 500,
	idleAutoHeal           = 0,
	idleTime               = 1800,
	maxDamage              = 265,
	category               = [[LAND]],
	
	-- Construction
	buildCostMetal         = 75,
	maxSlope               = 36,
	maxWaterDepth          = 0,
	
	-- Size
	collisionVolumeOffsets = [[0 0 0]],
	collisionVolumeScales  = [[15 30 15]],
	collisionVolumeType    = [[CylY]],
	objectName             = [[mbot.s3o]],
	script                 = [[small.lua]],
	footprintX             = 2,
	footprintZ             = 2,
	upright                = true,
	
	-- Movement
	movementClass          = [[SMALL_UNIT]],
	maxVelocity            = 3,
	acceleration           = 3,
	brakeRate              = 2,
	turnRate               = 0.16*33750, -- 33750 is 180 degrees in 1 frame
	moveState              = 0, -- Prevent movement while firing

	-- Movement defaults
	maxReverseVelocity     = 0,
	minCollisionSpeed      = 1,
	blocking               = true,
	collide                = true,
	turnInPlace            = true,
	turnInPlaceSpeedLimit  = 10,
	turnInPlaceAngleLimit  = 0,
	pushResistant          = false, -- Is broken
	
	customParams           = {
		turnaccel          = 0.16*33750,
		modelradius        = 15,
	},

	weapons                = {
		{
			def                = [[WEAPON]],
			onlyTargetCategory = [[LAND]],
		},
	},

	weaponDefs             = {

		WEAPON = {
			name                    = [[Laser Blaster]],
			areaOfEffect            = 8,
			coreThickness           = 0.5,
			craterBoost             = 0,
			craterMult              = 0,
			avoidGround             = false,
			avoidNeutral            = false,
			avoidFeature            = false,
			avoidFriendly           = false,
			collideGround           = false,
			collideNeutral          = false,
			collideFeature          = false,
			collideFriendly         = false,
			collideNonTarget        = false,
			canAttackGround         = false,
			cylinderTargeting       = 1,

			customParams            = {
				reaim_time = 1,
			},

			damage                  = {
				default = 0.1,
			},

			duration                = 0.02,
			fireStarter             = 50,
			heightMod               = 1,
			impactOnly              = true,
			impulseBoost            = 0,
			impulseFactor           = 0.4,
			interceptedByShieldType = 1,
			noSelfDamage            = true,
			range                   = 245,
			reloadtime              = 0.1,
			rgbColor                = [[1 0 0]],
			soundTrigger            = true,
			thickness               = 2.55,
			tolerance               = 10000,
			turret                  = true,
			weaponType              = [[LaserCannon]],
			weaponVelocity          = 880,
		},
	},
}

return lowerkeys({ small = unitDef })
