--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    weapondefs_post.lua
--  brief:   weaponDef post processing
--  author:  Dave Rodgers
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Per-unitDef weaponDefs
--

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end

local function hs2rgb(h, s)
	--// FIXME? ignores saturation completely
	s = 1

	local invSat = 1 - s

	if (h > 0.5) then h = h + 0.1 end
	if (h > 1.0) then h = h - 1.0 end

	local r = invSat / 2.0
	local g = invSat / 2.0
	local b = invSat / 2.0

	if (h < (1.0 / 6.0)) then
		r = r + s
		g = g + s * (h * 6.0)
	elseif (h < (1.0 / 3.0)) then
		g = g + s
		r = r + s * ((1.0 / 3.0 - h) * 6.0)
	elseif (h < (1.0 / 2.0)) then
		g = g + s
		b = b + s * ((h - (1.0 / 3.0)) * 6.0)
	elseif (h < (2.0 / 3.0)) then
		b = b + s
		g = g + s * ((2.0 / 3.0 - h) * 6.0)
	elseif (h < (5.0 / 6.0)) then
		b = b + s
		r = r + s * ((h - (2.0 / 3.0)) * 6.0)
	else
		r = r + s
		b = b + s * ((3.0 / 3.0 - h) * 6.0)
	end

	return ("%0.3f %0.3f %0.3f"):format(r,g,b)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ProcessUnitDef(udName, ud)

	local wds = ud.weapondefs
	if (not istable(wds)) then
		return
	end

	-- add this unitDef's weaponDefs
	for wdName, wd in pairs(wds) do
		if (isstring(wdName) and istable(wd)) then
			local fullName = udName .. '_' .. wdName
			WeaponDefs[fullName] = wd
		end
		
		wd.customparams = wd.customparams or {}
		wd.customparams.is_unit_weapon = 1
	end

	-- convert the weapon names
	local weapons = ud.weapons
	if (istable(weapons)) then
		for i = 1, 32 do
			local w = weapons[i]
			if (istable(w)) then
				if (isstring(w.def)) then
					local ldef = string.lower(w.def)
					local fullName = udName .. '_' .. ldef
					local wd = WeaponDefs[fullName]
					if (istable(wd)) then
						w.name = fullName
					end
				end
				w.def = nil
			end
		end
	end

	-- convert the death explosions
	if (isstring(ud.explodeas)) then
		local fullName = udName .. '_' .. ud.explodeas
		if (WeaponDefs[fullName]) then
			ud.explodeas = fullName
		end
	end
	if (isstring(ud.selfdestructas)) then
		local fullName = udName .. '_' .. ud.selfdestructas
		if (WeaponDefs[fullName]) then
			ud.selfdestructas = fullName
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Process the unitDefs
local UnitDefs = DEFS.unitDefs

for udName, ud in pairs(UnitDefs) do
	if (isstring(udName) and istable(ud)) then
		ProcessUnitDef(udName, ud)
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
