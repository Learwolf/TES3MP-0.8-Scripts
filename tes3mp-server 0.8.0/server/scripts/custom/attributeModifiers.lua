--[[
	Attributer Modifiers
		version 1.00 (for TES3MP 0.8.1)
			by Learwolf
	
	DESCRIPTION:
		This script allows server owners to customize their players level up attribute modifiers.
		By default, the script will ensure players always get +5 multiplier to all attributes (including luck).
		If you wish, you can customize within the CONFIGURATION SECTION below to fine tune levelup attribue modifiers to your liking.
		
	INSTALLATION:
		1) Place this file as `attributeModifiers.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.attributeModifiers")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	VERSION HISTORY:
		1.00	12/26/2022	-	Initial Release.
	
--]]

attributeModifiers = {}

-- -- -- -- -- -- -- -- --
--
-- CONFIGURATION SECTION:
-- -- -- -- -- -- -- -- --
attributeModifiers.config = {
	
	maxAllAttributesByLevel = 100 -- This automatically max all attributes once player reached this level. (**Set to 0 to disable this feature.**)
	includeLuckBonus = true, -- If true, luck will also have the modifier changes from this script applied. If false, luck will always be a 1 times multiplier.
	
	useStaticFormula = true, -- If set to true, all attribute multipliers will be set to whatever the `staticAttributeMultiplierValue` value (one line below) is on every level up.
	staticAttributeMultiplierValue = 5, -- Boosts the multipler by this static amount every level up. 
	
	-- Dynamic Formula (Only applies if `useStaticFormula` above is set to false):
	dynamicAttributeMultiplierFormula = { -- Boosts the multiplier by this dyanmic formulaic amount every level up.
		every_x_Levels = 10, -- Every 10 levels, increase the multiplier by the add_to_multiplier_by value (one line below).
		add_to_multiplier_by = 1 -- For every `every_x_Levels`, the attribute modifier bonus vwill increase by this amount. The default formula will give players +1 modifier to attributes every 10 levels.
	},
	
	bedRefIdMatches = {"_bed","_bunk"} -- Partial bed refId's to match for bed interaction in order to enforce attribute modifier updates upon interaction. Shouldn't need to touch unless you use a mod that adds new beds with different refId text.
}


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--
-- END OF CONFIGURATION SECTION.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--
-- DO NOT TOUCH ANYTHING FURTHER BELOW UNLESS YOU KNOW WHAT YOU'RE DOING.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Determine what the attribute static or dynamic multiplier value should be:
local determineMultiplierValue = function(pid)
	
	-- if player is using static formula:
	if attributeModifiers.config.useStaticFormula then
		local value = 0
		if attributeModifiers.config.staticAttributeMultiplierValue ~= nil and attributeModifiers.config.staticAttributeMultiplierValue >= 2 then
			value = (attributeModifiers.config.staticAttributeMultiplierValue * 2) -- We multiply by 2 here, because default morrowind GMST's for levelup multiplier values are divisible by 2.
		end
		return value
	end
	
	-- Otherwise, player is using dynamic formula:
	local lvBoost = attributeModifiers.config.dynamicAttributeMultiplierFormula.every_x_Levels or 10
	local attBoost = attributeModifiers.config.dynamicAttributeMultiplierFormula.add_to_multiplier_by or 0
	
	local currentLevel = Players[pid].data.stats.level or 1
	
	local lvFactor = math.floor(currentLevel / lvBoost)
	local multiplierValue = lvFactor * (attBoost * 2) -- We multiply by 2 here, because default morrowind GMST's for levelup multiplier values are divisible by 2.
	
	return multiplierValue
end

-- Push max attributes if applicable:
local maxAttributesAtLevelCap = function(pid)
	if attributeModifiers.config.maxAllAttributesByLevel ~= 0 and tes3mp.GetLevel(pid) >= attributeModifiers.config.maxAllAttributesByLevel then
		
		local reloadAttributes = false
		if Players[pid].data.attributes.Strength.base ~= nil then
			for aName,aData in pairs(Players[pid].data.attributes) do
				if aName ~= nil then
					local aBase = aData.base
					
					if aBase ~= nil and aBase < 100 then
						aData.base = 100
						reloadAttributes = true
					end
				
				end
			end
		end
		
		if reloadAttributes then
			Players[pid]:LoadAttributes()
			Players[pid]:SaveAttributes(packetReader.GetPlayerPacketTables(pid, "PlayerAttribute"))
		end
		
	end
end

-- Push the attributes multiplier to the player:
local pushAttributeIncreases = function(pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		local getMultiplierValue = determineMultiplierValue(pid)
		for attributeName,value in pairs(Players[pid].data.attributes) do
			if attributeName ~= "Luck" or attributeModifiers.config.includeLuckBonus == true then
				local attributeId = tes3mp.GetAttributeId(attributeName)
				tes3mp.SetSkillIncrease(pid, attributeId, getMultiplierValue)
			end
		end
		tes3mp.SendAttributes(pid)
	end
end

-- When a player levels up:
customEventHooks.registerValidator("OnPlayerLevel", function(eventStatus, pid)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
		maxAttributesAtLevelCap(pid)
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

-- Aftere a player levels up:
customEventHooks.registerHandler("OnPlayerLevel", function(eventStatus, pid)
	pushAttributeIncreases(pid)
		
	if levelInfoOutput ~= nil then
		levelInfoOutput.OnPlayerLevel(pid)
	end
	if levelProgressTracker ~= nil then
		levelProgressTracker.trackLevelCheating(pid)
	end
	
	maxAttributesAtLevelCap(pid)
end)

-- When a player logs in:
customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		pushAttributeIncreases(pid)
		maxAttributesAtLevelCap(pid)
	end
end)

-- Whena  player activates an object:
customEventHooks.registerValidator("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
		for _,object in pairs(objects) do
			
			-- Check if object matches a bed refId:
			for x,refIdMatch in pairs(attributeModifiers.config.bedRefIdMatches) do
				if string.match(object.refId, refIdMatch) then
					pushAttributeIncreases(pid)
					break
				end
			end
			
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)


return attributeModifiers