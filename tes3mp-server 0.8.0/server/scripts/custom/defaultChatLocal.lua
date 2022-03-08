--[[
	Default to Local Chat
		version 1.01 (For TES3MP 0.8)
			by Learwolf
	
	DESCRIPTION:
		This script allows players to talk in local chat by default, and requires players to use 
		`/global InsertMessageTextHere` to speak globally.
	
	INSTALLATION:
		1) Place this file as `defaultChatLocal.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.defaultChatLocal")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	VERSIONS:
		1.01	- Fixed a crash.
		1.00	- Per request, initial untested release.
--]]


defaultChatLocal = {}

-- CONFIGURATION:
local globalChatCommand = "global" -- Command to use (followed by message text) to speak in global chat. (i.e. "global" == /global enter text here to speak globally.)


-- -- -- -- -- -- -- -- -- -- -- -- 
-- No touch beyond this point.
-- -- -- -- -- -- -- -- -- -- -- -- 

defaultChatLocal.globalMessage = function(pid, cmd)
	local message = color.White .. logicHandler.GetChatName(pid) .. ": " .. tableHelper.concatenateFromIndex(cmd, 2) .. "\n"

	-- Check for chat overrides that add extra text
	if Players[pid]:IsServerStaff() then

		if Players[pid]:IsServerOwner() then
			message = config.rankColors.serverOwner .. "[Owner] " .. message
		elseif Players[pid]:IsAdmin() then
			message = config.rankColors.admin .. "[Admin] " .. message
		elseif Players[pid]:IsModerator() then
			message = config.rankColors.moderator .. "[Mod] " .. message
		end
	end

	tes3mp.SendMessage(pid, message, true)
end
customCommandHooks.registerCommand(globalChatCommand, defaultChatLocal.globalMessage)


customEventHooks.registerValidator("OnPlayerSendMessage", function(eventStatus, pid, message)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
		if message:sub(1, 1) ~= '/' then
			OnPlayerSendMessage(pid, "/local "..message)
			isValid = false
		end
	end
	
	eventStatus.validDefaultHandler = isValid
	return eventStatus
end)

return defaultChatLocal
