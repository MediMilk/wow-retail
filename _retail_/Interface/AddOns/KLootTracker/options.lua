local AddonName = "KLootTracker"
local KLT = LibStub("AceAddon-3.0"):GetAddon(AddonName)

-- LibStub default
KLT.default = {
    profile = {
        options = {
            myTrack = true,
            dungeonsTrack = true,
            raidTrack = true,
            typeQualityRaid = 4,
            typeQualityDung = 3,
            viewOnPage = 10,
            autoUpdate = true,
            receiveMlEv = false,
            invertLootTable = true,
            awardOnTrade = true,
            ownSystemAward = false,
            lastRaidOrDungeon = false,
            minimap = {
                hide = false,
            }
        },
        ItemStore = {
            instance = "",
            instanceDif = 0,
            instanceID = 0,
            lootID = 0,
            boss = "",
            itemID = 0,
            itemLink = "",
            receiver = "",
            awarded = false,
            onLootMethod = "",
            time = 0
        }
    }
}

-- AceConfig options
local options = {
    name = "KLooTracker",
    handler = KLT,
    type = "group",
    args = {
        General = {
            order = 1,
            type = "group",
            name = "Options",
            args = {
                MinimapButton = {
                    type = "toggle",
                    name = "Show Minimap Button",
                    desc = "Show Minimap Icon.",
                    get = "GetMinimapShow",
                    set = "SetMinimapShow",
                    order = 1,
                },
                MyTrack = {
                    type = "toggle",
                    name = "Stop Tracking",
                    desc = "Stop collecting items and mute messages.",
                    get = "GetMyTrack",
                    set = "SetMyTrack",
                    order = 2,
                },
                TableOptions = {
                    type = "description",
                    name = "|CFFFFFF01UI Table Options|R",
                    fontSize = "large",
                    order = 3,
                },
                Refactor = {
                    type = "execute",
                    name = "Change GL -> ML",
                    desc = "Change looted items with GroupLoot to Master, for use trade award."..
                            " If you splitting items at the end. (You must have MasterLooter)",
                    func = "RefGlToMlMessage",
                    order = 4,
                },
                AutoUpdate = {
                    type = "toggle",
                    name = "AutoRefreshTable",
                    desc = "Refresh table every time when loot or award item.",
                    get = "GetAutoUpdate",
                    set = "SetAutoUpdate",
                    order = 5,
                },
                ViewCountSelect = {
                    order = 6,
                    type = "range",
                    name = "Maximum items on page:",
                    desc = "Maximum items on page(|CFFFFFF01Optimal 20|R).",
                    min = 10,
                    max = 40,
                    step = 1,
                    get = function() return KLT.db.profile.options.viewOnPage end,
                    set = function(_, val) KLT.db.profile.options.viewOnPage = val end,
                },
                DeleteTable = {
                    type = "execute",
                    name = "DeleteTable",
                    desc = "Delete all collected items in table.",
                    func = "DeleteStorage",
                    order = 7,
                },
                InvertLootTable = {
                    type = "toggle",
                    name = "InvertLootTable",
                    desc = "First items in table(Last looted)",
                    get = function() return KLT.db.profile.options.invertLootTable end,
                    set = "SetInvertLootTable",
                    order = 8,
                },
                Instances = {
                    type = "description",
                    name = "|CFFFFFF01Instance|R",
                    fontSize = "large",
                    order = 9,
                },
                UseRaidTrack = {
                    type = "toggle",
                    name = "Use Raid Collecting",
                    desc = "Collect items in Normal&Heroic Raids.",
                    width = "double",
                    get = function() return KLT.db.profile.options.raidTrack end,
                    set = "SetRaidTrack",
                    order = 10,
                },
                ItemTypeQualityRaid = {
                    order = 11,
                    type = "select",
                    name = "TypeQuality Raids:",
                    desc = "Collecting type quality.",
                    values = {
                        [0] = "Poor +",
                        [1] = "Common +",
                        [2] = "Uncommon +",
                        [3] = "Rare +",
                        [4] = "Epic +",
                        [5] = "Legendary +",
                        [6] = "Artifact",
                    },
                    get = function() return KLT.db.profile.options.typeQualityRaid end,
                    set = function(_, val) KLT.db.profile.options.typeQualityRaid = val end,
                },
                UseDungeonsTrack = {
                    type = "toggle",
                    name = "Use Dungeons Collecting",
                    desc = "Collect items in Normal&Heroic dungeons.",
                    width = "double",
                    get = function() return KLT.db.profile.options.dungeonsTrack end,
                    set = "SetDungeonTrack",
                    order = 12,
                },
                ItemTypeQualityParty = {
                    order = 13,
                    type = "select",
                    name = "TypeQuality Dungeons:",
                    desc = "Collecting type quality.",
                    values = {
                        [0] = "Poor +",
                        [1] = "Common +",
                        [2] = "Uncommon +",
                        [3] = "Rare +",
                        [4] = "Epic +",
                        [5] = "Legendary +",
                        [6] = "Artifact",
                    },
                    get = function() return KLT.db.profile.options.typeQualityDung end,
                    set = function(_, val) KLT.db.profile.options.typeQualityDung = val end,
                },
                MasterLooter = {
                    type = "description",
                    name = "|CFFFFFF01MasterLooter/MasterLoot Method|R",
                    fontSize = "large",
                    order = 14,
                },
                DisableMasterLoot = {
                    type = "toggle",
                    name = "Disable MasterLoot info",
                    desc = "Disable KLT system message to raid if you are ML.",
                    get = function() return KLT.db.profile.options.receiveMlEv end,
                    set = "SetDisableMasterLoot",
                    order = 15,
                },
                IgnoreMasterLoot = {
                    type = "toggle",
                    name = "Use other item receive with ML",
                    desc = "If raid LootMethod is Master and MasterLooter dont use this Addon"..
                            " or MasterLoot info was disabled, then items are collected when someone receive item to bag.",
                    width = "double",
                    get = function() return KLT.db.profile.options.receiveMlEv end,
                    set = "SetDisableMasterLoot",
                    order = 16,
                },
                AwardSystem = {
                    type = "description",
                    name = "|CFFFFFF01AwardSystem|R",
                    fontSize = "large",
                    order = 17,
                },
                InfoMlAward = {
                    type = "description",
                    name = function() return "|cffFF4500"..KLT.info_Award.."|R" end,
                    fontSize = "medium",
                    order = 18,
                },
                TradeAward = {
                    type = "toggle",
                    name = "TradeAward",
                    desc = "Award item to player by trade. This save player name to table receiver. (Message to Raid)",
                    get = function() return KLT.db.profile.options.awardOnTrade end,
                    set = "SetTradeAward",
                    order = 19,
                },
                Info = {
                    type = "description",
                    name = "|CFFFFFF01Info|R",
                    fontSize = "large",
                    order = 20,
                },
                ShowHideInfo = {
                    type = "execute",
                    name = "Show/Hide Info",
                    func = "CallInfo",
                    order = 21,
                },
                InfoContent = {
                    type = "description",
                    name = function() return "|cffFFFFE0"..KLT.inf["content"].."|R" end,
                    fontSize = "medium",
                    order = 22,
                }
            }
        }
    }
}

function KLT:KLTRegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, options, {"KLT"})
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, nil, nil, "General")
end

function KLT:CallInfo()
    local state = not KLT.inf["state"]
    if state then
        KLT.inf["content"] = KLT.info
        KLT.inf["state"] = state
    else
        KLT.inf["content"] = ""
        KLT.inf["state"] = state
    end
end