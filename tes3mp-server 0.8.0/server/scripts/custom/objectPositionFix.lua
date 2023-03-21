--[[
	Object Position Fix
		version 1.00
	
	DESCRIPTION/INSTRUCTIONS:
		Lets face it. Morrowind has some misplaced static objects. So here's a simple means to fix it so your players no longer lose immersion.
	
		Limit yourself to only using this on static objects and activators, and avoid using this on objects that can be picked up by players. (Otherwise, bugs/issues will likely occur.)
		
		1) Find a misplaced static object you want to fix, and open the in-game console with the ~ key. (Requires console access on your account.)
		2) Select the object you wish to adjust the coordinates of. You should see the uniqueIndex appear at the top center. (It'll looke something like 5635-0.)
		3) The uniqueIndex is required below.
		4) Determine what needs to be adjusted via getpos x/y/z and getangle x/y/z
		5) Make the adjustments via setpos x/y/z <new position> and setangle x/y/z <new angle>
		6) Whenever you're happy, take note of what you set the position/angle to, and configure it like the example shown below in the `objectsToFix` table.
	
	
	INSTALLATION:
		1) Place this file as `objectPositionFix.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.objectPositionFix")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	
	VERSION HISTORY:
		1.00	3/21/2023	-	Initial Release.
	
--]]


positionFix = {}

local objectsToFix = {
	["9, 16"] = { -- Cell name. Can be obtained via the `/getpos <pid>` chat command.
		{uniqueIndex = "147025-0", pos = {x = 78639.227, y = 135184.828, z = 502.589}, rot = {x = 0, y = 0, z = 20.8}},
	},
	["-6, -1"] = { -- Hlormaren	("-6, -1" is the actuall cell's name, and can be obtained via the `/getpos <pid>` chat command.)
		 -- "ex_stronghold_enter00":
		{uniqueIndex = "5635-0", pos = {x = -43136, y = -3328, z = 3106}, rot = {x = 0, y = 0, z = 270}}, -- Here's an example of how to adjust an objects position coordinates.
		 -- "in_strong_vaultdoor00":
		{uniqueIndex = "5637-0", pos = {z = 3042}}, -- Technically, you only need the positions you actually want to adjust.
		-- "ex_stronghold_dome00":
		{uniqueIndex = "5666-0", pos = {z = 3234}} -- Technically, you only need the positions you actually want to adjust.
	},
}

--==----==----==----==----==----==--
-- Do not touch past this point!
--==----==----==----==----==----==--
local checkForObjectRepositions = function(pid)
	local cells = Players[pid].cellsLoaded
	for _,cellDescription in pairs(cells) do
		if objectsToFix[cellDescription] ~= nil and LoadedCells[cellDescription] ~= nil then
			for i=1,#objectsToFix[cellDescription] do
				local obj = objectsToFix[cellDescription][i]
				local uniqueIndex = obj.uniqueIndex
				if uniqueIndex ~= nil then
					if obj.pos ~= nil then
						for pos,coord in pairs(obj.pos) do
							logicHandler.RunConsoleCommandOnObject(pid, "setpos "..tostring(pos).." "..coord, cellDescription, uniqueIndex)
						end
					end
					if obj.rot ~= nil then
						for rot,coord in pairs(obj.rot) do
							logicHandler.RunConsoleCommandOnObject(pid, "setangle "..tostring(rot).." "..coord, cellDescription, uniqueIndex)
						end
					end
				end
			end
		end
	end
end


customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		checkForObjectRepositions(pid)
	end	
end)

return positionFix