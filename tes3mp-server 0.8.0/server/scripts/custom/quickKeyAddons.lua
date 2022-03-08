--[[
	Lear's Quick Key Addons
		version 1.00 (for TES3MP 0.8)
	
	DESCRIPTION:
		This script provides server owners a few additional features related to quick keys.
		* The primary feature being additional Quick Key pages. The number of pages can be customized below in the configuration section. 
			(See `quickKeyPages` below.)
		* This script also allow server owners to prevent specific refIds from being set as a Quick Key item. (See `bannedQuickKeyItemsTable` below.)
		* This script also allow server owners to prevent Quick Keys from being activated in specific cells. (See `cellsWithNoQuickKeys` below.)
		* This script has the option to allow player chat macro functionality via Hotkey items. Hotkeys items can be used from a players inventory or 
			bound and used from the Quick Key list. Hotkeys allow players to bind text (such as chat messages or chat commands) and can then be used 
			at the click of a quick key to instantly run the chat or command. (I.E., a macro.) (See `enableHotkeyPortion` and `macroHotKeysCount below.)
			There is no cooldown on Hotkeys, meaning players could spam them. They are disabled by default because of this. Enable them at your own risk.
			
	
	INSTALLATION:
		1) Place this file as `quickKeyAddons.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.quickKeyAddons")
		4) Be sure there are no `--` symbols to the left of it, else it will not work.
		5) Save `customScripts.lua` and restart your server.
	
	
	COMPATIBILITY:
		* This script is not compatibile with any other server scripts that alter the `Cell:SaveContainers(pid)` function.
	
	
	VERSION HISTORY:
		1.00 (3/8/2022)		- Initial public release.
		
	My Public TES3MP 0.8 Scripts Github:
		https://github.com/Learwolf/TES3MP-0.8-Scripts
	
	Enjoy my scripts? Want to say thanks? Consider supporting me on Patreon:
		https://www.patreon.com/nerevarineprophecies
	
	
--]]

quickKeyAddons = {}

local quickKeyPages = 4 -- Default number of quick key pages.
local macroHotKeysCount = 4 -- Default number of hotkey macros.

local bannedQuickKeyItemsTable = { "misc_uni_pillow_unique" } -- add (completely lowercase) item refId's here that you do not want to be able to be set as quick keys.
local cellsWithNoQuickKeys = { "ToddTest" } -- add cell names here for locations you want no quickkeys available to work.

local displayHotkeyActivationText = true -- If true, shows a messagebox stating that you activated the selected hotkey. Set to false to hide.
local enableHotkeyPortion = false -- If true, enables the hotkey/macro portions of this script.

local hotkeyNameCharacterLength = 26 -- number of characters allowed for hotkey name.
local hotkeyMacroTextCharacterLength = 100 -- number of characters allowed for hotkey macro text.

local hotkeyPrefix = "[*HK] " -- What will display before the hotkey text (For inventory sorting purposes.).
local hotkeyBody = "Hotkey " -- What the generic hotkey name is. (Values after this body get auto-populated.)

local qkaPrefix = "[*] " -- Prefix added to quick key paging items display name. (For inventory sorting purposes.)

local qkaLeftRefId = "qka_left" -- refId to use for the page left quick key. Shouldn't need to be changed.
local qkaRightRefId = "qka_right" -- refId to use for the page right quick key. Shouldn't need to be changed.
local qkaHotKeyBaseRefId = "qka_hotkey" -- base refId to use for the hotkey items. Shouldn't need to be changed.

local myQuickHotKeyMenuGui = 7201010 -- Shouldn't need to be changed.
local configureQuickHotKeyMenuGui = 7201011 -- Shouldn't need to be changed.
local myQuickHotKeyNameInputMenuGui = 7201012 -- Shouldn't need to be changed.
local myQuickHotKeyMacroInputMenuGui = 7201013 -- Shouldn't need to be changed.

local doLogs = false -- Print server logs? Used for debugging.


-- DO NOT TOUCH THESE CONFIGS BELOW!!!
local qkaHotKeyRecordType = "book" -- don't touch!
local qkaItemsToAlwaysHave = {qkaLeftRefId,qkaRightRefId} -- This will auto-populate. DO NOT TOUCH!
local refIdsToNeverLose = {qkaLeftRefId,qkaRightRefId} -- This will auto-populate. DO NOT TOUCH!


local doLogging = function(txt)
	if doLogs then
		tes3mp.LogMessage(enumerations.log.INFO, "[quickKeyAddons]: " .. txt)
	end
end

local playerChoiceHandler = {}

local quickKeysBlockedFromOverwrite = function(pid)
	local overwrite = Players[pid].data.customVariables.quickKeyOverwrite
	if overwrite ~= nil and overwrite == true then
		return true
	end
	return false
end

-- Function to add item:
local qkaAddItem = function(pid, refId, count, soul, charge, enchantmentCharge)

	if refId == nil then return end
	if count == nil then count = 1 end
	if soul == nil then soul = "" end
	if charge == nil then charge = -1 end
	if enchantmentCharge == nil then enchantmentCharge = -1 end
	
	refId = string.lower(refId)
	
	if logicHandler.IsGeneratedRecord(refId) then
		local cellDescription = tes3mp.GetCell(pid)
        local cell = LoadedCells[cellDescription]
		local recordType = logicHandler.GetRecordTypeByRecordId(refId)
		if RecordStores[recordType] ~= nil and cell ~= nil then
			local recordStore = RecordStores[recordType]
			for _, visitorPid in pairs(cell.visitors) do
				recordStore:LoadGeneratedRecords(visitorPid, recordStore.data.generatedRecords, {refId})
			end
		end
	end
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
	tes3mp.AddItemChange(pid, refId, count, charge, enchantmentCharge, soul)
	tes3mp.SendInventoryChanges(pid)
	
	Players[pid]:SaveInventory(packetReader.GetPlayerPacketTables(pid, "PlayerInventory"))
	
end

-- Function to remove item:
local qkaRemoveItem = function(pid, refId, count, soul, charge, enchantmentCharge)
	if pid == nil then return end
	if refId == nil then return end
	if count == nil then count = 1 end
	if soul == nil then soul = "" end
	if charge == nil then charge = -1 end
	if enchantmentCharge == nil then enchantmentCharge = -1 end
	
	refId = string.lower(refId)
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
	tes3mp.AddItemChange(pid, refId, count, charge, enchantmentCharge, soul)
	tes3mp.SendInventoryChanges(pid)
	
	Players[pid]:SaveInventory(packetReader.GetPlayerPacketTables(pid, "PlayerInventory"))
end



-- USE THIS AS A MEANS TO RENAME THE HOTKEYS
local renameHotkeyRecordForPid = function(pid, newName, refId, recordType)
	tes3mp.ClearRecords()
	tes3mp.SetRecordType(enumerations.recordType[string.upper(recordType)])
	packetBuilder.AddRecordByType(refId, {baseId = refId, name = newName}, recordType)
	tes3mp.SendRecordDynamic(pid, false, false)
end

local getHkBaseName = function()
	return hotkeyPrefix..hotkeyBody
end

quickKeyAddons.pagingRefIds = {
	qkaLeftRefId, 
	qkaRightRefId
}

local renamePlayersHotkeys = function(pid)
	--renameHotkeyRecordForPid(pid, hotkeyPrefix.."Name Test", "qka_hotkey1", "book")
	for qRefId,data in pairs(Players[pid].data.customVariables.quickHotKeys) do
		if data.name ~= nil then
			renameHotkeyRecordForPid(pid, data.name, qRefId, qkaHotKeyRecordType)
		end
	end
end

local quickKeysPageMessage = function(pid)
	local page = Players[pid].quickKeysPage
	if page then
		tes3mp.MessageBox(pid, -1, "Quick Key Page: "..color.White..page)
	end
end

-- Load a specified quick key page:
local loadQuickKeyPage = function(pid, page)
	if Players[pid].data.customVariables.quickKeyPaging and page ~= nil and Players[pid].data.customVariables.quickKeyPaging[page] ~= nil then
		Players[pid].data.quickKeys = tableHelper.deepCopy(Players[pid].data.customVariables.quickKeyPaging[page])
		Players[pid]:LoadQuickKeys()
	end
end

local removeAnyStoredActiveBannedItems = function(pid)
	local player = Players[pid].data.quickKeys
	for i=1,#player do
		local t = player[i]
		if t ~= nil and t.itemId ~= nil and t.itemId ~= "" then
			if tableHelper.containsValue(bannedQuickKeyItemsTable, t.itemId) then
				t.keyType = 3
				t.itemId = ""
			end
		end
	end
end

local saveBackupQuickKeys = function(pid)
	if Players[pid].data.customVariables.quickKeysBackup == nil then
		Players[pid].data.customVariables.quickKeysBackup = tableHelper.deepCopy(Players[pid].data.quickKeys)
	end
end
local loadBackupQuickKeys = function(pid)
	if Players[pid].data.customVariables.quickKeysBackup ~= nil then
		Players[pid].data.quickKeys = tableHelper.deepCopy(Players[pid].data.customVariables.quickKeysBackup)
		Players[pid].data.customVariables.quickKeysBackup = nil
		removeAnyStoredActiveBannedItems(pid)
		Players[pid]:LoadQuickKeys()
	end
end

-- Block Specific Quick Key Items:
function blockSpecificQuickKeyItem(pid)
	
	local shouldReloadQuickKeys = false
	for index = 0, tes3mp.GetQuickKeyChangesSize(pid) - 1 do
		
		local slot = tes3mp.GetQuickKeySlot(pid, index)
		local itemRefId = tes3mp.GetQuickKeyItemId(pid, index)
		
        if tableHelper.containsValue(bannedQuickKeyItemsTable, itemRefId) then
			tes3mp.SendMessage(pid, color.Error .. "This item cannot be set as a Quick Key.\n", false)
			Players[pid].data.quickKeys[slot] = { keyType = 3, itemId = "" }
			shouldReloadQuickKeys = true
        end
		
    end

	if shouldReloadQuickKeys then
		removeAnyStoredActiveBannedItems(pid)
		Players[pid]:LoadQuickKeys()
	end
end

function clearQuickKeys(pid)
    for keyIndex = 1, 9 do
        Players[pid].data.quickKeys[keyIndex] = { keyType = 3, itemId = "" }
    end
    Players[pid]:LoadQuickKeys()
	doLogging("Cleared quick keys for " .. logicHandler.GetChatName(pid))
end

local checkForQuickKeyClearing = function(pid)
	-- Always clear this player's quick keys if they're in a cell where no quick keys are allowed
	local currentCell = tes3mp.GetCell(pid)
	if tableHelper.containsValue(cellsWithNoQuickKeys, currentCell) then
		
		-- If a backup is not already made, lets make one.
		if Players[pid].data.customVariables.quickKeysBackup == nil then
			saveBackupQuickKeys(pid)
		end
		
        clearQuickKeys(pid)
		tes3mp.MessageBox(pid, -1, "You cannot use Quick Keys in this location.")
		doLogging("Cleared quickkeys for player ["..logicHandler.GetChatName(pid).."] inside cell ["..currentCell.."].")
	else
		loadBackupQuickKeys(pid)
    end
end

-- Change Quick Key Pages:
local changeQuickKeysPage = function(pid, direction)
	
	if quickKeysBlockedFromOverwrite(pid) then
		tes3mp.MessageBox(pid, -1, "You cannot change Quick Keys at this time.")
		
	elseif Players[pid].data.customVariables.quickKeyPaging then
		local totalPageCount = quickKeyPages --#Players[pid].data.customVariables.quickKeyPaging
		local currentPage = Players[pid].quickKeysPage or 1
		
		if direction == "left" then
			logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \"book page2\" 1 1.4")
			if currentPage == 1 then
				currentPage = totalPageCount
			else
				currentPage = currentPage - 1
			end
		elseif direction == "right" then
			logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \"book page\" 1 1.4")
			if currentPage == totalPageCount then
				currentPage = 1
			else
				currentPage = currentPage + 1
			end
		end
		
		Players[pid].quickKeysPage = currentPage
		quickKeysPageMessage(pid)
		clearQuickKeys(pid)
		loadQuickKeyPage(pid, currentPage)
	end
end

-- Get hotkey refId:
local getHotkeyRefId = function(pid, slot)
	return qkaHotKeyBaseRefId..playerChoiceHandler[pid].slot or nil
end

-- Get hotkey name:
local getHotkeyName = function(pid, slot)
	local player = Players[pid].data.customVariables.quickHotKeys
	if player ~= nil and slot ~= nil then
		local t = player[qkaHotKeyBaseRefId..slot]
		if t ~= nil then
			return t.name
		end
	end
	return hotkeyBody..slot --getHkBaseName()..slot
end

-- Get hotkeys macro text:
local getHotkeyMacro = function(pid, slot)
	
	local player = Players[pid].data.customVariables.quickHotKeys
	if player ~= nil then
		local t = player[qkaHotKeyBaseRefId..slot]
		if t ~= nil then
			return t.macro
		end
	end
	return ""
end


--
-- Setup the macro hotkeys here.
--
local activateQuickHotKey = function(pid, slot)
	local player = Players[pid].data.customVariables.quickHotKeys
	if player then
		local i = qkaHotKeyBaseRefId..slot
		if player[i] ~= nil and player[i].name ~= nil and player[i].macro ~= nil then
			
			--logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \"menu_xbox\" 1 1")
			logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \"Menu Click\" 1 1")
			
			if displayHotkeyActivationText then
				tes3mp.MessageBox(pid, -1, "Activate Hotkey "..slot..": "..color.Yellow..player[i].name)
			end
			
			if player[i].macro == nil or player[i].macro == "" then
				quickKeyAddons.myQuickHotKeyMenu(pid)
			else
				OnPlayerSendMessage(pid, player[i].macro)
			end
		end
	end
end

quickKeyAddons.quickKeyPageItemUsed = function(pid, refId)
	
	local currentCell = tes3mp.GetCell(pid)
	if tableHelper.containsValue(cellsWithNoQuickKeys, currentCell) then
		
		if refId == qkaLeftRefId or refId == qkaRightRefId then
			tes3mp.MessageBox(pid, -1, "You cannot change Quick Key Pages here.")
		else
			tes3mp.MessageBox(pid, -1, "You cannot activate Quick Hot Keys here.")
		end
	else
		if refId == qkaLeftRefId then
			changeQuickKeysPage(pid, "left")
		elseif refId == qkaRightRefId then
			changeQuickKeysPage(pid, "right")
		else
			for i=1,macroHotKeysCount do
				if refId == qkaHotKeyBaseRefId..i then
					activateQuickHotKey(pid, i)
				end
			end
		end
		
	end
end

local saveQuickKeyPage = function(pid)
	if Players[pid].data.customVariables.quickKeyPaging then
		local currentCell = tes3mp.GetCell(pid)
		if not tableHelper.containsValue(cellsWithNoQuickKeys, currentCell) then
			local page = Players[pid].quickKeysPage or 1
			Players[pid].data.customVariables.quickKeyPaging[page] = tableHelper.deepCopy(Players[pid].data.quickKeys)
		end
	end
end

customEventHooks.registerValidator("OnPlayerQuickKeys", function(eventStatus, pid)
	Players[pid]:SaveQuickKeys(packetReader.GetPlayerPacketTables(pid, "PlayerQuickKeys"))
	blockSpecificQuickKeyItem(pid)
    checkForQuickKeyClearing(pid)
	
	saveQuickKeyPage(pid)
end)

customEventHooks.registerValidator("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	checkForQuickKeyClearing(pid)
end)

customEventHooks.registerValidator("OnPlayerItemUse", function(eventStatus, pid, itemRefId)
    if tableHelper.containsValue(qkaItemsToAlwaysHave, itemRefId) then
		quickKeyAddons.quickKeyPageItemUsed(pid, itemRefId)
        return customEventHooks.makeEventStatus(false, false)
    end
end)


local getMyHotKeyList = function(pid)
	
	local txt = "  * Exit"
	
	local player = Players[pid].data.customVariables.quickHotKeys
	if player ~= nil then
		
		for i=1,macroHotKeysCount do
			local t = player[qkaHotKeyBaseRefId..i]
			t = {name = getHotkeyName(pid, i), macro = getHotkeyMacro(pid, i)}
			txt = txt.."\n[Slot "..i.."] - Hotkey Name: "..color.White..t.name.."\n    Macro Text: "..color.White..t.macro
		end
		
	end
	return txt
end


quickKeyAddons.myQuickHotKeyMenu = function(pid)
	playerChoiceHandler[pid] = {slot = 1, name = "", macro = ""}
	local message = color.DarkOrange.."Quick Hot Keys\n"..color.White.."Select a hotkey to edit and press OK"
	local myItems = getMyHotKeyList(pid)
	tes3mp.ListBox(pid, myQuickHotKeyMenuGui, message, myItems)
end

quickKeyAddons.configureQuickHotKeyMenu = function(pid)
	local mSlot = playerChoiceHandler[pid].slot
	if mSlot then
		local hkName = playerChoiceHandler[pid].name or getHkBaseName()..mSlot
		local macroTxt = playerChoiceHandler[pid].macro or ""
		local message = color.DarkOrange.."Configure Quick Hot Key\n"..
			color.Yellow.."Name: "..color.White..hkName..
			color.Yellow.."\nMacro: "..color.White..macroTxt.."\n"
		
		tes3mp.CustomMessageBox(pid, configureQuickHotKeyMenuGui, message, "Change Macro Name;Change Macro Text;Save Macro;Cancel")
	end
end


local hotkeyNameInput = function(pid)
	local tTxt = color.Yellow.."Enter a name for this hotkey:"
	local bTxt = color.Yellow.."(Limit of "..hotkeyNameCharacterLength.." characters displayed.)\nLeave blank to use the default hotkey name."
	tes3mp.InputDialog(pid, myQuickHotKeyNameInputMenuGui, tTxt, bTxt)
end


local hotkeyMacroTextInput = function(pid)
	local tTxt = color.Yellow.."Enter the macro text for this hotkey:"
	local bTxt = color.Yellow.."(Limit of "..hotkeyMacroTextCharacterLength.." characters.)\nExample macro text: /character"
	tes3mp.InputDialog(pid, myQuickHotKeyMacroInputMenuGui, tTxt, bTxt)
end



local updateHotkey = function(pid)
	local slot = playerChoiceHandler[pid].slot
	if slot ~= nil then
		
		local refId = getHotkeyRefId(pid, slot)
		Players[pid].data.customVariables.quickHotKeys[refId].name = hotkeyPrefix..playerChoiceHandler[pid].name --hotkeyPrefix..playerChoiceHandler[pid].name
		Players[pid].data.customVariables.quickHotKeys[refId].macro = playerChoiceHandler[pid].macro
		renamePlayersHotkeys(pid)
		
		logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \"scroll\" 1 1")
		tes3mp.SendMessage(pid, color.Yellow.."[QuickHotkey]: "..color.White..Players[pid].data.customVariables.quickHotKeys[refId].name.." saved successfully!\n", false)
	end
end


customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
	
		if idGui == myQuickHotKeyMenuGui then
			isValid = false
			
			if tonumber(data) == nil or tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then -- Back/Cancel
				return
			else
				local count = 0.5
				for i=1, tonumber(data) do
					count = count + 0.5
				end
				
				local button = math.floor(count)
				
				if button >= 1 and button <= macroHotKeysCount then
					playerChoiceHandler[pid] = {slot = button, name = getHotkeyName(pid, button), macro = getHotkeyMacro(pid, button)}
					quickKeyAddons.configureQuickHotKeyMenu(pid)
				end
			end

		elseif idGui == configureQuickHotKeyMenuGui then
			isValid = false
			
			if tonumber(data) == nil or tonumber(data) >= 3 then -- Back/Cancel
				quickKeyAddons.myQuickHotKeyMenu(pid)
			
			elseif tonumber(data) == 0 then -- Change Name
				-- go to change name text menu for text input.
				hotkeyNameInput(pid)
				
			elseif tonumber(data) == 1 then -- Change Macro Text
				-- go to macro text menu for text input.
				hotkeyMacroTextInput(pid)
				
			elseif tonumber(data) == 2 then -- Save Macro
				-- playerChoiceHandler[pid] = {slot = button, name = getHotkeyName(pid, button), macro = getHotkeyMacro(pid, button)}
				updateHotkey(pid)
				quickKeyAddons.myQuickHotKeyMenu(pid)
			end
		
		elseif idGui == myQuickHotKeyNameInputMenuGui then
			isValid = false
			
			if tostring(data) ~= nil then
				
				local newName = tostring(data)
				if tostring(data) ~= " " then
					newName = newName:sub(1,hotkeyNameCharacterLength)
					local limitAmount = hotkeyNameCharacterLength - 3
					if string.len(tostring(newName)) > limitAmount then
						newName = newName .. "..."
						tes3mp.SendMessage(pid, color.Error.."Your hotkey name has too many characters.\n", false)
					end
					playerChoiceHandler[pid].name = newName
				else
					playerChoiceHandler[pid].name = hotkeyBody..playerChoiceHandler[pid].slot -- getHkBaseName()..playerChoiceHandler[pid].slot
				end
				
				quickKeyAddons.configureQuickHotKeyMenu(pid)
			end

		elseif idGui == myQuickHotKeyMacroInputMenuGui then
			isValid = false
			
			if tostring(data) ~= nil then
				
				local mText = tostring(data)
				if tostring(data) ~= " " then
					mText = mText:sub(1,hotkeyMacroTextCharacterLength)
					local limitAmount = hotkeyMacroTextCharacterLength - 3
					if string.len(tostring(mText)) > limitAmount then
						mText = mText .. "..."
						tes3mp.SendMessage(pid, color.Error.."Your macro text has too many characters.\n", false)
					end
					playerChoiceHandler[pid].macro = mText
				else
					playerChoiceHandler[pid].macro = ""
				end
				
				quickKeyAddons.configureQuickHotKeyMenu(pid)
			end


		end
		
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

local removeAnyPreviouslyStoredBannedItems = function(pid)
	local player = Players[pid].data.customVariables.quickKeyPaging
	for i=1,#player do
		for x=1,#player[i] do
			local t = player[i][x]
			if t ~= nil and t.itemId ~= nil and t.itemId ~= "" then
				if tableHelper.containsValue(bannedQuickKeyItemsTable, t.itemId) then
					t.keyType = 3
					t.itemId = ""
				end
			end
		end
	end
end

local loadInitialQuickKeyPages = function(pid)
	
	for _,refId in pairs(qkaItemsToAlwaysHave) do
		if not inventoryHelper.containsItem(Players[pid].data.inventory, refId) then
			qkaAddItem(pid, refId, 1)
		end
	end
	
	local player = Players[pid].data.customVariables.quickKeyPaging
	if player == nil or #player ~= quickKeyPages then
		
		local page = {{keyType = 0,itemId = qkaLeftRefId},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 3,itemId = ""},{keyType = 0,itemId = qkaRightRefId}}
		Players[pid].data.customVariables.quickKeyPaging = {}
		Players[pid]:LoadQuickKeys()
		
		for i=1,quickKeyPages do
			table.insert(Players[pid].data.customVariables.quickKeyPaging, page)
		end
		Players[pid].data.customVariables.quickKeyPaging[1] = page --tableHelper.deepCopy(Players[pid].data.quickKeys)
	end
	
	removeAnyPreviouslyStoredBannedItems(pid) -- Now, lets remove any items that should be banned from quickkeys.
	Players[pid].data.quickKeys = tableHelper.deepCopy(Players[pid].data.customVariables.quickKeyPaging[1])
	
	Players[pid]:LoadQuickKeys()
	Players[pid].quickKeysPage = 1
	
	
	-- HOTKEY STUFF NOW:
	local player = Players[pid].data.customVariables.quickHotKeys
	
	if player == nil then
		
		local qhk = {}
		for i=1,macroHotKeysCount do
			qhk[qkaHotKeyBaseRefId..i] = {name = getHkBaseName()..i, macro = ""}
		end
		Players[pid].data.customVariables.quickHotKeys = qhk
	end
	
	-- Lets add the initial amount of quickhotkeys:
	for i=1,macroHotKeysCount do
		local tRefId = qkaHotKeyBaseRefId..i
		local inventory = Players[pid].data.inventory
		
		if enableHotkeyPortion then
			if not inventoryHelper.containsItem(inventory, tRefId) then
				qkaAddItem(pid, tRefId, 1)
			end
		else
			if inventoryHelper.containsItem(inventory, tRefId) then
				qkaRemoveItem(pid, tRefId, 1)
			end
		end
	end
	
	--renames players hotkeys to whatever they have saved.
	renamePlayersHotkeys(pid)
end

-- Setup quickkey paging on login.
customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		loadInitialQuickKeyPages(pid)
	end
end)

local callMacroMenu = function(pid, cmd)
	if enableHotkeyPortion then
		quickKeyAddons.myQuickHotKeyMenu(pid)
	else
		tes3mp.SendMessage(pid, color.Error .. "Hotkeys have been disabled on this server.\n", false)
	end
end
customCommandHooks.registerCommand("macro", callMacroMenu)
customCommandHooks.registerCommand("hotkey", callMacroMenu)
customCommandHooks.registerCommand("hotkeys", callMacroMenu)
customCommandHooks.registerCommand("hk", callMacroMenu)

-- Determine if item should be removable or not:
local itemShouldNotBeRemovable = function(itemRefId)
	
	for _,refId in pairs(refIdsToNeverLose) do
		local lowerRefId = string.lower(refId)
		if string.match(lowerRefId, itemRefId) then
			return true
		end
	end
	
	return false
end

-- Function called when a player tries to add a hotkey item to a container:
quickKeyAddons.preventStorage = function(pid, action, refId, itemRefId, itemCount, itemCharge, itemEnchantmentCharge, itemSoul)
	if itemShouldNotBeRemovable(string.lower(itemRefId)) then
		if action == enumerations.container.ADD then
			
			qkaAddItem(pid, itemRefId, itemCount, itemSoul, itemCharge, itemEnchantmentCharge)
			
			tes3mp.MessageBox(pid, -1, "One or more items cannot be removed from your inventory.")
			return true
			
		end
	end
end


customEventHooks.registerValidator("OnObjectPlace", function(eventStatus, pid, cellDescription, objects)
	
	--tableHelper.print(objects)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
		
		for uniqueIndex, object in pairs(objects) do
			local refId = object.refId
			
			if itemShouldNotBeRemovable(string.lower(refId)) then
				
				local soul = object.soul
				local charge = object.charge
				local enchantmentCharge = object.enchantmentCharge
				local count = object.count
				
				qkaAddItem(pid, refId, count, soul, charge, enchantmentCharge)	
				
				tes3mp.MessageBox(pid, -1, "You cannot drop that item.")
				
				return customEventHooks.makeEventStatus(false, false)
			end
		end
	
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)


-- Create the QKA items:
local function createRecord()
	
	local recordStore = RecordStores[qkaHotKeyRecordType]
	
	recordStore.data.permanentRecords[qkaRightRefId] = {
		name = qkaPrefix.."Quick Keys Page +",
		text = "",
		script = "",
		icon = "menu_number_inc.dds",
		scrollState = true,
		enchantmentId = "",
		enchantmentCharge = 0,
		skillId = -1,
		weight = 0,
		value = 0
	}
	
	recordStore.data.permanentRecords[qkaLeftRefId] = {
		name = qkaPrefix.."Quick Keys Page -",
		text = "",
		script = "",
		icon = "menu_number_dec.dds",
		scrollState = true,
		enchantmentId = "",
		enchantmentCharge = 0,
		skillId = -1,
		weight = 0,
		value = 0
	}
	
	for i=1,macroHotKeysCount do
		recordStore.data.permanentRecords[qkaHotKeyBaseRefId..i] = {
			name = getHkBaseName()..i,
			text = "",
			script = "", -- "macroHotkey",
			icon = "m\\tx_scroll_03.dds",
			scrollState = true,
			enchantmentId = "",
			enchantmentCharge = 0,
			skillId = -1,
			weight = 0,
			value = 0
		}
	end
	
	recordStore:Save()
end

local function OnServerPostInit(eventStatus)
	createRecord()
	if enableHotkeyPortion then
		for i=1,macroHotKeysCount do
			tableHelper.insertValueIfMissing(qkaItemsToAlwaysHave, qkaHotKeyBaseRefId..i)
		end
	end
	
	-- This is a stand alone way of preventing loss of the hotkey items:
	local tablesToUse = {qkaItemsToAlwaysHave}
	for _,tableName in pairs(tablesToUse) do
		for _,refId in pairs(tableName) do
			tableHelper.insertValueIfMissing(refIdsToNeverLose, refId)
		end
	end
	
	-- This alters the Cell:SaveContainers to what it needs to be for this script to work correctly. This will interfere with any other scripts that alter Cell:SaveContainers(pid)
	function Cell:SaveContainers(pid)

		tes3mp.ReadReceivedObjectList()
		tes3mp.CopyReceivedObjectListToStore()

		tes3mp.LogMessage(enumerations.log.INFO, "Saving Container from " .. logicHandler.GetChatName(pid) ..
			" about " .. self.description)

		local packetOrigin = tes3mp.GetObjectListOrigin()
		local action = tes3mp.GetObjectListAction()
		local subAction = tes3mp.GetObjectListContainerSubAction()

		for objectIndex = 0, tes3mp.GetObjectListSize() - 1 do

			local uniqueIndex = tes3mp.GetObjectRefNum(objectIndex) .. "-" .. tes3mp.GetObjectMpNum(objectIndex)
			local refId = tes3mp.GetObjectRefId(objectIndex)

			tes3mp.LogAppend(enumerations.log.INFO, "- " .. uniqueIndex .. ", refId: " .. refId)

			self:InitializeObjectData(uniqueIndex, refId)

			tableHelper.insertValueIfMissing(self.data.packets.container, uniqueIndex)

			local inventory = self.data.objectData[uniqueIndex].inventory

			-- If this object's inventory is nil, or if the action is SET,
			-- change the inventory to an empty table
			if inventory == nil or action == enumerations.container.SET then
				inventory = {}
			end

			for itemIndex = 0, tes3mp.GetContainerChangesSize(objectIndex) - 1 do

				local itemRefId = tes3mp.GetContainerItemRefId(objectIndex, itemIndex)
				local itemCount = tes3mp.GetContainerItemCount(objectIndex, itemIndex)
				local itemCharge = tes3mp.GetContainerItemCharge(objectIndex, itemIndex)
				local itemEnchantmentCharge = tes3mp.GetContainerItemEnchantmentCharge(objectIndex, itemIndex)
				local itemSoul = tes3mp.GetContainerItemSoul(objectIndex, itemIndex)
				local actionCount = tes3mp.GetContainerItemActionCount(objectIndex, itemIndex)

				-- Lear edit:
				if quickKeyAddons.preventStorage(pid, action, refId, itemRefId, itemCount, itemCharge, itemEnchantmentCharge, itemSoul) then
					return self:LoadContainers(pid, self.data.objectData, {uniqueIndex})
				end
				-- /End Lear edit.

				-- Check if the object's stored inventory contains this item already
				if inventoryHelper.containsItem(inventory, itemRefId, itemCharge, itemEnchantmentCharge, itemSoul) then
					local foundIndex = inventoryHelper.getItemIndex(inventory, itemRefId, itemCharge,
						itemEnchantmentCharge, itemSoul)
					local item = inventory[foundIndex]

					if action == enumerations.container.ADD then
						tes3mp.LogAppend(enumerations.log.VERBOSE, "- Adding count of " .. itemCount .. " to existing item " ..
							item.refId .. " with current count of " .. item.count)
						item.count = item.count + itemCount

					elseif action == enumerations.container.REMOVE then
						local newCount = item.count - actionCount

						-- The item will still exist in the container with a lower count
						if newCount > 0 then
							tes3mp.LogAppend(enumerations.log.VERBOSE, "- Removed count of " .. actionCount .. " from item " ..
								item.refId .. " that had count of " .. item.count .. ", resulting in remaining count of " .. newCount)
							item.count = newCount
						-- The item is to be completely removed
						elseif newCount == 0 then
							inventory[foundIndex] = nil
						else
							actionCount = item.count
							tes3mp.LogAppend(enumerations.log.WARN, "- Attempt to remove count of " .. actionCount ..
								" from item" .. item.refId .. " that only had count of " .. item.count)
							tes3mp.LogAppend(enumerations.log.WARN, "- Removed just " .. actionCount .. " instead")
							tes3mp.SetContainerItemActionCountByIndex(objectIndex, itemIndex, actionCount)
							inventory[foundIndex] = nil
						end

						-- Is this a generated record? If so, remove the link to it
						if inventory[foundIndex] == nil and logicHandler.IsGeneratedRecord(itemRefId) then
							local recordStore = logicHandler.GetRecordStoreByRecordId(itemRefId)

							if recordStore ~= nil then
								self:RemoveLinkToRecord(recordStore.storeType, itemRefId, uniqueIndex)
							end
						end
					end
				else
					if action == enumerations.container.REMOVE then
						tes3mp.LogAppend(enumerations.log.WARN, "- Attempt to remove count of " .. actionCount .. 
							" from non-existent item " .. itemRefId)
						tes3mp.SetContainerItemActionCountByIndex(objectIndex, itemIndex, 0)
					else
						tes3mp.LogAppend(enumerations.log.VERBOSE, "- Added new item " .. itemRefId .. " with count of " ..
							itemCount)
						inventoryHelper.addItem(inventory, itemRefId, itemCount,
							itemCharge, itemEnchantmentCharge, itemSoul)

						-- Is this a generated record? If so, add a link to it
						if logicHandler.IsGeneratedRecord(itemRefId) then
							local recordStore = logicHandler.GetRecordStoreByRecordId(itemRefId)

							if recordStore ~= nil then
								self:AddLinkToRecord(recordStore.storeType, itemRefId, uniqueIndex)
							end
						end
					end
				end
			end

			tableHelper.cleanNils(inventory)
			self.data.objectData[uniqueIndex].inventory = inventory
		end

		-- Is this a player replying to our request for container contents?
		-- If so, only send the reply to other players
		-- i.e. sendToOtherPlayers is true and skipAttachedPlayer is true
		if subAction == enumerations.containerSub.REPLY_TO_REQUEST then
			tes3mp.SendContainer(true, true)
		-- Is this a container packet originating from a client script or
		-- dialogue? If so, its effects have already taken place on the
		-- sending client, so only send it to other players
		elseif packetOrigin == enumerations.packetOrigin.CLIENT_SCRIPT_LOCAL or
			packetOrigin == enumerations.packetOrigin.CLIENT_SCRIPT_GLOBAL or
			packetOrigin == enumerations.packetOrigin.CLIENT_DIALOGUE then
			tes3mp.SendContainer(true, true)
		-- Otherwise, send the received packet to everyone, including the
		-- player who sent it (because no clientside changes will be made
		-- to the related container otherwise)
		-- i.e. sendToOtherPlayers is true and skipAttachedPlayer is false
		else
			tes3mp.SendContainer(true, false)
		end

		self:QuicksaveToDrive()

		-- Were we waiting on a full container data request from this pid?
		if self.isRequestingContainerData == true and self.containerRequestPid == pid and
			subAction == enumerations.containerSub.REPLY_TO_REQUEST then
			self.isRequestingContainerData = false
			self.data.loadState.hasFullContainerData = true

			tes3mp.LogAppend(enumerations.log.INFO, "- " .. self.description ..
				" is now recorded as having full container data")
		end
		
	end
	
end
customEventHooks.registerHandler("OnServerPostInit", OnServerPostInit)

return quickKeyAddons