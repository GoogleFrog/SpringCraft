
function widget:GetInfo()
	return {
		name      = "cheat",
		desc      = "Cheats",
		author    = "GoogleFrog",
		date      = "Dec 30, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

include("keysym.h.lua")

local function CheatAll()
	if not Spring.IsCheatingEnabled() then
		Spring.SendCommands{"cheat"}
	end
	Spring.SendCommands{"spectator"}
	if not Spring.IsGodModeEnabled() then
		Spring.SendCommands{"godmode"}
	end
end

function widget:TextCommand(command)  
	if command == "cheatall" then
		CheatAll()
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	if key == KEYSYMS.J then
		--Spring.SendCommands{"give turretemp"}
	end
	if modifier.ctrl then
		if key == KEYSYMS.G then
			--Spring.SendCommands{"give empiricaldpser 1"}
		end
		if key == KEYSYMS.V then
			CheatAll()
		end
		if key == KEYSYMS.Q then
			Spring.SendCommands{"quitforce"}
		end
		if key == KEYSYMS.R then
			local startScript = [[[game]
{
[allyteam1]
{
numallies=0;
}
[team1]
{
teamleader=1;
allyteam=1;
}
[modoptions]
{
maxspeed=20;
}
[allyteam0]
{
numallies=0;
}
[team0]
{
teamleader=0;
allyteam=0;
}
[player1]
{
team=1;
name=Enemy;
}
[player0]
{
team=0;
name=UnnamedPlayer;
}
mapname=Adansonia v4.1;
myplayername=UnnamedPlayer;
ishost=1;
gametype=SpringCraft $VERSION;
nohelperais=0;
}]]
			Spring.Restart("", startScript)
		end
	end
end
