
function gadget:GetInfo()
	return {
		name      = "Test",
		desc      = "Tests Stuff",
		author    = "GoogleFrog",
		date      = "12 Sep 2011",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	--Spring.Utilities.UnitEcho(unitID, unitDefID)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
