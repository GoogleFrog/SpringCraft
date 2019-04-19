unitDef = {
	unitname               = [[tiny]],
	name                   = [[Tiny]],
	description            = [[Tiny melee unit]],
	
	-- Abilities
	canGuard               = true,
	canMove                = true,
	canPatrol              = true,
	canAttack              = false,
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
	collisionVolumeScales  = [[25 25 25]],
	collisionVolumeType    = [[sphere]],
	objectName             = [[mbot.s3o]],
	script                 = [[small.lua]],
	footprintX             = 2,
	footprintZ             = 2,
	upright                = true,
	
	-- Movement
	movementClass          = [[SMALL_UNIT]],
	maxVelocity            = 5,
	acceleration           = 4.5,
	brakeRate              = 3.5,
	turnRate               = 0.3*33750, -- 33750 is 180 degrees in 1 frame
	stopToAttack           = true,

	-- Movement defaults
	maxReverseVelocity     = 0,
	minCollisionSpeed      = 0,
	blocking               = true,
	collide                = true,
	turnInPlace            = true,
	turnInPlaceSpeedLimit  = 10,
	turnInPlaceAngleLimit  = 0,
	pushResistant          = false, -- Sometimes set to true in LUS
	movestate              = 0,
	
	customParams           = {
		turnaccel          = 0.4*33750,
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
			beamTime                = 0.03,
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
				target_aquire_boost = 200,
			},

			damage                  = {
				default = 0.1,
			},

			duration                = 0.03,
			fireStarter             = 50,
			heightMod               = 1,
			hardStop                = true,
			impactOnly              = true,
			impulseBoost            = 0,
			impulseFactor           = 0.4,
			interceptedByShieldType = 1,
			noSelfDamage            = true,
			range                   = 32,
			reloadtime              = 1.5,
			rgbColor                = [[1 0 0]],
			soundTrigger            = true,
			targetBorder            = 1,
			thickness               = 2.55,
			tolerance               = 10000,
			turret                  = true,
			weaponType              = [[BeamLaser]],
			weaponVelocity          = 880,
		},
	},
}

return lowerkeys({ tiny = unitDef })
