--[[
	
	MWSript Converter for TES3MP 0.8
		by Learwolf
	
	The purpose of this script is to convert custom morrowind scripts into tes3mp custom record scripts
	
	
	For this script to work, it requires user setup. Please see my notes below or my tutorial video at:
		https://youtu.be/AkbDi651a8c
	
	
	1) You are required to create a folder called "MWScripts" (without the quotes) ionside the `\server\data\custom` folder.
	2) This newly created MWScripts folder will be where you add in your custom morrwoind scripts.
	3) Create/Save/Edit any morrowind scripts with a text editor (such as notepad++) and ensure the scripts file extension is saved as:
		`.es3`
	So for example, if your scripts name is `testScript`, you would save the file as `testScript.es3`
	
	4) In the `scriptsToConvert` table below, add the scripts name in quotations and with a comma at the end (do NOT include the `.es3` at the end here).
		(See example in the table below, but make sure your actual scripts do not have a `--` infront of them.)
	
	5) The `scriptsToDelete` table allows you to delete scripts that have been saved to your `script.json` file.
		(Used for removing no longer used/wanted scripts.) NOTE: YOU WILL NEED TO MANUALLY REMOVE THESE SCRIPT LINKS FROM ANY ACTOR/CREATURE/ACTIVATOR IT IS ATTACHED TO!
	
	[OPTIONALS]:
	6) The `npcScriptAttachments` table allows you to attach a script to any actor(s). See example below.
	7) The `creatureScriptAttachments` table allows you to attach a script to any creature(s). See example below.
	8) The `activatorScriptAttachments` table allows you to attach a script to any activator(s). See example below.
	
--]]

-- Scripts to add to your servers custom records:
local scriptsToConvert = {
	-- "myFirstScript",
	
}

-- Scripts to attach to specific npc refIds:
local npcScriptAttachments = {
	-- ["myFirstScript"] = {"caius cosades", "divayth fyr"},
	
}

-- Scripts to attach to specific creature refIds:
local creatureScriptAttachments = {
	-- ["myFirstScript"] = {"alit", "ancestor_ghost"},
	
}

-- Scripts to attach to specific activator refIds:
local activatorScriptAttachments = {
	-- ["myFirstScript"] = {"active_sign_balmora_01", "active_sign_balmora_02"},
	
}

-- Scripts to delete from your servers custom records:
local scriptsToDelete = {
	-- "myFirstScript"
	
}


--==--==--==--==--==--==--==--==--
-- Do not touch past this point!
--==--==--==--==--==--==--==--==--

-- see if the fileName exists
function file_exists(fileName)
  local f = io.open(fileName, "a")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a fileName, returns an empty 
-- list/table if the fileName does not exist
function lines_from(fName)
  local fileName = tes3mp.GetModDir().."/custom/MWScripts/"..fName..".es3"
  if not file_exists(fileName) then return nil end
  lines = {}
  for line in io.lines(fileName) do 
	lines[#lines + 1] = line
  end
  return lines
end


local function OnServerPostInit(eventStatus)
	-- http://lua-users.org/wiki/FileInputOutput
	
	
	local recordStore = RecordStores["script"]
	local doSave = false
	
	for _,i in pairs(scriptsToConvert) do
		-- tests the functions above
		local fileName = i
		print("Adding Custom Morrowind Script: "..i)
		local lines = lines_from(fileName)
		if lines ~= nil then
		
			local scriptToAdd = ""
			-- print all line numbers and their contents
			for k,v in pairs(lines) do
			  scriptToAdd = scriptToAdd..v.."\n"
			end
			
			recordStore.data.permanentRecords[fileName] = { scriptText = scriptToAdd }
			
			doSave = true
		end
	end
	
	
	if scriptsToDelete ~= nil and not tableHelper.isEmpty(scriptsToDelete) then
		for _,scriptId in pairs(scriptsToDelete) do
			recordStore.data.permanentRecords[scriptId] = nil
			doSave = true
		end
	end
	
	if doSave then
		recordStore:Save()
	end
	
	if npcScriptAttachments ~= nil then
		
		recordStore = RecordStores["npc"]
		local doNpcSave = false
		
		for scriptId,refIds in pairs(npcScriptAttachments) do
			if scriptId ~= nil and refIds ~= nil and not tableHelper.isEmpty(refIds) then
				for _,refId in pairs(refIds) do
					if refId ~= nil then
						recordStore.data.permanentRecords[string.lower(refId)] = {
							baseId = string.lower(refId),
							script = scriptId
						}
						doNpcSave = true
					end
				end
			end
			
		end
		
		if doNpcSave then
			recordStore:Save()
		end
		
	end
	
	if creatureScriptAttachments ~= nil then
		
		recordStore = RecordStores["creature"]
		local doCreatSave = false
		
		for scriptId,refIds in pairs(creatureScriptAttachments) do
			if scriptId ~= nil and refIds ~= nil and not tableHelper.isEmpty(refIds) then
				for _,refId in pairs(refIds) do
					if refId ~= nil then
						recordStore.data.permanentRecords[string.lower(refId)] = {
							baseId = string.lower(refId),
							script = scriptId
						}
						doCreatSave = true
					end
				end
			end
			
		end
		
		if doCreatSave then
			recordStore:Save()
		end
		
	end
	
	if activatorScriptAttachments ~= nil then
		
		recordStore = RecordStores["activator"]
		local doActivatorSave = false
		
		for scriptId,refIds in pairs(activatorScriptAttachments) do
			if scriptId ~= nil and refIds ~= nil and not tableHelper.isEmpty(refIds) then
				for _,refId in pairs(refIds) do
					if refId ~= nil then
						recordStore.data.permanentRecords[string.lower(refId)] = {
							baseId = string.lower(refId),
							script = scriptId
						}
						doActivatorSave = true
					end
				end
			end
			
		end
		
		if doActivatorSave then
			recordStore:Save()
		end
		
	end
	
end
customEventHooks.registerHandler("OnServerPostInit", OnServerPostInit)
