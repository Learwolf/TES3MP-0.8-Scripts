--[[
	deathdrop
		by David-AW
			(Updated for TES3MP 0.8 by Learwolf)
	
	INSTALLATION:
		
		1) Drop this script (deathdrop.lua) into your `\server\scripts\custom` folder.
		2) Add the following text to a new line in your `customScripts.lua`:
			require("custom/deathdrop")
		3) Save `customScripts.lua` and restart the server.
		
--]]



deathdrop = {}



local enableSafeZones = true -- If true then PVP in safezone will jail the killer and items will not drop
local dropItemsOnDeath = true -- Allow dropping of Items on death
local dropItemsFromPVP = true -- Do you want players to be able to take items from other players in PVP.
local dropItemsFromPVE = true -- Do you want players to have to run back to their gear after a lost fight with nature.
local dropItemsFromPVEInSafeZone = true -- Do you want players to drop their items in SafeZone if killed by NPC
local dropItemsFromSuicide = true -- This could mean player died from magic, or committed suicide.
local dropItemsFromSuicideInSafeZone = false -- Can be used as a way around SafeZone if enabled.
local dropItemsWhenJailed = true -- When a player spawn kills their items will drop before being sent to jail

local jailTimeInMins = 5
local jailedMsg = "You were sent to jail for killing a player in a safezone, your sentence is "..jailTimeInMins.." minutes.\n"
local releaseMsg = "You were released from jail.\n"
local jailMsgColor = color.DarkSalmon

local broadcastWhenPlayerGetsJailed = true
local msg = " was sent to jail for killing another player in a safezone.\n"
local msgColor = color.DarkSalmon

local safeExteriorCells = {"-3, -2", "-3, -1", "-3, -3", "-2, -2", "-4, -2"}
local safeInteriorCellHeaders = {"Balmora,"}
local notifyIfInSafeZone = true
local enteringMsg = "You have entered a safezone.\n"
local exitingMsg = "You have left a safezone.\n"
local enterMsgColor = color.Green
local exitMsgColor = color.Red

-- you can use [ deathDrop.IsPlayerInJail(pid) ] and [ deathDrop.IsPlayerInSafeZone(pid) ] for your custom scripts if your script needs to know if someone is in the safezone or jailed.

local jail1 = {
	cell = "Vivec, Hlaalu Prison Cells",
	posX = 245,
	posY = 504,
	posZ = -114.6,
	rotX = 0.11703610420227,
	rotZ = 3.1264209747314
}

local jail2 = {
	cell = "Vivec, Hlaalu Prison Cells",
	posX = 253,
	posY = -279,
	posZ = -116,
	rotX = 0.12100458145142,
	rotZ = 0.007171630859375
}

local jailcells = {jail1, jail2}


local jailed = {}
local safePlayers = {}

customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		
		local player = Players[pid]
		
		local cellDescription = player.data.location.cell
		
		local diedInSafeZone = false
		local diedToAPlayer = false
		local diedToUnknown = false
		
		if deathdrop.IsPlayerInSafeZone(pid) == true then
			diedInSafeZone = true
		end

		local cell = LoadedCells[cellDescription] -- Get the cell that player died in
		local killer = nil
		
		if tes3mp.DoesPlayerHavePlayerKiller(pid) then
			local killerPid = tes3mp.GetPlayerKillerPid(pid)
			if killerPid ~= nil then
				
				if killerPid == pid then
					diedToUnknown = true -- Death was "suicide"
				else
					killer = Players[killerPid]
					diedToAPlayer = true
				end
				
			end
		end
		
		local decision = false
		
		if dropItemsOnDeath == true then -- This whole block determines the decision to drop players items based on config
			if diedInSafeZone == true and enableSafeZones == true then
				if diedToAPlayer == true then -- Died to player in safezone
					if killer ~= nil then
						if Players[killer.pid] ~= nil and Players[killer.pid]:IsLoggedIn() then
							tes3mp.SendMessage(killer.pid, jailMsgColor..jailedMsg..color.Default, false)
							if broadcastWhenPlayerGetsJailed == true then
								tes3mp.SendMessage(killer.pid, "[SERVER] :"..msgColor..killer.data.login.name..msg..color.Default, true)
							end
							addJailed(killer.pid)
							tes3mp.SetHealthCurrent(killer.pid, 0) -- Kill the Killer then send him to jail
							tes3mp.SendStatsDynamic(killer.pid)
							killer.tid_jailed = tes3mp.CreateTimerEx("UnJailPlayer", time.seconds(jailTimeInMins*60), "i", killer.pid)
							tes3mp.StartTimer(killer.tid_jailed)
						end
					end
				elseif diedToUnknown == true then -- Died to Suicide/Magic in safezone
					if dropItemsFromSuicideInSafeZone == true then
						decision = true
					end
				else 							-- Died to NPC in safezone
					if dropItemsFromPVEInSafeZone == true then
						decision = true
					end
				end
			else
				if diedToAPlayer == true then -- Died to player in wild
					if dropItemsFromPVP == true then
						decision = true
					end
				elseif diedToUnknown == true then -- Died to Suicide/Magic in wild
					if dropItemsFromSuicide == true then
						decision = true
					end
				else 							-- Died to NPC in wild
					if dropItemsFromPVE == true then
						decision = true
					end
				end
			end
		end

		if setContains(jailed, pid) == true and dropItemsWhenJailed == true then -- If you are jailed you lose items
			decision = true
		end
		
		if decision == true then
			
			local pX = tes3mp.GetPosX(pid) -- gets player position.
			local pY = tes3mp.GetPosY(pid) + 1
			local pZ = tes3mp.GetPosZ(pid)
			local rX = tes3mp.GetRotX(pid)
			local rZ = tes3mp.GetRotZ(pid)
			
			
			for index,item in pairs(player.data.equipment) do
				tes3mp.UnequipItem(pid, index) -- creates unequipItem packet
				tes3mp.SendEquipment(pid) -- sends packet to pid
			end
			
			local temp = tableHelper.deepCopy(player.data.inventory)
			
			player.data.inventory = {} -- clear inventory data in the files
			player.data.equipment = {}
			
			tes3mp.ClearInventoryChanges(pid) -- clear inventory data on the server
			tes3mp.SendInventoryChanges(pid)

			for index,item in pairs(temp) do
				item.location = {posX = pX, posY = pY, posZ = pZ, rotX = rX, rotY = 0, rotZ = rZ}
			end
			logicHandler.CreateObjects(cellDescription, temp, "place")
			
		end

	end
end)

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		if setContains(jailed, pid) == true then -- Check to see if player is jailed
			local jail = jailcells[jailed[pid]] -- Get the cell player is supposed to be in
			if Players[pid]:IsLoggedIn() then
				if Players[pid].data.location.cell ~= jail.cell then -- If player left the cell they will be teleported back
					tes3mp.SetCell(pid, jail.cell)
					tes3mp.SendCell(pid)
					tes3mp.SetPos(pid, jail.posX, jail.posY, jail.posZ)
					tes3mp.SetRot(pid, jail.rotX, jail.rotZ)
					tes3mp.SendPos(pid)
				end
			end
		elseif setContains(safePlayers, pid) and notifyIfInSafeZone == true then -- If player is not jailed and supposed to be in safezone
			if deathdrop.IsPlayerInSafeZone(pid) == false then -- If player is no longer in safezone send notification
				tes3mp.SendMessage(pid, exitMsgColor..exitingMsg, false)
				removeFromSet(safePlayers, pid)
			end
		elseif deathdrop.IsPlayerInSafeZone(pid) and notifyIfInSafeZone == true then -- If player is not jailed and was not previously in a safezone send notification
			tes3mp.SendMessage(pid, enterMsgColor..enteringMsg, false)
			addToSet(safePlayers, pid)
		end
	end
end)

customEventHooks.registerValidator("OnObjectSpawn", function(eventStatus, pid, cellDescription, objects)
	
	local isValid = eventStatus.validDefaultHandler
	if isValid ~= false then
	
		if enableSafeZones == true then
			tes3mp.ReadLastEvent() -- Server doesnt save objects to memory so we only get access to the current packet sent which was "OnObjectSpawn"
			
			local inSafeZone = false
			local isObjectAssassin = false
			local Assassins = {}
			local found = 0
			
			for i = 0, tes3mp.GetObjectChangesSize() - 1 do -- Loop through all objects sent in packet
				local refId = tes3mp.GetObjectRefId(i)
				print("I FOUND A: "..refId)
				if refId:match("db_assassin") ~= nil then
					isObjectAssassin = true
					Assassins[found] = tes3mp.GetObjectMpNum(i) -- This is how we get the MP num for actors
					found = found + 1
				end
			end
			
			if found > 0 then
				if deathdrop.IsPlayerInJail(pid) == false then -- If player is jailed automatically disallow assassin spawns
					inSafeZone = deathdrop.IsPlayerInSafeZone(pid)
				else
					inSafeZone = true
				end
				
				if inSafeZone == true then
					isValid = false
				end
			end
		end
		
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

deathdrop.IsPlayerInJail = function(pid)
	return setContains(jailed, pid)
end

deathdrop.IsPlayerInSafeZone = function(pid)
	
	local inSafeZone = false
	local cellDescription = Players[pid].data.location.cell

	for index,c in pairs(safeExteriorCells) do -- Check if cellDescription is an exterior safezone
		if (c == cellDescription) then
			inSafeZone = true
			break
		end
	end

	for index,header in pairs(safeInteriorCellHeaders) do
		if cellDescription:match(header) ~= nil then -- All interiors with the prefix matching a header will also be a safezone
			inSafeZone = true
			break
		end
	end
	
	return inSafeZone
end

function UnJailPlayer(pid) -- this is called by the timer
	tes3mp.SendMessage(pid, jailMsgColor..releaseMsg..color.Default, false)
	if config.defaultRespawnCell ~= nil then
        tes3mp.SetCell(pid, config.defaultRespawnCell)
        tes3mp.SendCell(pid)

        if config.defaultRespawnPos ~= nil and config.defaultRespawnRot ~= nil then
            tes3mp.SetPos(pid, config.defaultRespawnPos[1], config.defaultRespawnPos[2], config.defaultRespawnPos[3])
            tes3mp.SetRot(pid, config.defaultRespawnRot[1], config.defaultRespawnRot[2])
            tes3mp.SendPos(pid)
        end
    end
	removeFromSet(jailed, pid)
end

function addJailed(key)
	local room = math.random(table.getn(jailcells) + 1)
	print(table.getn(jailcells).." _ "..room)
	jailed[key] = room
end

function addToSet(set, key)
	set[key] = true
end

function removeFromSet(set, key)
    set[key] = nil
end

function setContains(set, key)
    return set[key] ~= nil
end


return deathdrop