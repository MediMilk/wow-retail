local AddonName = "KLootTracker"
local KLT = LibStub("AceAddon-3.0"):GetAddon(AddonName)

-- LOOT_TYPE -----------------------------------------------------------------------------------------------------------
-- MASTER_LOOT SYSTEM
function KLT:MASTER_LOOT_ENABLED(event, message, author)
    if event and KLT.masterLooter == KLT.playerName and KLT.startTrack and KLT.LootMethod == "master"
            and not KLT.db.profile.options.receiveMlEv then

        local itemId = tonumber(message:match("item:(%d+):"))
        local itemLink, itemRarity, itemType = self:GetItemValues(nil, itemId)

        if self:ItemTypeAndQuality(itemRarity, itemType, itemId) then
            if self:IsInRaid() then
                SendChatMessage(KLT.Prefix.."LOOT:"..author..":".. self:GetCorpseUnitName(itemId, itemRarity)
                        ..":"..itemLink, "RAID", "Common");
            end
        end
    end
end

-- GROUP_LOOT SYSTEM & NEED_BEFORE_GREED
function KLT:GROUP_LOOT_ENABLED(event)
    if event:find("won:") and KLT.startTrack and KLT.LootMethod == "group" then
        local auth = select(2, strsplit(" ",event))

        if auth == "You" then
            self:InsertItemRules(event, KLT.playerName)
        else
            self:InsertItemRules(event, auth)
        end
    end
end

-- FREE_FOR_ALL LOOT & ROUND_ROBIN, PERSONAL_LOOT
function KLT:FREE_FOR_ALL_ENABLED(event, message, author)
    if event and KLT.startTrack and KLT.LootMethod == "ffa" then
        self:InsertItemRules(message, author)
    end
end

-- ON MASTER_LOOT METHOD USE ONLY (SystemMessageLootReceive)
function KLT:MASTER_LOOT_DISABLED(event, message, author)
    if event and KLT.startTrack and KLT.LootMethod == "master" and KLT.db.profile.options.receiveMlEv then
        self:InsertItemRules(message, author)
    end
end

-- MASTER_LOOT_RAID_LISTENER -> RAID_MESSAGE_CORPSE_LOOT
function KLT:RAID_MESSAGE_LOOT_SOURCE_INFO(msg, condition)
    if msg:find(KLT.Prefix.."LOOT:") and condition and not KLT.db.profile.options.receiveMlEv then

        local itemId = tonumber(msg:match("item:(%d+):"))
        local itemLink, itemRarity = self:GetItemValues(nil, itemId)

        self:InsertItemToDB(itemId, itemLink, self:StringSelect(2, ":", msg), itemRarity)
    end
end

--EVENT_TRADE ----------------------------------------------------------------------------------------------------------
local target = ""
local playerTradeSlots = {}
local targetTradeSlots = {}

function KLT:TRADE_SHOW()
    target = UnitName("npc")
end

function KLT:TRADE_PLAYER_ITEM_CHANGED()

    playerTradeSlots = {}
    local p_Index = 0

    for index = 1, 6 do
        local playerTradeSlotItemLink = GetTradePlayerItemLink(index)

        if playerTradeSlotItemLink ~= nil then
            p_Index = p_Index + 1
            table.insert(playerTradeSlots, p_Index, playerTradeSlotItemLink)
        end

    end
end

function KLT:TRADE_TARGET_ITEM_CHANGED()

    targetTradeSlots = {}
    local t_Index = 0

    for index = 1, 6 do
        local targetTradeSlotItemLink = GetTradeTargetItemLink(index)

        if targetTradeSlotItemLink ~= nil then
            t_Index = t_Index + 1
            table.insert(targetTradeSlots, t_Index, targetTradeSlotItemLink)
        end
    end
end

function KLT:TRADE_REQUEST_CANCEL()
    self:ResetAwardData() -- UI_INFO_MESSAGE
end

local f = CreateFrame("Frame");
f:RegisterEvent("UI_INFO_MESSAGE");
f:RegisterEvent("UI_ERROR_MESSAGE");
f:SetScript("OnEvent", function(_, event, ...)
    if (event == "UI_INFO_MESSAGE" or event == "UI_ERROR_MESSAGE") then
        local type, _ = ...;

        if type == 233 then
            -- Trade complete.
            KLT:DrawTargetTradeSlots()
            KLT:DrawPlayerTradeSlots()
            KLT:ResetAwardData()
        elseif type == 232 then
            -- Trade canceled.
            KLT:ResetAwardData()
        end
    end
end)

-- AWARD_SYSTEM --------------------------------------------------------------------------------------------------------
function KLT:KLT_AWARD_TO_ML(msg, auth)
    if msg:find(KLT.Prefix.."SELF AWARD:") and self:MasterLootCondition(auth) then
        self:SetAwardAndPlayerNameFromMsg(msg)
    end
end

function KLT:KLT_TRADE_AWARD(msg, auth)
    if msg:find(KLT.Prefix.."TRADE:") and self:MasterLootCondition(auth)
            and self.db.profile.options.awardOnTrade then
        self:SetAwardAndPlayerNameFromMsg(msg)
    end
end

function KLT:KLT_TRADE_RE_AWARD(msg, auth)
    if msg:find(KLT.Prefix.."ITEM RETURN:") and self:MasterLootCondition(auth) then
        self:SetAwardAndPlayerNameFromMsg(msg)
    end
end

function KLT:KLT_REFACTOR_GL_TO_ML(msg, auth)
    if msg:find(KLT.Prefix.."REF:") and self:MasterLootCondition(auth) then
        self:RefactorItemsInDbToMl()
    end
end

-- [LOOT API] -> -------------------------------------------------------------------------------------------------------
function KLT:CheckLootMethod()
    local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()

    local ignorePartyML = false
    KLT.masterLooter = ""
    KLT.LootMethod = ""

    if masterLooterRaidID ~= nil then
        KLT.masterLooter = GetRaidRosterInfo(masterLooterRaidID);
    elseif masterLooterPartyID ~= nil then
        ignorePartyML = true
    end

    if lootMethod == "master" then
        KLT.LootMethod = "master"
    elseif lootMethod == "group" or lootMethod == "needbeforegreed" then
        KLT.LootMethod = "group"
    elseif lootMethod == "freeforall" or lootMethod == "roundrobin" or lootMethod == "personalloot" then
        KLT.LootMethod = "ffa"
    end

    if ignorePartyML and KLT.LootMethod == "master" then
        KLT.LootMethod = "ffa"
    end
end

function KLT:ItemTypeAndQuality(itemRarity, itemType, itemId)
    local result = true
    local typeQuality = 1

    if self:IsInInstance() == "raid" then
        typeQuality = self.db.profile.options.typeQualityRaid
    elseif self:IsInInstance() == "party" then
        typeQuality = self.db.profile.options.typeQualityDung
    end

    if typeQuality <= itemRarity then
        for i = 1, #KLT.Ignore do
            if KLT.Ignore[i] == itemType then
                if KLT.Exception[itemId] then
                    result = true
                else
                    result = false
                end
                break
            end
        end
    else
        result = false
    end
    return result
end

function KLT:MasterLootCondition(author)
    return (author == KLT.masterLooter and KLT.startTrack and self:IsInRaid())
end

-- [AWARD API] -> ------------------------------------------------------------------------------------------------------
function KLT:DrawPlayerTradeSlots()
    if self:MessageConEvOnTrade() then
        for i = 1, #playerTradeSlots do
            if self:IsItemInStore(playerTradeSlots[i]:match("item:(%d+):")) then
                SendChatMessage(KLT.Prefix.."TRADE: ".. playerTradeSlots[i].." to "..target ,"RAID" ,"COMMON")
            end
        end
    end
end

function KLT:DrawTargetTradeSlots()
    if self:MessageConEvOnTrade() then
        for i = 1, #targetTradeSlots do
            if self:IsItemInStoreWithReturningPlayer(targetTradeSlots[i]:match("item:(%d+):"), target) then
                SendChatMessage(KLT.Prefix.."ITEM RETURN: ".. targetTradeSlots[i].." to "..KLT.masterLooter.." (ML) from "..target ,"RAID" ,"COMMON")
            end
        end
    end
end

function KLT:SelfMasterLooterAward(itemLink)
    if self:MessageConEvOnTrade() then
        SendChatMessage(KLT.Prefix.."SELF AWARD: "..itemLink.." to "..KLT.masterLooter,"RAID" ,"COMMON")
    end
end

function KLT:SelfMasterLooterReturnAward(itemLink)
    if self:MessageConEvOnTrade() then
        SendChatMessage(KLT.Prefix.."ITEM RETURN: ".. itemLink.." to "..KLT.masterLooter.." (ML) from "..KLT.playerName ,"RAID" ,"COMMON")
    end
end

function KLT:MessageConEvOnTrade()
    return (self:IsInRaid() and KLT.masterLooter == KLT.playerName and KLT.startTrack
            and KLT.db.profile.options.awardOnTrade)
end

function KLT:ResetAwardData()
    target = ""
    playerTradeSlots = {}
    targetTradeSlots = {}
end

function KLT:IsItemInStore(itemId)
    local result = false
    for i = 1, #self:ItemStore() do
        if tonumber(self:ItemStore()[i].itemID) == tonumber(itemId) and not self:ItemStore()[i].awarded then
            result = true
            break
        end
    end
    return result
end

function KLT:IsItemInStoreWithReturningPlayer(itemId, re_Player)
    local result
    for i = 1, #self:ItemStore() do
        if tonumber(self:ItemStore()[i].itemID) == tonumber(itemId) and self:ItemStore()[i].receiver == re_Player then
            result = re_Player
            break
        end
    end
    return result
end

function KLT:IsFFAorGLInStore()
    local result = false
    for i = 1, #self:ItemStore() do
        if self:ItemStore()[i].onLootMethod == "group" and self:ItemStore()[i].receiver == KLT.masterLooter then
            result = true
            break
        elseif self:ItemStore()[i].onLootMethod == "ffa" and self:ItemStore()[i].receiver == KLT.masterLooter then
            result = true
            break
        end
    end
    return result
end

local l_Shift = false
local l_Alt = false
local r_Shift = false
local r_Alt = false
local r_Ctrl = false

function KLT:KeysCombination(isPressed, key_val)

    if isPressed == 1 and key_val == "LSHIFT" then
        l_Shift = true
    elseif isPressed == 0 then
        l_Shift = false
    end

    if isPressed == 1 and key_val == "LALT" then
        l_Alt = true
    elseif isPressed == 0 then
        l_Alt = false
    end

    if isPressed == 1 and key_val == "RSHIFT" then
        r_Shift = true
    elseif isPressed == 0 then
        r_Shift = false
    end

    if isPressed == 1 and key_val == "RCTRL" then
        r_Ctrl = true
    elseif isPressed == 0 then
        r_Ctrl = false
    end

    if isPressed == 1 and key_val == "RALT" then
        r_Alt = true
    elseif isPressed == 0 then
        r_Alt = false
    end

    if isPressed == 1 and r_Shift and r_Ctrl then
        local itemLink = select(2, GameTooltip:GetItem())

        if itemLink ~= nil then
            if self:IsItemInStore(itemLink:match("item:(%d+):")) then
                self:SelfMasterLooterAward(itemLink)
            end
        end
    end

    if isPressed == 1 and r_Shift and r_Alt then
        local itemLink = select(2, GameTooltip:GetItem())

        if itemLink ~= nil then
            if self:IsItemInStoreWithReturningPlayer(itemLink:match("item:(%d+):"), KLT.playerName) ~= nil then
                self:SelfMasterLooterReturnAward(itemLink)
            end
        end
    end
end

-- [REFACTOR] GL TO ML ->-----------------------------------------------------------------------------------------------
function KLT:RefGlToMlMessage()
    if self:MasterLootCondition(KLT.playerName) and self:IsFFAorGLInStore() then
        SendChatMessage(KLT.Prefix.."REF:GL TO ML to "..KLT.masterLooter,"RAID" ,"COMMON")
    elseif not self:IsFFAorGLInStore() then
        if KLT.playerName == KLT.masterLooter then
            self:Print("In Store arent items from GroupLoot!")
        else
            self:Print("You are not Master Looter!")
        end
    end
end

function KLT:RefactorItemsInDbToMl()
    for i = 1, #self:ItemStore() do
        if self:ItemStore()[i].onLootMethod == "group" and self:ItemStore()[i].receiver == KLT.masterLooter then
            self:UpdateAwardedStatusInItemStore(i, "", false, "master", false)
        elseif self:ItemStore()[i].onLootMethod == "ffa" and self:ItemStore()[i].receiver == KLT.masterLooter then
            self:UpdateAwardedStatusInItemStore(i, "", false, "master", false)
        end
    end

    self:RedrawTableRows()
end