local addonName = "KLootTracker"
local KLT = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local icon = LibStub("LibDBIcon-1.0")

-- ON INIT
function KLT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName, KLT.default)
    self:KLTRegisterOptionsTable()
    self:CreateMinimapIcon()
    self:CreateFrame()
end

-- WHEN ADDON LOADED
function KLT:OnEnable()

    self:Print(addonName,": Loaded...")

    -- REGISTER_GAME_EVENTS
    -- EVENTS
    self:RegisterEvent("MODIFIER_STATE_CHANGED","MODIFIER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD","ENTERING_WORLD_OR_INSTANCE")
    self:RegisterEvent("UPDATE_INSTANCE_INFO","UPDATE_INSTANCE_INFO")
    self:RegisterEvent("BOSS_KILL","ENCOUNTER_KILL")

    --LOOT EVENTS
    self:RegisterEvent("CHAT_MSG_LOOT","CHAT_SYSTEM_EVENT_LOOT")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER","CHAT_MASTER_LISTENER")
    self:RegisterEvent("CHAT_MSG_RAID","CHAT_MASTER_LISTENER")
    self:RegisterEvent("GROUP_ROSTER_UPDATE","PARTY_RAID_CHANGED")

    --TRADE EVENTS
    self:RegisterEvent("TRADE_SHOW","TRADE_SHOW")
    self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED","TRADE_PLAYER_ITEM_CHANGED")
    self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED","TRADE_TARGET_ITEM_CHANGED")
    self:RegisterEvent("TRADE_REQUEST_CANCEL","TRADE_REQUEST_CANCEL")

end

-- ON LOGOUT&RELOAD
function KLT:OnDisable()
end

-- REGISTER_MINIMAP_ICON
function KLT:CreateMinimapIcon()
    local LibMapIco = LibStub("LibDataBroker-1.1"):NewDataObject(addonName,
            {
                type = "data source",
                text = addonName,
                icon = "interface/icons/inv_misc_book_05",
                OnClick = function(_, button)
                    if (button == "RightButton") then
                        self:InterfaceOptionsFrameOpenToCategory()
                    elseif (button == "LeftButton") then
                        self:CallFrame()
                    end
                end,
                OnTooltipShow = function(tooltip)
                    tooltip:AddLine(string.format("|cff71C671%s|r %s", addonName, KLT.addonVer))
                    tooltip:AddLine(string.format("|cFFCFCFCF%s|r %s", "Left Click", "to open Table"))
                    tooltip:AddLine(string.format("|cFFCFCFCF%s|r %s", "Right Click", "to open Options"))
                end
            })
    icon:Register(addonName, LibMapIco, self.db.profile.options.minimap)
end

-- GAME_EVENTS ---------------------------------------------------------------------------------------------------------
function KLT:MODIFIER_STATE_CHANGED(_, key_val, isPressed)
    self:KeysCombination(isPressed, key_val)
end

function KLT:ENTERING_WORLD_OR_INSTANCE()
    --Fired when the player enters the world, enters/leaves an instance, or respawns at a graveyard.
    --Also fires any other time the player sees a loading screen.

    --Check ENTER or LEAVE instance
    self:InstanceMapID()
    self:CheckConditionsOfRaidAndDungeon()
end

function KLT:UPDATE_INSTANCE_INFO()
    self:InstanceMapID()
end

function KLT:PARTY_RAID_CHANGED()
    -- Check ML and PARTY or RAID (Inv/Leave members)
    self:CheckConditionsOfRaidAndDungeon()
end

function KLT:ENCOUNTER_KILL(_, evEncounterName)
    KLT.encounterName = KLT.BossNameById[evEncounterName]
end

function KLT:CHAT_SYSTEM_EVENT_LOOT(_, event, _, _, _, author)

    -- LOOT_METHOD ->
    self:MASTER_LOOT_ENABLED(self:SystemMessageLootReceive(event), event, author)

    self:GROUP_LOOT_ENABLED(event)

    self:FREE_FOR_ALL_ENABLED(self:SystemMessageLootReceive(event), event, author)

    self:MASTER_LOOT_DISABLED(self:SystemMessageLootReceive(event), event, author)

end

function KLT:CHAT_MASTER_LISTENER(_, msg, author)

    local auth = self:StringSelect(1, "-", author)

    -- RAID_MESSAGE_CORPSE_LOOT
    self:RAID_MESSAGE_LOOT_SOURCE_INFO(msg, self:MasterLootCondition(auth))

    -- AWARD_SYSTEM_LISTENER [ADDONS]
    self:KLT_AWARD_TO_ML(msg, auth)

    self:KLT_TRADE_AWARD(msg, auth)

    self:KLT_TRADE_RE_AWARD(msg, auth)

    self:KLT_REFACTOR_GL_TO_ML(msg, auth)

end

-- API -----------------------------------------------------------------------------------------------------------------
-- DATABASE
function KLT:ItemStore()
    return self.db.profile.ItemStore
end

function KLT:InsertItemToDB(itemId, itemLink, receiver, itemRarity)
    self:InstanceMapID()

    local awarded = false
    local r_receiver = self:ReceiverResult(receiver)

    if r_receiver ~= "" then
        awarded = true
    end

    table.insert(self:ItemStore(),(self:GetLastTableIndex(self:ItemStore())),{
        instance = KLT.InstanceMap["name"],
        instanceDif = KLT.InstanceMap["diff_id"],
        instanceID = KLT.InstanceMap["id"],
        lootID = self:GetLastTableIndex(self:ItemStore()),
        boss = self:GetCorpseUnitName(itemId, itemRarity),
        itemID = itemId,
        itemLink = itemLink,
        receiver = r_receiver,
        awarded = awarded,
        onLootMethod = KLT.LootMethod,
        time = GetServerTime()
    })

    self:RedrawTableRows()
end

function KLT:InsertItemRules(event,receiver)
    local itemId = tonumber(event:match("item:(%d+):"))
    local itemLink, itemRarity, itemType = self:GetItemValues(nil, itemId)

    if self:ItemTypeAndQuality(itemRarity, itemType, itemId) then
        self:InsertItemToDB(itemId, itemLink, receiver, itemRarity)
    end
end

function KLT:FilteredTableRows(itemTypeAndSubType, awardedState, selectedPage)
    local onChange = false

    if itemTypeAndSubType ~= KLT.fItemTypeAndSubType or awardedState ~= KLT.fAwardedState then
        onChange = true
        KLT.fItemTypeAndSubType = itemTypeAndSubType
        KLT.fAwardedState = awardedState
    end

    local filteredTable = {}

    if itemTypeAndSubType ~= "All" then
        if awardedState ~= "All" then
            for i = 1, #self:ItemStore() do
                local _, _, itemType, itemSubType = self:GetItemValues(self:ItemStore()[i].itemLink)

                if itemTypeAndSubType == itemSubType and self:AwardedFilter(self:ItemStore(), i, awardedState) then
                    table.insert(filteredTable,self:GetLastTableIndex(filteredTable),self:InsertItemToFilter(self:ItemStore(),i))
                elseif itemTypeAndSubType == "Weapon" and itemTypeAndSubType == itemType
                        and self:AwardedFilter(self:ItemStore(), i, awardedState) then
                    table.insert(filteredTable,self:GetLastTableIndex(filteredTable),self:InsertItemToFilter(self:ItemStore(),i))
                end
            end
        else
            for i = 1, #self:ItemStore() do
                local _, _, itemType, itemSubType = self:GetItemValues(self:ItemStore()[i].itemLink)

                if itemTypeAndSubType == itemSubType then
                    table.insert(filteredTable,self:GetLastTableIndex(filteredTable),self:InsertItemToFilter(self:ItemStore(),i))
                elseif itemTypeAndSubType == "Weapon" and itemTypeAndSubType == itemType then
                    table.insert(filteredTable,self:GetLastTableIndex(filteredTable),self:InsertItemToFilter(self:ItemStore(),i))
                end
            end
        end
    else
        if awardedState ~= "All" then
            for i = 1, #self:ItemStore() do
                if self:AwardedFilter(self:ItemStore(), i, awardedState) then
                    table.insert(filteredTable,self:GetLastTableIndex(filteredTable),self:InsertItemToFilter(self:ItemStore(),i))
                end
            end
        else
            filteredTable = self:ItemStore()
        end
    end

    filteredTable = self:ShowLastInstance(filteredTable)

    return self:PageFilter(self:InvertFilteredArray(filteredTable, false), selectedPage, onChange)
end

function KLT:PageFilter(filteredTable, selectedPage, onChange)
    local actualFilteredPage = {}
    local pageList = {}

    local currentPage = selectedPage

    local total = self:GetCountTableRows(filteredTable)
    local toShow = self.db.profile.options.viewOnPage

    if KLT.fToShow ~= toShow then
        currentPage = 1
        KLT.fToShow = toShow
    end

    if total < toShow and total ~= 0 then
        toShow = total
    end

    local quotient = (total - (total % toShow)) / toShow

    for i = 1, quotient do
        if i > 1 then
            table.insert(pageList,i, { startPage = (((i * toShow) + 1) - toShow), endPage = (i * toShow)})
        else
            table.insert(pageList,i, { startPage = 1, endPage = (i * toShow)})
        end
    end

    if total - (quotient * toShow) ~= 0 then
        table.insert(pageList,quotient + 1, { startPage = ((((quotient + 1) * toShow) + 1) - toShow), endPage = total})
    end

    if onChange or self:GetCountTableRows(pageList) == 0 then
        currentPage = 1
    end

    if self:GetCountTableRows(filteredTable) ~= 0 then
        local index = 1
        local startPagePos = pageList[currentPage].startPage
        repeat
            table.insert(actualFilteredPage,index,self:InsertItemToFilter(filteredTable, startPagePos))
            index = index + 1
            startPagePos = startPagePos + 1
        until( startPagePos > pageList[currentPage].endPage)
    end

    local totalPages = self:GetCountTableRows(pageList)

    if self:GetCountTableRows(pageList) == 0 then
        totalPages = 1
    end

    return actualFilteredPage, totalPages, currentPage, total
end

function KLT:InvertFilteredArray(array, permit)
    local invertedArray = {}

    if self.db.profile.options.invertLootTable and self:GetCountTableRows(array) ~= 0 or permit then
        local index = self:GetCountTableRows(array)
        local pos = 1

        repeat
            table.insert(invertedArray,pos,self:InsertItemToFilter(array, index))
            index = index - 1
            pos = pos + 1
        until (index == 0)

        return invertedArray
    else
        return array
    end
end

function KLT:ShowLastInstance(array)
    local lastInstance = {}
    local array_i
    local id, dif

    if self:GetCountTableRows(array) ~= 0 then
        array_i = self:InvertFilteredArray(array, true)
    end

    if self:GetCountTableRows(self:ItemStore()) ~= 0 then
        id = self:ItemStore()[table.maxn(self:ItemStore())].instanceID
        dif = self:ItemStore()[table.maxn(self:ItemStore())].instanceDif
    end

    if self.db.profile.options.lastRaidOrDungeon and array_i ~= nil and id ~= nil then

        for i = 1, #array_i do
            if id == array_i[i].instanceID and dif == array_i[i].instanceDif then
                table.insert(lastInstance,i,self:InsertItemToFilter(array_i, i))
            else
                break
            end
        end

        if self:GetCountTableRows(lastInstance) ~= 0 then
            return self:InvertFilteredArray(lastInstance, true)
        else
            return lastInstance
        end
    else
        return array
    end
end

function KLT:AwardedFilter(array, index, awardedState)

    if awardedState == KLT.playerName then
        if array[index].receiver == awardedState then
            return true
        else
            return false
        end
    else
        if array[index].awarded == awardedState then
            return true
        else
            return false
        end
    end

end

function KLT:SortByInstance(instance_id, instance_dif)

    if KLT.InstanceIdGui == nil then
        KLT.InstanceIdGui = {
            ["inst"] = instance_id,
            ["dif"] = instance_dif
        }
        return true
    end

    if KLT.InstanceIdGui["inst"] ~= instance_id or KLT.InstanceIdGui["dif"] ~= instance_dif then
        KLT.InstanceIdGui["inst"] = instance_id
        KLT.InstanceIdGui["dif"] = instance_dif
        return true
    end
    return
end

function KLT:GetCountTableRows(array)
    return table.maxn(array)
end

function KLT:GetLastTableIndex(array)
    return table.maxn(array) + 1
end

function KLT:InsertItemToFilter(table, index)
    return {
        instance = table[index].instance,
        instanceDif = table[index].instanceDif,
        instanceID = table[index].instanceID,
        lootID = table[index].lootID,
        boss = table[index].boss,
        itemID = table[index].itemID,
        itemLink = table[index].itemLink,
        receiver = table[index].receiver,
        time = table[index].time
    }
end

function KLT:SetAwardAndPlayerNameFromMsg(msg)
    local list = {strsplit(" ", msg)}
    local to_Index = self:IndexOfString(list, self:ContainsSpecificString(msg:match("%[?([^%[%]]*)%]"),"to"), "to")
    local from_Index = self:IndexOfString(list, 0, "from")
    local return_Player

    if msg:find("from") and from_Index ~= 0 then
        return_Player = select((from_Index), strsplit(" ", msg))
    end

    self:CheckStatusOfAwardedMsg(msg:match("item:(%d+):"), select((to_Index), strsplit(" ", msg)), return_Player)
end

function KLT:CheckStatusOfAwardedMsg(itemId, receiver, return_Player)
    for i = 1, #self:ItemStore() do
        if tonumber(self:ItemStore()[i].itemID) == tonumber(itemId) then
            if return_Player == nil then
                if self:ItemStore()[i].onLootMethod == "master" and self:ItemStore()[i].receiver == "" then
                    self:UpdateAwardedStatusInItemStore(i,receiver,true,"master",true)
                    break
                elseif self:ItemStore()[i].onLootMethod == "group"
                        and self:ItemStore()[i].receiver == KLT.masterLooter and KLT.LootMethod == "master" then
                    self:UpdateAwardedStatusInItemStore(i,receiver,true,"master",true)
                    break
                elseif self:ItemStore()[i].onLootMethod == "ffa" and KLT.LootMethod == "master" then
                    self:UpdateAwardedStatusInItemStore(i,receiver,true,"master",true)
                    break
                end
            else
                if self:ItemStore()[i].receiver == return_Player and KLT.LootMethod == "master" then
                    self:UpdateAwardedStatusInItemStore(i,"",false,"master",true)
                    break
                end
            end
        end
    end
end

function KLT:UpdateAwardedStatusInItemStore(index,receiver,award,l_Method,drawRows)
    self:ItemStore()[index].receiver = receiver
    self:ItemStore()[index].awarded = award
    self:ItemStore()[index].onLootMethod = l_Method

    if drawRows then
        self:RedrawTableRows()
    end
end

function KLT:DeleteStorage()
    StaticPopupDialogs["DeleteConfirm"] = {
        text = "Are you sure you want to DELETE all items from database?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        OnAccept = function()
            self.db.profile.ItemStore = {}
            self:Print("Storage was deleted...")
            self:RedrawTableRows(true)
        end,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("DeleteConfirm")
end

-- CHECK PLAYER STATE --------------------------------------------------------------------------------------------------
local instanceRaidHook, isInRaidHook, popUpHook, instanceDungeonHook

function KLT:IsInInstance()
    local inInstance, instanceType = IsInInstance()
    local result = ""

    if inInstance and instanceType == "raid" then
        instanceRaidHook = true
        result = "raid"
    elseif inInstance and instanceType == "party" then
        instanceDungeonHook = true
        result = "party"
    end
    return result
end

function KLT:IsInRaid()
    local result = false

    if UnitInRaid(KLT.playerName) ~= nil then
        result = true
        isInRaidHook = true
    end
    return result
end

function KLT:CheckConditionsOfRaidAndDungeon()

    self:CheckLootMethod()

    local isInRaid = self:IsInRaid()

    if self.db.profile.options.myTrack then
        self:Dungeons(isInRaid)
        self:Raids(isInRaid)
    else
        self:ClosePopUpInstanceFrame()
        KLT.startTrack = false
        popUpHook = false
        isInRaidHook = false
        instanceRaidHook = false
        instanceDungeonHook = false
    end

    self:GetBottomStatusTextInfo()
end

function KLT:Raids(isInRaid)
    if isInRaid and self.db.profile.options.raidTrack and self:IsInInstance() ~= "party" then
        KLT.startTrack = true
        if self:IsInInstance() == "raid" then
            if not popUpHook and not KLT.DontShowAgain then
                KLT:CallPopUpInstanceFrame()
            end
            popUpHook = true
        else
            self:ClosePopUpInstanceFrame()
            if KLT.startTrack and instanceRaidHook and popUpHook then
                instanceRaidHook = false
                popUpHook = false
            end
        end
    else
        if isInRaidHook and not instanceDungeonHook and self.db.profile.options.raidTrack then
            self:Print("KLT stop tracking items. You leave Raid")
            self:RaidConReset()
        elseif not self.db.profile.options.raidTrack and not instanceDungeonHook then
            self:RaidConReset()
        elseif instanceDungeonHook then
            isInRaidHook = false
            instanceRaidHook = false
        end
    end
end

function KLT:Dungeons(isInRaid)
    if self:IsInInstance() == "party" and not isInRaid and self.db.profile.options.dungeonsTrack then
        KLT.startTrack = true
        if not popUpHook and not KLT.DontShowAgain then
            KLT:CallPopUpInstanceFrame()
        end
        popUpHook = true
    else
        if KLT.startTrack and instanceDungeonHook and popUpHook then
            self:ClosePopUpInstanceFrame()
            if self.db.profile.options.dungeonsTrack and not isInRaid then
                self:Print("KLT stop tracking items. You leave Dungeons Instance")
            elseif self.db.profile.options.dungeonsTrack and isInRaid then
                isInRaidHook = false
                self:Print("KLT stop tracking items. You are in raid!!")
            end
            popUpHook = false
            KLT.startTrack = false
            instanceDungeonHook = false
        end
        KLT.startTrack = false
        instanceDungeonHook = false
    end
end

function KLT:InstanceMapID()
    local instance, _, difficultyID, difficultyName, _, _, _, instanceID, _ = GetInstanceInfo()
    --local name, groupType, isHeroic, isChallengeMode, displayHeroic,
    --displayMythic, toggleDifficultyID = GetDifficultyInfo(difficultyID)

    if KLT.InstanceMap["id"] ~= instanceID and KLT.Zones[instanceID] == nil then
        KLT.InstanceMap["id"] = instanceID
        KLT.encounterName = nil
        KLT.DontShowAgain = false
        self:SetDontShowToggle()
    end

    if  KLT.InstanceMap["id"] == instanceID then
        KLT.InstanceMap["name"] = instance.." - "..difficultyName
        KLT.InstanceMap["diff_id"] = difficultyID
    end

end

function KLT:RaidConReset()
    self:ClosePopUpInstanceFrame()
    KLT.startTrack = false
    popUpHook = false
    isInRaidHook = false
    instanceRaidHook = false
end

-- INTERFACE_OPTIONS ---------------------------------------------------------------------------------------------------
function KLT:InterfaceOptionsFrameOpenToCategory()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    InterfaceOptionsFrame_OpenToCategory(addonName)
end

function KLT:SetMinimapShow()
    self.db.profile.options.minimap.hide = self:GetMinimapShow()
    if self.db.profile.options.minimap.hide then
        icon:Hide(addonName)
    else
        icon:Show(addonName)
    end
end

function KLT:SetMyTrack()
    self.db.profile.options.myTrack = self:GetMyTrack()
    self:CheckConditionsOfRaidAndDungeon()
end

function KLT:GetMyTrack()
    return not self.db.profile.options.myTrack
end

function KLT:GetStartTrack()
    return KLT.startTrack
end

function KLT:GetMinimapShow()
    return not self.db.profile.options.minimap.hide
end

function KLT:GetAutoUpdate()
    return self.db.profile.options.autoUpdate
end

function KLT:SetAutoUpdate(_,value)
    self.db.profile.options.autoUpdate = value
end

function KLT:SetRaidTrack(_, val)
    self.db.profile.options.raidTrack = val
    self:CheckConditionsOfRaidAndDungeon()
end

function KLT:SetDungeonTrack(_, val)
    self.db.profile.options.dungeonsTrack = val
    self:CheckConditionsOfRaidAndDungeon()
end

function KLT:SetTradeAward(_, val)
    KLT.db.profile.options.awardOnTrade = val
    self:GetBottomStatusTextInfo()
end

function KLT:SetDisableMasterLoot(_, val)
    KLT.db.profile.options.receiveMlEv = val
    self:SetIgnoreMlToggle()
end

function KLT:SetInvertLootTable(_, val)
    KLT.db.profile.options.invertLootTable = val
    self:RedrawTableRows()
end

--SERVICES -------------------------------------------------------------------------------------------------------------
function KLT:GetItemValues(ItemLink, ItemId)
    local itemId

    if ItemId ~= nil and ItemId ~= "" then
        itemId = ItemId
    else
        if ItemLink ~= nil and ItemLink ~= "" then
            itemId = tonumber(ItemLink:match("item:(%d+):"))
        else
            itemId = 29434
        end
    end

    local _, itemLink, itemRarity, _, _, itemType, itemSubType, _, _, itemTexture, _, _, _, bindType = GetItemInfo(itemId)

    return itemLink, itemRarity, itemType, itemSubType, itemTexture, bindType
end

function KLT:StringSelect(index, regex, string)
    return select(index, strsplit(regex, string))
end

function KLT:ContainsSpecificString(itemName, string)
    local list = {strsplit(" ", itemName)}
    return self:IndexOfString(list, 0, string)
end

function KLT:SystemMessageLootReceive(event)
    return (event:find("receives loot:") or event:find("receive loot:"))
end

function KLT:ReceiverResult(author)
    local result = author

    if author == KLT.masterLooter then
        result = ""
    end
    return result
end

function KLT:GetCorpseUnitName(item_id, itemRarity)
    local zoneTrash = KLT.TrashItems[KLT.InstanceMap["id"]]

    if KLT.encounterName == nil or KLT.encounterName == "" then
        KLT.encounterName = "Trash"
    end

    local result = KLT.encounterName

    if itemRarity <= 2 then
        result = "Trash"
    end

    if zoneTrash ~= nil then
        if zoneTrash[item_id] then
            result = "Trash"
        end
    end

    return result
end

function KLT:IsNameInRaidRoster(val)
    local result = false
    for i = 1, 40 do
        local name = GetRaidRosterInfo(i);
        if name == val then
            result = true
            break
        end
    end
    return result
end

function KLT:IndexOfString(list, ignore, string)
    local index = 0
    for i = 1, #list do
        if list[i] == string then
            if ignore == 0 then
                index = i + 1
                break
            end
            ignore = ignore - 1
        end
    end
    return index
end

function KLT:DebugNilInt(value)
    if value == nil then
        return 0
    end
    return value
end

function KLT:DBItemLinkRep()
    for i = 1, #self:ItemStore() do
        local itemLink = self:GetItemValues(nil, self:ItemStore()[i].itemID)
        if self:ItemStore()[i].itemLink == nil then
            self:ItemStore()[i].itemLink = itemLink
        end
    end
end