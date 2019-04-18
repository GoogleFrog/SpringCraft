function gadget:GetInfo()
	return {
		name 	= "Command Raw Move",
		desc	= "Make unit move ahead at all cost!",
		author	= "xponen, GoogleFrog",
		date	= "June 12 2014",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true,
	}
end
include("LuaRules/Configs/customcmds.lua")

if gadgetHandler:IsSyncedCode() then

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Speedups

local spGetUnitPosition   = Spring.GetUnitPosition
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spMoveCtrlGetTag    = Spring.MoveCtrl.GetTag
local spGetCommandQueue   = Spring.GetCommandQueue

local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ

local CMD_STOP    = CMD.STOP
local CMD_INSERT  = CMD.INSERT
local CMD_REMOVE  = CMD.REMOVE
local CMD_REPAIR  = CMD.REPAIR
local CMD_RECLAIM = CMD.RECLAIM
local CMD_MOVE    = CMD.MOVE

local MAX_UNITS = Game.maxUnits

local rawBuildUpdateIgnore = {
	[CMD.ONOFF] = true,
	[CMD.FIRE_STATE] = true,
	[CMD.MOVE_STATE] = true,
	[CMD.REPEAT] = true,
	[CMD.CLOAK] = true,
	[CMD.STOCKPILE] = true,
	[CMD.TRAJECTORY] = true,
	[CMD.IDLEMODE] = true,
}

local stopCommand = {
	[CMD.GUARD] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[CMD.PATROL] = true,
	[CMD.FIGHT] = true,
	[CMD.MOVE] = true,
}

local queueFrontCommand = {
	[CMD.WAIT] = true,
	[CMD.TIMEWAIT] = true,
	[CMD.DEATHWAIT] = true,
	[CMD.SQUADWAIT] = true,
	[CMD.GATHERWAIT] = true,
}

local DIRANGLE = {
	{0.71,   0.71},
	{0,  1},
	{-0.71,  0.71},
	{-1, 0},
	{-0.71, -0.71},
	{0, -1},
	{0.71,  -0.71},
	{1,  0},
}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Commmands

local moveRawCmdDesc = {
	id      = CMD_RAW_MOVE,
	type    = CMDTYPE.ICON_MAP,
	name    = 'Move',
	cursor  = 'Move', -- add with LuaUI?
	action  = 'rawmove',
	tooltip = 'Move: Order the unit to move to a position.',
}

local attackRawCmdDesc = {
	id      = CMD_RAW_ATTACK,
	type    = CMDTYPE.ICON_UNIT_OR_MAP,
	name    = 'Attack',
	cursor  = 'Attack', -- add with LuaUI?
	action  = 'rawattack',
	tooltip = 'Attack: Fire at a unit or move to a position, stoping to attack along the way.',
}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Data

local canMoveDefs = {}
local canFlyDefs = {}
local goalDist = {}
local turnDiameterSq = {}
local turnPeriods = {}
local stopDistSq = {}
local loneStopDistSq = {}
local stoppingRadiusIncrease = {}
local stuckTravelOverride = {}
local startMovingTime = {}

-- Check unit queues because perhaps CMD_RAW_MOVE is not the first command anymore
local unitQueueCheckRequired = false
local unitQueuesToCheck = {}

local attackMoveUnit = {}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Configuration

local TEST_MOVE_SPACING = 16
local LAZY_TEST_MOVE_SPACING = 8
local LAZY_SEARCH_DISTANCE = 450
local BLOCK_RELAX_DISTANCE = 250
local STUCK_TRAVEL = 25
local STUCK_MOVE_RANGE = 140
local GIVE_UP_STUCK_DIST_SQ = 250^2
local STOP_STOPPING_RADIUS = 10000000
local RAW_CHECK_SPACING = 500
local MAX_COMM_STOP_RADIUS = 400^2
local COMMON_STOP_RADIUS_ACTIVE_DIST_SQ = 120^2 -- Commands shorter than this do not activate common stop radius.

local CONSTRUCTOR_UPDATE_RATE = 30
local CONSTRUCTOR_TIMEOUT_RATE = 2

local MAX_FORMATION_RADIUS = 65
local FORMATION_SHRINK = 0.97

local STOP_RADIUS_INC_FACTOR = 1.2
local STOP_DIST_FACTOR = 1.5

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Configuration
local constructorBuildDistDefs = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canMove then
		if ud.isMobileBuilder and (not ud.isAirUnit) then
			constructorBuildDistDefs[i] = math.max(50, ud.buildDistance  - 10)
		end

		canMoveDefs[i] = true
		local stopDist = ud.xsize*8*STOP_DIST_FACTOR
		local loneStopDist = 16
		local turningDiameter = 2*(ud.speed*2195/(ud.turnRate * 2 * math.pi))
		if turningDiameter > 20 then
			turnDiameterSq[i] = turningDiameter*turningDiameter
		end
		if ud.turnRate > 150 then
			turnPeriods[i] = math.ceil(1100/ud.turnRate)
		else
			turnPeriods[i] = 8
		end
		if (ud.moveDef.maxSlope or 0) > 0.8 and ud.speed < 60 then
			-- Slow spiders need a lot of leeway when climing cliffs.
			stuckTravelOverride[i] = 5
			startMovingTime[i] = 12 -- May take longer to start moving
			-- Lower stopping distance for more precise placement on terrain
			loneStopDist = 4
		end
		if ud.canFly then
			canFlyDefs[i] = true
			stopDist = ud.speed
			loneStopDist = ud.speed*0.66
			if ud.isHoveringAirUnit then
				stopDist = math.min(stopDist, 120)
				loneStopDist = math.min(loneStopDist, 80)
			end
			goalDist[i] = 8
		end
		if stopDist then
			stopDistSq[i] = stopDist*stopDist
		end
		loneStopDistSq[i] = (loneStopDist and loneStopDist*loneStopDist) or stopDistSq[i] or 256
		if stopDist and not goalDist[i] then
			goalDist[i] = loneStopDist
		end
		stoppingRadiusIncrease[i] = ud.xsize*250*STOP_RADIUS_INC_FACTOR
	end
end

-- Debug
--local oldSetMoveGoal = Spring.SetUnitMoveGoal
--function Spring.SetUnitMoveGoal(unitID, x, y, z, radius, speed, raw)
--	oldSetMoveGoal(unitID, x, y, z, radius, speed, raw)
--	Spring.MarkerAddPoint(x, y, z, ((raw and "r") or "") .. (radius or 0))
--end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Variables

local rawMoveUnit = {}
local commonStopRadius = {}
local oldCommandStoppingRadius = {}
local commandCount = {}
local oldCommandCount = {}
local fromFactory = {}
local unitsWithCommand = {}

local constructors = {}
local constructorBuildDist = {}
local constructorByID = {}
local constructorCount = 0
local constructorsPerFrame = 0
local constructorIndex = 1
local alreadyResetConstructors = false

local moveCommandReplacementUnits
local fastConstructorUpdate

local delayedInit = {}
local handleInGameFrame

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Utilities

local function IsPathFree(unitDefID, sX, sZ, gX, gZ, distance, testSpacing, distanceLimit, goalDistance, blockRelaxDistance)
	local vX = gX - sX
	local vZ = gZ - sZ
	-- distance had better be math.sqrt(vX*vX + vZ*vZ) or things will break
	if distance < testSpacing then
		return true
	end
	vX, vZ = vX/distance, vZ/distance
	local orginDistance = distance
	if goalDistance then
		distance = distance - goalDistance
	end

	if distanceLimit and (distance > distanceLimit) then
		if blockRelaxDistance then
			blockRelaxDistance = blockRelaxDistance - distance + distanceLimit
			if blockRelaxDistance < testSpacing then
				blockRelaxDistance = false
			end
		end
		distance = distanceLimit
	end

	local blockedDistance = false
	for test = 0, distance, testSpacing do
		if not Spring.TestMoveOrder(unitDefID, sX + test*vX, 0, sZ + test*vZ) then
			blockedDistance = test
			break
		end
	end
	
	
	if (not blockedDistance) or (not blockRelaxDistance) or (blockedDistance == 0) or ((distance - blockedDistance) > blockRelaxDistance) then
		return (not blockedDistance)
	end
	
	-- Don't take goalDistance into account when stopping early due to blockage.
	distance = orginDistance
	local relaxX, relaxZ
	for test = distance, blockedDistance - testSpacing, -testSpacing do
		if Spring.TestMoveOrder(unitDefID, sX + test*vX, 0, sZ + test*vZ) then
			if not relaxX then
				relaxX, relaxZ = sX + test*vX, sZ + test*vZ
			end
		elseif relaxX then
			return false, relaxX, relaxZ
		end
	end
	
	return true, relaxX, relaxZ
end

local function ResetUnitData(unitData)
	unitData.cx = nil
	unitData.cz = nil
	unitData.mx = nil
	unitData.mz = nil
	unitData.switchedFromRaw = nil
	unitData.nextTestTime = nil
	unitData.commandHandled = nil
	unitData.stuckCheckTimer = nil
	unitData.handlingWaitTime = nil
	unitData.nextRawCheckDistSq = nil
	unitData.doingRawMove = nil
	unitData.possiblyTurning = nil
	unitData.xOff = nil
	unitData.zOff = nil
	unitData.initComplete = nil
end

local function ResetToInitUnitData(unitData)
	unitData.toinit_cmdStr = nil
	unitData.toinit_cmdStrOffsetX = nil
	unitData.toinit_cmdStrOffsetZ = nil
end

local function ProcessUnitCommandOffets(unitDefID, cmdStr, cx, cz)
	local unitList = unitsWithCommand[cmdStr]
	unitsWithCommand[cmdStr] = nil

	-- Check whether all this is necessary
	if (not unitList) or (#unitList <= 1) or (not Spring.TestMoveOrder(unitDefID, cx, 0, cz)) then
		return
	end
	
	-- Find average unit position and offset
	local xOff = {}
	local zOff = {}
	local avX, avZ = 0, 0
	local count = 0
	for i = 1, #unitList do
		local unitID = unitList[i]
		local x, _, z = spGetUnitPosition(unitID)
		if x then
			xOff[i] = x
			zOff[i] = z
			avX, avZ = avX + x, avZ + z
			count = count + 1
			--Spring.MarkerAddPoint(x, 0, z, i)
		end
	end
	
	if count <= 1 then
		return
	end
	avX, avZ = avX/count, avZ/count
	--Spring.MarkerAddPoint(avX, 0, avZ, "av")
	
	local dist = {}
	local maxUnitDist
	local avDist = 0
	for i = 1, #unitList do
		if xOff[i] then
			xOff[i] = xOff[i] - avX
			zOff[i] = zOff[i] - avZ
			dist[i] = math.sqrt(xOff[i]*xOff[i] + zOff[i]*zOff[i])
			avDist = avDist + dist[i]
			if (not maxUnitDist) or (maxUnitDist < dist[i]) then
				maxUnitDist = dist[i]
			end
		end
	end
	avDist = avDist/count
	
	if not maxUnitDist then
		return
	end
	
	-- Calculate the space available in the target location
	local targetRadius
	local maxFormRadius = math.min(maxUnitDist, MAX_FORMATION_RADIUS)
	local step = MAX_FORMATION_RADIUS/2
	for r = step, maxFormRadius, step do
		for dir = 1, 8 do
			if not Spring.TestMoveOrder(unitDefID, cx + r*DIRANGLE[dir][1], 0, cz + r*DIRANGLE[dir][2]) then
				targetRadius = r - step
				break
			end
		end
		if targetRadius then
			break
		end
	end
	targetRadius = targetRadius or maxFormRadius
	
	--Spring.Echo("avDist", avDist, "targetRadius", targetRadius, "maxUnitDist", maxUnitDist)
	if avDist > targetRadius then
		targetRadius = targetRadius*targetRadius/avDist
	end
	
	-- Calculate the offset for each unit
	for i = 1, #unitList do
		if xOff[i] then
			xOff[i] = xOff[i]*FORMATION_SHRINK*targetRadius/maxUnitDist
			zOff[i] = zOff[i]*FORMATION_SHRINK*targetRadius/maxUnitDist
			
			--Spring.MarkerAddPoint(xOff[i] + cx, 0, zOff[i] + cz, i)
			
			local unitID = unitList[i]
			rawMoveUnit[unitID] = rawMoveUnit[unitID] or {}
			rawMoveUnit[unitID].toinit_cmdStr = cmdStr
			rawMoveUnit[unitID].toinit_cmdStrOffsetX = xOff[i]
			rawMoveUnit[unitID].toinit_cmdStrOffsetZ = zOff[i]
		end
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Raw Move Handling

local function StopUnit(unitID, stopNonRaw)
	if not rawMoveUnit[unitID] then
		return
	end
	if stopNonRaw or not rawMoveUnit[unitID].switchedFromRaw then
		Spring.ClearUnitGoal(unitID)
	end
	rawMoveUnit[unitID] = nil
	--Spring.Echo("StopUnit", math.random())
end

local function HandleRawMove(unitID, unitDefID, cmdParams)
	if spMoveCtrlGetTag(unitID) then
		return true, false
	end
	if #cmdParams < 3 then
		return true, true
	end

	local mx, my, mz = cmdParams[1], cmdParams[2], cmdParams[3]
	if mx < 0 or mx >= mapSizeX or mz < 0 or mz >= mapSizeZ then
		return true, true
	end

	local goalDistOverride = cmdParams[4]
	local timerIncrement = cmdParams[5] or 1
	if not rawMoveUnit[unitID] then
		rawMoveUnit[unitID] = {}
	end
	
	local unitData = rawMoveUnit[unitID]
	if not (unitData.cx == mx and unitData.cz == mz) then
		ResetUnitData(unitData)
	end
	if unitData.handlingWaitTime then
		unitData.handlingWaitTime = unitData.handlingWaitTime - timerIncrement
		if unitData.handlingWaitTime <= 0 then
			unitData.handlingWaitTime = nil
		end
		return true, false
	end
	
	if not unitData.cx then
		local cx, cz = cmdParams[1], cmdParams[3]
		unitData.cx, unitData.cz = cx, cz
		unitData.commandString = cx .. "_" .. cz
		commandCount[unitData.commandString] = (commandCount[unitData.commandString] or 0) + 1
	end
	
	if unitData.commandString then
		if not commandCount[unitData.commandString] then
			commandCount[unitData.commandString] = oldCommandCount[unitData.commandString] or 1
		end
		if unitsWithCommand[unitData.commandString] then
			ProcessUnitCommandOffets(unitDefID, unitData.commandString, mx, mz)
		end
	end
	
	if unitData.toinit_cmdStr then
		if unitData.toinit_cmdStr == unitData.commandString then
			if unitData.toinit_cmdStrOffsetX then
				unitData.xOff = unitData.toinit_cmdStrOffsetX
				unitData.zOff = unitData.toinit_cmdStrOffsetZ
			end
			ResetToInitUnitData(unitData)
		end
	end

	mx = mx + (unitData.xOff or 0)
	mz = mz + (unitData.zOff or 0)

	local x, y, z = spGetUnitPosition(unitID)
	local distSq = (x - (unitData.mx or mx))^2 + (z - (unitData.mz or mz))^2

	if not unitData.initComplete then
		unitData.preventGoalClumping = (not goalDistOverride) and (distSq > COMMON_STOP_RADIUS_ACTIVE_DIST_SQ) and not select(4, Spring.GetUnitStates(unitID, false, true))
		unitData.initComplete = true
	end

	if unitData.preventGoalClumping and unitData.commandString and not commonStopRadius[unitData.commandString] then
		commonStopRadius[unitData.commandString] = oldCommandStoppingRadius[unitData.commandString] or 0
	end

	local alone = (commandCount[unitData.commandString] <= 1)
	local myStopDistSq = (goalDistOverride and goalDistOverride*goalDistOverride) or (alone and loneStopDistSq[unitDefID]) or stopDistSq[unitDefID] or 256
	if unitData.preventGoalClumping then
		myStopDistSq = myStopDistSq + commonStopRadius[unitData.commandString]
	end

	if distSq < myStopDistSq then
		if unitData.preventGoalClumping then
			commonStopRadius[unitData.commandString] = (commonStopRadius[unitData.commandString] or 0) + stoppingRadiusIncrease[unitDefID]
			if commonStopRadius[unitData.commandString] > MAX_COMM_STOP_RADIUS then
				commonStopRadius[unitData.commandString] = MAX_COMM_STOP_RADIUS
			end
		end
		StopUnit(unitID, true)
		return true, true
	end

	if canFlyDefs[unitDefID] then
		if unitData.commandHandled then
			return true, false
		end
		unitData.switchedFromRaw = true
		unitData.commandHandled = true
		Spring.SetUnitMoveGoal(unitID, mx, my, mz, goalDistOverride or goalDist[unitDefID] or 16, nil, false)
		return true, false
	end

	if not unitData.stuckCheckTimer then
		unitData.ux, unitData.uz = x, z
		unitData.stuckCheckTimer = (startMovingTime[unitDefID] or 8)
		if distSq > GIVE_UP_STUCK_DIST_SQ then
			unitData.stuckCheckTimer = unitData.stuckCheckTimer + math.floor(math.random()*8)
		end
	end
	unitData.stuckCheckTimer = unitData.stuckCheckTimer - timerIncrement

	if unitData.stuckCheckTimer <= 0 then
		local oldX, oldZ = unitData.ux, unitData.uz
		local travelled = math.abs(oldX - x) + math.abs(oldZ - z)
		unitData.ux, unitData.uz = x, z
		if travelled < (stuckTravelOverride[unitDefID] or STUCK_TRAVEL) then
			unitData.stuckCheckTimer = math.floor(math.random()*6) + 5
			if distSq < GIVE_UP_STUCK_DIST_SQ then
				StopUnit(unitID, true)
				return true, true
			else
				local vx = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				local vz = math.random()*2*STUCK_MOVE_RANGE - STUCK_MOVE_RANGE
				Spring.SetUnitMoveGoal(unitID, x + vx, y, z + vz, 16, nil, false)
				unitData.commandHandled = nil
				unitData.switchedFromRaw = nil
				unitData.nextTestTime = nil
				unitData.doingRawMove = nil
				unitData.handlingWaitTime = math.floor(math.random()*4) + 2
				return true, false
			end
		else
			unitData.stuckCheckTimer = 4 + math.min(6, math.floor(distSq/500))
			if distSq > GIVE_UP_STUCK_DIST_SQ then
				unitData.stuckCheckTimer = unitData.stuckCheckTimer + math.floor(math.random()*10)
			end
		end
	end

	if unitData and unitData.switchedFromRaw then
		if unitData.nextRawCheckDistSq and (unitData.nextRawCheckDistSq > distSq) then
			unitData.switchedFromRaw = nil
			unitData.nextTestTime = nil
		else
			return true, false
		end
	end

	unitData.nextTestTime = (unitData.nextTestTime or 0) - timerIncrement
	if unitData.nextTestTime <= 0 then
		local lazy = unitData.doingRawMove
		local freePath
		if (turnDiameterSq[unitDefID] or 0) > distSq then
			freePath = false
		else
			local distance = math.sqrt(distSq)
			local rx, rz
			freePath, rx, rz = IsPathFree(unitDefID, x, z, mx, mz, distance, TEST_MOVE_SPACING, lazy and LAZY_SEARCH_DISTANCE, goalDistOverride and (goalDistOverride - 20), BLOCK_RELAX_DISTANCE)
			if rx then
				mx, my, mz = rx, Spring.GetGroundHeight(rx, rz), rz
			end
			if (not freePath) then
				unitData.nextRawCheckDistSq = (distance - RAW_CHECK_SPACING)*(distance - RAW_CHECK_SPACING)
			end
		end
		if (not unitData.commandHandled) or unitData.doingRawMove ~= freePath then
			Spring.SetUnitMoveGoal(unitID, mx, my, mz, goalDist[unitDefID] or 16, nil, freePath)
			unitData.mx, unitData.mz = mx, mz
			unitData.nextTestTime = math.floor(math.random()*2) + turnPeriods[unitDefID]
			unitData.possiblyTurning = true
		elseif unitData.possiblyTurning then
			unitData.nextTestTime = math.floor(math.random()*2) + turnPeriods[unitDefID]
			unitData.possiblyTurning = false
		else
			unitData.nextTestTime = math.floor(math.random()*5) + 6
		end

		unitData.doingRawMove = freePath
		unitData.switchedFromRaw = not freePath
	end

	if not unitData.commandHandled then
		unitData.commandHandled = true
	end
	return true, false
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Attack Handling

local function CheckAttackMove(unitID)
	local tarType, isUser, targetID = Spring.GetUnitWeaponTarget(unitID, 1)
	if targetID then
		--Spring.Utilities.UnitEcho(targetID, "t")
		if Spring.GetUnitWeaponTestRange(unitID, 1, targetID) then
			StopUnit(unitID, true)
			return true
		end
	end
	return false
end

local function CheckAllAttackMoveUnits()
	for unitID, _ in pairs(attackMoveUnit) do
		local cmdID, _, cmdTag, cmdParam_1, cmdParam_2, cmdParam_3 = Spring.GetUnitCurrentCommand(unitID)
		if cmdID == CMD_RAW_ATTACK and cmdParam_3 then
			CheckAttackMove(unitID)
		else
			attackMoveUnit[unitID] = nil
		end
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Command Handling

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if not (cmdID == CMD_RAW_MOVE or (cmdID == CMD_RAW_ATTACK and #cmdParams > 1) or cmdID == CMD_RAW_BUILD) then
		return false
	end
	if cmdID == CMD_RAW_ATTACK then
		attackMoveUnit[unitID] = true
		if CheckAttackMove(unitID) then
			return true, false
		end
	end
	if delayedInit[unitID] then
		if (delayedInit[unitID] == (cmdParams[1] or 0) .. "_" .. (cmdParams[3] or 0)) then
			handleInGameFrame = handleInGameFrame or {}
			handleInGameFrame[#handleInGameFrame + 1] = {unitID, unitDefID, cmdParams}
			delayedInit[unitID] = nil
			return true, false
		end
		delayedInit[unitID] = nil
	end
	local cmdUsed, cmdRemove = HandleRawMove(unitID, unitDefID, cmdParams)
	return cmdUsed, cmdRemove
end

local function CheckUnitQueues()
	for unitID,_ in pairs(unitQueuesToCheck) do
		if Spring.GetUnitCurrentCommand(unitID) ~= CMD_RAW_MOVE then
			StopUnit(unitID)
		end
		unitQueuesToCheck[unitID] = nil
	end
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
	if cmdID == CMD_STOP then
		-- Handling for shift clicking on commands to remove.
		StopUnit(unitID)
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_MOVE and not canFlyDefs[unitDefID] then
		moveCommandReplacementUnits = moveCommandReplacementUnits or {}
		moveCommandReplacementUnits[#moveCommandReplacementUnits + 1] = unitID
	end

	if constructorBuildDistDefs[unitDefID] and not rawBuildUpdateIgnore[cmdID] then
		fastConstructorUpdate = fastConstructorUpdate or {}
		fastConstructorUpdate[#fastConstructorUpdate + 1] = unitID
		--Spring.Utilities.UnitEcho(unitID, cmdID)
	end

	if canMoveDefs[unitDefID] then
		if cmdID == CMD_STOP or ((not cmdOptions.shift) and (cmdID < 0 or stopCommand[cmdID])) then
			StopUnit(unitID)
		elseif cmdID == CMD_INSERT and (cmdParams[1] == 0 or not cmdOptions.alt) then
			StopUnit(unitID)
		elseif queueFrontCommand[cmdID] then
			unitQueueCheckRequired = true
			unitQueuesToCheck[unitID] = true
		end
	else
		if cmdID == CMD_INSERT then
			cmdID = cmdParams[2]
		end
		if cmdID == CMD_RAW_MOVE then
			return false
		end
	end

	if cmdID == CMD_RAW_MOVE and cmdParams[3] then
		local cmdStr = cmdParams[1] .. "_" .. cmdParams[3]
		delayedInit[unitID] = cmdStr
		unitsWithCommand[cmdStr] = unitsWithCommand[cmdStr] or {}
		unitsWithCommand[cmdStr][#unitsWithCommand[cmdStr] + 1] = unitID
	end
	return true
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Constructor Handling

local function GetConstructorCommandPos(cmdID, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6, unitID)
	if cmdID == CMD_RAW_BUILD then
		cmdID, _, _, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6 = Spring.GetUnitCurrentCommand(unitID, 2)
	end
	if not cmdID then
		return false
	end

	if cmdID < 0 then
		return cp_1, cp_2, cp_3
	end

	if cmdID == CMD_REPAIR then
		-- (#cmd.params == 5 or #cmd.params == 1)
		if (cp_1 and not cp_2) or (cp_5 and not cp_6) then
			local unitID = cp_1
			local unitDefID = Spring.GetUnitDefID(unitID)
			if unitDefID and not canMoveDefs[unitDefID] then
				-- Don't try to chase moving units with raw move.
				local x, y, z = Spring.GetUnitPosition(unitID)
				if x then
					return x, y, z
				end
			end
		end
	end

	if cmdID == CMD_RECLAIM then
		-- (#cmd.params == 5 or #cmd.params == 1)
		if (cp_1 and not cp_2) or (cp_5 and not cp_6) then
			local x, y, z = Spring.GetFeaturePosition(cp_1 - MAX_UNITS)
			if x then
				return x, y, z
			end
		end
	end
end

local function CheckConstructorBuild(unitID)
	local buildDist = constructorBuildDist[unitID]
	if not buildDist then
		return
	end
	
	local cmdID, _, cmdTag, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6 = Spring.GetUnitCurrentCommand(unitID)
	if not cmdID then
		return
	end
	local cx, cy, cz = GetConstructorCommandPos(cmdID, cp_1, cp_2, cp_3, cp_4, cp_5, cp_6, unitID)

	if cmdID == CMD_RAW_BUILD and cp_3 then
		if (not cx) or math.abs(cx - cp_1) > 3 or math.abs(cz - cp_3) > 3 then
			Spring.GiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
			StopUnit(unitID, true)
		end
		return
	end

	if cx then
		local x,_,z = Spring.GetUnitPosition(unitID)
		local buildDistSq = (buildDist + 30)^2
		local distSq = (cx - x)^2 + (cz - z)^2
		if distSq > buildDistSq then
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD_RAW_BUILD, 0, cx, cy, cz, buildDist, CONSTRUCTOR_TIMEOUT_RATE}, CMD.OPT_ALT)
		end
	end
end

local function AddConstructor(unitID, buildDist)
	if not constructorByID[unitID] then
		constructorCount = constructorCount + 1
		constructors[constructorCount] = unitID
		constructorByID[unitID] = constructorCount
	end
	constructorBuildDist[unitID] = buildDist
	constructorsPerFrame = math.ceil(constructorCount/CONSTRUCTOR_UPDATE_RATE)
end

local function ResetConstructors()
	if alreadyResetConstructors then
		Spring.Echo("LUA_ERRRUN", "ResetConstructors already reset")
		return
	end
	
	alreadyResetConstructors = true
	Spring.Echo("LUA_ERRRUN", "ResetConstructors", constructorCount, constructorsPerFrame, constructorIndex)
	Spring.Utilities.TableEcho(constructorBuildDist, "constructorBuildDist")
	Spring.Utilities.TableEcho(constructorByID, "constructorByID")
	
	constructors = {}
	constructorBuildDist = {}
	constructorByID = {}
	constructorCount = 0
	constructorsPerFrame = 0
	constructorIndex = 1
	
	for _, unitID in pairs(Spring.GetAllUnits()) do
		if constructorBuildDistDefs[unitDefID] then
			AddConstructor(unitID, constructorBuildDistDefs[unitDefID])
		end
	end
end

local function RemoveConstructor(unitID)
	if not constructorByID[unitID] then
		return
	end
	
	if not constructors[constructorCount] then
		ResetConstructors()
		return
	end
	
	local index = constructorByID[unitID]

	constructors[index] = constructors[constructorCount]
	constructorBuildDist[unitID] = nil
	constructorByID[constructors[constructorCount] ] = index
	constructorByID[unitID] = nil
	constructors[constructorCount] = nil
	constructorCount = constructorCount - 1

	constructorsPerFrame = math.ceil(constructorCount/CONSTRUCTOR_UPDATE_RATE)
end

local function UpdateConstructors(n)
	if n%CONSTRUCTOR_UPDATE_RATE == 0 then
		constructorIndex = 1
	end

	local fastUpdates
	if fastConstructorUpdate then
		fastUpdates = {}
		for i = 1, #fastConstructorUpdate do
			local unitID = fastConstructorUpdate[i]
			if not fastUpdates[unitID] then
				fastUpdates[unitID] = true
				CheckConstructorBuild(unitID)
			end
		end
		fastConstructorUpdate = nil
	end

	local count = 0
	while constructors[constructorIndex] and count < constructorsPerFrame do
		if not (fastUpdates and fastUpdates[unitID]) then
			CheckConstructorBuild(constructors[constructorIndex])
		end
		constructorIndex = constructorIndex + 1
		count = count + 1
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Move replacement

local function ReplaceMoveCommand(unitID)
	local cmdID, _, cmdTag, cmdParam_1, cmdParam_2, cmdParam_3 = Spring.GetUnitCurrentCommand(unitID)

	if cmdID == CMD_MOVE and cmdParam_3 then
		if fromFactory[unitID] then
			fromFactory[unitID] = nil
		else
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD_RAW_MOVE, 0, cmdParam_1, cmdParam_2, cmdParam_3}, CMD.OPT_ALT)
		end
		Spring.GiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0)
	end
end

local function UpdateMoveReplacement()
	if not moveCommandReplacementUnits then
		return
	end

	local fastUpdates = {}
	for i = 1, #moveCommandReplacementUnits do
		local unitID = moveCommandReplacementUnits[i]
		if not fastUpdates[unitID] then
			fastUpdates[unitID] = true
			ReplaceMoveCommand(unitID)
		end
	end
	moveCommandReplacementUnits = nil
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Gadget Interface

local function WaitWaitMoveUnit(unitID)
	local unitData = unitID and rawMoveUnit[unitID]
	if unitData then
		ResetUnitData(unitData)
	end
	Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
	Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, 0)
end

local function AddRawMoveUnit(unitID)
	rawMoveUnit[unitID] = true
end

local function RawMove_IsPathFree(unitDefID, sX, sZ, gX, gZ)
	local vX = gX - sX
	local vZ = gZ - sZ
	return IsPathFree(unitDefID, sX, sZ, gX, gZ, math.sqrt(vX*vX + vZ*vZ), TEST_MOVE_SPACING)
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	fromFactory[unitID] = true
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_RAW_MOVE)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end

	GG.AddRawMoveUnit = AddRawMoveUnit
	GG.StopUnit = StopUnit
	GG.RawMove_IsPathFree = RawMove_IsPathFree
	GG.WaitWaitMoveUnit = WaitWaitMoveUnit
end

local function RemoveCommand(unitID, cmdID)
	local descID = Spring.FindUnitCmdDesc(unitID, cmdID)
	if descID then
		Spring.RemoveUnitCmdDesc(unitID, descID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if (canMoveDefs[unitDefID]) then
		spInsertUnitCmdDesc(unitID, moveRawCmdDesc)
		spInsertUnitCmdDesc(unitID, attackRawCmdDesc)
		RemoveCommand(unitID, CMD.MOVE)
		RemoveCommand(unitID, CMD.ATTACK)
		RemoveCommand(unitID, CMD.FIGHT)
	end
	if constructorBuildDistDefs[unitDefID] and not constructorByID[unitID] then
		AddConstructor(unitID, constructorBuildDistDefs[unitDefID])
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitID then
		rawMoveUnit[unitID] = nil
		if unitDefID and constructorBuildDistDefs[unitDefID] and constructorByID[unitID] then
			RemoveConstructor(unitID)
		end
	end
end

local needGlobalWaitWait = false
function gadget:GameFrame(n)
	if handleInGameFrame then
		for i = 1, #handleInGameFrame do
			if Spring.ValidUnitID(handleInGameFrame[i][1]) then
				HandleRawMove(handleInGameFrame[i][1], handleInGameFrame[i][2], handleInGameFrame[i][3])
			end
		end
		handleInGameFrame = nil
	end
	
	CheckAllAttackMoveUnits()
	
	if needGlobalWaitWait then
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			WaitWaitMoveUnit(unitID)
		end
		needGlobalWaitWait = false
	end
	
	UpdateConstructors(n)
	UpdateMoveReplacement()
	if n%247 == 4 then
		oldCommandStoppingRadius = commonStopRadius
		commonStopRadius = {}

		oldCommandCount = commandCount
		commandCount = {}
		
		if alreadyResetConstructors then
			alreadyResetConstructors = false
		end
	end
	if unitQueueCheckRequired then
		CheckUnitQueues()
		unitQueueCheckRequired = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	needGlobalWaitWait = true
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
else --UNSYNCED--
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------


function gadget:DefaultCommand(targetType, targetID)
	if not targetID then
		return CMD_RAW_MOVE
	else
		return CMD_RAW_ATTACK
	end
end

function gadget:Initialize()
	--Note: IMO we must *allow* LUAUI to draw this command. We already used to seeing skirm command, and it is informative to players.
	--Also, its informative to widget coder and allow player to decide when to manually micro units (like seeing unit stuck on cliff with jink command)
	gadgetHandler:RegisterCMDID(CMD_RAW_MOVE)
	Spring.SetCustomCommandDrawData(CMD_RAW_MOVE, "RawMove", {0.5, 1.0, 0.5, 0.7})
	Spring.AssignMouseCursor("RawMove", "cursormove", true, true)
	
	gadgetHandler:RegisterCMDID(CMD_RAW_ATTACK)
	Spring.SetCustomCommandDrawData(CMD_RAW_ATTACK, "RawAttack", {1.0, 0.2, 0.2, 0.7})
	Spring.AssignMouseCursor("RawAttack", "cursorattack", true, true)
end

end
