local ilc, c, l = unpack(select(2, ...))

--------------------------------------------------
-- VERSION TEST THE RAID
-- Also alerts which players don't have it installed
--------------------------------------------------
function ilc:checkRaidVersions()
	ilc.versions = {}

	ilc:print("Your Version:", tonumber(ilc.version) and ilc.version or "Developer")
	if (not IsInRaid() ) then
		ilc:print("You can only do a version check while in raid.")
		return
	end

	-- store a list of users who may not have ilc
	local noAddon = {}
	for i = 1, GetNumGroupMembers() do
		local name = ilc:FetchUnitName(select(1, GetRaidRosterInfo(i)))
		noAddon[name] = true
	end

	-- request raid versions
	ilc:print("Building version list, waiting 5 seconds for responses.");
	ilc:sendAction("requestVersions", ilc.localPlayer);

	-- wait, since we can't really know when all of them are returned
	C_Timer.After(5, function()

		for version, players in pairs(ilc.versions) do
			local version = tonumber(version) or "Developer"
			local printString = version..": " 

			-- these players have returned their versions
			for name, v in pairs (players) do
				-- remove from no addon list
				noAddon[ilc:FetchUnitName(name)] = nil
				printString = printString..ilc:prettyName(name)..", "
			end

			-- remove trailing comma
			print(string.utf8sub(printString, 0, -2))
		end
		
		-- these are leftover from the returns
		-- if (#noAddon > 0) then
			local printString = "ILC not installed: "
			for name, v in pairs(noAddon) do
				printString = printString..ilc:prettyName(name)..", "
			end

			-- no trailing comma
			print(string.utf8sub(printString, 0, -2))
		-- end
	end)
end

function ilc:requestVersions(sendBackTo)
	ilc.overrideChannel = "WHISPER"
	ilc.overrideRecipient = sendBackTo
	ilc:sendAction("returnVersion", ilc.version, ilc.localPlayer);
end

function ilc:returnVersion(version, player)
	if (not tonumber(version)) then version = "Developer" end

	ilc.versions[version] = ilc.versions[version] or {}
	ilc.versions[version][ilc:FetchUnitName(player)] = true
end

-- @@ exit
--- not doing update checks anymore


-- store various versions in here
-- ilc.versions = CreateFrame("frame", nil, UIParent)
-- ilc.versions:RegisterEvent("PLAYER_LOGIN")
-- ilc.versions:SetScript("OnEvent", function(self)
-- 	-- let's not alert for now
-- 	-- ilc:checkForUpdates()
-- end)
--------------------------------------------------
-- ASK FOR GUILD VERSIONS
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
-- function ilc:guildTopVersion(versionToBeat, sendBackTo)
-- 	-- don't count developer
-- 	if (ilc.version == "@project-version@") then return end

-- 	-- We have a more recent version than them
-- 	if (ilc.version > versionToBeat) then
-- 		ilc.overrideChannel = "WHISPER"
-- 		ilc.overrideRecipient = sendBackTo
-- 		ilc:sendAction("newerVersion", ilc.version);
-- 	end

-- 	-- Wait a second, they are more up to date than us
-- 	if (versionToBeat > ilc.version) then
-- 		ilc:alertOutOfDate()
-- 	end
-- end

-- function ilc:newerVersion(version)
-- 	ilc.newestVersion = math.max(ilc.newestVersion, version)
-- end

-- --------------------------------------------------
-- -- GET UPDATE ALERT
-- -- When a user logs in, check if they should update by using the guild
-- --------------------------------------------------
-- function ilc:checkForUpdates()
-- 	-- Only ask if you're not a developer
-- 	if (ilc.version == "@project-version@") then return end
	
-- 	ilc.newestVersion = 0

-- 	-- ask the guild
-- 	ilc.overrideChannel = "GUILD"
-- 	ilc:sendAction("guildTopVersion", ilc.version, ilc.localPlayer);

-- 	-- wait x seconds for all responses to come back
-- 	C_Timer.After(5, function()
-- 		if (ilc.newestVersion > ilc.version) then
-- 			ilc:alertOutOfDate()
-- 		else
-- 			ilc.print("You're up to date. Version: "..ilc.version)
-- 		end
-- 	end)
-- end

-- function ilc:alertRecent(newestVersion)
-- 	local myVersion = ilc.version
-- 	ilc.newestVersion = newestVersion

-- 	if (tonumber(myVersion) and myVersion < newestVersion) then
-- 		ilc:alertOutOfDate()
-- 	end
-- end

-- function ilc:alertOutOfDate()
-- 	if (not ilc.alertedOutOfDate) then
-- 		ilc.print("You're out of date! Please update as soon as possible, old versions will break and send lua errors to other players.")
-- 		ilc.print("Your version: "..ilc.version)
-- 		ilc.print("Most recent version: "..ilc.newestVersion)
-- 		ilc.alertedOutOfDate = true
-- 	end
-- end