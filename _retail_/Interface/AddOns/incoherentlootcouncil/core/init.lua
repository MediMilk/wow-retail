local addonName, engine = ...
engine[1] = CreateFrame("Frame", nil, UIParent) -- core
engine[2] = CreateFrame("Frame", nil, UIParent) -- config
engine[3] = {} -- locales

ilc = engine[1]
ilc.addonName = addonName
ilc.messagePrefix = "ILC";
ilc.deliminator = "><";
ilc.colorString = "|cffA02C2FIncoherent|r Loot Council "
ilc.localPlayer = Ambiguate(UnitName("player").."-"..GetRealmName(), "mail"):utf8lower()
ilc.comm = LibStub:GetLibrary("AceComm-3.0")
ilc.config = {}
ilc.enabledebug = false
ilc.enableTests = false

-- tooltip scanner
ilc.tt = CreateFrame('GameTooltip', 'ILC:TooltipScan', UIParent, 'GameTooltipTemplate')
ilc.tt:SetOwner(UIParent, 'ANCHOR_NONE')

-- basic media options
ilc.media = {
	flat = "Interface\\Buttons\\WHITE8x8",
	smooth = "Interface\\Addons\\incoherentlootcouncil\\media\\smooth.tga",
	font = "Interface\\Addons\\incoherentlootcouncil\\media\\font.ttf",
	arrow = "Interface\\Addons\\incoherentlootcouncil\\media\\arrow.blp",
	border = {.03, .04, .05, 1},
	backdrop = {.08, .09, .11, 0.9},
	hover = {.28, .29, .31, 0.9},
	red = {.62, .17, .18, 1},
	blue = {.2, .4, 0.8, 1},
	green = {.1, .7, 0.3, 1},
}

-- main font object
ilc.font = CreateFont("ilc_font")
ilc.font:SetFont(ilc.media.font, 14, "THINOUTLINE")
ilc.font:SetShadowColor(0, 0, 0)
ilc.font:SetShadowOffset(1, -1)

-- defaults
ilc.configDefaults = {
	council_min_rank = 2,
	debug = false,
	custom_council = {},
	council_votes = 1,
	quick_notes = {
		["BiS"] = true, 
		["20%"] = true,
		["10%"] = true,
	},
	-- text, color, enable, require note
	buttons = {
		[1] = {"Mainspec", {.2, 1, .2}, true, true},
		[2] = {"Minor Up", {.6, 1, .6}, true, false},
		[3] = {"Offspec", {.8, .6, .6}, true, false},
		[4] = {"Reroll", {.1, .6, .6}, true, false},
		[5] = {"Transmog", {.8, .4, 1}, true, false},
	}
}

-- info holders
ilc.loot_council = {}
ilc.loot_council_votes = {}
ilc.loot_council_index_history = {}
ilc.items_waiting_for_verify = {}
ilc.items_waiting_for_session = {}
ilc.player_items_waiting = {}
ilc.tradedItems = {}
ilc.itemMap = {}
ilc.loot_sessions = {}
ilc.loot_want = {}
ilc.item_drops = {}

-- Commands
SLASH_ilc1 = "/ilc"
SlashCmdList["ilc"] = function(original_msg, editbox)
	local msg, msg2, msg3 = strsplit(" ", strtrim(original_msg), 2)

	-- list of commands
	if (msg == "" or msg == " ") then
		print("|cffA02C2FILC|r commands:")
		print("  /|cffA02C2Filc|r |cffEEFFAAtest|r - Tests the addon outside of raid")
		print("  /|cffA02C2Filc|r |cffEEFFAAconfig|r - Shows the configuration window")
		print("  /|cffA02C2Filc|r |cffEEFFAAshow|r - Shows the vote window (if you're in the LC)")
		print("  /|cffA02C2Filc|r |cffEEFFAAhide|r - Hides the vote window (if you're in the LC)")
		print("  /|cffA02C2Filc|r |cffEEFFAAversion|r - Check the ilc versions that the raid is using")
		print("  /|cffA02C2Filc|r |cffEEFFAAaddtolc|r |cffAAEEFFplayername|r - Adds a player to the loot council (if you're the Masterlooter)")
		print("  /|cffA02C2Filc|r |cffEEFFAAremovefromlc|r |cffAAEEFFplayername|r - Adds a player to the loot council (if you're the Masterlooter)")
		print("  /|cffA02C2Filc|r |cffEEFFAAreset|r - Resets configuration to defaults")
		print("  /|cffA02C2Filc|r |cffEEFFAArequestlc|r - Requests LC information to be resent, use if LC is innacurate")
		print("  /|cffA02C2Filc|r |cffEEFFAAdebug|r - Toggles debug mode")
		print("  /|cffA02C2Filc|r |cffEEFFAAvalid|r |cffAAEEFF[itemlink]|r - Checks item information and if its valid for an automatic session.")

		return
	end

	-- debug
	if (msg == "debug") then
		ilc.config.debug = not ilc.config.debug
		ilc:print("Debug mode:", ilc.config.debug and "On" or "Off")

		return
	end

	-- test
	if (msg == "test") then
		ilc:startMockSession()

		return
	end

	-- show
	if (msg == "show") then
		if (ilc:inLC()) then
			ilc.window:Show()
		else
			ilc:print("Can't show window - you are not in the loot council.")
		end

		return
	end

	-- start
	if (msg == "start") then
		if (not msg2) then
			ilc:print("3rd parameter needs to be an itemLink")
			return
		end
		ilc:sendAction("startSession", msg2, ilc.localPlayer);
		
		return
	end

	-- start
	if (msg == "requestlc") then
		ilc:requestLC()

		ilc:print("Requested LC")

		return
	end

	-- start
	if (msg == "valid") then
		if (not msg2) then
			ilc:print("3rd parameter needs to be an itemLink")
		end
		if (ilc:itemValidForSession(msg2, ilc.localPlayer, true, -1)) then
			ilc:print(msg2, "valid for session.")
		else
			ilc:print(msg2, "not valid for session.")
		end
		
		return
	end

	-- hide
	if (msg == "hide") then
		ilc.window:Hide()
		
		return
	end

	-- version
	if (msg == "version") then
		ilc:checkRaidVersions()

		return
	end

	-- edit lc
	if (msg == "addtolc" or msg == "removefromlc") then
		ilc:addremoveLC(msg, msg2)

		return
	end

	-- config
	if (msg == "config") then
		ilc.config_window:SetShown(not ilc.config_window:IsShown())
		
		return
	end

	-- reset
	if (msg == "reset") then
		ILC_CONFIG = ilc.configDefaults
		ilc.config = ILC_CONFIG

		ReloadUI();

		return
	end

	ilc:print("Command "..original_msg.. "not recognized.")
end

-- ilc.looters = {}

-- ilc.tradedItems = {}

-- ilc.item_drops = {}
-- ilc.enchanters = {}
-- ilc.award_slot = nil

-- ilc.loot_slots = {}
-- ilc.loot_sessions = {}

-- ilc.loot_want = {}

-- ilc.loot_council = {}
-- ilc.loot_council_votes = {}
-- ilc.loot_council_votes.indexhistory = {}

-- ilc.items_waiting_for_verify = {}
-- ilc.items_waiting_for_session = {}
-- ilc.player_items_waiting = {}
-- ilc.master_looter_qn = {}

-- ilc.itemMap = {}

-- -- Config
-- ilc.config = {
-- 	flat = "Interface\\Buttons\\WHITE8x8"
-- 	, height = 400
-- 	, width = 600
-- 	-- , debug = true
-- 	-- , version = "@project-version@"
-- 	, version = "2.50"
-- }
-- ilc.defaults = {
-- 	council_min_rank = 2,
-- 	custom_council = {},
-- 	custom_qn = {
-- 		["BiS"] = true,
-- 		["2p"] = true,
-- 		["4p"] = true,
-- 	}
-- }