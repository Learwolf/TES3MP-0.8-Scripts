--[[
	Lear's Periodic Cell Reset Script
		version 1.10 (for TES3MP 0.8 & 0.8.1)
	
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
	
	Players can adjust the amount of days to which a merchant cell restock, should they want it to occur before a
		standard cell reset. The `merchantDayRestock` configuration option below will cause a merchant cell to reset 
		every X amount of in-game days, with X being the value applied to `merchantDayRestock`.
	
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
		1.10 (5/2/2022)		- Added method to reset merchant cells specifically.
		1.09 (4/23/2022)	- Updated to take in changes made by David to new config.recordStoreLoadOrder.
		1.08 (4/2/20022)	- Added requested option in configuration section to disable resetting of any interior cells.
		1.07 (3/16/2022)	- Added toggleable configuration option to also reset world kill counts on server startup.
		1.06 (3/13/2022)	- Added `/resets` command for players to view upcoming cell resets. New options related to this function can be found in the config section of this script.
							- Added `resetNormalCellsOnRestart` config option to allow server owners to wipe all cells on a hard server restart. (Disabled by default.)
							
		1.05 (3/13/2022)	- Removes linked records that no longer exist on cell resets. (Toggleable, default set to On)
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
-- For the above two values, they will push a cell reset upon loading up a respective cell for the first 
-- time, x amount of seconds from when it was first initialized.

local merchantDayRestock = 1 -- Day intervals that merchant cells reset/restock. (1 = Merchants restock daily)

local runStartupCommandsAutomatically = false -- Setting this to `true` will ensure the `/runstartup` gets run whenever the server is restarted.

local requiredStaffRank = 1 -- Required staff rank to manually force resets. 1 = Moderator, 2 = Admin, 3 = Owner.
local viewResetsStaffRank = 0 -- Required staff rank to view what cells will be reset soon.
local viewResetSortTypeCellName = true -- If true, sorts the `/resets` by cell name. If false, sorts by time remaining until the cell reset.

local resetExteriorCellsOnly = false -- If true, only exerior cells will reset. -- string.match(cellDescription, patterns.exteriorCell)

local resetNormalCellsOnRestart = false -- WARING!! This does not seem to work as intended, and seems to ALWAYS delete Exterior cells! If true, deletes all non-exempt cells on server startup.
local resetWorldKillCountsOnRestart = false -- If true, resets the worlds kill count on server startup. (Requires resetNormalCellsOnRestart to also be true!)

local unlinkCustomRecordsOnReset = true -- Advised to leave as true. This unlinks records from cells that are reset. (Prevents customRecord bloat.)

-- Exact cell names:
periodicCellResets.exemptCellNamesExact = { -- Exact cell names included in this list are not affected by the automated cell reset times in this script.
	
	-- AVOID RESETTING THE FOLLOWING CELLS, BECAUSE IT WILL CAUSE WONKY BEHAVIOR WITH THE STARTING BOAT:
	"-1, -9",
	"-1, -10",
	"-2, -9",
	"-2, -10"
	
}

-- Similar cell names:interiorCellExemption
periodicCellResets.exemptCellNamesLike = { -- Cell names that match strings included in this list are not affected by the automated cell reset times in this script.
	
	"$custom_", -- Custom generated cells.
	
	-- Prevent the following cells to prevent bugs:
	"Seyda Neen, Census and Excise Office",
	
	
	-- "Seyda Neen" -- Anything with Seyda Neen in the name, would be exempt from resets if you uncomment this line.
	
}


--[[
	END OF CONFIGURATION. DO NOT TOUCH LINES BELOW UNLESS YOU KNOW WHAT YOU ARE DOING.
--]]

local ViewResetsGuiId = 44332202 -- GUI Id used for the `/resets` menu (Shouldn't need to touch this.)

local cellResetTimers = jsonInterface.load("custom/cellResetTimers.json")

local merchantCells = {} -- Tracks merchant cells that need to be restocked. Don't touch

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

local removeCustomRecordsFromResetCell = function(cellDescription)
	
	if unlinkCustomRecordsOnReset then
		
		if type(config.recordStoreLoadOrder[1]) == "table" then -- Using new config.recordStoreLoadOrder
			
			for priorityLevel, recordStoreTypes in ipairs(config.recordStoreLoadOrder) do
				for _, storeType in ipairs(recordStoreTypes) do
			
					if RecordStores[storeType].data.recordLinks ~= nil then
					
						local recordLinks = RecordStores[storeType].data.recordLinks
						for recordId,recordData in pairs(recordLinks) do
							if recordData.cells ~= nil and tableHelper.containsValue(recordData.cells, cellDescription) then
								
								local linkIndex = tableHelper.getIndexByValue(recordData.cells, cellDescription)

								if linkIndex ~= nil then
									recordLinks[recordId].cells[linkIndex] = nil
								end

								if not RecordStores[storeType]:HasLinks(recordId) then
									table.insert(RecordStores[storeType].data.unlinkedRecordsToCheck, recordId)
								end
								
							end
						end
						
					end
					
				end
			end
			
		else -- Using old config.recordStoreLoadOrder
			
			for _, storeType in pairs(config.recordStoreLoadOrder) do
				if RecordStores[storeType].data.recordLinks ~= nil then
					
					local recordLinks = RecordStores[storeType].data.recordLinks
					for recordId,recordData in pairs(recordLinks) do
						if recordData.cells ~= nil and tableHelper.containsValue(recordData.cells, cellDescription) then
							
							local linkIndex = tableHelper.getIndexByValue(recordData.cells, cellDescription)

							if linkIndex ~= nil then
								recordLinks[recordId].cells[linkIndex] = nil
							end

							if not RecordStores[storeType]:HasLinks(recordId) then
								table.insert(RecordStores[storeType].data.unlinkedRecordsToCheck, recordId)
							end
							
						end
					end
					
				end
			end
			
		end
	end

end

local getCellsArray = function(directory)
	--This function finds the filename when given a complete path 
	--local directory = config.dataPath .. "\\cell"
	
	local i, t, popen = 0, {}, io.popen
	
	--local pfile = popen('dir "'..directory..'" /b /ad') -- the /ad gets directories only it seems.
	local pfile = popen('dir "'..directory..'" /b')
	
	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	
	return t
end

local resetCellsOnStartup = function()
	if resetNormalCellsOnRestart ~= nil and resetNormalCellsOnRestart == true then
		
		local clearedCellCount = 0
		local directory = tes3mp.GetModDir() .. "/cell/"
		local cells = getCellsArray(directory)
		
		local tempMerge = {}
		for _,cellName in pairs(periodicCellResets.exemptCellNamesExact) do
			tableHelper.insertValueIfMissing(tempMerge, cellName)
		end
		for _,cellName in pairs(periodicCellResets.exemptCellNamesLike) do
			tableHelper.insertValueIfMissing(tempMerge, cellName)
		end
		
		for _,cellFile in pairs(cells) do
			
			local splitFileExtension = cellFile:split(".")
			local cellName = splitFileExtension[1]
			
			local preventDeletion = false
			for x,BlockedCellName in pairs(tempMerge) do
				if string.match(cellName, BlockedCellName) then
					preventDeletion = true
					break
				end
			end
			
			-- If only allowed to delete exterior cells is true:
			if resetExteriorCellsOnly == true then
				if not string.match(cellName, patterns.exteriorCell) then
					preventDeletion = true
				end
			end
			
			if not preventDeletion then
				if string.match(string.lower(cellFile), ".json") then
					os.remove(directory..cellFile)
					clearedCellCount = clearedCellCount + 1
				end
			end
			
		end
		
		if clearedCellCount > 0 then
			print("Total Cells Deleted: "..clearedCellCount)
		end
		
	end
	
	if resetWorldKillCountsOnRestart ~= nil and resetWorldKillCountsOnRestart == true then
		local clearedCellKills = 0
        for refId, killCount in pairs(WorldInstance.data.kills) do
			clearedCellKills = clearedCellKills + WorldInstance.data.kills[refId]
            WorldInstance.data.kills[refId] = 0
        end

        WorldInstance:QuicksaveToDrive()
        print("Total Kills Cleared: "..clearedCellKills)
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
			removeCustomRecordsFromResetCell(cellDescription)
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
	resetCellsOnStartup()
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

local interiorCellExemption = function(cellDescription)
	
	if resetExteriorCellsOnly == true then
		
		local currentCell = string.lower(cellDescription)
		if not string.match(currentCell, patterns.exteriorCell) then
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
		
		removeCustomRecordsFromResetCell(cellDescription) -- Remove custom record links from a cell when the cell is reset.
		
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
							
							removeCustomRecordsFromResetCell(cellDescription)
							
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
						
						removeCustomRecordsFromResetCell(cellDescription) -- Remove custom record links from a cell when the cell is reset.
						
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

customEventHooks.registerHandler("OnObjectDialogueChoice", function(eventStatus, pid, cellDescription, objects)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		local isValid = eventStatus.validDefaultHandler
		
		if not tableHelper.containsValue(periodicCellResets.exemptCellNamesExact, cellDescription) and not nameLikeCellExemptions(cellDescription) and not interiorCellExemption(cellDescription) then
			for uniqueIndex, object in pairs(objects) do
				
				if object.dialogueChoiceType == 3 then -- 3 == barter
					if merchantCells[cellDescription] == nil then 
						merchantCells[cellDescription] = (WorldInstance.data.time.daysPassed + merchantDayRestock)
					end
				end
				
			end
		end
		
	end
end)

local checkMerchantCell = function()
	
	local doSave = false
	local currentDay = WorldInstance.data.time.daysPassed
	for cellDescription, daySaved in pairs(merchantCells) do
		
		if LoadedCells[cellDescription] == nil then
			if daySaved ~= nil and currentDay >= daySaved then 
				cellResetTimers[cellDescription] = 0
				merchantCells[cellDescription] = nil
				doSave = true
			end
		end
	end
	
	if doSave then
		SaveCellResetTimers()
	end
end

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		
		local cellDescription = playerPacket.location.cell
		local cell = LoadedCells[cellDescription]
		if cell ~= nil then
			
			if not tableHelper.containsValue(periodicCellResets.exemptCellNamesExact, cellDescription) and not nameLikeCellExemptions(cellDescription) and not interiorCellExemption(cellDescription) then
				
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
	
	checkMerchantCell()
	
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
								
								removeCustomRecordsFromResetCell(cellDescription) -- Remove custom record links from a cell when the cell is reset.
								
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


local determineTime = function(timeInput)
	local timeString = ""
    local mod
    local timeArray = {0, 0, 0}
    local timeSection = {86400, 3600, 60}
    local timeName
    local div1
    local div2
    local plural
    local dot
    if returnList == false then
        timeName = {" day", " hour", " minute", " second"}
        div1 = ", "
        div2 = " and "
        plural = "s"
        dot = "."
    else
        timeName = {"d", "h", "m", "s"}
        div1 = " "
        div2 = " "
        plural = ""
        dot = ""
    end
    for i = 1, 3 do
        mod = timeInput % timeSection[i]
        timeArray[i] = (timeInput - mod) / timeSection[i]
        if timeArray[i] > 0 then
            if i > 1 then
                if timeArray[i-1] > 0 then
                    if mod ~= 0 then
                        timeString = timeString .. div1 .. timeArray[i]
                    else
                        timeString = timeString .. div2 .. timeArray[i]
                    end
                else
                    timeString = timeString .. timeArray[i]
                end
            else
                timeString = timeArray[i]
            end
            if timeArray[i] > 1 then
                timeString = timeString .. timeName[i] .. plural
            else
                timeString = timeString .. timeName[i]
            end
        end
        timeInput = mod
    end
    if mod ~= 0 then
        if timeString ~= "" then
            if mod > 1 then
                timeString = timeString .. div2 .. mod .. timeName[4] .. plural .. dot
            else
                timeString = timeString .. div2 .. mod .. timeName[4] .. dot
            end
        else
            if mod > 1 then
                timeString = mod .. timeName[4] .. plural .. dot
            else
                timeString = mod .. timeName[4] .. dot
            end
        end
    end
    return timeString
end

local getListOfUpcomingResetCells = function()
	
	local txt = ""
	local list = {}
	
	if tableHelper.isEmpty(cellResetTimers) then
		return "There are no cells with upcoming resets."
	else
		for cellDescription, resetTime in pairs(cellResetTimers) do
			local timeRemainder = resetTime - os.time()
			
			local timeRemainderText = color.Lime.."Leave cell for reset!"
			
			if timeRemainder > 0 then
				
				local timerColor = color.Grey
				
				if timeRemainder <= 900 then
					timerColor = color.Red
				elseif timeRemainder <= 1700 then
					timerColor = color.Orange
				elseif timeRemainder <= 5400 then
					timerColor = color.Yellow
				elseif timeRemainder <= 9000 then
					timerColor = color.Khaki
				end
				
				timeRemainderText = timerColor..determineTime(timeRemainder)
			end
			
			table.insert(list, {name = cellDescription, timer = timeRemainder, timeText = timeRemainderText})
		end
	end
	
	if viewResetSortTypeCellName then
		table.sort(list, function(a,b) return a.name<b.name end)
	else
		table.sort(list, function(a,b) return a.timer<b.timer end)
	end
	for i=1,#list do
		txt = txt .. "\"" .. list[i].name .. "\"\n" .. color.White .. "  - Resets in: "..list[i].timeText.."\n"
	end
	
	return txt:sub(1, -2)
end

local viewResetMenu = function(pid)
	local header = color.DarkOrange.."View Upcoming Cell Resets\n" .. color.Yellow .. "The following list contains cells and how long until they will reset."
	tes3mp.ListBox(pid, ViewResetsGuiId, header, getListOfUpcomingResetCells())
end

-- GUI Handler
customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
	
		if idGui == ViewResetsGuiId then
			isValid = false
			return
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

periodicCellResets.viewResets = function(pid, cmd)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		if Players[pid].data.settings.staffRank >= viewResetsStaffRank then
			viewResetMenu(pid)
		else
			tes3mp.SendMessage(pid, color.Error.."You do not have access to that command.\n")
		end
	end
end
customCommandHooks.registerCommand("resets", periodicCellResets.viewResets)

return periodicCellResets
