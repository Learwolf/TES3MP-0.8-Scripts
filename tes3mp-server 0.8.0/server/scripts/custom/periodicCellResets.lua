--[[
	Lear's Periodic Cell Reset Script
		version 1.04 (for TES3MP 0.8)
	
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
		`/pushresets` (skips waiting for the global timer, and checks all cells that have a reset timer to see if they can be reset now.)
		`/reset "InsertACellNameHere"`(instantly resets a specific cell if it is in the reset timer list. )
		`/resetall` (Will forcibly reset every cell that does not currently have an online player inside it.)
	
	INSTALLATION:
		1) Place this file as `periodicCellResets.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.periodicCellResets")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	
	VERSION HISTORY:
		1.04 (3/9/2022)		- Fixed issue where actor AI would not work correctly after entering a newly reset cell.
		1.03 (2/18/2022)	- Added a `/resetall` command. Added confirmation text for /pushresets command. Optional `/runstartup` command automatically run for the first player to log on after the server has started up.
		1.02 (2/11/2022)	- Fixed issue with cell file names that use ; instead of :
		1.01 (2/10/2022)	- Removes a cells timer on server startup, if the cell does not exist in the servers cell folder.
		1.00 (2/9/2022)		- Initial public release.
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

local runStartupCommandsAutomatically = false -- Setting this to `true` will ensure the `/runstartup` gets run whenever the server is restarted.

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

local startupCommandsHaveRun = false
local runStartupCommands = function(pid)
	for _, scriptName in pairs(config.worldStartupScripts) do
        logicHandler.RunConsoleCommandOnPlayer(pid, "startscript " .. scriptName, false)
    end
	
    WorldInstance.coreVariables.hasRunStartupScripts = true
	startupCommandsHaveRun = true
end

local SaveCellResetTimers = function()
	jsonInterface.save("custom/cellResetTimers.json", cellResetTimers)
end

local LoadCellResetTimers = function()
	if cellResetTimers == nil then
		cellResetTimers = {}
		SaveCellResetTimers()
	end
end

local removeDeletedCellsFromResetTimers = function()
	
	local doSave = false
	tes3mp.LogAppend(enumerations.log.INFO, "-=-=-CHECKING RESET TIMER CELLS-=-=-")
	for cellDescription,_ in pairs(cellResetTimers) do
		local fixedCellDescription = fileHelper.fixFilename(cellDescription)
		if fixedCellDescription ~= nil and tes3mp.GetCaseInsensitiveFilename(tes3mp.GetDataPath() .. "/cell/", fixedCellDescription .. ".json") == "invalid" then
			cellResetTimers[fixedCellDescription] = nil
			tes3mp.LogAppend(enumerations.log.INFO, "Removing stored reset timer for \""..fixedCellDescription.."\" since the cell no longer exists.")
			doSave = true
		end
	end
	
	if doSave then
		tableHelper.cleanNils(cellResetTimers)
		SaveCellResetTimers()
	end
	
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	LoadCellResetTimers()
	removeDeletedCellsFromResetTimers()
end)

local specificCellFunctionsToAlwaysRun = function(pid, cellDescription)
	
	-- You can add functions here to always run when you enter a cell.
	
	
	
end

local nameLikeCellExemptions = function(cellDescription)
	
	local currentCell = string.lower(cellDescription)
	for _,exemptCellName in pairs(periodicCellResets.exemptCellNamesLike) do
		
		local exemptCell = string.lower(exemptCellName)
		if string.match(currentCell, exemptCell) then
			return true
		end
		
	end

	return false
end

local doCellReset = function(pid, cellDescription)
	
	local txt = color.Error.."That cell is not in the reset table."
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
			
			local txt = color.Error.."There are no cells that are ready to be reset."
			
			local cellsReset = 0
			local cellLoaded = 0
			
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
								logicHandler.UnloadCell(cellDescription)
							end

							tes3mp.ClearCellsToReset()
							tes3mp.AddCellToReset(cellDescription)
							tes3mp.SendCellReset(pid, true)
							
							cellResetTimers[cellDescription] = nil
							
							cellsReset = cellsReset + 1
							
							doSave = true
							
						else
							cellLoaded = cellLoaded + 1
						end
					end
				end
				
			end
			
			
			if cellsReset > 1 then
				txt = color.White..cellsReset..color.Yellow.." cells have been reset."
			elseif cellsReset == 1 then
				txt = color.White.."1"..color.Yellow.." cell has been reset."
			end
			
			if cellLoaded > 1 then
				txt = color.White..cellLoaded..color.Error.." cells could not be reset because they have players in them."
			elseif cellLoaded == 1 then
				txt = color.White..cellLoaded..color.Error.." cell could not be reset because it has players in it."
			end
			
			tes3mp.SendMessage(pid, txt.."\n")
			
			if doSave then
				tableHelper.cleanNils(cellResetTimers)
				SaveCellResetTimers()
			end
			
		end
		
	end
end
customCommandHooks.registerCommand("pushresets", pushCellResetsEarly)
customCommandHooks.registerCommand("PUSHRESETS", pushCellResetsEarly)

local pushResetAllCells = function(pid, cmd)

	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		if Players[pid].data.settings.staffRank >= requiredStaffRank then
			
			local doSave = false
			
			local txt = color.Error.."There are no cells that are ready to be reset."
			
			local cellsReset = 0
			local cellLoaded = 0
			
			if not tableHelper.isEmpty(cellResetTimers) then
				
				for cellDescription,cellResetTime in pairs(cellResetTimers) do
						
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
							logicHandler.UnloadCell(cellDescription)
						end

						tes3mp.ClearCellsToReset()
						tes3mp.AddCellToReset(cellDescription)
						tes3mp.SendCellReset(pid, true)
						
						cellResetTimers[cellDescription] = nil
						
						cellsReset = cellsReset + 1
						
						doSave = true
						
					else
						cellLoaded = cellLoaded + 1
					end
					
				end
				
			end
			
			
			if cellsReset > 1 then
				txt = color.White..cellsReset..color.Yellow.." cells have been reset."
			elseif cellsReset == 1 then
				txt = color.White.."1"..color.Yellow.." cell has been reset."
			end
			
			if cellLoaded > 1 then
				txt = color.White..cellLoaded..color.Error.." cells could not be reset because they have players in them."
			elseif cellLoaded == 1 then
				txt = color.White..cellLoaded..color.Error.." cell could not be reset because it has players in it."
			end
			
			tes3mp.SendMessage(pid, txt.."\n")
			
			if doSave then
				tableHelper.cleanNils(cellResetTimers)
				SaveCellResetTimers()
			end
			
		end
		
	end
	
end
customCommandHooks.registerCommand("resetall", pushResetAllCells)
customCommandHooks.registerCommand("resetAll", pushResetAllCells)
customCommandHooks.registerCommand("ResetAll", pushResetAllCells)
customCommandHooks.registerCommand("RESETALL", pushResetAllCells)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		
		local cellDescription = playerPacket.location.cell
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

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if runStartupCommandsAutomatically and not startupCommandsHaveRun then
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
			runStartupCommands(pid)
			startupCommandsHaveRun = true
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
									logicHandler.UnloadCell(cellDescription)
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
