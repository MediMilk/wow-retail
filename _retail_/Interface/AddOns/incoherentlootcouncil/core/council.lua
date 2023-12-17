local ilc, c, l = unpack(select(2, ...))
ilc.loot_council = {}

-- ===================================
-- Rewrite
-- ===================================
-- have the leader create the loot council from their point of view
local function create_lc()

end


-- just reset it
local function reset_lc()
	ilc.loot_council = {}
end


-- distribute your lc to the raid
function ilc:request_lc()
	if (not ilc:IsRaidLeader()) then return end
end


-- distribute your lc to the raid
local function distribute_lc()
	reset_lc()

	-- send this if you're the raid leader
	if (not ilc:IsRaidLeader()) then return end


end


-- take results and populate your own LC array
function populate_lc(...)

end


-- add one person to lc
function add_to_lc(name)
	if (not name) then ilc:print("Please provide a name to add to the loot council") return false end
	name = ilc:FetchUnitName(name)

	ilc.config.custom_council[name] = true
	ilc:print("Adding "..name.." to your loot council.")
end


-- remove one person from lc
function remove_from_lc(name)
	if (not name) then ilc:print("Please provide a name to add to the loot council") return false end
	name = ilc:FetchUnitName(name)

	ilc.config.custom_council[name] = nil
	ilc:print("Removing "..name.." from your loot council.")
end



-- if i'm in lc, raid leader, or not in a group
function ilc:inLC()
	return ilc.loot_council[ilc.localPlayer] or ilc:IsRaidLeader()
end

function ilc:customButtons(buttons)
	ilc.buttons = {}

	local btns = {strsplit("//", buttons)}
	for k, v in pairs(btns) do
		local index, name, r, g, b, enabled, require_note = strsplit(",", v)
		index, r, g, b = tonumber(index), tonumber(r), tonumber(g), tonumber(b)
		enabled = tonumber(enabled) == 1 and true or false
		require_note = tonumber(require_note) == 1 and true or false

		if (index) then
			ilc.buttons[index] = {name, {r, g, b}, enabled, require_note}
		end
	end

	-- display to debug
	local buttons = ""
	for k, v in pairs(ilc.buttons) do
		local hex = ilc:RGBPercToHex(unpack(v[2]))
		local name, enabled, require_note = v[1], v[3], v[4]
		if (enabled) then
			enabled = enabled and "Enabled" or "Disabled"
			require_note = require_note and "Requires Note" or "No Required Note"
			buttons = buttons.."|cff"..hex..v[1].."|r : "..enabled.." : "..require_note.."\n"
		end
	end

	ilc:debug("Current Buttons:\n", buttons)
end

function ilc:councilVotes(votes)
	ilc:debug("Current Council Votes: ", votes)
	ilc.council_votes = tonumber(votes)
end

function ilc:customQN(...)
	ilc.master_looter_qn = {}

	local notes = {...}
	for k, v in pairs(notes) do
		ilc.master_looter_qn[v] = true
	end

	ilc:debug("Current Quicknotes: ", unpack(notes))
end

----------------------------------------
-- BULK ADD TO LC
-- Takes a table of players and adds all at once
----------------------------------------
function ilc:addToLC(...)
	reset_lc()
	
	local council = {...}

	for k, v in pairs(council) do
		local name = ilc:FetchUnitName(v)

		ilc.loot_council[name] = true
	end

	ilc:debug("Current Council: ", unpack(ilc.loot_council))
end

-----------------------------------------------
-- ADD SINGLE PLAYER TO LC
-- this will add/remove the player from your custom council. 
-- If you're group leader it'll then rebuild the council list and redistribute it to the raid
-----------------------------------------------
function ilc:addremoveLC(msg, name)
	if (not name) then ilc:print("Please provide a name to add to the loot council") return false end
	
	name = ilc:FetchUnitName(name)
	
	if (msg == "addtolc") then -- add
		ilc.config.custom_council[name] = true
		ilc:print("Adding "..name.." to loot council.")
	else -- remove
		ilc.config.custom_council[name] = nil
		ilc:print("Removing "..name.." from your loot council.")
	end

	-- rebuild and redistribute your list if you're LM or leader
	ilc:sendLC()

	return true
end


-------------------------------------------
-- Returns min rank or default for LC
-------------------------------------------
function ilc:GetLCMinRank()
	local min_rank = ilc.config.council_min_rank
	min_rank = tonumber(min_rank)

	ilc:debug("Minimum LC Rank: ", min_rank)

	if (not min_rank) then
		ilc.config.council_min_rank = ilc.configDefaults.council_min_rank
		min_rank = ilc.configDefaults.council_min_rank
		ilc:print("Major error: min_rank didn't return a value! Using default value of ", min_rank)
	end

	return min_rank
end

function ilc:GetRaidMembers()
	local inraid = {}
	inraid[ilc:FetchUnitName('player')] = true

	local numRaid = 40
	for i = 1, numRaid do
		local name = ilc:FetchUnitName("raid"..i) or ilc:FetchUnitName("party"..i)
		if (name) then
			inraid[name] = true
		end
	end

	return inraid
end

----------------------------------------
-- BuildLC
-- Wipes default loot council, quick notes, and enchanters. Then rebuilds in bulk
----------------------------------------
function ilc:requestLC()
	if (ilc:IsRaidLeader()) then
		ilc:sendLC()
	end
end

function ilc:sendLC()
	if (not ilc:IsRaidLeader()) then return end

	ilc:debug("Building LC")

	-- get the saved or default min_rank
	local min_rank = ilc:GetLCMinRank()

	-------------------------------------------------------
	-- COUNCIL
	-------------------------------------------------------
	local council = {}
	local raid = ilc:GetRaidMembers()
	council[ilc:FetchUnitName('player')] = true

	-- add players automatically via guild rank
	local numGuildMembers = select(1, GetNumGuildMembers())
	for i = 1, numGuildMembers do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
		name = ilc:FetchUnitName(name)

		if (rankIndex <= min_rank and raid[name]) then
			council[name] = true
		end
	end

	-- add from the raid
	local myGuild = select(1, GetGuildInfo("player"))
	local numRaid = GetNumGroupMembers() or 1
	for i = 1, numRaid do
		local unit = select(1, GetRaidRosterInfo(i))
		if (unit) then
			local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit);
			local name = ilc:FetchUnitName(unit)

			if (guildName == myGuild and guildRankIndex <= min_rank and raid[name]) then
				council[name] = true
			end
		end
	end

	-------------------------------------------------------
	-- CUSTOM COUNCIL
	-- People who are in your custom loot council and in raid
	-------------------------------------------------------
	for k, v in pairs (ilc.config.custom_council) do
		local name = ilc:FetchUnitName(k)
		if (UnitExists(k)) then
			council[name] = true
		end
	end
	
	-------------------------------------------------------
	-- QUICK NOTES
	-------------------------------------------------------
	local quicknotes = {}
	for k, v in pairs(ilc.config.quick_notes) do
		quicknotes[k] = true
	end

	-------------------------------------------------------
	-- CUSTOM BUTTONS
	-------------------------------------------------------
	-- local buttons_string = ""
	-- for i = 1, #ilc.config.buttons do
	-- 	v = ilc.config.buttons[i]

	-- 	local name, color, enable, req = unpack(v)
	-- 	local r, g, b = unpack(color)
	-- 	local k = tostring(i)
	-- 	enable = enable and "1" or "0"
	-- 	req = req and "1" or "0"
	-- 	local info = {k, name, tostring(r), tostring(g), tostring(b), enable, req}
	-- 	buttons_string = buttons_string..table.concat(info, ",").."//"
	-- end

	-- loot council
	local friendlyCouncil = {}
	for name, v in pairs(council) do
		table.insert(friendlyCouncil, name)
	end

	ilc:sendAction("addToLC", unpack(friendlyCouncil) )

	-- custom quicknotes
	local friendlyQN = {}
	for note, v in pairs(quicknotes) do
		table.insert(friendlyQN, note)
	end
	ilc:sendAction("customQN", unpack(friendlyQN) );

	-- number of council votes
	-- ilc.overridePriority = "ALERT" -- not gonna mess with this right now
	ilc:sendAction("councilVotes", ilc.config.council_votes);

	-- buttons
	-- ilc:sendAction("customButtons", buttons_string);
end


local council_events = CreateFrame("frame")
council_events:RegisterEvent("PLAYER_LOGIN")
council_events:RegisterEvent("BOSS_KILL")
council_events:RegisterEvent("GUILD_ROSTER_UPDATE")
council_events:RegisterEvent("RAID_ROSTER_UPDATE")
council_events:RegisterEvent("CHAT_MSG_SYSTEM")
ilc.am_leader = ilc:IsRaidLeader()
council_events:SetScript("OnEvent", function(self, event, arg1)
	C_GuildInfo.GuildRoster() -- keep this up to date

	-- if i've left a loading screen, they want the LC
	if (event == "PLAYER_LOGIN") then
		C_Timer.After(1, function()
			ilc:sendAction("requestLC");
		end)
		
		return
	end

	-- when group lead changes
	if (event == "CHAT_MSG_SYSTEM") then
		C_Timer.After(.1, function()
			-- raid leader toggle check
			if (not ilc.am_leader and ilc:IsRaidLeader()) then
				ilc:sendLC()
			end
			
			ilc.am_leader = ilc:IsRaidLeader()
		end)

		return
	end
	
	-- when a boss dies it's time for more sessions
	if (event == "BOSS_KILL" or event == "GUILD_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
		council_events:UnregisterEvent("GUILD_ROSTER_UPDATE")
		ilc:sendLC()
		
		return
	end
end)