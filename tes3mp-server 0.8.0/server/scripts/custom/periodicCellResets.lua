--[[
	Lear's Periodic Cell Reset Script
		version 1.00 (for TES3MP 0.8)
	
	DESCRIPTION:
	This simple script allows cells to be periodically reset in game without the need for a server 
		restart. It's based on a certain amount of seconds that pass from the cells initial creation. 
		The cells will only reset when the time for reset has been reached (based on your servers 
		computer clock), and the cell is not currently loaded.
	
	Cells listed in `periodicCellResets.exemptCellNamesExact` will never be reset by this script. 
		Cells in this table must be named exactly as they are in-game to prevent this script from resetting them.
	
	Cells listed in `periodicCellResets.exemptCellNamesLike` will not be reset by this script if the names 
		have matching letter patterns. (I.E., "vivec" will prevent all cells with vivec in the name from being 
		reset via this script.)
	
	There are two commands for staff members to use. They are: 
		`/pushresets` (skips waiting for the timer, and checks all cells that have a reset timer to see if they can be reset.)
		`/reset "InsertACellNameHere"`(instantly resets a specific cell if it is in the reset timer list. )
	Enjoy!
	
	INSTALLATION:
		1) Place this file as `periodicCellResets.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.periodicCellResets.lua")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
--]]



periodicCellResets = {} -- No touchy this line.


--[[
	CONFIGURATION:
--]]

local cellResetTimeCheck = 300 -- Every x seconds (300 = 5 minutes), check unloaded cells to see if a reset is ready.

local exteriorCellResetTime = 21600 -- Exterior cells reset every 21600 seconds (6 hours) of real time.
local interiorCellResetTime = 14400 -- Interior cells reset every 14400 seconds (4 hours) of real time.
-- For the above two times, they will push a cell reset upon loading up a respective cell for the first 
-- time, x amount of seconds from when it was first initialized.

local requiredStaffRank = 1 -- Required staff rank to manually force resets. 1 = Moderator, 2 = Admin, 3 = Owner.

-- Exact cell names:
periodicCellResets.exemptCellNamesExact = { -- Exact cell names included in this list are not affected by the automated cell reset times in this script.
		
	-- AVOID RESETTING THE FOLLOWING CELLS, BECAUSE IT WILL CAUSE WONKY BEHAVIOR WITH THE STARTING BOAT:
	"-1, -9",
	"-1, -10",
	"-2, -9",
	"-2, -10"
	
}

-- Similar cell names:
periodicCellResets.exemptCellNamesLike = { -- Cell names that match strings included in this list are not affected by the automated cell reset times in this script.
	
	"$custom_", -- Custom generated cells.
	
	-- Prevent the following cells to prevent bugs:
	"Seyda Neen, Census and Excise Office",
	
	
	-- "Seyda Neen" -- Anything with Seyda Neen in the name, would be exempt from resets if you uncomment this line.
	
}


--[[
	END OF CONFIGURATION. DO NOT TOUCH LINES BELOW UNLESS YOU KNOW WHAT YOU ARE DOING.
--]]

local cellResetTimers = jsonInterface.load("custom/cellResetTimers.json")

local SaveCellResetTimers = function()
	jsonInterface.save("custom/cellResetTimers.json", cellResetTimers)
end

local LoadCellResetTimers = function()
	if cellResetTimers == nil then
		cellResetTimers = {}
		SaveCellResetTimers()
	end
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	LoadCellResetTimers()
end)

local specificCellFunctionsToAlwaysRun = function(pid, cellDescription)
	
	-- You can add functions here to always run when you enter a cell.
	
	
	
end

local nameLikeCellExemptions = function(cellDescription)
	
	for _,exemptCellName in pairs(periodicCellResets.exemptCellNamesLike) do
		if string.match(string.lower(exemptCellName), string.lower(cellDescription)) then
			return true
		end
	end

	return false
end

local doCellReset = function(pid, cellDescription)
	
	local txt = color.Error.."That cell is not in the reset table.\n"
	if cellResetTimers[cellDescription] ~= nil then
		
		local unloadAtEnd
		-- If the desired cell is not loaded, load it temporarily
		if LoadedCells[cellDescription] == nil then
			logicHandler.LoadCell(cellDescription)
			unloadAtEnd = true
		end
		
		LoadedCells[cellDescription].isResetting = true
		LoadedCells[cellDescription].data.objectData = {}
		LoadedCells[cellDescription].data.packets = {}
		LoadedCells[cellDescription]:EnsurePacketTables()
		LoadedCells[cellDescription].data.loadState.hasFullActorList = false
		LoadedCells[cellDescription].data.loadState.hasFullContainerData = false
		LoadedCells[cellDescription]:ClearRecordLinks()
		
		-- Unload a temporarily loaded cell
		if unloadAtEnd then
			logicHandler.UnloadCell(cellDescription)
		end
		
		tes3mp.ClearCellsToReset()
		tes3mp.AddCellToReset(cellDescription)
		tes3mp.SendCellReset(pid, true)
		
		cellResetTimers[cellDescription] = nil
		
		tableHelper.cleanNils(cellResetTimers)
		SaveCellResetTimers()
		
		txt = color.Green..cellDescription..color.White.." has been reset and is no longer in the list of cells to reset."
	end
	tes3mp.SendMessage(pid, color.Yellow.."[CellResets]: "..txt.."\n")
end

local pushForCellReset = function(pid, cmd)
	if Players[pid].data.settings.staffRank >= requiredStaffRank then
		
		if cmd[2] == nil then
			tes3mp.SendMessage(pid, 'Invalid inputs! Use /resetcell "Cell Name"\n')
			return
		end
		
		local inputConcatenation = tableHelper.concatenateFromIndex(cmd, 2)
		local cellDescription = string.gsub(inputConcatenation, '"', '')

		doCellReset(pid, cellDescription)
		
	end
end
customCommandHooks.registerCommand("reset", pushForCellReset)
customCommandHooks.registerCommand("RESET", pushForCellReset)

local pushCellResetsEarly = function(pid, cmd)

	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		if Players[pid].data.settings.staffRank >= requiredStaffRank then
			
			local markTime = os.time()
			local doSave = false
			
			if not tableHelper.isEmpty(cellResetTimers) then
			
				for cellDescription,cellResetTime in pairs(cellResetTimers) do
					if markTime >= cellResetTime then
						
						if LoadedCells[cellDescription] == nil then
							
							local unloadAtEnd
							
							if LoadedCells[cellDescription] == nil then
								logicHandler.LoadCell(cellDescription)
								unloadAtEnd = true
							end

							LoadedCells[cellDescription].isResetting = true
							LoadedCells[cellDescription].data.objectData = {}
							LoadedCells[cellDescription].data.packets = {}
							LoadedCells[cellDescription]:EnsurePacketTables()
							LoadedCells[cellDescription].data.loadState.hasFullActorList = false
							LoadedCells[cellDescription].data.loadState.hasFullContainerData = false
							LoadedCells[cellDescription]:ClearRecordLinks()

							-- Unload a temporarily loaded cell
							if unloadAtEnd then
								logicHandler.UnloadCell(1)
							end

							tes3mp.ClearCellsToReset()
							tes3mp.AddCellToReset(cellDescription)
							tes3mp.SendCellReset(pid, true)
							
							cellResetTimers[cellDescription] = nil
							
							doSave = true
							
						end
					end
				end
			
			end
			
			if doSave then
				tableHelper.cleanNils(cellResetTimers)
				SaveCellResetTimers()
			end
			
		end
		
	end
end
customCommandHooks.registerCommand("pushresets", pushCellResetsEarly)
customCommandHooks.registerCommand("PUSHRESETS", pushCellResetsEarly)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, previousCellDescription, currentCellDescription)
	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		local cellDescription = Players[pid].data.location.cell -- Use this instead of currentCellDescription for now, because currentCellDescription is bugged and stores your previous instead of current cell description.
		local cell = LoadedCells[cellDescription]
		if cell ~= nil then
			
			if not tableHelper.containsValue(periodicCellResets.exemptCellNamesExact, cellDescription) and not nameLikeCellExemptions(cellDescription) then
				
				if cellResetTimers[cellDescription] == nil then
					local exteriorCell = cell.isExterior
					local getResetTime = exteriorCellResetTime
					if not exteriorCell then
						getResetTime = interiorCellResetTime
					end
					cellResetTimers[cellDescription] = os.time() + getResetTime
					SaveCellResetTimers()
				end
			
			end
			
			specificCellFunctionsToAlwaysRun(pid, cellDescription)
		end
		
	end
end)


periodicCellResets.UpdateResetTimers = function()
	
	for pid, player in pairs(Players) do
		if Players[pid] ~= nil and player:IsLoggedIn() then
			
			local markTime = os.time()
			local doSave = false
			
			if not tableHelper.isEmpty(cellResetTimers) then
				
				for cellDescription,cellResetTime in pairs(cellResetTimers) do
						
						if markTime >= cellResetTime then
							
							if LoadedCells[cellDescription] == nil then
								
								local unloadAtEnd
								-- If the desired cell is not loaded, load it temporarily
								if LoadedCells[cellDescription] == nil then
									logicHandler.LoadCell(cellDescription)
									unloadAtEnd = true
								end

								LoadedCells[cellDescription].isResetting = true
								LoadedCells[cellDescription].data.objectData = {}
								LoadedCells[cellDescription].data.packets = {}
								LoadedCells[cellDescription]:EnsurePacketTables()
								LoadedCells[cellDescription].data.loadState.hasFullActorList = false
								LoadedCells[cellDescription].data.loadState.hasFullContainerData = false
								LoadedCells[cellDescription]:ClearRecordLinks()

								-- Unload a temporarily loaded cell
								if unloadAtEnd then
									logicHandler.UnloadCell(1)
								end

								tes3mp.ClearCellsToReset()
								tes3mp.AddCellToReset(cellDescription)
								tes3mp.SendCellReset(pid, true)
								
								cellResetTimers[cellDescription] = nil
								
								doSave = true
								
							end
						end
					
				end
			end
			
			if doSave then
				tableHelper.cleanNils(cellResetTimers)
				SaveCellResetTimers()
			end
			
			break
		end
	end
	
	tes3mp.RestartTimer(GlobalCellResetTimer, time.seconds(cellResetTimeCheck))
end

GlobalCellResetTimerUpdate = periodicCellResets.UpdateResetTimers
GlobalCellResetTimer = tes3mp.CreateTimer("GlobalCellResetTimerUpdate", time.seconds(cellResetTimeCheck))
tes3mp.StartTimer(GlobalCellResetTimer)

return periodicCellResets
