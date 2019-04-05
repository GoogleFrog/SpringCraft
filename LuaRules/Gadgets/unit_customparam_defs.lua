
function gadget:GetInfo()
	return {
		name      = "CustomParam Defs",
		desc      = "Implements some parameters that don't exist in the unitDefs table.",
		author    = "GoogleFrog",
		date      = "7 Sep 2014",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData
local getMovetype              = Spring.Utilities.getMovetype
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag

function gadget:UnitCreated(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local ud = UnitDefs[unitDefID]
	if getMovetype(ud) == 2 and spMoveCtrlGetTag(unitID) == nil then -- Ground/Sea
		if ud.customParams.turnaccel then
			spSetGroundMoveTypeData(unitID, "turnAccel", tonumber(ud.customParams.turnaccel))
		end
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end