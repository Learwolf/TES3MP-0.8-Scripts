--[[
	Lear's Custom Merchant Restock Script:
		version 1.00 (for TES3MP 0.8 & 0.8.1)
	
	DESCRIPTION:
		This simple script will ensure your designated merchants always have their gold restocked.
		Simply add the refId of the merchant you want to always restock gold into the `restockingGoldMerchants` table below.
	
	INSTALLATION:
		1) Place this file as `customMerchantRestock.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.customMerchantRestock")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	
	VERSION HISTORY:
		1.00 (5/30/2022)		- Initial public release.
--]]


customMerchantRestock = {}

-- Add the refId of merchants you want to restock their gold every time the "Barter" option is selected below:
local restockingGoldMerchants = {
	"mudcrab_unique",
	"scamp_creeper"
}


local initialMerchantGoldTracking = {} -- Used below for tracking merchant uniqueIndexes and their goldPools.
local fixGoldPool = function(pid, cellDescription, uniqueIndex)
	
	if initialMerchantGoldTracking[uniqueIndex] ~= nil then
	
		local cell = LoadedCells[cellDescription]
		local objectData = cell.data.objectData
		if objectData[uniqueIndex] ~= nil and objectData[uniqueIndex].refId ~= nil then
			
			local currentGoldPool = objectData[uniqueIndex].goldPool
			
			if currentGoldPool ~= nil and currentGoldPool < initialMerchantGoldTracking[uniqueIndex] then
				
				tes3mp.ClearObjectList()
				tes3mp.SetObjectListPid(pid)
				tes3mp.SetObjectListCell(cellDescription)
				
				local lastGoldRestockHour = objectData[uniqueIndex].lastGoldRestockHour
				local lastGoldRestockDay = objectData[uniqueIndex].lastGoldRestockDay
				
				if lastGoldRestockHour == nil or lastGoldRestockDay == nil then
					objectData[uniqueIndex].lastGoldRestockHour = 0
					objectData[uniqueIndex].lastGoldRestockDay = 0
				end
				
				objectData[uniqueIndex].goldPool = initialMerchantGoldTracking[uniqueIndex]

				packetBuilder.AddObjectMiscellaneous(uniqueIndex, objectData[uniqueIndex])
				
				tes3mp.SendObjectMiscellaneous()
			
			end
			
		end
		
	end
	
end

customEventHooks.registerValidator("OnObjectDialogueChoice", function(eventStatus, pid, cellDescription, objects)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		for uniqueIndex, object in pairs(objects) do
			
			for _,refId in pairs(restockingGoldMerchants) do
				if object.refId == refId then
					if object.dialogueChoiceType == 3 then -- BARTER
						fixGoldPool(pid, cellDescription, uniqueIndex)
					end
				end
			end
			
        end
	end
end)

customEventHooks.registerValidator("OnObjectMiscellaneous", function(eventStatus, pid, cellDescription, objects)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		for uniqueIndex, object in pairs(objects) do
			
			if object.goldPool ~= nil and object.goldPool > 0 then
				for _,refId in pairs(restockingGoldMerchants) do
					if object.refId == refId then		
						if initialMerchantGoldTracking[uniqueIndex] == nil then
							initialMerchantGoldTracking[uniqueIndex] = object.goldPool
						else
							fixGoldPool(pid, cellDescription, uniqueIndex)
						end
					end
				end
			end
			
        end
	end
end)

return customMerchantRestock