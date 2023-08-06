--[[
	Max Merchants Disposition Script:
		version 1.00 (for TES3MP 0.8 & 0.8.1)
	
	DESCRIPTION:
		This simple script will ensure any actor who can barter will have max disposition when you attempt to barter with them.
		Note that the merchant NPC's disposition will not max until you actually enter the Barter menu with the merchant.
	
	INSTALLATION:
		1) Place this file as `maxMerchantDisposition.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.maxMerchantDisposition")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	
	VERSION HISTORY:
		1.00 (8/5/2023)		- Initial creation per request of GifFromGod on the official TES3MP discord.
--]]


maxMerchantDisposition = {}

customEventHooks.registerValidator("OnObjectDialogueChoice", function(eventStatus, pid, cellDescription, objects)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		for uniqueIndex, object in pairs(objects) do
			if object.dialogueChoiceType == 3 then -- BARTER
				logicHandler.RunConsoleCommandOnObject(pid, "setDisposition 100", cellDescription, uniqueIndex, false)
			end
        end
	end
end)

return maxMerchantDisposition