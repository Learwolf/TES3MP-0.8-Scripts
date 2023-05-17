# TES3MP-0.8-Scripts
A list of my tes3mp server Lua scripts available for public use.

Note that these scripts have been designed and tested for TES3MP 0.8.0 - 0.8.1
It is unlikely they will work in 0.7.x and lower.



**actorActiveSpellStackLimit.lua**
  - This (curently in beta) script allows server owners to set active effect limits to the actors (NPCs/Creatures) on their server.
  - Configurable.


**attributeModifiers.lua**
  - This script allows server owners to customize their players level up attribute modifiers.
  - Configurable.


**constantEffectSummonFix.lua**
  - This resolves issues with constant effect summons not actually appearing for players.
  - Optional setting to only allow players to summon one of each creature type, instead of as many as they have spells for.
  - Optional setting to only allow the player to have a certain amount of total active summons.
  - Configurable.


**customMerchantRestock.lua**
  - This script will ensure your designated merchants always have their gold restocked.
  - Add the desired merchant refId's to the `restockingGoldMerchants` table in the script.


**dbFix.lua**
  - This script allows server owners to set a level requirement for players to spawn a dark brotherhood assassins.
  - This script also ensures an assassin spawns once (and only once) per each player.


**deathdrop.lua**
  - deathdrop was originally created by David-AW for TES3MP 0.7 and ported over per request to TES3MP 0.8 by me.
  - Enforce certain items to drop from a players inventory when they die.
  - Highly configurable.


**defaultChatLocal.lua**
  - This script allows players to talk in local chat by default, and requires players to use `/global InsertMessageTextHere` to speak globally.
  - `global` chat comimand is customizable.


**drowningRebalance.lua**
  - This script allows server owners to easily modify drowning damage.
  - The default drowning damage is 3 points every second, and does not scale.
  - With this script, it will (by default) be 3 points times the players level.
  - A level 1 will take 3 points of drowning damage every second, while a level 50 will take 150.
  - Argonians can be configured to take half damage.


**levelCap.lua**
  - This simple script allows server owners to set a level cap for players. Keep in mind, it does not retroactively revert players levels if they have bypassed said cap prior to installing this script.


**mwScriptConverter.lua**
  - The purpose of this script is to easily convert custom morrowind scripts into tes3mp custom record scripts via a text file conversion.
  - This script requires in-depth user setup. Please see my tutorial video at: https://youtu.be/AkbDi651a8c


**objectPositionFix.lua**
  - A server side method of fixing misplaced objects in the game world.


**periodicCellResets.lua**
  - This script allows cells to be periodically reset in game without the need for a server restart.
  - It's based on a certain amount of seconds that pass from the cells initial creation. 
  - The cells will only reset when the time for reset has been reached (based on your servers computer clock), and the cell is not currently loaded.
  - Highly customizable.
  - Configuration allows for specified cells to be exempt from ever resetting.


**preventPrisonSkilldowns.lua**
  - This script allows server owners to prevent players from having skill lower from going to prison.
 
 
**quickKeyAddons.lua**
  - This script provides server owners a few additional features related to quick keys.
  - The primary feature being additional Quick Key pages. The number of pages can be customized below in the configuration section.
  - This script also allow server owners to prevent specific refIds from being set as a Quick Key item.
  - This script also allow server owners to prevent Quick Keys from being activated in specific cells.
  - This script has the option to allow player chat macro functionality via Hotkey items. Hotkeys items can be used from a players inventory or bound and used from the Quick Key list. 
      Hotkeys allow players to bind text (such as chat messages or chat commands) and can then be used at the click of a quick key to instantly run the chat or command. (I.E., a macro.) 
 
 
**respawnAtCellEntry.lua**
  - This script will resurrect a player at cell entry rather than the nearest temple.

