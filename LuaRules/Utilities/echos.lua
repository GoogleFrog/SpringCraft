
function Spring.Utilities.UnitEcho(unitID, st)
	st = st or unitID
	if Spring.ValidUnitID(unitID) then
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid unitID")
		Spring.Echo(unitID)
		Spring.Echo(st)
	end
end

function Spring.Utilities.FeatureEcho(featureID, st)
	st = st or featureID
	if Spring.ValidFeatureID(featureID) then
		local x,y,z = Spring.GetFeaturePosition(featureID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid featureID")
		Spring.Echo(featureID)
		Spring.Echo(st)
	end
end

local function TableEcho(data, name, indent)
	name = name or "TableEcho"
	Spring.Echo((indent or "") .. name .. " = {")
	indent = indent or "    "
	for n, v in pairs(data) do
		local ty =  type(v)
		if ty == "table" then
			TableEcho(v, n, indent .. "    ")
		elseif ty == "boolean" then
			Spring.Echo(indent .. n .. " = " .. (v and "true" or "false"))
		else
			Spring.Echo(indent .. n .. " = " .. v)
		end
	end
	Spring.Echo(indent .. "}")
end

Spring.Utilities.TableEcho = TableEcho
