
local playerLevelCap = 100 -- Level cap value.

customEventHooks.registerValidator("OnPlayerLevel", function(eventStatus, pid)
	
	local isValid = eventStatus.validDefaultHandler
	if isValid ~= false then
		if tes3mp.GetLevel(pid) >= playerLevelCap and Players[pid].data.stats.level >= playerLevelCap and tes3mp.GetLevelProgress(pid) > 0 then
			Players[pid].data.stats.levelProgress = 0
			Players[pid]:LoadLevel()
			isValid = false
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

customEventHooks.registerHandler("OnPlayerLevel", function(eventStatus, pid)
	if tes3mp.GetLevel(pid) >= playerLevelCap and Players[pid].data.stats.level >= playerLevelCap and tes3mp.GetLevelProgress(pid) > 0 then
		Players[pid].data.stats.levelProgress = 0
		Players[pid]:LoadLevel()
	end
end)
