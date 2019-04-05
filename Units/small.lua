unitDef = {
	unitname               = [[shieldraid]],
	name                   = [[Bandit]],
	description            = [[Small unit]],
	acceleration           = 0.5,
	brakeRate              = 0.4,
	buildCostMetal         = 75,
	canGuard               = true,
	canMove                = true,
	canPatrol              = true,
	collisionVolumeOffsets = [[0 0 0]],
	collisionVolumeScales  = [[24 29 24]],
	collisionVolumeType    = [[cylY]],
	explodeAs              = [[SMALL_UNITEX]],
	footprintX             = 2,
	footprintZ             = 2,
	idleAutoHeal           = 0,
	idleTime               = 1800,
	maxDamage              = 265,
	maxSlope               = 36,
	maxVelocity            = 3,
	maxWaterDepth          = 0,
	movementClass          = [[SMALL_UNIT]],
	objectName             = [[mbot.s3o]],
	script                 = [[small.lua]],
	sightDistance          = 500,
	turnRate               = 2500,
	upright                = true,

	customParams           = {
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
