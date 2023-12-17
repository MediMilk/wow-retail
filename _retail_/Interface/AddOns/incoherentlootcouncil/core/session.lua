local ilc, c, l = unpack(select(2, ...))

--==========================================
-- Sessions
--==========================================
function ilc:startSession(itemLink, lootedBy, forced, rollID)
	if (not itemLink) then return end
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	lootedBy = lootedBy and ilc:FetchUnitName(lootedBy) or ""

	-- convert these from "1" or "0" to true or false booleans
	if (type(forced) == "string") then
		forced = tonumber(forced) == 1 and true or false
	end
	-- roll needs to be something for uid
	if (rollID == nil or rollID == false) then rollID = -1 end
	if (type(rollID) == "string") then
		rollID = tonumber(rollID)
	end

	-- check if item is cached in wow
	if (GetItemInfo(itemLink)) then
		local itemUID = ilc:GetItemUID(itemLink, lootedBy, rollID)
		ilc.itemMap[itemUID] = itemLink

		if (ilc:itemValidForSession(itemLink, lootedBy, false, rollID) or forced) then
			ilc:debug("Starting session for "..itemLink)
			ilc.loot_sessions[itemUID] = lootedBy
			ilc.loot_want[itemUID] = {}

			if (ilc:inLC()) then
				ilc.loot_council_votes[itemUID] = {} 
				ilc:createVoteWindow(itemUID, lootedBy)
				ilc:updateVotesRemaining(itemUID, ilc.localPlayer)
			end

			ilc:createRollWindow(itemUID, lootedBy)
		end
	else
		-- need to await server async info
		ilc.items_waiting_for_session[itemID] = {itemLink, lootedBy, forced, rollID}
		GetItemInfo(itemLink) -- queue the server
	end
end

----------------------------------------
-- Fired when an item is received via chat (trade or loot)
----------------------------------------
function ilc:StartSessionFromTradable(itemLink, arg1, arg2, forced)
	if (not IsInRaid() and not ilc.enableTests) then return end

	local delay = 1

	if (not itemLink and (arg1 or arg2)) then -- coming from chat
		local myItem = LOOT_ITEM_PUSHED_SELF:gsub('%%s', '(.+)');
		local myLoot = LOOT_ITEM_SELF:gsub('%%s', '(.+)');
		itemLink = arg1:match(myLoot) or arg1:match(myItem)
	else -- being manually called
		delay = 0 -- this means we have the itemLink and don't need to play safe
	end

	if (itemLink) then -- if this doesn't exist then this should be an item at all?
		GetItemInfo(itemLink)

		C_Timer.After(delay, function()
			local itemUID = ilc:GetItemUID(itemLink, false, -1)

			-- this was traded to me, ignore it
			if (ilc.tradedItems[itemUID]) then
				ilc:debug('Experimental: Item received via trading, will not be announced again.')
				ilc:sendAction("tradeReceived", ilc.localPlayer, itemLink)
				return
			end

			-- can we trade this item? scan the tooltip
			if (ilc:verifyTradability(itemLink)) then
				ilc:debug(itemLink, "is tradable")
				ilc:sendAction("startSession", itemLink, ilc:FetchUnitName('player'), 0, 0)
			end
		end)
	end
end

----------------------------------------
-- fired when trade is received and we can remove a user from the trade assignment window
----------------------------------------
function ilc:tradeReceived(targetPlayer, itemLink)
	if (not ilc:IsRaidLeader()) then return end

	ilc:remove_trade_assignment(itemLink, targetPlayer)
end

----------------------------------------
-- EndSession
----------------------------------------
function ilc:endSession(itemUID)
	local itemLink = ilc.itemMap[itemUID]

	if not itemLink then return end

	local tab = ilc:getTab(itemUID)
	tab.itemUID = nil
	tab.entries:ReleaseAll()
	ilc.tabs:Release(tab)

	local roll = ilc:getRoll(itemUID)
	ilc.rolls:Release(roll)

	ilc.item_drops[itemLink] = nil
	ilc.loot_sessions[itemUID] = nil
	ilc.loot_council_votes[itemUID] = nil
	ilc.loot_want[itemUID] = nil
	
	ilc:repositionFrames()

	-- just to kill fringe cases
	C_Timer.After(1, function()
		ilc:repositionFrames()
	end)
end

function ilc:createVoteWindow(itemUID, lootedBy)
	lootedBy = lootedBy and ilc:FetchUnitName(lootedBy) or ""

	local itemLink = ilc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	ilc.window:Show()
	local name, color = ilc:prettyName(lootedBy)
	
	-- Set Up tab and item info
	local tab = ilc:getTab(itemUID)
	tab:Show()
	tab.itemUID = itemUID
	tab.itemLink = itemLink
	tab.icon:SetTexture(texture)
	tab.table.item.itemtext:SetText(itemLink)
	tab.table.item.num_items:SetText("Looted by "..name)
	tab.table.item.num_items:SetTextColor(1, 1, 1)
	tab.table.item.icon.tex:SetTexture(texture)

	local ilvl, wf_tf, socket, infostr = ilc:GetItemValue(itemLink)
	tab.wfsock:SetText(infostr)
	tab.table.item.wfsock:SetText(infostr)

	local slotname = string.lower(string.gsub(equipSlot, "INVTYPE_", ""));
	slotname = slotname:gsub("^%l", string.utf8upper)
	tab.table.item.itemdetail:SetText("ilvl: "..ilvl.."    "..subclass..", "..slotname);

	tab.table.item.itemLink = itemLink
	
	ilc:repositionFrames()
end

function ilc:createRollWindow(itemUID, lootedBy)
	lootedBy = lootedBy and ilc:FetchUnitName(lootedBy) or ""

	local roll = ilc:getRoll(itemUID)
	local itemLink = ilc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)

	local name, color = ilc:prettyName(lootedBy)

	-- reroll button for tier
	if (ilc:isTier(itemLink)) then
		roll.buttons["Reroll"]:Show()
	else
		roll.buttons["Reroll"]:Hide()
	end

	roll:Show()
	roll.itemUID = itemUID
	roll.item.icon.tex:SetTexture(texture)
	roll.item.item_text:SetText(itemLink)

	-- for tooltips
	roll.item.icon.itemLink = itemLink
	roll.item.num_items:SetText("Looted by "..name)

	local ml_qn = {}
	if (ilc.master_looter_qn) then
		for k, v in pairs(ilc.master_looter_qn) do
			table.insert(ml_qn, k)
		end
		table.sort(ml_qn)
		for k, v in pairs(ml_qn) do
			local qn
			for i = 1, 10 do
				local rqn = roll.buttons.note.quicknotes[i]
				if (not rqn:IsShown()) then
					qn = rqn
					break
				end
			end
			
			qn:Show()
			qn:SetText(v)
			ilc:skinButton(qn, true)
		end
	end

	local ilvl, wf_tf, socket, infostr = ilc:GetItemValue(itemLink)
	roll.item.icon.wfsock:SetText(infostr)
	
	if ilc:itemEquippable(itemUID) then
		ilc:debug("I can use", itemLink)
		ilc:sendAction("addUserConsidering", itemUID, ilc.localPlayer);
	else
		ilc:debug("I can't use", itemLink, "so I pass.")
		local itemLink1, itemLink2 = ilc:fetchUserGear("player", itemLink)
		ilc.rolls:Release(roll)
	end

	ilc:repositionFrames()
end

----------------------------------------
-- UpdateUserNote
----------------------------------------
function ilc:updateUserNote(itemUID, playerName, notes)
	local playerName = ilc:FetchUnitName(playerName)
	local itemLink = ilc.itemMap[itemUID]
	
	if not ilc:inLC() then return false end
	if (not ilc.loot_sessions[itemUID]) then return false end

	local entry = ilc:getEntry(itemUID, playerName)
	if (not entry) then return end
	
	-- add notes
	entry.notes = notes
	if (notes and tostring(notes) and strlen(notes) > 1) then
		entry.user_notes:Show()
	else
		entry.user_notes:Hide()
	end

	entry:updated()
end

----------------------------------------
-- UpdateUserItem
----------------------------------------
function ilc:updateUserItem(itemLink, frame)
	local texture = select(10, GetItemInfo(itemLink))
	frame:Show()
	frame.tex:SetTexture(texture)
	frame:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

----------------------------------------
-- AddUserConsidering
----------------------------------------
function ilc:addUserConsidering(itemUID, playerName)
	local playerName = ilc:FetchUnitName(playerName)
	local itemLink = ilc.itemMap[itemUID]
	
	if not ilc:inLC() then return false end
	if (not ilc.loot_sessions[itemUID]) then return false end

	local entry = ilc:getEntry(itemUID, playerName)
	if (not entry) then return end
	
	ilc:debug("User considering:", playerName, itemLink)

	local guildName, guildRankName, guildRankIndex = GetGuildInfo(ilc:FetchUnitName(playerName));
	entry.rankIndex = guildRankName and guildRankIndex or 10

	entry.wantLevel = 15
	entry.notes = ""

	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local name, color = ilc:prettyName(playerName)
	
	entry:Show()
	entry.name.text:SetText(name)
	entry.name.text:SetTextColor(color.r, color.g, color.b);
	entry.interest.text:SetText(l["frameConsidering"]);
	entry.interest.text:SetTextColor(.5,.5,.5);
	entry.gear1:Hide()
	entry.gear2:Hide()
	entry.ilvl:SetText("")
	entry.rank:SetText("")
	entry.itemUID = itemUID
	entry.playerName = playerName
	
	if (ilc:IsRaidLeader()) then
		entry.removeUser:Show()
	else
		entry.removeUser:Hide()
	end

	ilc:repositionFrames()
end

function ilc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2, roll, ilvl, guildRank, notes, quicknotes)
	playerName = ilc:FetchUnitName(playerName)

	if (not notes or strlen(notes) == 0) then notes = false end
	local itemLink = ilc.itemMap[itemUID]

	if (not ilc.loot_sessions[itemUID]) then return end
	if (not ilc:inLC()) then return false end
	
	-- -- actual want text
	local entry = ilc:getEntry(itemUID, playerName)
	if (not entry) then return end

	ilc.loot_want[itemUID][playerName] = {itemUID, playerName, want, itemLink1, itemLink2, notes}
	
	local wantText, wantColor = unpack(ilc.buttons[want])

	ilc:debug("User want:", playerName, itemLink, wantText)

	local name, color = ilc:prettyName(playerName)
	entry.name.text:SetText(name)
	entry:Show()
	entry.interest.text:SetText(wantText)
	entry.interest.text:SetTextColor(unpack(wantColor))
	entry.voteUser:Show()
	entry.roll = roll
	entry.myilvl = tonumber(ilvl) or 0
	entry.wantLevel = want
	entry.itemUID = itemUID
	entry.playerName = playerName
	entry.rank:SetText(guildRank)
	entry.ilvl:SetText(ilvl)

	entry.updated()

	-- player items
	if (GetItemInfo(itemLink1)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink1)
		entry.gear1:Show()
		entry.gear1.tex:SetTexture(texture1)
		entry.gear1:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		entry.gear1:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink1))
		if (itemID) then
			ilc.player_items_waiting[itemID] = {itemLink1, entry.gear1}
		end
	end

	if (GetItemInfo(itemLink2)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink2)
		entry.gear2:Show()
		entry.gear2.tex:SetTexture(texture1)
		entry.gear2:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		entry.gear2:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink2))
		if (itemID) then
			ilc.player_items_waiting[itemID] = {itemLink2, entry.gear2}
		end
	end
	
	ilc:repositionFrames()

	-- add notes
	ilc:updateUserNote(itemUID, playerName, notes)
end


----------------------------------------
-- RemoveUserConsidering
----------------------------------------
function ilc:removeUserConsidering(itemUID, playerName)
	if (not ilc:inLC()) then return end

	playerName = ilc:FetchUnitName(playerName)

	-- reset frame
	local tab = ilc:getTab(itemUID)
	local entry = ilc:getEntry(itemUID, playerName)
	local itemLink = ilc.itemMap[itemUID]

	tab.entries:Release(entry)

	-- stop if no session exists
	if (not ilc.loot_sessions[itemUID]) then return false end

	-- reset votes
	if (ilc.loot_council_votes[itemUID]) then
		for council, tab in pairs(ilc.loot_council_votes[itemUID]) do
			for v = 1, #ilc.loot_council_votes[itemUID][council] do
				if (ilc.loot_council_votes[itemUID][council][v] == playerName) then
					ilc.loot_council_votes[itemUID][council][v] = false
				end
			end
		end

		ilc:updateVotesRemaining(itemUID, ilc.localPlayer)
	end

	-- tell that user to kill their roll window
	ilc.overrideChannel = "WHISPER"
	ilc.overrideRecipient = playerName
	ilc:sendAction("removeUserRoll", itemUID, playerName);
	ilc.loot_want[itemUID][playerName] = nil
	
	ilc:repositionFrames()
	
	-- ilc:debug("Removed", playerName, "considering", itemLink)
end

----------------------------------------
-- removeUserRoll
----------------------------------------
function ilc:removeUserRoll(itemUID, playerName)
	playerName = ilc:FetchUnitName(playerName)

	if (ilc.localPlayer == playerName) then
		local roll = ilc:getRoll(itemUID)
		ilc.rolls:Release(roll)
		ilc:repositionFrames()
	end
end

----------------------------------------
-- awardLoot
-- This function alerts awarding and then sends a raid message
----------------------------------------
function ilc:awardLoot(playerName, itemUID)
	if (not ilc:IsRaidLeader()) then return end
	
	if (not itemUID) then return end
	local lootedBy = ilc.loot_sessions[itemUID]
	local itemLink = ilc.itemMap[itemUID]
	if (not itemLink) then return end

	playerName = ilc:FetchUnitName(playerName)
	local unit = ilc:unitName(playerName)

	SendChatMessage("ILC: Please trade "..itemLink.." to "..unit, "WHISPER", nil, lootedBy)
	SendChatMessage("ILC: "..lootedBy.."'s "..itemLink.." awarded to "..unit, "RAID")

	ilc:add_trade_assignment(lootedBy, itemLink, playerName)

	-- ilc:sendAction("addLootHistory", itemUID, playerName)

	ilc:repositionFrames()
end

----------------------------------------
-- addLootHistory
-- store log of when / what user was awarded in the past
----------------------------------------
-- idk a shity one, return days since 1-1-2020
local function days_ago(strtime, days)
	return strtime - days
end

local function strtotime(month, day, year)
	local today = date("%m-%d-%Y")
	local d_month, d_day, d_year = strsplit("-", today)
	month = month and tonumber(month) or tonumber(d_month)
	day = month and tonumber(day) or tonumber(d_day)
	year = month and tonumber(year) or tonumber(d_year)

	-- use this for days in each month
	local days_in_month = {
		[1] = 31,
		[2] = 28,
		[3] = 31,
		[4] = 30,
		[5] = 31,
		[6] = 30,
		[7] = 31,
		[8] = 31,
		[9] = 30,
		[10] = 31,
		[11] = 30,
		[12] = 31,
	}

	-- how many days have passed in before this month
	local days_months = 0
	local prev_months = (month - 1)
	if (prev_months > 0) then
		for i = 1, (month - 1) do
			days_months = days_months + (days_in_month[i])
		end
	end

	-- years since 2020 * 365 days a year
	local days_year = (year - 2020) * 365

	return day + days_months + days_year
end

-- function ilc:addLootHistory(itemUID, playerName)
-- 	local today = date("%m-%d-%Y")
-- 	local month, day, year = strsplit("-", today)
-- 	local today = tostring(strtotime(month, day, year))

-- 	if (not ilc.loot_sessions[itemUID]) then return end
-- 	if (not ilc:inLC()) then return false end
-- 	if (not ilc.loot_want[itemUID] or ilc.loot_want[itemUID][playerName]) then
-- 		return
-- 	end
	
-- 	-- loot info
-- 	local lootedBy = ilc.loot_sessions[itemUID]
-- 	local itemLink = ilc.itemMap[itemUID]

-- 	ilc:debug("add loot history", playerName, today, itemLink)

-- 	-- store player entries by day
-- 	ILC_HISTORY[playerName] = ILC_HISTORY[playerName] or {}
-- 	ILC_HISTORY[playerName][today] = ILC_HISTORY[playerName][today] or {}

-- 	-- data table
-- 	local itemID, gem1, bonusID1, bonusID2, upgradeValue, lootedBy = strsplit(":", itemUID)
	
-- 	-- information about why they were in on the item
-- 	local itemUID, playerName, want, itemLink1, itemLink2, notes = unpack(ilc.loot_want[itemUID][playerName])
-- 	local want, wantColor = unpack(ilc.buttons[want])
-- 	wantColor = ilc:RGBPercToHex(unpack(wantColor))

-- 	-- info on items
-- 	local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture, vendorPrice = GetItemInfo(itemLink)
-- 	local itemName1, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture1, vendorPrice = GetItemInfo(itemLink1)
-- 	local itemName2, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture2, vendorPrice = GetItemInfo(itemLink2)

-- 	-- now store it
-- 	local entry = {}
-- 	entry['itemName'] = itemName
-- 	entry['itemTexture'] = itemTexture
-- 	entry['date'] = date("%m-%d-%y")
-- 	entry['itemLink'] = itemLink
-- 	entry['lootedBy'] = lootedBy
-- 	entry['entry'] = {
-- 		['want'] = want,
-- 		['wantString'] = "|cff"..wantColor..want.."|r",
-- 		['itemLink1'] = itemLink1,
-- 		['itemTexture1'] = itemTexture1,
-- 		['itemLink2'] = itemLink2,
-- 		['itemTexture2'] = itemTexture2,
-- 		['notes'] = notes,
-- 	}

-- 	local num = getn(ILC_HISTORY[playerName][today])

-- 	ILC_HISTORY[playerName][today][num + 1] = entry
-- end

-- return loot history by player
-- function ilc:getLootHistory(playerName)
-- 	local today = date("%m-%d-%Y")
-- 	local month, day, year = strsplit("-", today)
-- 	local today = strtotime(month, day, year)

-- 	local last_month = days_ago(today, 45)

-- 	local history = {}
-- 	local remove = {}

-- 	if (not ILC_HISTORY[playerName]) then return {} end

-- 	for loot_date, entries in ilc:spairs(ILC_HISTORY[playerName], function(a, b)
-- 		return tonumber(a) > tonumber(b)
-- 	end) do
-- 		loot_date = tonumber(loot_date)
-- 		-- was in the last 30 days
-- 		if (loot_date > last_month) then
-- 			-- return any multiple entries from one day
-- 			for i = 1, #entries do
-- 				table.insert(history, entries[i])
-- 			end
-- 		else
-- 			-- remove this
-- 			table.insert(remove, loot_date)
-- 		end
-- 	end

-- 	-- now loop through remove and remove these items
-- 	-- print(#remove)
-- 	-- for loot_date, entries in pairs(remove) do
-- 	-- 	ILC_HISTORY[playerName][loot_date] = nil
-- 	-- end

-- 	-- done
-- 	return history
-- end

--==========================================
-- Receive messages
--==========================================
local lc_only = {

}
local ml_only = {

}

function ilc:messageCallback(prefix, message, channel, sender)
	local method, partyMaster, raidMaster = GetLootMethod()
	local pre_params = {strsplit(ilc.deliminator, message)}
	local params = {}
	local action = false

	for k, v in pairs(pre_params) do
		if (v and v ~= "") then
			if (not action) then
				action = v
			else
				if (tonumber(v)) then
					tinsert(params, tonumber(v))
				else
					tinsert(params, v)
				end
			end
		end
	end

	-- -- auto methods have to force a self param
	if (ilc[action] or not params) then
		if (params and unpack(params)) then -- if params arne't blank
			ilc[action](self, unpack(params))
		else
			ilc[action](self)
		end
	else
		ilc:debug(action, "not found from", sender, channel);
	end
end


----------------------------------------
-- Voting for users
-- supports multiple votes per officer
----------------------------------------
function ilc:updateVotesRemaining(itemUID, councilName)
	councilName = ilc:FetchUnitName(councilName) --councilName:utf8lower()

	if (not ilc.loot_sessions[itemUID]) then return false end
	if (ilc.localPlayer ~= councilName) then return end

	local itemLink = ilc.itemMap[itemUID]
	local numvotes = tonumber(ilc.council_votes) --1--ilc.item_drops[itemLink]
	local currentvotes = 0;
	local color = "|cff00FF00"
	local tab = ilc:getTab(itemUID)

	if (ilc.loot_council_votes[itemUID][councilName]) then
		for v = 1, numvotes do
			if (ilc.loot_council_votes[itemUID][councilName][v]) then
				currentvotes = currentvotes + 1
			end
		end
		
		if (numvotes - currentvotes == 0) then
			color = "|cffFF0000"
		end
	end

	tab.table.numvotes:SetText("Your Votes Remaining: "..color..(numvotes - currentvotes).."|r")

	tab = ilc:getTab(itemUID)
	for entry, k in tab.entries:EnumerateActive() do
		if (numvotes - currentvotes == 0) then
			if (entry.voteUser:GetText() == l['frameVote']) then
				ilc:skinButton(entry.voteUser, true, 'dark')
			else
				ilc:skinButton(entry.voteUser, true, 'blue')
			end
		else
			ilc:skinButton(entry.voteUser, true, 'blue')
		end
	end
end

function ilc:voteForUser(councillorName, itemUID, playerEntryName, lcl)
	if (not ilc.loot_sessions[itemUID]) then ilc:debug("Votes failed, no session for itemuid") return false end
	if (not ilc.loot_council_votes[itemUID]) then ilc:debug("Vote failed, no votes for itemuid") return false end
	if not ilc:inLC() then return false end

	councillorName = ilc:FetchUnitName(councillorName)
	playerEntryName = ilc:FetchUnitName(playerEntryName)
	
	-- allow local voting
	if (not lcl and ilc.localPlayer == councillorName) then ilc:debug("Votes failed, not in lc") return end

	local itemLink = ilc.itemMap[itemUID]
	local numvotes = tonumber(ilc.council_votes) --1 --#ilc.item_drops[itemLink]
	local votes = ilc.loot_council_votes[itemUID]

	-- if they haven't voted yet, then give them # votes
	if (not votes[councillorName]) then
		votes[councillorName] = {}
		for v = 1, numvotes do
			votes[councillorName][v] = false
		end
	end

	-- only let them vote for each player once
	local hasVotedForPlayer = false
	for v = 1, numvotes do
		if (votes[councillorName][v] == playerEntryName) then hasVotedForPlayer = v break end
	end

	if (hasVotedForPlayer) then
		votes[councillorName][hasVotedForPlayer] = false
		if (ilc.localPlayer == councillorName) then
			local entry = ilc:getEntry(itemUID, playerEntryName)
			entry.voteUser:SetText(l["frameVote"])
		end
	else
		-- disable rolling votes? limit at # here
		local currentvotes = 0;
		for v = 1, numvotes do
			if (votes[councillorName][v]) then
				currentvotes = currentvotes + 1
			end
		end

		if (currentvotes < numvotes) then
			-- reset the table
			local new = {}
			new[1] = false -- reserve pos 1
			for v = 1, numvotes do
				if (votes[councillorName][v]) then -- correct any table key gaps
					new[#new+1] = votes[councillorName][v]
				end
			end
			votes[councillorName] = new -- reset the tables keys

			-- remove the least recent vote
			if (ilc.localPlayer == councillorName) then
				-- local entry = ilc:getEntry(itemUID, votes[councillorName][numvotes+1])
				local entry = ilc:getEntry(itemUID, playerEntryName)
				entry.voteUser:SetText(l["frameVote"])
			end
			votes[councillorName][numvotes+1] = nil 

			votes[councillorName][1] = playerEntryName -- prepend the vote
			if (ilc.localPlayer == councillorName) then
				local entry = ilc:getEntry(itemUID, playerEntryName)
				entry.voteUser:SetText(l["frameVoted"])
			end
		end

	end
	ilc:updateVotesRemaining(itemUID, councillorName)

	-- now loop through and tally
	for itemUID, info in pairs(ilc.loot_sessions) do
		local tab = ilc:getTab(itemUID)
		for entry, k in tab.entries:EnumerateActive() do
			if (entry.itemUID) then
				local votes = 0
				for council, v in pairs(ilc.loot_council_votes[itemUID]) do
					for v = 1, numvotes do
						if ilc.loot_council_votes[itemUID][council][v] == entry.playerName then
							votes = votes + 1
						end
					end
				end
				entry.votes.text:SetText(votes)
			end

		end
	end
end

--==========================================
-- Async Item Info
-- update - blizzard broke GET_ITEM_INFO_RECEIVED so using this for now
--==========================================
ilc.async = CreateFrame("frame", nil, UIParent)
ilc.async:RegisterEvent("GET_ITEM_INFO_RECEIVED")
ilc.async:SetScript("OnEvent", function(self, event, itemID, success)
	-- couldn't tell if this item could be traded yet
	if (ilc.items_waiting_for_verify[itemID]) then
		local itemLink = ilc.items_waiting_for_verify[itemID]

		ilc:StartSessionFromTradable(itemLink)

		ilc.items_waiting_for_verify[itemID] = nil
	end

	-- startable in session, but didn't know what it was yet
	if (ilc.items_waiting_for_session[itemID]) then
		local itemLink, lootedBy, forced, rollID = unpack(ilc.items_waiting_for_session[itemID])

		ilc:startSession(itemLink, lootedBy, forced, rollID)

		ilc.items_waiting_for_session[itemID] = nil
	end

	-- updating users current gear
	if (ilc.player_items_waiting[itemID]) then
		local itemLink, gear = unpack(ilc.player_items_waiting[itemID])

		ilc:updateUserItem(itemLink, gear)

		ilc.player_items_waiting[itemID] = nil
	end
end)


