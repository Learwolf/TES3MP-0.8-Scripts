--[[
	Drowning Rebalance
	
	DESCRIPTION:
		This script allows server owners to easily modify drowning damage.
		The default drowning damage is 3 points every second, and does not scale.
		With this script, it will (by default) be 3 points times the players level.
		A level 1 will take 3 points of drowning damage every second, while a level 50 will take 150.

	NOTES:
		A limitation to how openMw deals with the drowning damage GMST is that this specific GMST change can only occur once per play session,
		and it must be done before a player takes drown damage. What this means is, if a player already took drowning damage during their 
		current play session, then levels up, the drowning damage may not correctly update until the player relogs.
	
	INSTALLATION:
		1) Place this file as `drowningRebalance.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.drowningRebalance")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
		
	VERSION HISTORY:
		1.00	3/9/2023	-	Initial Release.
		
--]]

drowningRebalance = {}

-- User Configuration:
local config = {
	defaultValue = 3.0000, -- (Default: 3.0000) Drowning damage will be this value times the players level.
	argoniansTakeHalfDamage = false -- If true, argonian players take half drowning damage.
}

--==----==----==----==----==----==----==----
-- Shouldn't touch anything past this point.
--==----==----==----==----==----==----==----
local pushChange = function(pid, value)
	local setValue = value or config.defaultValue
	tes3mp.ClearRecords()
	tes3mp.SetRecordType(enumerations.recordType["GAMESETTING"])
	packetBuilder.AddRecordByType("fSuffocationDamage", {floatVar = setValue}, "gamesetting")
	tes3mp.SendRecordDynamic(pid, false, false)
end

drowningRebalance.calculateValue = function(pid)

	local value = config.defaultValue or 3.0000
	local lvl = Players[pid].data.stats.level or 1
	
	-- Argonian Race Check:
	if config.argoniansTakeHalfDamage ~= nil and config.argoniansTakeHalfDamage == true then
		local pRace = Players[pid].data.character.race
		if pRace ~= nil then
			if string.lower(pRace) == "argonian" then
				value = value * 0.5
			end
		end
	end
	
	value = value * lvl
	
	pushChange(pid, value)
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		drowningRebalance.calculateValue(pid)
	end
end)

customEventHooks.registerHandler("OnPlayerLevel", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		drowningRebalance.calculateValue(pid)
	end
end)

local setDefaultGmstValue = function()
	local recordStore = RecordStores["gamesetting"]
	
	recordStore.data.permanentRecords["fSuffocationDamage"] = {
		floatVar = config.defaultValue
	}
	
	recordStore:Save()
end

local function OnServerPostInit(eventStatus)
	setDefaultGmstValue()
end

customEventHooks.registerHandler("OnServerPostInit", OnServerPostInit)

return drowningRebalance