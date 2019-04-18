
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
local spSetUnitMidAndAimPos    = Spring.SetUnitMidAndAimPos
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight

local function UnpackInt3(str)
	local index = 0
	local ret = {}
	for i = 1,3 do
		ret[i] = str:match("[-]*%d+", index)
		index = (select(2, str:find(ret[i], index)) or 0) + 1
	end
	return ret
end

local leashRangeUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modelRadii = {}
local leashRangeDefs = {}
for i = 1,#UnitDefs do
	local ud = UnitDefs[i]
	local midPosOffset = ud.customParams.midposoffset
	local aimPosOffset = ud.customParams.aimposoffset
	local modelRadius  = ud.customParams.modelradius
	local modelHeight  = ud.customParams.modelheight
	if midPosOffset or aimPosOffset then
		local mid = (midPosOffset and UnpackInt3(midPosOffset)) or {0,0,0}
		local aim = (aimPosOffset and UnpackInt3(aimPosOffset)) or mid
		offsets[i] = {
			mid = mid,
			aim = aim,
		}
	end
	if modelRadius or modelHeight then
		modelRadii[i] = true -- mark that we need to initialize this
	end
	
	if ud.customParams.leash_range then
		leashRangeDefs[i] = tonumber(ud.customParams.leash_range)
	end
end

local function GetModelRadii(unitDefID)
	if modelRadii[unitDefID] == true then
		local ud = UnitDefs[unitDefID]
		local modelRadius = ud.customParams.modelradius
		local modelHeight = ud.customParams.modelheight
		modelRadii[unitDefID] = {
			radius = (modelRadius and tonumber(modelRadius) or ud.radius),
			height = (modelHeight and tonumber(modelHeight) or ud.height),
		}
	end

	return modelRadii[unitDefID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local reaimTimeDefs = {}

for udID = 1, #UnitDefs do
	local weapons = UnitDefs[udID].weapons
	for i = 1, #weapons do
		local wd = WeaponDefs[weapons[i].weaponDef]
		if wd and wd.customParams.reaim_time then
			reaimTimeDefs[udID] = reaimTimeDefs[udID] or {}
			reaimTimeDefs[udID][i] = tonumber(wd.customParams.reaim_time)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	if getMovetype(ud) == 2 and spMoveCtrlGetTag(unitID) == nil then -- Ground/Sea
		if ud.customParams.turnaccel then
			spSetGroundMoveTypeData(unitID, "turnAccel", tonumber(ud.customParams.turnaccel))
		end
	end
	
	if modelRadii[unitDefID] then
		local mr = GetModelRadii(unitDefID)
		spSetUnitRadiusAndHeight(unitID, mr.radius, mr.height)
	end
	
	if reaimTimeDefs[unitDefID] then
		for weaponNum, reaimTime in pairs(reaimTimeDefs[unitDefID]) do
			Spring.SetUnitWeaponState(unitID, weaponNum, "reaimTime", reaimTime)
		end
	end
	
	if leashRangeDefs[unitDefID] then
		leashRangeDefs[unitID] = leashRangeDefs[unitDefID]
	else
		leashRangeDefs[unitID] = nil
	end
end

function gadget:AllowUnitTargetRange(unitID, aquireRange)
	return true, (unitID and leashRangeDefs[unitID]) or aquireRange
end

function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	return true, defPriority
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
	
	for weaponID,wd in pairs(WeaponDefs) do
		if wd.customParams and wd.customParams.is_unit_weapon then
			Script.SetWatchWeapon(weaponID, true)
		end
	end
end