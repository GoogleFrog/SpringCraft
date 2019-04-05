unitDef = {
	unitname               = [[shieldraid]],
	name                   = [[Bandit]],
	description            = [[Small unit]],
	
	-- Abilities
	canGuard               = true,
	canMove                = true,
	canPatrol              = true,
	sightDistance          = 500,
	idleAutoHeal           = 0,
	idleTime               = 1800,
	maxDamage              = 265,
	
	-- Construction
	buildCostMetal         = 75,
	maxSlope               = 36,
	maxWaterDepth          = 0,
	
	-- Size
	--collisionVolumeOffsets = [[0 0 0]],
	--collisionVolumeScales  = [[24 29 24]],
	--collisionVolumeType    = [[cylY]],
	objectName             = [[mbot.s3o]],
	script                 = [[small.lua]],
	footprintX             = 2,
	footprintZ             = 2,
	upright                = true,
	
	-- Movement
	movementClass          = [[SMALL_UNIT]],
	maxVelocity            = 3,
	acceleration           = 4,
	brakeRate              = 2,
	turnRate               = 0.18*33750, -- 33750 is 180 degrees in 1 frame
	--pushResistant          = true,

	-- Movement defaults
	maxReverseVelocity     = 0,
	minCollisionSpeed      = 1,
	blocking               = true,
	collide                = true,
	turnInPlace            = true,
	turnInPlaceSpeedLimit  = 10,
	turnInPlaceAngleLimit  = 0,
	
	customParams           = {
		turnaccel          = 0.22*33750,
	},

	weapons                = {
		{
			def                = [[WEAPON]],
			badTargetCategory  = [[FIXEDWING]],
			onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
		},
	},

	weaponDefs             = {

		WEAPON = {
			name                    = [[Laser Blaster]],
			areaOfEffect            = 8,
			coreThickness           = 0.5,
			craterBoost             = 0,
			craterMult              = 0,

			customParams        = {
			light_camera_height = 1200,
			light_radius = 120,
			},

			damage                  = {
			default = 9.53,
			subs    = 0.61,
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
