--[[
	GameSetting Changes (by Learwolf)
	
	DESCRIPTION:
		Easily adjust Morrowinds gamesettings options.
	
	** Note that not all gamesettings will work, as some have to be applied 
	before the game starts (and these get pushed after the game has already 
	started/when connecting to the server.)
	
	Also note that different gamesetting types require a different var type.
	For example;
		`fEnchantmentChanceMult` requires you to set a `floatVar` because it has to be a float value.
		`sMagicInsufficientCharge` requires you to set a `stringVar` because it has to be a string value.
		`iPickMaxChance` requires you to set a `intVar` because it has to be an integer value.
	You can tell which type a setting needs based on the first letter in its gamesetting name (f for Float, s for String and i for Integer).
	
	INSTALLATION:
		1) Place this file as `gamesettingChanges.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.gamesettingChanges")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	VERSION HISTORY:
		1.00	8/23/2026	-	Initial Release.
	
--]]

local updateGameSettings = true -- Setting this to false will disable this script on the next server startup.
local runUndoGameSettings = false -- Setting this to true will revert any gamesetting id's found in the `gsettingsToUndo` table further below.

-- Add a game setting id to this table to adjust it for players connecting to the server.
-- ** Note that not all gamesetting id's will work because some require change before starting the game (which is not how TES3MP works) with updating these.
local gsettings = {
	
-- Float Examples:
	-- {id = "fLevelUpHealthEndMult", floatVar = 0}, -- Default: 0.1000
	{id = "fEnchantmentChanceMult", floatVar = 0.1000}, -- Default: 0.1000
	{id = "fWeaponDamageMult", floatVar = 0.0100}, -- Default: 0.1000
	
	
-- String Examples:
	-- {id = "sMessage2", stringVar = "Quit TES3MP?"}, -- Default: "Quit Morrowind?"
	-- {id = "sNotifyMessage39", stringVar = "Your %s skill has increased."}, -- default = "Your %s skill increased to %d."
	{id = "sMagicInsufficientCharge", stringVar = ""}, -- Default: "Item does not have enough charge." -- Setting this to "" removes the message from ever being displayed.
	
	
-- Integer Examples:
	{id = "iPickMinChance", intVar = 1}, -- Default: 5
	{id = "iPickMaxChance", intVar = 95}, -- Default: 75
	
	
}


-- Add any game setting id to this list and start the server to revert that specific gamesetting back to its original value:
local gsettingsToUndo = {
	"fEnchantmentChanceMult",
	"fWeaponDamageMult",
	"sMagicInsufficientCharge",
	"iPickMinChance",
	"iPickMaxChance",
}

local function createRecord()
	
	local doSave = false
	local recordStore = RecordStores["gamesetting"]
	
	if updateGameSettings then
		for i=1,#gsettings do
			if gsettings[i].id ~= nil then
				recordStore.data.permanentRecords[gsettings[i].id] = {
					stringVar = gsettings[i].stringVar,
					intVar = gsettings[i].intVar,
					floatVar = gsettings[i].floatVar
				}
				doSave = true
			end
		end
	end
	
	if runUndoGameSettings then
		if not tableHelper.isEmpty(gsettingsToUndo) then
			for i=1,#gsettingsToUndo do
				recordStore.data.permanentRecords[gsettings[i]] = nil
				doSave = true
			end
		end
	end
	
	if doSave then
		recordStore:Save()
	end
end

local function OnServerPostInit(eventStatus)
	createRecord()
end
customEventHooks.registerHandler("OnServerPostInit", OnServerPostInit)