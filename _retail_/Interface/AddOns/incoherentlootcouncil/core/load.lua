local ilc, c, l = unpack(select(2, ...))
local loader = CreateFrame("frame", nil, ilc)
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
	if (addon ~= ilc.addonName) then return end
	loader:UnregisterEvent("ADDON_LOADED")

	ilc.version = GetAddOnMetadata(ilc.addonName, "Version") 

	-- Register Messages
	ilc.comm:RegisterComm(ilc.messagePrefix, function(...)
		ilc:messageCallback(...)
	end)

	-- config initialize
	ILC_CONFIG = ilc.configDefaults
	-- ILC_CONFIG = ILC_CONFIG or ilc.configDefaults
	-- ILC_HISTORY = ILC_HISTORY or {}
	ilc.config = ILC_CONFIG
	
	-- do a one time reset
	-- if (not ilc.config["shadowlands2"]) then
	-- 	ILC_CONFIG = ilc.configDefaults
	-- 	ilc.config = ILC_CONFIG
	-- 	ilc.config["shadowlands2"] = true
	-- end

	-- C_Timer.After(0.2, function()
		-- ilc:startMockSession()
	-- end)

	local version = tonumber(ilc.version) and ilc.version or "Developer"
	ilc:print("Loaded, enjoy! Version: "..version)

	-- default local stores
	ilc.council_votes = ilc.config.council_votes
	ilc.buttons = ilc.configDefaults.buttons
	ilc.master_looter_qn = ilc.config.quick_notes


	-- ilc:startMockSession()
end)