
function gadget:GetInfo()
	return {
		name      = "Dev Commands",
		desc      = "Adds useful commands.",
		author    = "Google Frog",
		date      = "12 Sep 2011",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spIsCheatingEnabled = Spring.IsCheatingEnabled

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function MoveUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 3) then 
		return
	end
	local unitID = tonumber(words[1])
	local x = tonumber(words[2])
	local z = tonumber(words[3])
	
	if not (unitID and x and z) then
		return
	end
	
	Spring.SetUnitPosition(unitID, x, z)
end

local function DestroyUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 1) then 
		return
	end
	local unitID = tonumber(words[1])
	if unitID then
		Spring.DestroyUnit(unitID, false, true)
	end
end

local function RotateUnit(cmd, line, words, player)
	if not (spIsCheatingEnabled() and #words >= 2) then 
		return
	end
	local unitID = tonumber(words[1])
	local facing = tonumber(words[2])
	if not (unitID and facing and Spring.ValidUnitID(unitID)) or Spring.GetUnitIsDead(unitID) then
		return
	end
	local teamID = Spring.GetUnitTeam(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if ud.isImmobile then
		x, z = SanitizeBuildPositon(x, z, ud, facing)
	end
	
	Spring.DestroyUnit(unitID, false, true)
	Spring.CreateUnit(unitDefID, x, y, z, facing, teamID)
end

local function gentleKill(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.SetUnitHealth(unitID,0.1)
			Spring.AddUnitDamage(unitID,1, 0, nil, -7)
		end
	end
end

local function damage(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.SetUnitHealth(unitID,1)
		end
	end
end

local function clearFeatures(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local features = Spring.GetAllFeatures()
		for i=1, #features do
			local featureID = features[i]
			Spring.DestroyFeature(featureID)
		end
	end
end

local function clearUnits(cmd,line,words,player)
	if spIsCheatingEnabled() then
		local units = Spring.GetAllUnits()
		for i=1, #units do
			local unitID = units[i]
			Spring.DestroyUnit(unitID, false, true)
		end
	end
end

local function clear(cmd,line,words,player)
	clearFeatures(cmd,line,words,player)
	uclear(cmd,line,words,player)
end

function gadget:Initialize()
	gadgetHandler.actionHandler.AddChatAction(self,"moveunit", MoveUnit, "Moves a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"destroyunit", DestroyUnit, "Destroys a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"rotateunit", RotateUnit, "Rotates a unit.")
	gadgetHandler.actionHandler.AddChatAction(self,"gk",gentleKill,"Gently kills everything.")
	gadgetHandler.actionHandler.AddChatAction(self,"damage",damage,"Damages everything.")
	gadgetHandler.actionHandler.AddChatAction(self,"clear",clear,"Clears all units and wreckage.")
	gadgetHandler.actionHandler.AddChatAction(self,"cu",clearUnits,"Clears all units.")
	gadgetHandler.actionHandler.AddChatAction(self,"cf",clearFeatures,"Clears all features.")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

end
   
