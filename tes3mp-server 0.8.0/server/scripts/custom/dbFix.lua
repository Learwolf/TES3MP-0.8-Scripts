--[[
	Dark Brotherhood Fix
		version 1.00 (for TES3MP 0.8-0.8.1)
	
	DESCRIPTION:
		This script allows server owners to set a level requirement for players to spawn a dark brotherhood assassins.
		This script also ensures an assassin spawns once (and only once) per each player.

	INSTALLATION:
		1) Place this file as `dbFix.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.dbFix")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
--]]

dbFix = {}

--==----==----==----==--
-- User Configurations:
--==----==----==----==--
local levelRequirement = 30 -- This sets the level required to spawn an Assassin when a player uses a bed.
local onlySpawnOnce = true -- Setting this to false effectively disables this scripts functionality.

--==----==----==----==----==----==--
-- Don't touch beyond this point!
--==----==----==----==----==----==--
local journalIteration = function(journal)
	for id,data in pairs(journal) do
		if data.quest ~= nil and data.quest == "tr_dbattack" then
			if data.index >= 10 then 
				return true
			end
		end
	end
	return false
end

local hasDarkBrotherhoodJournalEntry = function(pid)
	if not config.shareJournal then
		return journalIteration(Players[pid].data.journal)
	else
		return journalIteration(WorldInstance.data.journal)
	end
	return false
end

local playerHasScriptRunning = {}
customEventHooks.registerHandler("OnPlayerJournal", function(eventStatus, pid, playerPacket)
	if onlySpawnOnce == true and Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		for index,data in pairs(playerPacket.journal) do
			if data.quest == "tr_dbattack" and data.index >= 10 then
				logicHandler.RunConsoleCommandOnPlayer(pid, "stopscript dbAttackScript")
				playerHasScriptRunning[pid] = false
			end
		end
	end
end)

customEventHooks.registerHandler("OnPlayerLevel", function(eventStatus, pid)
	if not playerHasScriptRunning[pid] and not hasDarkBrotherhoodJournalEntry(pid) and tes3mp.GetLevel(pid) >= levelRequirement then
		logicHandler.RunConsoleCommandOnPlayer(pid, "startscript dbAttackScript")
		playerHasScriptRunning[pid] = true
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and onlySpawnOnce == true then
		if hasDarkBrotherhoodJournalEntry(pid) or Players[pid].data.stats.level < levelRequirement then
			logicHandler.RunConsoleCommandOnPlayer(pid, "stopscript dbAttackScript")
			playerHasScriptRunning[pid] = false
		else
			playerHasScriptRunning[pid] = true
		end
	end
end)

return dbFix