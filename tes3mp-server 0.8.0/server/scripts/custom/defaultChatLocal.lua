--[[
	Default to Local Chat
		version 1.00 (For TES3MP 0.8)
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
		
--]]


defaultChatLocal = {}

-- CONFIGURATION:
local globalChatCommand = "global" -- Command to use (followed by message text) to speak in global chat. (i.e. "global" == /global enter text here to speak globally.)
local showStaffBadgeInLocalChat = true -- If true, will display staff member badges in local chat, similar to how global chat does.
local showStaffBadgeInGlobalChat = true -- If true, will display staff member badges in global chat.

-- -- -- -- -- -- -- -- -- -- -- -- 
-- No touch beyond this point.
-- -- -- -- -- -- -- -- -- -- -- -- 

defaultChatLocal.globalMessage = function(pid, cmd)
	local message = color.White .. logicHandler.GetChatName(pid) .. ": " .. tableHelper.concatenateFromIndex(cmd, 2) .. "\n"

	if showStaffBadgeInGlobalChat == true then
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
	end

	tes3mp.SendMessage(pid, message, true)
end
customCommandHooks.registerCommand(globalChatCommand, defaultChatLocal.globalMessage)


customEventHooks.registerValidator("OnPlayerSendMessage", function(eventStatus, pid, message)
	
	 -- Is this a chat command? If so, pass it over to the commandHandler
	if message:sub(1, 1) == '/' then

		local command = (message:sub(2, #message)):split(" ")
		commandHandler.ProcessCommand(pid, command)
	else
		local cellDescription = Players[pid].data.location.cell
		
		if logicHandler.IsCellLoaded(cellDescription) == true then
			for index, visitorPid in pairs(LoadedCells[cellDescription].visitors) do

				local message = logicHandler.GetChatName(pid) .. " to local area: "
				
				if showStaffBadgeInLocalChat == true then
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
				end
				
				message = message .. tableHelper.concatenateFromIndex(cmd, 2) .. "\n"
				tes3mp.SendMessage(visitorPid, message, false)
			end
		end

	end	
	eventStatus.validDefaultHandler = false
	return eventStatus
end)

return defaultChatLocal