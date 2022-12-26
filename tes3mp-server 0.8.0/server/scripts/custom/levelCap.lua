--[[
	Lear's Level Cap Script
		version 1.01 (for TES3MP 0.8)
	
	DESCRIPTION:
	This simple script allows server owners to set a level cap for players. Keep in mind, it does not retroactively 
		revert players levels if they have bypassed said cap prior to installing this script.

	INSTALLATION:
		1) Place this file as `levelCap.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.levelCap")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	Version History:
		
		1.01	-	Updated to be easily pull level cap via other scripts. New addition to retroactively downlevel players who 
						went above the level cap before this scripts level cap was applied.
		1.00	-	Initial release.
--]]

playerLevelCapper {}

-----------------
-- Configuration:
-----------------
playerLevelCapper.config = {
	levelCap = 100, -- Enforced level cap value.
	downLevelRetroactively = true -- Will down-level players who went past the above levelCap before this scripts levelCap was applied.
}

-----------------------------------------------------
-- Shouldn't need to touch anything below this point.
-----------------------------------------------------
customEventHooks.registerValidator("OnPlayerLevel", function(eventStatus, pid)
	
	local isValid = eventStatus.validDefaultHandler
	if isValid ~= false then
		if tes3mp.GetLevel(pid) >= playerLevelCapper.config.levelCap and Players[pid].data.stats.level >= playerLevelCapper.config.levelCap and tes3mp.GetLevelProgress(pid) > 0 then
			Players[pid].data.stats.levelProgress = 0
			Players[pid]:LoadLevel()
			isValid = false
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

customEventHooks.registerHandler("OnPlayerLevel", function(eventStatus, pid)
	if tes3mp.GetLevel(pid) >= playerLevelCapper.config.levelCap and Players[pid].data.stats.level >= playerLevelCapper.config.levelCap and tes3mp.GetLevelProgress(pid) > 0 then
		Players[pid].data.stats.levelProgress = 0
		Players[pid]:LoadLevel()
	end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if playerLevelCapper.config.downLevelRetroactively and Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		if Players[pid].data.stats.level > playerLevelCapper.config.levelCap then
			Players[pid].data.stats.level = playerLevelCapper.config.levelCap
			Players[pid].data.stats.levelProgress = 0
			Players[pid]:LoadLevel()
		end
	end
end)

return playerLevelCapper
