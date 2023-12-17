local ilc, c, l = unpack(select(2, ...))

ilc.demo_samples = {
	classes = {"HUNTER","WARLOCK","PRIEST","PALADIN","MAGE","ROGUE","DRUID","WARRIOR","DEATHKNIGHT","MONK","DEMONHUNTER","EVOKER"},
	ranks = {"Raid Leader", "Treasure-her", "Council", "Council Alt", "Core Raider", "Bench Raider", "Trial Raider", "Alt Toon", "Friend/Mythic+", "Initiate"},
	names = {"Medimilk", "Sÿs", "Natrone", "Devastor", "Swôle", "Quitollis", "Pogrunnerup", "Badoomp", "Monvis", "Luhgon", "Keranna", "Perlyta", "Mowk", "Mittàns", "Rajamatic"}
}

local function rando_name()
	return ilc:FetchUnitName(ilc.demo_samples.names[math.random(#ilc.demo_samples.names)])
end
local function rando_ilvl()
	local ilvl = GetAverageItemLevel()

	return math.random(ilvl * 0.7, ilvl * 1.3)
end
local function rando_rank()
	return ilc.demo_samples.ranks[math.random(#ilc.demo_samples.ranks)]
end
local function rando_class()
	return ilc.demo_samples.classes[math.random(#ilc.demo_samples.classes)]
end

function ilc:startMockSession()
	if (IsInGroup() and not ilc:inLC()) then
		ilc:print("You cannot run a test while inside of a raid group unless you are on the Loot Council.")
		return
	end

	ilc:print("Starting mock session")
	
	-- add random people, up to a whole raid worth of fakers
	local demo_players = {}
	for i = 1, math.random(2, 6) do
		demo_players[rando_name()] = {rando_class()}
	end
	
	-- fake build an LC
	local itemslots = {1, 2, 3, 5, 8, 9, 10, 11, 12, 13, 14, 15}
	ilc.item_drops = {}
	for i = 1, 4 do
		local index = itemslots[math.random(#itemslots)]
		ilc.item_drops[GetInventoryItemLink("player", index)] = rando_name()
		table.remove(itemslots,index)
	end

	-- now lets start fake sessions
	for k, v in pairs(ilc.item_drops) do
		local itemUID = ilc:GetItemUID(k, ilc.localPlayer, -1)
		ilc:sendAction("startSession", k, ilc.localPlayer);

		-- add our demo players in 
		for name, data in pairs(demo_players) do
			ilc:sendAction("addUserConsidering", itemUID, name);
		end

		-- send a random "want" after 2-5s, something like a real person
		C_Timer.After(math.random(2, 5), function()
			for name, data in pairs(demo_players) do
				ilc:sendAction("addUserWant", itemUID, name, math.random(1, 5), 0, 0, math.random(1, 100), rando_ilvl(), rando_rank(), "");
			end
		end)
	end
end
