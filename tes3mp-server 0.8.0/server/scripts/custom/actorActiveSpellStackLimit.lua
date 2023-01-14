--[[
	Actor Active Spell Stack Limit
		version 1.00 (For TES3MP 0.8.1)
			by Learwolf
	
	DESCRIPTION:
		This script allows server owners to set active effect limits to the actors (NPCs/Creatures) on their server.
		The contents of the `effectIdsToLimit` table below affects all actors.
		The contents of the `actorEffecIdsToLimit` table below affect only specified refIds. (Said actors will still refer to `effectIdsToLimit` if an effect is not overwritten in the `actorEffecIdsToLimit` table.)
		Note that effect ID's that are not found within these tables will be ignored, and use default behavior.
		Also note that any effect ID's that have been added to the tables will result in only 1 stack of said effect being applied to the actor. (With the highest magnitude value (or newest iteration if magnitudes tie) taking priority.)
		
			Example setup:
				[7] = { -- 7 is the Burden effect ID.
					valueLimit = 100 -- This is the total amount of Burden a player can apply of this effect to the actor.
				},
	
	
	INSTALLATION:
		1) Place this file as `actorActiveSpellStackLimit.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.actorActiveSpellStackLimit")
		4) BE SURE THERE IS NO `--` SYMBOLS TO THE LEFT OF IT, ELSE IT WILL NOT WORK.
		5) Save `customScripts.lua` and restart your server.

	VERSION HISTORY:
		1.00	1/14/2023	-	Initial Release.
		
--]]

actorActiveSpellStackLimit = {}

--[[ Effect ID Reference:
enumerations.effects = { WATER_BREATHING = 0, SWIFT_SWIM = 1, WATER_WALKING = 2, SHIELD = 3, FIRE_SHIELD = 4, 
    LIGHTNING_SHIELD = 5, FROST_SHIELD = 6, BURDEN = 7, FEATHER = 8, JUMP = 9, LEVITATE = 10, SLOW_FALL = 11, LOCK = 12, 
    OPEN = 13, FIRE_DAMAGE = 14, SHOCK_DAMAGE = 15, FROST_DAMAGE = 16, DRAIN_ATTRIBUTE = 17, DRAIN_HEALTH = 18, 
    DRAIN_MAGICKA = 19, DRAIN_FATIGUE = 20, DRAIN_SKILL = 21, DAMAGE_ATTRIBUTE = 22, DAMAGE_HEALTH = 23, 
    DAMAGE_MAGICKA = 24, DAMAGE_FATIGUE = 25, DAMAGE_SKILL = 26, POISON = 27, WEAKNESS_FIRE = 28, WEAKNESS_FROST = 29, 
    WEAKNESS_SHOCK = 30, WEAKNESS_MAGICKA = 31, WEAKNESS_COMMON_DISEASE = 32, WEAKNESS_BLIGHT_DISEASE = 33, 
    WEAKNESS_CORPRUS_DISEASE = 34, WEAKNESS_POISON = 35, WEAKNESS_NORMAL_WEAPONS = 36, DISINTEGRATE_WEAPON = 37, 
    DISINTEGRATE_ARMOR = 38, INVISIBILITY = 39, CHAMELEON = 40, LIGHT = 41, SANCTUARY = 42, NIGHTEYE = 43, CHARM = 44, 
    PARALYZE = 45, SILENCE = 46, BLIND = 47, SOUND = 48, CALM_HUMANOID = 49, CALM_CREATURE = 50, FRENZY_HUMANOID = 51, 
    FRENZY_CREATURE = 52, DEMORALIZE_HUMANOID = 53, DEMORALIZE_CREATURE = 54, RALLY_HUMANOID = 55, RALLY_CREATURE = 56, 
    DISPEL = 57, SOULTRAP = 58, TELEKINESIS = 59, MARK = 60, RECALL = 61, DIVINE_INTERVENTION = 62, 
    ALMSIVI_INTERVENTION = 63, DETECT_ANIMAL = 64, DETECT_ENCHANTMENT = 65, DETECT_KEY = 66, SPELL_ABSORPTION = 67, 
    REFLECT = 68, CURE_COMMON_DISEASE = 69, CURE_BLIGHT_DISEASE = 70, CURE_CORPRUS_DISEASE = 71, CURE_POISON = 72, 
    CURE_PARALYZATION = 73, RESTORE_ATTRIBUTE = 74, RESTORE_HEALTH = 75, RESTORE_MAGICKA = 76, RESTORE_FATIGUE = 77, 
    RESTORE_SKILL = 78, FORTIFY_ATTRIBUTE = 79, FORTIFY_HEALTH = 80, FORTIFY_MAGICKA = 81, FORTIFY_FATIGUE = 82, 
    FORTIFY_SKILL = 83, FORTIFY_MAXIMUM_MAGICKA = 84, ABSORB_ATTRIBUTE = 85, ABSORB_HEALTH = 86, ABSORB_MAGICKA = 87, 
    ABSORB_FATIGUE = 88, ABSORB_SKILL = 89, RESIST_FIRE = 90, RESIST_FROST = 91, RESIST_SHOCK = 92, RESIST_MAGICKA = 93, 
    RESIST_COMMON_DISEASE = 94, RESIST_BLIGHT_DISEASE = 95, RESIST_CORPRUS_DISEASE = 96, RESIST_POISON = 97, 
    RESIST_NORMAL_WEAPONS = 98, RESIST_PARALYSIS = 99, REMOVE_CURSE = 100, TURN_UNDEAD = 101, SUMMON_SCAMP = 102, 
    SUMMON_CLANNFEAR = 103, SUMMON_DAEDROTH = 104, SUMMON_DREMORA = 105, SUMMON_ANCESTRAL_GHOST = 106, 
    SUMMON_SKELETAL_MINION = 107, SUMMON_BONEWALKER = 108, SUMMON_GREATER_BONEWALKER = 109, SUMMON_BONELORD = 110, 
    SUMMON_WINGED_TWILIGHT = 111, SUMMON_HUNGER = 112, SUMMON_GOLDEN_SAINT = 113, SUMMON_FLAME_ATRONACH = 114, 
    SUMMON_FROST_ATRONACH = 115, SUMMON_STORM_ATRONACH = 116, FORTIFY_ATTACK = 117, COMMAND_CREATURE = 118, 
    COMMAND_HUMANOID = 119, BOUND_DAGGER = 120, BOUND_LONGSWORD = 121, BOUND_MACE = 122, BOUND_BATTLE_AXE = 123, 
    BOUND_SPEAR = 124, BOUND_LONGBOW = 125, EXTRASPELL = 126, BOUND_CUIRASS = 127, BOUND_HELM = 128, BOUND_BOOTS = 129, 
    BOUND_SHIELD = 130, BOUND_GLOVES = 131, CORPRUS = 132, VAMPIRISM = 133, SUMMON_CENTURION_SPHERE = 134, SUN_DAMAGE = 135, 
    STUNTED_MAGICKA = 136, SUMMON_FABRICANT = 137, CALL_WOLF = 138, CALL_BEAR = 139, SUMMON_BONEWOLF = 140, 
    S_EFFECT_SUMMON_CREATURE04 = 141, S_EFFECT_SUMMON_CREATURE05 = 142 }
--]]

--==----==----==----==--==--
-- CONFIGURATION SECTION:
--==----==----==----==--==--
-- All actors are affected by the values in this table:
local effectIdsToLimit = { -- All effects listed in this table will be limited to 1 stack of the effect per actor, and allow for a specified value limit.
	[7] = { -- Burden
		valueLimit = 100 -- This is the total amount a player can apply of this effect to an actor.
	},
	[17] = { -- Drain Attribute
		valueLimit = 100
	},
	[21] = { -- Drain Skill
		valueLimit = 100
	},
	[22] = { -- Damage Attribute
		valueLimit = 100
	},
	[26] = { -- Damage Skill
		valueLimit = 100
	},
	[28] = { -- Weakness to Fire
		valueLimit = 100
	},
	[29] = { -- Weakness to Frost
		valueLimit = 100
	},
	[30] = { -- Weakness to Shock
		valueLimit = 100
	},
	[31] = { -- Weakness to Magicka
		valueLimit = 100
	},
	[35] = { -- Weakness to Poison
		valueLimit = 100
	},
	[36] = { -- Weakness to Normal Weapons
		valueLimit = 100
	},
	[58] = { -- Soul Trap
		valueLimit = 1
	},
	[118] = { -- Command Creature
		valueLimit = 100
	},
	[119] = { -- Command Humanoid
		valueLimit = 100
	}
}

-- Only specified actors are affected by the values in this table:
local actorEffecIdsToLimit = { -- All effects listed in this table will override what is found in the effectIdsToLimit for the specified actor refId.
	["dagoth_ur_1"] = {
		[28] = { -- Weakness to Fire
			valueLimit = 50
		},
		[29] = { -- Weakness to Frost
			valueLimit = 50
		},
		[30] = { -- Weakness to Shock
			valueLimit = 50
		},
		[31] = { -- Weakness to Magicka
			valueLimit = 50
		},
		[35] = { -- Weakness to Poison
			valueLimit = 50
		},
		[36] = { -- Weakness to Normal Weapons
			valueLimit = 50
		},
		[58] = { -- Soul Trap
			valueLimit = 0
		},
	},
	["dagoth_ur_2"] = {
		[28] = { -- Weakness to Fire
			valueLimit = 50
		},
		[29] = { -- Weakness to Frost
			valueLimit = 50
		},
		[30] = { -- Weakness to Shock
			valueLimit = 50
		},
		[31] = { -- Weakness to Magicka
			valueLimit = 50
		},
		[35] = { -- Weakness to Poison
			valueLimit = 50
		},
		[36] = { -- Weakness to Normal Weapons
			valueLimit = 50
		}
	},
	["almalexia"] = {
		[28] = { -- Weakness to Fire
			valueLimit = 50
		},
		[29] = { -- Weakness to Frost
			valueLimit = 50
		},
		[30] = { -- Weakness to Shock
			valueLimit = 50
		},
		[31] = { -- Weakness to Magicka
			valueLimit = 50
		},
		[35] = { -- Weakness to Poison
			valueLimit = 50
		},
		[36] = { -- Weakness to Normal Weapons
			valueLimit = 50
		},
		[58] = { -- Soul Trap
			valueLimit = 0
		}
	},
	["almalexia"] = {
		[28] = { -- Weakness to Fire
			valueLimit = 50
		},
		[29] = { -- Weakness to Frost
			valueLimit = 50
		},
		[30] = { -- Weakness to Shock
			valueLimit = 50
		},
		[31] = { -- Weakness to Magicka
			valueLimit = 50
		},
		[35] = { -- Weakness to Poison
			valueLimit = 50
		},
		[36] = { -- Weakness to Normal Weapons
			valueLimit = 50
		}
	}
}

------------------------------------------------------------------------

--==----==----==----==----==----==----==----==----==----==----==----==--
--  DO NOT TOUCH BELOW THIS POINT UNLESS YOU KNOW WHAT YOU'RE DOING!
--==----==----==----==----==----==----==----==----==----==----==----==--
customEventHooks.registerValidator("OnActorSpellsActive", function(eventStatus, pid, cellDescription, actors)
	
	local isValid = eventStatus.validDefaultHandler
	
	if isValid ~= false then
	 
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
			
			for actor,data in pairs(actors) do
				
				local uniqueIndex = data.uniqueIndex
				
				if LoadedCells[cellDescription] ~= nil and LoadedCells[cellDescription].data.objectData[uniqueIndex] ~= nil then
					
					local actorData = LoadedCells[cellDescription].data.objectData[uniqueIndex]
					local refId = actorData.refId
					
					if refId ~= nil and data.spellsActive ~= nil then
					
						local storeOverrideChange = false
						local reapplySpellsActive = false
						local activeSpellsToReapply = {}
						
						for spellId,spellData in pairs(data.spellsActive) do
							
							for stack,stackData in pairs(spellData) do
								if stackData.effects ~= nil then
									
									for effect,newEffectData in pairs(stackData.effects) do
										
										local limitData = effectIdsToLimit[newEffectData.id]
										
										if limitData ~= nil then
											
											-- If there is a value limit, lets set it:
											local valueLimit = effectIdsToLimit[newEffectData.id].valueLimit 
											if actorEffecIdsToLimit[refId] and actorEffecIdsToLimit[refId][newEffectData.id] then
												valueLimit = actorEffecIdsToLimit[refId][newEffectData.id].valueLimit
											end
											if newEffectData.magnitude > valueLimit then
												newEffectData.magnitude = valueLimit
												reapplySpellsActive = true
												storeOverrideChange = true
											end
											
											if actorData.spellsActive ~= nil then -- Get actors current active spells.
												
												for activeSpellId, activeSpellData in pairs(actorData.spellsActive) do
													
													-- pull stored active data, or add this activespell to the stored active data:
													local spellReplacement = activeSpellsToReapply[activeSpellId] or tableHelper.deepCopy(activeSpellData)
													local storeReplacementChange = false
													
													if spellReplacement ~= nil and spellReplacement[1] ~= nil and spellReplacement[1].effects ~= nil then
														
														-- Lets get the time the spell was initially cast:
														local markTime = spellReplacement[1].startTime or 0
														local passedTime = os.time() - markTime
														
														-- Iterate through the active effects of the stored activespell data:
														for s=1,#spellReplacement[1].effects do
															local active = spellReplacement[1].effects[s]
															
															-- Lets check if the id and arg match up, as well as make sure the effect still has an active duration:
															if active ~= nil and active.id == newEffectData.id and active.arg == newEffectData.arg and passedTime < active.duration then																
																
																-- If our new effect has higher value, lets use that value:
																if active.magnitude <= newEffectData.magnitude then
																	active.magnitude = 0
																	storeReplacementChange = true
																else -- If our old effect has higher value, lets use that value:
																	newEffectData.magnitude = 0
																	if #stackData.effects > 1 then
																		reapplySpellsActive = true
																	end
																	storeOverrideChange = true
																end
																
															end
														end
													end
													
													-- If new value is better, lets store the changes we made to the old stored active value:
													if storeReplacementChange then
														activeSpellsToReapply[activeSpellId] = spellReplacement
													end
												end
											end
											
										end
										
									end
									
								end
							end
							
						end
						
						-- If making changes to the newly incoming effect values:
						if not tableHelper.isEmpty(activeSpellsToReapply) or storeOverrideChange then
								
							tes3mp.ClearActorList()
							tes3mp.SetActorListPid(pid)
							tes3mp.SetActorListCell(cellDescription)
							
							local splitIndex = uniqueIndex:split("-")
							tes3mp.SetActorRefNum(splitIndex[1])
							tes3mp.SetActorMpNum(splitIndex[2])
							
							-- Make changes to already existing spell effects:
							if not tableHelper.isEmpty(activeSpellsToReapply) then
								
								local reapplyThisEffect = false
								
								for spellId,spellData in pairs(activeSpellsToReapply) do
									
									if not tableHelper.isEmpty(spellData[1]) then
										
										local markTime = spellData[1].startTime or 0
										local passedTime = os.time() - markTime
										activeSpellsToReapply[spellId][1].stackingState = false
										for i=1,#spellData[1].effects do
											spellData[1].effects[i].duration = passedTime
										end
									
									end
								end
								
								packetBuilder.AddActorSpellsActive(uniqueIndex, activeSpellsToReapply, enumerations.spellbook.REMOVE)
								tes3mp.SendActorSpellsActiveChanges()
								packetBuilder.AddActorSpellsActive(uniqueIndex, activeSpellsToReapply, enumerations.spellbook.ADD)
								tes3mp.SendActorSpellsActiveChanges()
							end
							
							-- Make changes to active incoming spell effects:
							if storeOverrideChange then
								for stateSpellId,__ in pairs(data.spellsActive) do
									data.spellsActive[stateSpellId][1].stackingState = false
								end
								
								packetBuilder.AddActorSpellsActive(uniqueIndex, data.spellsActive, enumerations.spellbook.REMOVE)
								tes3mp.SendActorSpellsActiveChanges()
								
								if reapplySpellsActive then
									packetBuilder.AddActorSpellsActive(uniqueIndex, data.spellsActive, enumerations.spellbook.ADD)
									tes3mp.SendActorSpellsActiveChanges()
								end
							end
							
						end
					
					end
				
				end
				
			end
			
		end
		
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

return actorActiveSpellStackLimit
