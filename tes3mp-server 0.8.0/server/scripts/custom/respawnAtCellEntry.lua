--[[
	Respawn at Cell Entry:
		version 1.00 (for TES3MP 0.8 & 0.8.1)
	
	DESCRIPTION:
		This script will resurrect a player at cell entry rather than the nearest temple.
		All other death-related settings from TES3MP's `config.lua` will still apply.
	
	INSTALLATION:
		1) Place this file as `respawnAtCellEntry.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.respawnAtCellEntry")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.
	
	
	VERSION HISTORY:
		1.00 (7/4/2022)		- Initial public release.
--]]

respawnAtCellEntry = {}

local markCellEntry = function(pid)
	local coordinates = { cell = tes3mp.GetCell(pid), posX = tes3mp.GetPosX(pid), posY = tes3mp.GetPosY(pid), posZ = tes3mp.GetPosZ(pid), rotX = tes3mp.GetRotX(pid), rotZ = tes3mp.GetRotZ(pid), deathTime = os.time() }
	Players[pid].data.customVariables.lastCellEntry = coordinates
end

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and os.time() >= Players[pid].data.timestamps.lastLogin then
		local markTime = os.time() + 2 -- We do this check to ensure players only update their respawn point on cell entry, and not everytime they log on.
		if Players[pid].data.timestamps.lastLogin ~= nil and markTime >= Players[pid].data.timestamps.lastLogin then
			markCellEntry(pid)
		end
	end
end)

local sendToCellEntry = function(pid)
	local loc = Players[pid].data.customVariables.lastCellEntry
	tes3mp.SetCell(pid, loc.cell)
	tes3mp.SendCell(pid)
	tes3mp.SetPos(pid, loc.posX, loc.posY, loc.posZ)
	tes3mp.SetRot(pid, loc.rotX, loc.rotZ)
	tes3mp.SendPos(pid)
end

customEventHooks.registerValidator("OnDeathTimeExpiration", function(eventStatus, pid)
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
	
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
			if Players[pid].data.customVariables.lastCellEntry ~= nil then

				isValid = false -- Use this resurrect option instead of the default one.

				sendToCellEntry(pid) -- Send the player back to the cell they entered from.

				local message = "You have been revived.\n"

				-- Ensure that dying as a werewolf turns you back into your normal form
				if Players[pid].data.shapeshift.isWerewolf == true then
					Players[pid]:SetWerewolfState(false)
				end

				-- Ensure that we unequip deadly items when applicable, to prevent an
				-- infinite death loop
				contentFixer.UnequipDeadlyItems(pid)

				tes3mp.Resurrect(pid, enumerations.resurrect.REGULAR)

				if config.deathPenaltyJailDays > 0 or config.bountyDeathPenalty then
					local jailTime = 0
					local resurrectionText = "You've been revived and brought back here, " ..
						"but your skills have been affected by "

					if config.bountyDeathPenalty then
						local currentBounty = tes3mp.GetBounty(pid)

						if currentBounty > 0 then
							jailTime = jailTime + math.floor(currentBounty / 100)
							resurrectionText = resurrectionText .. "your bounty"
						end
					end

					if config.deathPenaltyJailDays > 0 then
						if jailTime > 0 then
							resurrectionText = resurrectionText .. " and "
						end

						jailTime = jailTime + config.deathPenaltyJailDays
						resurrectionText = resurrectionText .. "your time spent incapacitated"    
					end

					resurrectionText = resurrectionText .. ".\n"
					tes3mp.Jail(pid, jailTime, true, true, "Recovering", resurrectionText)
				end

				if config.bountyResetOnDeath then
					tes3mp.SetBounty(pid, 0)
					tes3mp.SendBounty(pid)
					Players[pid]:SaveBounty()
				end

				tes3mp.SendMessage(pid, message, false)
			end
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

return respawnAtCellEntry