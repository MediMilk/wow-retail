local ilc, c, l = unpack(select(2, ...))

local config = CreateFrame('frame', 'ILC Config', UIParent, BackdropTemplateMixin and "BackdropTemplate")
config:SetFrameStrata("HIGH")
config:SetFrameLevel(9)
config:SetSize(500, 430)
config:SetPoint("CENTER")
config:EnableMouse(true)
config:SetMovable(true)
config:SetUserPlaced(true)
config:SetClampedToScreen(true)
config:RegisterForDrag("LeftButton","RightButton")
config:SetScript("OnDragStart", function(self) config:StartMoving() end)
config:SetScript("OnDragStop", function(self)  config:StopMovingOrSizing() end)
config:Hide()
ilc:setBackdrop(config)

-- Config Title
config.title = config:CreateFontString(nil, "OVERLAY")
config.title:SetFontObject(ilc:get_font(16, "OUTLINE"))
config.title:SetText("|cffA02C2FIncoherent|r Loot Council Config")
config.title:SetTextColor(1,1,1)
config.title:SetPoint("TOP", config, "TOP", 0,-6)

-- Close Button
config.close = CreateFrame("Button", nil, config, BackdropTemplateMixin and "BackdropTemplate")
config.close:SetPoint("TOPRIGHT", config, "TOPRIGHT", -4, -4)
config.close:SetText("x")
ilc:skinButton(config.close, true, "red")
config.close:SetBackdropColor(.5,.1,.1,.5)
config.close:SetScript("OnClick", function()
	config:Hide()
	ilc.config_toggle = false
end)

ilc.config_window = config

--==========================================
-- Council minimum rank
--==========================================
local guild_ranks = {}
local function store_ranks()
	guild_ranks = {}

	local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	for i =1, numGuildMembers do
		local name, rank, rankIndex, _, class = GetGuildRosterInfo(i)
		guild_ranks[rankIndex] = rank
	end
end

config:RegisterEvent("GUILD_ROSTER_UPDATE")
config:SetScript("OnEvent", function(self, event)
	store_ranks()
end)
C_GuildInfo.GuildRoster()

config:SetScript("OnShow", function(self)
	if (self.init) then return end
	self.init = true
	store_ranks()

	-- ======================
	-- min rank
	-- ======================
	local default = ilc.config and ilc.config.council_min_rank or ilc.configDefaults.council_min_rank
	local options = {
		['name'] = 'lc_rank',
		['parent'] = self,
		['title'] = 'Minimum LC Guild Rank',
		['items'] = guild_ranks,
		['width'] = 200,
		['default'] = guild_ranks[default],
		['callback'] = function(dropdown, value, id)
			ilc.config.council_min_rank = id
			ilc:sendLC()
		end
	}

	local minrank = ilc:createDropdown(options)
	minrank:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -50)

	--======================
	-- allowed votes
	--======================
	local options = {
		['name'] = 'votes',
		['parent'] = self,
		['title'] = 'Loot Council Number of Votes',
		['width'] = 140,
		['default'] = ilc.config.council_votes,
		['callback'] = function(value, key)
			ilc.config.council_votes = tonumber(value)
			ilc.council_votes = ilc.config.council_votes
			ilc:sendLC()
		end
	}

	local votes = ilc:createEdit(options)
	votes:SetNumeric(true)
	votes:SetPoint("LEFT", minrank, "RIGHT", 10)

	--======================
	-- custom council
	--======================
	local options = {
		['name'] = 'custom_council',
		['parent'] = self,
		['title'] = 'Custom Council',
		['items'] = ilc.config.custom_council,
		['width'] = 400,
		['lower'] = true,
		['callback'] = function(container, value)
			value = ilc:FetchUnitName(value)

			if(ilc.config.custom_council[value]) then
				container.insert.alert:SetText(value.." removed")
				container.insert.alert:SetTextColor(1, .3, .3)
				container:startfade()

				ilc.config.custom_council[value] = nil
			else
				container.insert.alert:SetText(value.." added")
				container.insert.alert:SetTextColor(.3, 1, .3)
				container:startfade()

				ilc.config.custom_council[value] = true
			end

			container:populate(ilc.config.custom_council)
			ilc:sendLC()
		end
	}

	local custom_council = ilc:createList(options)
	custom_council:SetPoint("TOPLEFT", minrank, "BOTTOMLEFT", 20, -50)

	--======================
	-- quick notes
	--======================
	local options = {
		['name'] = 'quick_notes',
		['parent'] = self,
		['title'] = 'Quick Notes',
		['items'] = ilc.config.quick_notes,
		['width'] = 400,
		['callback'] = function(container, value)
			if(ilc.config.quick_notes[value]) then
				container.insert.alert:SetText(value.." removed")
				container.insert.alert:SetTextColor(1, .3, .3)
				container:startfade()
				
				ilc.config.quick_notes[value] = nil
			else
				container.insert.alert:SetText(value.." added")
				container.insert.alert:SetTextColor(.3, 1, .3)
				container:startfade()

				ilc.config.quick_notes[value] = true
			end

			container:populate(ilc.config.quick_notes)
			ilc:sendLC()
		end
	}

	local quick_notes = ilc:createList(options)
	quick_notes:SetPoint("TOPLEFT", custom_council, "BOTTOMLEFT", 0, -70)

	--======================
	-- custom buttons
	--======================
	if (true == false) then
		config:SetHeight(config:GetHeight() + 170)
		local last = false
		for i = 1, 5 do
			-- enable
			local options = {
				['name'] = 'use_button_'..i,
				['parent'] = self,
				['title'] = 'Enable',
				['default'] = ilc.config.buttons[i][3],
				['callback'] = function(toggle, button)
					ilc.config.buttons[i][3] = toggle:GetChecked()
					ilc:sendLC()
				end
			}
			local enable = ilc:createToggle(options)

			-- text
			local options = {
				['name'] = 'button_text'..i,
				['parent'] = self,
				['title'] = '',
				['width'] = 130,
				['default'] = ilc.config.buttons[i][1],
				['callback'] = function(value, key)
					ilc.config.buttons[i][1] = value
					ilc:sendLC()
				end
			}
		
			local text = ilc:createEdit(options)
			text:SetPoint("LEFT", enable, "RIGHT", 60, 0)

			-- color
			local options = {
				['name'] = 'button_color'..i,
				['parent'] = self,
				['title'] = 'Color',
				['width'] = 100,
				['default'] = ilc.config.buttons[i][2],
				['callback'] = function(picker, r, g, b, a)
					local value = table.concat({r, g, b})
					local current = table.concat(ilc.config.buttons[i][2])
					if (current ~= value) then
						ilc.config.buttons[i][2] = {r, g, b}
						ilc:sendLC()
					end
				end
			}
		
			local picker = ilc:createColor(options)
			picker:SetPoint("LEFT", text, "RIGHT", 20, 0)

			-- require
			local options = {
				['name'] = 'req_note_'..i,
				['parent'] = self,
				['title'] = 'Require Note',
				['default'] = ilc.config.buttons[i][4],
				['callback'] = function(toggle, button)
					ilc.config.buttons[i][4] = toggle:GetChecked()
					ilc:sendLC()
				end
			}
			local req = ilc:createToggle(options)
			req:SetPoint("LEFT", picker, "RIGHT", 45, 0)

			-- position
			if (not last) then
				enable:SetPoint("TOPLEFT", quick_notes, "BOTTOMLEFT", 0, -10)
			else
				enable:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -10)
			end

			last = enable
		end
	end
end)