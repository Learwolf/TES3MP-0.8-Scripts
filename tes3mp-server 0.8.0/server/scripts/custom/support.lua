--[[
	Support System (ver. 1.00)
		by Learwolf
	
	DESCRIPTION:
	A robust ticket system server owners can utilize to allow their players to open tickets as a means of communication to staff members. This can be useful for reporting bugs, player harassment, requesting furniture to be removed from their home, etc. (Pretty much anything you can think of.)
	All staff members (configurable by staffRank) can view, respond to, and close active tickets. 

	INSTALLATION INSTRUCTIONS:
		* Place `support.lua` inside your `\tes3mp-server\server\scripts\custom` folder.
		* Open `customScripts.lua` found inside your `\tes3mp-server\server\scripts` folder with a text editor such as notepad.
		* Paste the following onto a new line, and ensure there are no -- dashes infront of it:
			require("custom.support")
		* Save `customScripts.lua` and relaunch your server. (Be sure to edit any configurations in this script before starting your server!)
	
	FEATURES:
		* The support system allows players to open support tickets via the `/support` or `/ticket` chat commands.
		* Server owners can setup topics and subtopcs (see `listOfSupportTopics` configuration below) players can select to better filter their issue.
		* All players with staffRank >= `reqStaffRank` configuration (configured below) can view the pool of open tickets and respond to them.
		* Tickets that a staff member has responded to will have an `Active` tag displayed in the staff ticket pool.
		* Tickets can be closed by the origin player or staff member. (Players can close their tickets instantly. Staff members sets it on a 48 hour (configured below under 
			`staffTicketCloseTimer`) timer before it is closed. (This gives the player time to respond which cancels the close timer.)
		* Tickets that a staff member has started the close timer for will have a `Closed` tag displayed in the staff ticket pool.
		* Staff members can also review all closed tickets separate from the actively open ticket pool.
	
	
	VERSION HISTORY:
		* 1/23/2021 v.1.00 - Initial script release.
	
--]]


support = {} -- Don't touch this.


--==----==----==----==----==--
-- BEGIN CONFIGURATION:
-- You can configure the below:
--==----==----==----==----==--
local textColor = "#CAA560" -- Color of standard gui text.
local titleColor = "#BDAA87" -- Color of title gui text.
local notificationColor = "#FF1493" -- Color of player notification sendMessage text. (DeepPink by default.)

local reqStaffRank = 1 -- Required staffRank in order to view tickets. (0 = player, 1 = moderator, 2 = admin, 3 = owner)

local newTicketCooldown = 60 -- cooldown in seconds before players can create a new ticket.
local updateTicketCooldown = 60 -- cooldown in seconds before players can update an existing ticket.

local staffTicketCloseTimer = 172800 -- deafult is 172800 (which is 48 hours in seconds.)
local closeTicketTimer = 300 -- every 300 seconds (5 minutes), tickets are checked if they should be closed due to staff previously closing them. 5 minutes should be fine.

local listOfSupportTopics = { -- Take care in making sure you edit this part correctly!!!
	{
		topic = "Character Issue", -- topic
		subtopics = { -- possible subtopics to go along with the above topic.
			"Attributes/Skills/Level",
			"Item Duplication",
			"Quest Progression",
			"Stuck At Location",
			"Other Issue"
		}
	},
	{
		topic = "Location/NPC Issue",
		subtopics = {
			"Broken Quest NPC", -- You can add or remove as many subtopics as you want. (Down to 1 subtopic minimum.)
			"Dead/Missing NPC", -- Just make sure they are separated with commas if more than one exist.
			"Unlootable NPC", -- With the last one lacking a comma.
			"Other Issue" -- <- Like here.
		}
	},
	{
		topic = "Other Player Issue",
		subtopics = {
			"Player Cheating/Hacking",
			"Player Griefing/Harasssment",
			"Other Issue"
		}
	},
	--[[ -- This is an example if using atkanas housing. Uncomment the below if you want to use it.
	{
		topic = "Player Housing",
		subtopics = {
			"Remove Furniture From My Home",
			"Other Issue"
		}
	},
	--]]
	{
		topic = "Other",
		subtopics = {
			"Other Issue" -- You need /at least/ one subtopic.
		}
	}
}

local deleteClosedTicketsOnServerStartUp = false -- Setting this to true DELETES ALL `Closed` TICKETS ON SERVER LAUNCH. 
												-- I recommend only using this if your tickets .json file is HUGE.


--==----==----==----==----==----==----==----==----==----==--
-- You shouldn't need to touch anything below this point.
--==----==----==----==----==----==----==----==----==----==--
local totalLetterCount = 500 -- total letters that can be put in the body of a report. Don't Touch!
local supportMainMenuGUI = 118202031 -- menu gui number. Don't touch!
local ticketData = jsonInterface.load("custom/supportTickets.json") -- Don't Touch!

--==----==----==----==----==----==----==----==----==--
-- END CONFIGURATION:
-- Seriously, don't touch anything below this point.
--==----==----==----==----==----==----==----==----==--
local menuVar = {} -- Don't touch!

local getDate = function()
	return os.date("[%m-%d-%y %H:%M:%S]")
end

local getPName = function(pid)
	return Players[pid].accountName
end

local clearMsgVariables = function(pid)
	menuVar[pid].sendRequest = nil
	menuVar[pid].updateMessage = nil
end

local function Save()
	jsonInterface.save("custom/supportTickets.json", ticketData)
end

local function Load()
	ticketData = jsonInterface.load("custom/supportTickets.json")
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	local file = jsonInterface.load("custom/supportTickets.json") --io.open(tes3mp.GetModDir() .. "/custom/supportTickets.json", "r") --jsonInterface.load("custom/"..pouchData.pouchDB..".json")
	if ticketData == nil then
		ticketData = {ticketNum = 0, openTickets = {}, closedTickets = {}}
		Save()
	end
	Load()
	
	-- This will clear any possible nil/null values:
	tableHelper.cleanNils(ticketData)
	Save()
	
	if deleteClosedTicketsOnServerStartUp ~= nil and deleteClosedTicketsOnServerStartUp == true then
		ticketData.closedTickets = {}
		Save()
	end
end)

local alertStaffNewTicket = function()
	for pid, player in pairs(Players) do
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
			if Players[pid].data.settings.staffRank >= reqStaffRank then
				tes3mp.SendMessage(pid, notificationColor.."There are unread support tickets.\n", false)
			end
		end
	end
end

local alertPlayerUpdatedTicket = function(name)
	for pid, player in pairs(Players) do
		if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
			if string.lower(name) == string.lower(getPName(pid)) then
				tes3mp.SendMessage(pid, notificationColor.."You have an unread support ticket.\n", false)
				break
			end
		end
	end
end

local messageLimiter = function(text)
	
	local bodyPreview = tostring(text) or ""
	local bodyOutString = ""
	
	if bodyPreview ~= nil and bodyPreview ~= "" then
		
		local maxLine = 35 --47
		local currentChars = 0
		local wordList = {}

		for w in bodyPreview:gmatch("%S+") do table.insert(wordList, w) end

		for _, word in pairs(wordList) do
			
			currentChars = currentChars + word:len()
			
			if string.match(word, "/n") then
				
				bodyOutString = bodyOutString..color.White..string.gsub( word, "(/n)", "" ).."\n"
				currentChars = 5 + word:len() + 1
			
			else
			
				if currentChars > maxLine then
					bodyOutString = bodyOutString .. "\n"..color.White..word.." "
					currentChars = 5 + word:len() + 1
				else
					bodyOutString = bodyOutString..color.White..word.." "
					currentChars = currentChars + 1
				end
				
			end
		end
	
	end
	
	return bodyOutString
end

local getTopicText = function(pid)
	local txt = ""
	local topicIndex = menuVar[pid].sendRequest.topic
	if topicIndex ~= nil and listOfSupportTopics[topicIndex] ~= nil and listOfSupportTopics[topicIndex].topic ~= nil then
		txt = listOfSupportTopics[topicIndex].topic
	end
	return txt
end

local getSubtopicText = function(pid)
	local txt = ""
	local topicIndex = menuVar[pid].sendRequest.topic
	local subtopicIndex = menuVar[pid].sendRequest.subtopic
	if topicIndex ~= nil and subtopicIndex ~= nil and listOfSupportTopics[topicIndex] ~= nil and listOfSupportTopics[topicIndex].topic ~= nil and listOfSupportTopics[topicIndex].subtopics ~= nil and listOfSupportTopics[topicIndex].subtopics[subtopicIndex] ~= nil then
		txt = listOfSupportTopics[topicIndex].subtopics[subtopicIndex]
	end
	return txt
end

local confirmMsg = function(pid, txt)
	tes3mp.SendMessage(pid, textColor..txt.."\n", false)
end

local errorMsg = function(pid, txt)
	tes3mp.SendMessage(pid, color.Error..txt.."\n", false)
end

local sentMsgSound = function(pid)
	local sfx = "enchant success"
	logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \""..sfx.."\" 1.0 1.0")
end

local deleteMsgSound = function(pid)
	local sfx = "enchant fail"
	logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \""..sfx.."\" 1.0 1.0")
end

local okSound = function(pid)
	local sfx = "Menu Size" -- "Menu Click"
	logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySoundVP \""..sfx.."\" 1.0 1.0")
end

local errorSound = function(pid)
	local sfx = "Fx\\inter\\menuNEWxbx.wav"
	logicHandler.RunConsoleCommandOnPlayer(pid, "Player->Say \""..sfx.."\", \"\"")
end

local pushMessageCharacterLimit = function(pid, bodyText)
	if string.len(tostring(bodyText)) > totalLetterCount then
		bodyText = bodyText:sub(1, totalLetterCount)
		bodyText = bodyText .. textColor .. "..."
		errorSound(pid)
		errorMsg(pid, "Your message contained too many characters.")
	end
	return bodyText
end

local getNewTicketNumber = function()
	local ticketNum = ticketData.ticketNum + 1
	ticketData.ticketNum = ticketNum
	return ticketNum
end

local getTopic = function(topicIndex)
	if listOfSupportTopics[topicIndex] ~= nil then
		return listOfSupportTopics[topicIndex].topic
	else
		return ""
	end
end

local getSubtopic = function(topicIndex, subtopicIndex)
	if listOfSupportTopics[topicIndex] ~= nil and listOfSupportTopics[topicIndex].subtopics[subtopicIndex] ~= nil then
		return listOfSupportTopics[topicIndex].subtopics[subtopicIndex]
	else
		return ""
	end
end

local updateViewedTicket = function(pid)
	if menuVar[pid] ~= nil and menuVar[pid].viewTicket ~= nil then
		local ticket = menuVar[pid].viewTicket
		
		for i=1,#ticketData.openTickets do
			local t = ticketData.openTickets[i]
			if t.number == ticket.number then
				if Players[pid].data.settings.staffRank < reqStaffRank then
					-- Player, so should only update playerViewed
					if t.playerViewed ~= true then
						t.playerViewed = true
						Save()
					end
				else
					-- Staff, sho should only update staffViewed
					if t.staffViewed ~= true then
						t.staffViewed = true
						Save()
					end
				end
				break
			end
		end
		
	end
end

local createNewTicket = function(pid)
	
	local tData = menuVar[pid].sendRequest
	if tData ~= nil and tData.topic ~= nil and tData.subtopic ~= nil and tData.message ~= nil then
		
		local ticketNum = getNewTicketNumber()
		local dateFormat = getDate()
		local senderName = getPName(pid)
		
		local newTicketData = {
			number = ticketNum,
			player = senderName,
			originDate = dateFormat,
			topic = getTopic(tData.topic), --tData.topic,
			subtopic = getSubtopic(tData.topic, tData.subtopic), --tData.subtopic,
			staffViewed = false,
			playerViewed = true,
			messages = {}
		}
		
		local ticketResponse = {
			messageDate = dateFormat,
			sender = senderName,
			message = tData.message
		}
		
		table.insert(newTicketData.messages, ticketResponse)
		table.insert(ticketData.openTickets, newTicketData)
		
		sentMsgSound(pid)
		confirmMsg(pid, notificationColor.."Your ticket (ticket ## "..ticketNum..") has been successfully created. A staff member will review your ticket as soon as possible. Thank you for your patience!")
		
		Save()
		
		clearMsgVariables(pid)
		
		alertStaffNewTicket() -- Alerts any online staff of a new unread ticket.
	end
end

local menuMenuScreen = function(pid)
	local txt = "Support System\n"
	
	if Players[pid].data.settings.staffRank < reqStaffRank then
		return tes3mp.CustomMessageBox(pid, supportMainMenuGUI, txt, "Request Help;Help Status;Exit")
	else
		return tes3mp.CustomMessageBox(pid, supportMainMenuGUI, txt, "View Open Tickets;View Closed Tickets;Exit")
	end
end

local requestHelpMenuScreen = function(pid)
	local txt = titleColor.."Request Help\n"..textColor.."Please fill out all fields below."
	local insertChoices = {}
	local options = ""
	
	local choices = {"Cancel","Submit Request","Topic: ","Subtopic: ","Message: "}
	if menuVar[pid].sendRequest == nil then menuVar[pid].sendRequest = {} end
	
	local menu = menuVar[pid].sendRequest
	for i=1,#choices do
		local o = choices[i]
		if i == 2 then
			if menu.topic == nil or menu.subtopic == nil or menu.message == nil then
				o = color.DimGrey..o
			end
		elseif i > 2 then
			local displayTxt = ""
			if i == 3 then -- Topic: txt 
				displayTxt = getTopicText(pid)
			elseif i == 4 then -- Subtopic: txt
				displayTxt = getSubtopicText(pid)
			elseif i == 5 then -- Message: txt
				displayTxt = menuVar[pid].sendRequest.message or ""
				if displayTxt ~= "" then
					displayTxt = "\n"..messageLimiter(displayTxt)
				end
			end
			
			o = o..color.White..displayTxt
		end
		table.insert(insertChoices, o)
	end
	
	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			options = options..insertChoices[i].."\n"
			table.insert(menuVar[pid].choices, insertChoices[i])
		end
		return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options:sub(1, -2))
	end
end

local topicSelectMenuScreen = function(pid)
	local txt = titleColor.."Request Help\n"..textColor.."Select a Topic."
	local insertChoices = {}
	local options = ""
	
	if menuVar[pid].sendRequest == nil then menuVar[pid].sendRequest = {} end
	if menuVar[pid].sendRequest.topic == nil then menuVar[pid].sendRequest.topic = 0 end
	
	for i=1,#listOfSupportTopics do
		table.insert(menuVar[pid].choices, listOfSupportTopics[i].topic)
		if menuVar[pid].sendRequest.topic == i then
			table.insert(insertChoices, listOfSupportTopics[i].topic) -- change text since this is the active one?
		else
			table.insert(insertChoices, listOfSupportTopics[i].topic)
		end
	end
	
	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			options = options..insertChoices[i].."\n"
			table.insert(menuVar[pid].choices, insertChoices[i])
		end
		return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
	end
end

local subtopicSelectMenuScreen = function(pid)
	local txt = titleColor.."Request Help\n"..textColor.."Select a Subtopic."
	local insertChoices = {}
	local options = ""
	
	if menuVar[pid].sendRequest == nil or menuVar[pid].sendRequest.topic == nil or menuVar[pid].sendRequest.topic == 0 then
		errorSound(pid)
		errorMsg(pid, "You must select a Topic first.")
		menuVar[pid].menu = "Request Help"
		return support.MainSupportMenuGUI(pid)
	end
	
	local index = menuVar[pid].sendRequest.topic
	if listOfSupportTopics[index].subtopics == nil then
		errorSound(pid)
		errorMsg(pid, "An error has occurred. Try again.")
		menuVar[pid].menu = "Request Help"
		return support.MainSupportMenuGUI(pid)
	end
	
	if menuVar[pid].sendRequest.subtopic == nil then menuVar[pid].sendRequest.subtopic = 0 end
	
	for i=1,#listOfSupportTopics[index].subtopics do
		table.insert(menuVar[pid].choices, listOfSupportTopics[index].subtopics[i])
		if menuVar[pid].sendRequest.topic == i then
			table.insert(insertChoices, listOfSupportTopics[index].subtopics[i]) -- change text since this is the active one?
		else
			table.insert(insertChoices, listOfSupportTopics[index].subtopics[i])
		end
	end
	
	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			options = options..insertChoices[i].."\n"
			table.insert(menuVar[pid].choices, insertChoices[i])
		end
		
		return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
	end
end

local requestHelpMessageMenuScreen = function(pid)
	
	if menuVar[pid].sendRequest == nil or menuVar[pid].sendRequest.topic == nil or menuVar[pid].sendRequest.topic == 0 then
		errorSound(pid)
		errorMsg(pid, "You must select a Topic first.")
		menuVar[pid].menu = "Request Help"
		return support.MainSupportMenuGUI(pid)
	end
	
	if menuVar[pid].sendRequest.subtopic == nil or menuVar[pid].sendRequest.subtopic == 0 then
		errorSound(pid)
		errorMsg(pid, "You must select a Subtopic first.")
		menuVar[pid].menu = "Request Help"
		return support.MainSupportMenuGUI(pid)
	end
	
	local topMsg = "Describe your issue:"
	local bottomMsg = "Please describe your issue in as much detail as possible."
	return tes3mp.InputDialog(pid, supportMainMenuGUI, topMsg, bottomMsg)
end

local viewOpenTicketsMenuScreen = function(pid)
	
	local txt = titleColor.."Open Ticket Inbox\n"..textColor.."View open tickets\nTicket ##        Topic        Player                                       "
	
	local unviewedTickets = {}
	local viewedTickets = {}
	local insertChoices = {}
	local options = " * Exit"
	
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.staffViewed == true then
			table.insert(viewedTickets, t)
		else
			table.insert(unviewedTickets, t)
		end
	end
	
	-- Sort unviewed tickets:
	if not tableHelper.isEmpty(unviewedTickets) then
		table.sort(unviewedTickets, function(a,b) return a.number<b.number end)
		for i=1,#unviewedTickets do
			table.insert(insertChoices, unviewedTickets[i])
		end
	end
	
	-- Sort viewed tickets:
	if not tableHelper.isEmpty(viewedTickets) then
		table.sort(viewedTickets, function(a,b) return a.number>b.number end)
		for i=1,#viewedTickets do
			table.insert(insertChoices, viewedTickets[i])
		end
	end
	
	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			local t = insertChoices[i]
			
			local ticketNum = tostring(t.number) or "???"
			local ticketTopic = t.topic
			if ticketTopic == nil then
				ticketTopic = "???"
			end
			
			if t.staffViewed ~= nil and t.staffViewed == true then
				
				local clr = color.White
				local status = color.Yellow.." [ACTIVE] "
				if t.close ~= nil then
					clr = color.DimGrey
					status = color.Green.." [CLOSED] "
				end
				options = options.."\n"..ticketNum.."  "..clr..ticketTopic..status..color.White..t.player
			else
				local status = ""
				for m=1,#t.messages do
					if t.messages[m].sender ~= nil and string.lower(t.messages[m].sender) ~= string.lower(t.player) then
						status = color.Yellow.." [ACTIVE]"
						if t.close ~= nil then
							clr = color.DimGrey
							status = color.Green.." [CLOSED] "
						end
						break
					end
				end
				options = options.."\n"..ticketNum.."  "..ticketTopic..status..color.White.." "..t.player
			end
			
			table.insert(menuVar[pid].choices, t)
			
		end
	end
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
end

local viewClosedTicketsMenuScreen = function(pid)
	
	local txt = titleColor.."Closed Ticket Inbox\n"..textColor.."View closed tickets\nTicket ##        Topic        Player                                       "
	
	local insertChoices = {}
	local options = " * Exit"
	
	for i=1,#ticketData.closedTickets do
		table.insert(insertChoices, ticketData.closedTickets[i])
	end
	
	--table.sort(insertChoices, function(a,b) return a.number<b.number end)
	table.sort(insertChoices, function(a,b) return a.number>b.number end)

	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			local t = insertChoices[i]
			
			local ticketNum = tostring(t.number) or "???"
			local ticketTopic = t.topic
			if ticketTopic == nil then
				ticketTopic = "???"
			end
			
			options = options.."\n"..ticketNum.."  "..ticketTopic.."  "..color.White..t.player
			
			table.insert(menuVar[pid].choices, t)
			
		end
	end
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
end

local helpStatusMenuScreen = function(pid)
	
	local txt = titleColor.."Service Request Inbox\n"..textColor.."View open tickets.\nTicket ##        Topic                                       "
	
	local unviewedTickets = {}
	local viewedTickets = {}
	local insertChoices = {}
	local options = " * Exit"
	local pName = string.lower(getPName(pid))
	
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.player ~= nil and string.lower(t.player) == pName then
			if t.playerViewed == true then
				table.insert(viewedTickets, t)
			else
				table.insert(unviewedTickets, t)
			end
			
		end
	end
	
	-- Sort unviewed tickets:
	if not tableHelper.isEmpty(unviewedTickets) then
		table.sort(unviewedTickets, function(a,b) return a.number<b.number end)
		for i=1,#unviewedTickets do
			table.insert(insertChoices, unviewedTickets[i])
		end
	end
	
	 -- Sort viewed tickets:
	if not tableHelper.isEmpty(viewedTickets) then
		table.sort(viewedTickets, function(a,b) return a.number>b.number end)
		for i=1,#viewedTickets do
			table.insert(insertChoices, viewedTickets[i])
		end
	end
	
	if not tableHelper.isEmpty(insertChoices) then
		for i=1,#insertChoices do
			local t = insertChoices[i]
			
			local ticketNum = tostring(t.number) or "???"
			local ticketTopic = t.topic or ""
			local ticketSubtopic = t.subtopic or ""
			
			if t.playerViewed ~= nil and t.playerViewed == true then
				options = options.."\n##"..ticketNum.."  "..color.White..ticketTopic -- .." "..ticketSubtopic -- subtopics tend to drag off the screen.
			else
				options = options.."\n##"..ticketNum.."  "..ticketTopic -- .." "..ticketSubtopic -- subtopics tend to drag off the screen.
			end
			
			table.insert(menuVar[pid].choices, t)
			
		end
	end
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
end

local helpStatusViewTicketScreen = function(pid)
	if menuVar[pid] == nil or menuVar[pid].viewTicket == nil then
		menuVar[pid].menu = "Help Status"
		return support.MainSupportMenuGUI(pid)
	end
	
	local ticket = menuVar[pid].viewTicket
	
	if Players[pid].data.settings.staffRank < reqStaffRank then
		updateViewedTicket(pid) -- Update ticket as viewed, since the player opened it.
	end
	
	local ticketTopic = ticket.topic
	local ticketSubtopic = ticket.subtopic
	
	local txt = titleColor..ticketTopic..textColor.."\n"..ticketSubtopic
	
	local options = " * Back\n * Update Ticket\n * Close Ticket\n"
	
	local msgs = {}
	for i=1,#ticket.messages do
		table.insert(msgs, ticket.messages[i])
	end
	
	local sortedMsgs = {}
	if not tableHelper.isEmpty(msgs) then
		local endCount = #msgs
		for i=1,#msgs do
			table.insert(sortedMsgs, msgs[endCount])
			endCount = endCount - 1
		end
	end
	
	local playerName = getPName(pid)
	for i=1,#sortedMsgs do
		local t = sortedMsgs[i]
		
		local senderName = t.sender		
		
		if string.lower(senderName) == string.lower(playerName) then
			senderName = " You wrote:"
		else
			senderName = " "..senderName.." wrote:"
		end
		
		options = options.."\n"..titleColor..t.messageDate..color.Yellow..senderName.."\n"..messageLimiter(t.message).."\n"
	end
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options:sub(1, -2))
end

local helpStatusViewClosedTicketScreen = function(pid)
	if menuVar[pid] == nil or menuVar[pid].viewTicket == nil then
		menuVar[pid].menu = "View Closed Tickets"
		return support.MainSupportMenuGUI(pid)
	end
	
	local ticket = menuVar[pid].viewTicket
	
	if Players[pid].data.settings.staffRank < reqStaffRank then
		updateViewedTicket(pid) -- Update ticket as viewed, since the player opened it.
	end
	
	local ticketTopic = ticket.topic
	local ticketSubtopic = ticket.subtopic
	
	local txt = titleColor..ticketTopic..textColor.."\n"..ticketSubtopic
	
	local options = " * Back"
	
	local msgs = {}
	for i=1,#ticket.messages do
		table.insert(msgs, ticket.messages[i])
	end
	
	local sortedMsgs = {}
	if not tableHelper.isEmpty(msgs) then
		local endCount = #msgs
		for i=1,#msgs do
			table.insert(sortedMsgs, msgs[endCount])
			endCount = endCount - 1
		end
	end
	
	local playerName = getPName(pid)
	for i=1,#sortedMsgs do
		local t = sortedMsgs[i]
		
		local senderName = t.sender		
		
		if string.lower(senderName) == string.lower(playerName) then
			senderName = " You wrote:"
		else
			senderName = " "..senderName.." wrote:"
		end
		
		options = options.."\n"..titleColor..t.messageDate..color.Yellow..senderName.."\n"..messageLimiter(t.message).."\n"
	end
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options:sub(1, -2))
end

local updateTicketMessageMenuScreen = function(pid)
	
	if menuVar[pid] == nil or menuVar[pid].viewTicket == nil then
		menuVar[pid].menu = "Help Status"
		return support.MainSupportMenuGUI(pid)
	end
	
	if Players[pid].data.settings.staffRank >= reqStaffRank then
		local topMsg = "Update player on this issue:"
		local bottomMsg = "Please be professional in your response.\n Use /n to skip lines."
		return tes3mp.InputDialog(pid, supportMainMenuGUI, topMsg, bottomMsg)
	else
		local topMsg = "Update your issue:"
		local bottomMsg = "Please describe your issue in as much detail as possible."
		return tes3mp.InputDialog(pid, supportMainMenuGUI, topMsg, bottomMsg)
	end
end

local updateTicketMenuScreen = function(pid)
	if menuVar[pid] == nil or menuVar[pid].viewTicket == nil then
		menuVar[pid].menu = "Help Status"
		return support.MainSupportMenuGUI(pid)
	end
	
	local ticket = menuVar[pid].viewTicket
	
	local ticketTopic = ticket.topic
	local ticketSubtopic = ticket.subtopic
	
	local txt = titleColor..ticketTopic.."\n"..textColor..ticketSubtopic
	
	local options = " * Cancel\n * Submit This Message\n * Edit Message\n"
	local uMessage = menuVar[pid].updateMessage
	options = options..titleColor.."Message:\n"..messageLimiter(uMessage)
	
	return tes3mp.ListBox(pid, supportMainMenuGUI, txt, options)
end

local closeTicketConfirmationMenu = function(pid)
	local t = menuVar[pid].viewTicket
	if t.number ~= nil then
		local txt = textColor.."Are you sure you want to close ticket ##"..titleColor..t.number..textColor.."?\n"
		return tes3mp.CustomMessageBox(pid, supportMainMenuGUI, txt, "Close Ticket;Cancel")
	end
end

support.MainSupportMenuGUI = function(pid)
	
	if menuVar[pid] ~= nil and menuVar[pid].menu ~= nil then		
		
		local menuScreen = menuVar[pid].menu
		menuVar[pid].choices = {}
		
		if menuScreen == "Main Menu" then -- option menu
			menuMenuScreen(pid)
		elseif menuScreen == "Request Help" then -- list menu
			requestHelpMenuScreen(pid)
		elseif menuScreen == "View Open Tickets" then -- list menu
			viewOpenTicketsMenuScreen(pid)
		elseif menuScreen == "View Closed Tickets" then -- list menu
			viewClosedTicketsMenuScreen(pid)
		elseif menuScreen == "Topic: " then
			topicSelectMenuScreen(pid)
		elseif menuScreen == "Subtopic: " then
			subtopicSelectMenuScreen(pid)
		elseif menuScreen == "Request Help Message" then
			requestHelpMessageMenuScreen(pid)
		elseif menuScreen == "Help Status" then -- list menu
			helpStatusMenuScreen(pid)
		elseif menuScreen == "View Ticket" then -- view selected ticket menu
			helpStatusViewTicketScreen(pid)
		elseif menuScreen == "View Closed Ticket" then -- view selected closed ticket menu
			helpStatusViewClosedTicketScreen(pid)
		elseif menuScreen == "Update Ticket" then -- add on to selected ticket
			updateTicketMessageMenuScreen(pid)
		elseif menuScreen == "Update Ticket Menu" then -- Confirmation menu for updated ticket
			updateTicketMenuScreen(pid)
		elseif menuScreen == "Close Ticket" then -- close ticket confirmation menu
			closeTicketConfirmationMenu(pid)
		end
		
	end
end

local mainMenuChoiceHandler = function(pid, data)
	if tonumber(data) ~= nil then
		
		if Players[pid].data.settings.staffRank < reqStaffRank then
			if tonumber(data) == 0 then -- "Request Help"
				menuVar[pid].menu = "Request Help"
				return support.MainSupportMenuGUI(pid)
				
			elseif tonumber(data) == 1 then -- "Help Status"
				menuVar[pid].menu = "Help Status"
				return support.MainSupportMenuGUI(pid)
				
			end
		else
			
			if tonumber(data) == 0 then -- "View Open Tickets"
				menuVar[pid].menu = "View Open Tickets"
				return support.MainSupportMenuGUI(pid)
				
			elseif tonumber(data) == 1 then -- "View Closed Tickets"
				menuVar[pid].menu = "View Closed Tickets"
				return support.MainSupportMenuGUI(pid)
				
			end
		end
	
	end
	menuVar[pid] = nil
end

local requestHelpChoiceHandler = function(pid, data)
	if tonumber(data) ~= nil then
		if tonumber(data) == 0 then -- "Cancel"
			menuVar[pid].menu = "Main Menu"
			
		elseif tonumber(data) == 1 then -- "Submit Request"
			
			-- Prevent from sending if topic or subtopic or message is missing.
			if menuVar[pid] ~= nil then
				local request = menuVar[pid].sendRequest
				local currentTime = os.time()
				if menuVar[pid].newTicketTimer == nil or currentTime > menuVar[pid].newTicketTimer then
		
					local request = menuVar[pid].sendRequest
					if request ~= nil and request.topic ~= nil and request.subtopic ~= nil and request.message ~= nil then
						createNewTicket(pid)
						menuVar[pid].newTicketTimer = currentTime + newTicketCooldown
						menuVar[pid].menu = "Main Menu"
					else
						errorSound(pid)
						errorMsg(pid, "Fill out all fields below first.")
						menuVar[pid].menu = "Request Help"
					end
				
				else
					errorSound(pid)
					errorMsg(pid, "You cannot submit another request so soon.")
					menuVar[pid].menu = "Request Help"
				end
			end
			
		elseif tonumber(data) == 2 then -- "Topic: "
			menuVar[pid].menu = "Topic: "
			
		elseif tonumber(data) == 3 then -- "Subtopic: "
			menuVar[pid].menu = "Subtopic: "
			
		elseif tonumber(data) == 4 then -- "Message: "
			menuVar[pid].menu = "Request Help Message"
		end
		return support.MainSupportMenuGUI(pid)
	end
	menuVar[pid] = nil
end

local requestHelpTopicChoiceHandler = function(pid, data)
	if tonumber(data) ~= nil then
		local index = tonumber(data) + 1
		if listOfSupportTopics[index] ~= nil then
			menuVar[pid].sendRequest.topic = index
			menuVar[pid].sendRequest.subtopic = 0
			okSound(pid)
		else
			errorSound(pid)
		end
	end
	menuVar[pid].menu = "Request Help"
	return support.MainSupportMenuGUI(pid)
end

local requestHelpSubtopicChoiceHandler = function(pid, data)
	if tonumber(data) ~= nil then
		local tIndex = menuVar[pid].sendRequest.topic
		local index = tonumber(data) + 1
		
		if listOfSupportTopics[tIndex] ~= nil and listOfSupportTopics[tIndex].subtopics[index] ~= nil then
			menuVar[pid].sendRequest.subtopic = index
			okSound(pid)
		else
			errorSound(pid)
		end
	end
	menuVar[pid].menu = "Request Help"
	return support.MainSupportMenuGUI(pid)
end

local requestHelpMessageChoiceHandler = function(pid, data)
	
	if data ~= nil and tostring(data) ~= "" and tostring(data) ~= " " and tostring(data) ~= "  " then
		menuVar[pid].sendRequest.message = pushMessageCharacterLimit(pid, tostring(data))
		okSound(pid)
	else
		errorSound(pid)
	end
	menuVar[pid].menu = "Request Help"
	return support.MainSupportMenuGUI(pid)
end

local moveTicketToClosedTickets = function(ticket)
	
	table.insert(ticketData.closedTickets, ticket)
	
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.number == ticket.number then
			ticketData.openTickets[i] = nil
			break
		end
	end
	
	tableHelper.cleanNils(ticketData)
end

local delayTicketClosing = function(ticket)
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.number == ticket.number then
			local delayCloseTime = os.time() + staffTicketCloseTimer
			t.close = delayCloseTime
			break
		end
	end
	Save()
end

support.checkForClosedTickets = function()
	
	local ticketsToClose = {}
	local currentTime = os.time()
	local pushSave = false
	
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.close ~= nil and currentTime > t.close then
			table.insert(ticketsToClose, t)
		end
	end
	
	if not tableHelper.isEmpty(ticketsToClose) then
		for i=1,#ticketsToClose do
			moveTicketToClosedTickets(ticketsToClose[i])
			pushSave = true
		end
	end
	
	if pushSave then
		Save()
	end
	tes3mp.RestartTimer(GlobalFishingTimeTimer, time.seconds(closeTicketTimer))
end
GlobalCloseTicketTimeUpdate = support.checkForClosedTickets
GlobalCloseTicketTimeTimer = tes3mp.CreateTimer("GlobalCloseTicketTimeUpdate", time.seconds(closeTicketTimer))
tes3mp.StartTimer(GlobalCloseTicketTimeTimer)

local closeTicket = function(pid)
	local t = menuVar[pid].viewTicket
	
	if t ~= nil then
		local ticketNum = t.number or "???"
		if t.player ~= nil and string.lower(t.player) == string.lower(getPName(pid)) then
			-- Move this ticket to closed tickets immediately because the player closed it.
			moveTicketToClosedTickets(t)
			deleteMsgSound(pid)
			confirmMsg(pid, notificationColor.."You have closed ticket ##"..ticketNum)
			menuVar[pid].menu = "Help Status"
		else
			-- Move this ticket to the closed tickets in 48 hours because a staff member closed it.
			delayTicketClosing(t)
			confirmMsg(pid, notificationColor.."You have set ticket ##"..ticketNum.." to close in 48 hours if player does not respond first.")
			menuVar[pid].menu = "View Open Tickets"
		end
		
	end
	
	return support.MainSupportMenuGUI(pid)
end

local openTicketChoiceHandler = function(pid, data)
	local target = tonumber(data)
	if target == nil or target == 0 or target == 18446744073709551615 then
		menuVar[pid].menu = "Main Menu"
	else
		menuVar[pid].viewTicket = menuVar[pid].choices[target]
		menuVar[pid].menu = "View Ticket"
	end
	return support.MainSupportMenuGUI(pid)
end

local closedTicketChoiceHandler = function(pid, data)
	local target = tonumber(data)
	if target == nil or target == 0 or target == 18446744073709551615 then
		menuVar[pid].menu = "Main Menu"
	else
		menuVar[pid].viewTicket = menuVar[pid].choices[target]
		menuVar[pid].menu = "View Closed Ticket"
	end
	return support.MainSupportMenuGUI(pid)
end

local helpStatusChoiceHandler = function(pid, data)
	local target = tonumber(data)
	if target == nil or target == 0 or target == 18446744073709551615 then
		menuVar[pid].menu = "Main Menu"
	else
		menuVar[pid].viewTicket = menuVar[pid].choices[target]
		menuVar[pid].menu = "View Ticket"
	end
	return support.MainSupportMenuGUI(pid)
end

local viewTicketChoiceHandler = function(pid, data)
	local target = tonumber(data)
	
	if Players[pid].data.settings.staffRank < reqStaffRank then
		if target == nil or target == 0 or target == 18446744073709551615 then -- Back
			menuVar[pid].menu = "Help Status"
		elseif target == 1 then --Update Ticket
			menuVar[pid].menu = "Update Ticket"
		elseif target == 2 then -- Close Ticket
			menuVar[pid].menu = "Close Ticket"
		end
	else
		if target == nil or target == 0 or target == 18446744073709551615 then -- Back
			menuVar[pid].menu = "View Open Tickets"
		elseif target == 1 then --Update Ticket
			menuVar[pid].menu = "Update Ticket"
		elseif target == 2 then -- Close Ticket
			menuVar[pid].menu = "Close Ticket"
		end
	end
	return support.MainSupportMenuGUI(pid)
end

local confirmUpdateTicket = function(pid)
	
	if menuVar[pid] == nil or menuVar[pid].viewTicket == nil then
		menuVar[pid].menu = "Help Status"
		return support.MainSupportMenuGUI(pid)
	end
	
	local ticket = menuVar[pid].viewTicket
	local dateFormat = getDate()
	local senderName = getPName(pid)
	local uMessage = menuVar[pid].updateMessage
	
	local saveTicket = false
	
	for i=1,#ticketData.openTickets do
		local t = ticketData.openTickets[i]
		if t.number == ticket.number then
			local ticketResponse = {
				messageDate = dateFormat,
				sender = senderName,
				message = uMessage
			}
			
			if Players[pid].data.settings.staffRank >= reqStaffRank then
				t.staffViewed = true
				t.playerViewed = false
			else
				t.staffViewed = false
				t.playerViewed = true
			end
			
			
			t.close = nil
			table.insert(t.messages, ticketResponse)
			saveTicket = true
			break
		end
	end
	
	if saveTicket then
		Save()
		
		if Players[pid].data.settings.staffRank < reqStaffRank then -- Only do this if its a non-staff member updating a ticket!
			alertStaffNewTicket() -- Alerts any online staff of a new unread ticket.
		elseif string.lower(ticket.player) ~= string.lower(senderName) then
			alertPlayerUpdatedTicket(ticket.player)
		end
		
		clearMsgVariables(pid)
		
		okSound(pid)
		sentMsgSound(pid)
		confirmMsg(pid, notificationColor.."You have updated ticket ##"..ticket.number..".")
		
		menuVar[pid].menu = "View Ticket"
	else
		errorSound(pid)
		errorMsg(pid, "That ticket no longer exists.")
		menuVar[pid].menu = "Help Status"
	end
	return support.MainSupportMenuGUI(pid)
end

local updateTicketChoiceHandler = function(pid, data)
	local target = tonumber(data)
	if target == nil or target == 0 or target == 18446744073709551615 then -- Cancel
		if Players[pid].data.settings.staffRank >= reqStaffRank then
			menuVar[pid].menu = "View Open Tickets" -- Take staff to a different page
		else
			menuVar[pid].menu = "Help Status"
		end
	elseif target == 1 then -- Confirm Update
		
		if menuVar[pid] ~= nil then
			
			if Players[pid].data.settings.staffRank >= reqStaffRank then
				return confirmUpdateTicket(pid)
			else
				local currentTime = os.time()
				
				if menuVar[pid].updateTicketTimer == nil or currentTime > menuVar[pid].updateTicketTimer then
					
					menuVar[pid].updateTicketTimer = currentTime + updateTicketCooldown
					return confirmUpdateTicket(pid)
				
				else
					errorSound(pid)
					errorMsg(pid, "You cannot update another request so soon.")
					menuVar[pid].menu = "View Ticket"
				end
			end
		end
		
	elseif target == 2 then --  Edit Message
		menuVar[pid].menu = "Update Ticket"
	end
	
	return support.MainSupportMenuGUI(pid)
end

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	local isValid = eventStatus.validDefaultHandler

	if isValid ~= false then
		if idGui == supportMainMenuGUI and menuVar[pid] and menuVar[pid].menu then
			isValid = false
			
			local menuScreen = menuVar[pid].menu
			
			if menuScreen == "Main Menu" then
				mainMenuChoiceHandler(pid, data)
			
			elseif menuScreen == "View Open Tickets" then
				openTicketChoiceHandler(pid, data)
			
			elseif menuScreen == "View Closed Tickets" then
				closedTicketChoiceHandler(pid, data)
			
			elseif menuScreen == "Request Help" then
				requestHelpChoiceHandler(pid, data)
			
			elseif menuScreen == "Topic: " then
				requestHelpTopicChoiceHandler(pid, data)
			
			elseif menuScreen == "Subtopic: " then
				requestHelpSubtopicChoiceHandler(pid, data)
			
			elseif menuScreen == "Request Help Message" then
				requestHelpMessageChoiceHandler(pid, data)
		
			elseif menuScreen == "Help Status" then
				helpStatusChoiceHandler(pid, data)
		
			elseif menuScreen == "View Ticket" then
				viewTicketChoiceHandler(pid, data)
			
			elseif menuScreen == "View Closed Ticket" then
				menuVar[pid].menu = "View Closed Tickets"
				return support.MainSupportMenuGUI(pid)
			
			elseif menuScreen == "Update Ticket" then
				local update = tostring(data)
				if update ~= nil and update ~= "" and update ~= " " and update ~= "  " then
					menuVar[pid].updateMessage = pushMessageCharacterLimit(pid, tostring(data))
					okSound(pid)
					menuVar[pid].menu = "Update Ticket Menu"
				else
					errorSound(pid)
					menuVar[pid].menu = "Update Ticket"
				end
				return support.MainSupportMenuGUI(pid)
				
			elseif menuScreen == "Update Ticket Menu" then
				updateTicketChoiceHandler(pid, data)
			
			elseif menuScreen == "Close Ticket" then
				if tonumber(data) ~= nil and tonumber(data) == 0 then
					closeTicket(pid)
				else
					menuVar[pid].menu = "View Ticket"
					return support.MainSupportMenuGUI(pid)
				end
				
			end
		end
	end
	
	eventStatus.validDefaultHandler = isValid
    return eventStatus
end)

local callSupportMenu = function(pid)	
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		if menuVar[pid] == nil then menuVar[pid] = {} end
		menuVar[pid].menu = "Main Menu"
		support.MainSupportMenuGUI(pid)
	end
end
customCommandHooks.registerCommand("support", function(pid, cmd) callSupportMenu(pid) end)
customCommandHooks.registerCommand("ticket", function(pid, cmd) callSupportMenu(pid) end)
customCommandHooks.registerCommand("tickets", function(pid, cmd) callSupportMenu(pid) end)

local checkIfHasUnreadTicket = function(pid)
	
	if Players[pid].data.settings.staffRank >= reqStaffRank then
		
		for i=1,#ticketData.openTickets do
			local t = ticketData.openTickets[i]
			if t.staffViewed ~= nil and t.staffViewed == false and t.close == nil then
				tes3mp.SendMessage(pid, notificationColor.."There are unread support tickets.\n", false)
				break
			end
		end
		
	else
		
		local pName = string.lower(getPName(pid))
		
		for i=1,#ticketData.openTickets do
			local t = ticketData.openTickets[i]
			if t ~= nil and t.player ~= nil and string.lower(t.player) == pName then
				if t.playerViewed ~= nil and t.playerViewed == false then
					tes3mp.SendMessage(pid, notificationColor.."You have an unread support ticket.\n", false)
					break
				end
			end
		end
	
	end
	
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		checkIfHasUnreadTicket(pid)
		menuVar[pid] = nil
	end
end)

return support
