--[[
	Constant Effect Summon Fix
		version 1.01 (For TES3MP 0.8.1)
			by Learwolf
	
	DESCRIPTION:
		This resolves issues with constant effect summons not actually appearing for players.
		Optional setting to only allow players to summon one of each creature type, instead of as many as they have spells for.
		Optional setting to only allow the player to have a certain amount of total active summons.
	
	INSTALLATION:
		1) Place this file as `constantEffectSummonFix.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.constantEffectSummonFix")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.

	VERSION HISTORY:
		1.01	1/17/2023	-	Limit active summons.
		1.00	1/16/2023	-	Initial Release.
		
--]]

constantEffectSummonsFix = {}

-- This is the only configuration option:
local limitSummonedCreaturesByType = true -- If true, forces players to only allow 1 of each creature type, regardless of how many summon spells they create.
local activeSummonLimit = 4 -- Limit the total amount of summons a player can have active to this value. Set to 0 or less to disable limits.

-- -- -- -- -- -- -- -- -- -- -- -- 
--==----==----==----==----==----==--
-- DO NOT TOUCH BEYOND THIS POINT!  
--==----==----==----==----==----==--
-- -- -- -- -- -- -- -- -- -- -- -- 
local checkForStraySummons = function(pid, cellDescription)
	
	local cell = LoadedCells[cellDescription]
	if cell ~= nil then
	
		local indexesToDelete = {}
		
		for _,uniqueIndex in pairs(cell.data.packets.actorList) do
			if cell.data.objectData[uniqueIndex] ~= nil then
				
				local summon = cell.data.objectData[uniqueIndex].summon
				if summon ~= nil then

					if summon.summoner.refId ~= nil then
						
					elseif summon.summoner.playerName ~= nil then
						
						local foundOwner = false
						
						for sPid, player in pairs(Players) do
							if Players[sPid] ~= nil and player:IsLoggedIn() and Players[sPid].summons[uniqueIndex] ~= nil then
								foundOwner = true
								break
							end	
						end
						
						if not foundOwner then
							tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
						end
					
					else
						tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
					end
					
				elseif cell.data.objectData[uniqueIndex].refId ~= nil and string.match(cell.data.objectData[uniqueIndex].refId, "_summon") then
					tableHelper.insertValueIfMissing(indexesToDelete, uniqueIndex)
				end
				
			end
		end
		
		if not tableHelper.isEmpty(indexesToDelete) then
			for _,uniqueIndex in pairs(indexesToDelete) do
				logicHandler.DeleteObject(pid, cellDescription, uniqueIndex, true)
				LoadedCells[cellDescription]:DeleteObjectData(uniqueIndex)
			end
		end
		
	end
end

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid, playerPacket, previousCellDescription)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		checkForStraySummons(pid, playerPacket.location.cell)
	end
end)


customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)

	function Cell:SaveObjectsSpawned(objects)

		for uniqueIndex, object in pairs(objects) do

			local location = object.location
			local preventSave = false

			-- Ensure data integrity before proceeeding
			if tableHelper.getCount(location) == 6 and tableHelper.usesNumericalValues(location) and
				self:ContainsPosition(location.posX, location.posY) then

				local refId = object.refId
				self:InitializeObjectData(uniqueIndex, refId)

				tes3mp.LogAppend(enumerations.log.INFO, "- " .. uniqueIndex .. ", refId: " .. refId)

				self.data.objectData[uniqueIndex].location = location

				if object.summon ~= nil then
					local summonDuration = object.summon.duration -- Add one second duration to make sure constant effect summons get tracked.

					if summonDuration == 0 then
						summonDuration = 2419200 -- 1 month.
					end

					if summonDuration > 0 then
						local summon = {}
						summon.duration = summonDuration -- object.summon.duration
						summon.effectId = object.summon.effectId
						summon.spellId = object.summon.spellId
						summon.startTime = object.summon.startTime
						summon.summoner = {}

						local hasPlayerSummoner = object.summon.hasPlayerSummoner

						if hasPlayerSummoner then
							local summonerPid = object.summon.summoner.pid
							tes3mp.LogAppend(enumerations.log.INFO, "- summoned by player " ..
								logicHandler.GetChatName(summonerPid))

							-- Track the player and the summon for each other
							summon.summoner.playerName = object.summon.summoner.playerName

							if Players[summonerPid] ~= nil then

								if limitSummonedCreaturesByType then
									if Players[summonerPid] ~= nil and Players[summonerPid]:IsLoggedIn() and Players[summonerPid].accountName == summon.summoner.playerName then

										for summonUniqueIndex, summonRefId in pairs(Players[summonerPid].summons) do

											if refId == summonRefId and summonUniqueIndex ~= uniqueIndex then
												-- logicHandler.RunConsoleCommandOnPlayer(summonerPid, "player->removeeffects "..summon.effectId)
												-- self:DeleteObjectData(uniqueIndex)
												-- preventSave = true
												local cell = logicHandler.GetCellContainingActor(summonUniqueIndex)
												if cell ~= nil then
													local cellDescription = cell.description
													logicHandler.DeleteObject(summonerPid, cellDescription, summonUniqueIndex, true)
													cell:DeleteObjectData(summonUniqueIndex)
												end
												Players[summonerPid].summons[summonUniqueIndex] = nil
											end
										end
									end
								end
								
								if not preventSave then
									Players[summonerPid].summons[uniqueIndex] = refId
								end
							else
								preventSave = true
							end
						else
							summon.summoner.refId = object.summon.summoner.refId
							summon.summoner.uniqueIndex = object.summon.summoner.uniqueIndex
							tes3mp.LogAppend(enumerations.log.INFO, "- summoned by actor " .. summon.summoner.uniqueIndex ..
								", refId: " .. summon.summoner.refId)
						end

						-- Deal with limited number of active summons:
						local activeSummonCount = 0
							for x,y in pairs(Players[summonerPid].summons) do
								activeSummonCount = activeSummonCount + 1
							end
							
							-- If a player runs into an issue where they cannot resummon a summon, note that it is because 
							-- the spell is still active on their character even though the summon was deleted.
							if activeSummonLimit > 0 then
							if Players[summonerPid].summons ~= nil and activeSummonCount >= activeSummonLimit then
								local uniqueIndexesToClear = {}
								local uniqueSummonIndexes = {}
								
								for summonUniqueIndex, summonRefId in pairs(Players[summonerPid].summons) do
									table.insert(uniqueSummonIndexes, {uniqueIndex = summonUniqueIndex, refId = summonRefId})
								end
								
								table.sort(uniqueSummonIndexes, function(a,b) return a.uniqueIndex<b.uniqueIndex end)

								if #uniqueSummonIndexes >= activeSummonLimit then
									
									local overlimitCount = (#uniqueSummonIndexes - activeSummonLimit) + 1
									
									for n=1,overlimitCount do
										local t = uniqueSummonIndexes[n]
										if t ~= nil and t.uniqueIndex ~= nil then
											local cell = logicHandler.GetCellContainingActor(t.uniqueIndex)
											if cell ~= nil then
												local cellDescription = cell.description
												logicHandler.DeleteObject(summonerPid, cellDescription, t.uniqueIndex, true)
												cell:DeleteObjectData(t.uniqueIndex)
											end
											Players[summonerPid].summons[t.uniqueIndex] = nil
										end
									end
									
								end
								
							end
						end
						
						if not preventSave then
							self.data.objectData[uniqueIndex].summon = summon
						end
					end
				end

				if not preventSave then
					table.insert(self.data.packets.spawn, uniqueIndex)
					table.insert(self.data.packets.actorList, uniqueIndex)

					if logicHandler.IsGeneratedRecord(refId) then
						local recordStore = logicHandler.GetRecordStoreByRecordId(refId)

						if recordStore ~= nil then
							self:AddLinkToRecord(recordStore.storeType, refId, uniqueIndex)
						end
					end
				end
			end
		end
	end

	function Cell:LoadObjectsSpawned(pid, objectData, uniqueIndexArray, forEveryone)

		local objectCount = 0

		tes3mp.ClearObjectList()
		tes3mp.SetObjectListPid(pid)
		tes3mp.SetObjectListCell(self.description)

		for arrayIndex, uniqueIndex in pairs(uniqueIndexArray) do

			if objectData[uniqueIndex] ~= nil then

				local location = objectData[uniqueIndex].location

				-- Ensure data integrity before proceeeding
				if type(location) == "table" and tableHelper.getCount(location) == 6 and
					tableHelper.usesNumericalValues(location) and
					self:ContainsPosition(location.posX, location.posY) then

					local shouldSkip = false
					local summon = objectData[uniqueIndex].summon

					if summon ~= nil then
						local currentTime = os.time()

						local summonDuration = summon.duration

						if summonDuration == 0 then
							summonDuration = 2419200 -- 1 month.
						end

						local finishTime = summon.startTime + summonDuration

						-- Don't spawn this summoned creature if its summoning duration is over..
						if currentTime >= finishTime then
							self:DeleteObjectData(uniqueIndex)
							shouldSkip = true
						-- ...or if its player is offline
						elseif summon.summoner.playerName ~= nil then

							if not logicHandler.IsPlayerNameLoggedIn(summon.summoner.playerName) then
								self:DeleteObjectData(uniqueIndex)
								shouldSkip = true
							end

						-- ...or if it doesn't have an actor stored as its summoner
						elseif summon.summoner.uniqueIndex == nil then
							shouldSkip = true
						end
					end

					if not shouldSkip then
						packetBuilder.AddObjectSpawn(uniqueIndex, objectData[uniqueIndex])
						objectCount = objectCount + 1
					end
				else
					objectData[uniqueIndex] = nil
					tableHelper.removeValue(uniqueIndexArray, uniqueIndex)
				end
			end
		end

		if objectCount > 0 then
			tes3mp.SendObjectSpawn(forEveryone)
		end
	end

end)

return constantEffectSummonsFix
