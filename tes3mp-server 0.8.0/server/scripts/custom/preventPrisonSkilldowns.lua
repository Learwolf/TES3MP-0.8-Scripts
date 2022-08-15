--[[
	Prevent Prison Skilldowns
		version 1.00 (for TES3MP 0.8.1)
	
	DESCRIPTION:
		This script allows server owners to prevent players from having skill lower from going to prison.
		There is one configurable option below that allows this to only prevent murder jail time (1000 bounty or higher).
		
	INSTALLATION:
		1) Place this file as `preventPrisonSkilldowns.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.preventPrisonSkilldowns")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.

--]]


preventPrisonSkilldowns = {}

local OnlyAfterMurders = false -- If true, only prevents skill downs if the player has gained a 1,000 bounty. If false, prevents any skilldowns from jail time.


local trackedBounty = {}
customEventHooks.registerHandler("OnPlayerBounty", function(eventStatus, pid)
	
	if trackedBounty[pid] ~= nil and trackedBounty[pid] > 0 and Players[pid].data.fame.bounty == 0 and (not OnlyAfterMurders or trackedBounty[pid] >= 1000) then
		Players[pid].skipPrisonSkills = (os.time() + 10)
	end
	trackedBounty[pid] = tableHelper.deepCopy(Players[pid].data.fame.bounty)
end)

customEventHooks.registerValidator("OnPlayerSkill", function(eventStatus, pid, playerPacket)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
	 
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then -- and Players[pid].data.settings.staffRank < 1 then
			
			if Players[pid].skipPrisonSkills and os.time() < Players[pid].skipPrisonSkills then
				
				for skillName,skillData in pairs(playerPacket.skills) do
					if skillData ~= nil and skillData.base ~= nil then
						local plyrSkl = Players[pid].data.skills[skillName]
						if plyrSkl ~= nil and plyrSkl.base ~= nil and plyrSkl.base > skillData.base then
							Players[pid]:LoadSkills()
							Players[pid].skipPrisonSkills = nil
							return customEventHooks.makeEventStatus(false, false)
						end
					end
				end
				
			else
				Players[pid].skipPrisonSkills = nil
			end
			
		end

	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	trackedBounty[pid] = tableHelper.deepCopy(Players[pid].data.fame.bounty)
end)

customEventHooks.registerHandler("OnPlayerConnect", function(eventStatus, pid)
	trackedBounty[pid] = nil
end)

return preventPrisonSkilldowns
