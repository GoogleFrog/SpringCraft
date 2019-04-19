
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name 	= "Target Priority",
		desc	= "Controls target priority because the engine seems to be based on random numbers.",
		author	= "Google Frog",
		date	= "September 25 2011", --update: 9 January 2014
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitSeparation = Spring.GetUnitSeparation

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	if not defPriority then
		-- This callin is effectively script.BlockShot but for CommandAI.
		-- The engine will discard target priority information.
		return true
	end

	return true, spGetUnitSeparation(unitID ,targetID, true)
end

function gadget:Initialize()
	for weaponID,wd in pairs(WeaponDefs) do
		if wd.customParams and wd.customParams.is_unit_weapon then
			if Script.SetWatchAllowTarget then
				Script.SetWatchAllowTarget(weaponID, true)
			else
				Script.SetWatchWeapon(weaponID, true)
			end
		end
	end
end
