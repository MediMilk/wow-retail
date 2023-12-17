local AddonName = "KLootTracker"
local KLT = LibStub("AceAddon-3.0"):GetAddon(AddonName)
local AceGUI = LibStub("AceGUI-3.0")

local selectedPage = 1
local frame, scrollFrame, BottomStatusLbl, BottomPageStateLbl, lTotalPages, cFrame, filteredTableCount, RefreshBtn

function KLT:CreateFrame()
    -- Frame
    frame = AceGUI:Create("Window")
    frame:SetTitle(AddonName)
    frame:SetWidth(700)
    frame:SetHeight(480)
    -- Close on ECS..
    local frameName = AddonName .. "_MainFrame"
    _G[frameName] = frame
    table.insert(UISpecialFrames, frameName)
    frame:EnableResize(false)
    frame:SetLayout("Flow")
    frame:Hide()

    -- Header
    self:CreateHeader()

    -- Table Content Header
    self:CreateTableContentHeader()

    -- Content Table * ScrollFrame
    self:CreateContentScrollFrame()

    -- BottomGroup
    self:CreateBottom()

    -- Create Content table rows
    --self:CreateRows()
    self:CreateContentOnFirstLoad()

    -- Get info
    self:GetBottomStatusTextInfo()

end

function KLT:CreateHeader()
    -- Header
    local NavHeader = AceGUI:Create("SimpleGroup")
    NavHeader:SetFullWidth(true)
    NavHeader:SetLayout("Flow")
    frame:AddChild(NavHeader)

    -- Item Filter
    local FilterItemsLbl = AceGUI:Create("Label")
    FilterItemsLbl:SetText("Item filter:")
    FilterItemsLbl:SetRelativeWidth(0.09)
    NavHeader:AddChild(FilterItemsLbl)

    local DpfItemList = AceGUI:Create("Dropdown")
    DpfItemList:SetList(KLT.ItemSubTypeList)
    DpfItemList:SetValue(KLT.ItemTypeSelect)
    DpfItemList:SetRelativeWidth(0.20)
    DpfItemList:SetCallback("OnValueChanged", function(_, _, selected)
        KLT.ItemTypeSelect = selected
        self:RedrawTableRows(true)
    end)
    NavHeader:AddChild(DpfItemList)

    -- Padding
    local Padding = AceGUI:Create("Label")
    Padding:SetRelativeWidth(0.02)
    NavHeader:AddChild(Padding)

    -- ReceiveList Api Filter
    local FilterReceiverLbl = AceGUI:Create("Label")
    FilterReceiverLbl:SetText("Receiver Filter:")
    FilterReceiverLbl:SetRelativeWidth(0.12)
    FilterReceiverLbl:SetColor(255,222,162)
    NavHeader:AddChild(FilterReceiverLbl)

    local DpfReceiverList = AceGUI:Create("Dropdown")
    DpfReceiverList:SetList(KLT.ReceiverList)
    DpfReceiverList:SetValue(KLT.ReceiverSelect)
    DpfReceiverList:SetRelativeWidth(0.19)
    DpfReceiverList:SetCallback("OnValueChanged", function(_, _, selected)
        KLT.ReceiverSelect = selected
        self:RedrawTableRows(true)
    end)
    NavHeader:AddChild(DpfReceiverList)

    -- Padding
    Padding = AceGUI:Create("Label")
    Padding:SetRelativeWidth(0.02)
    NavHeader:AddChild(Padding)

    -- Last RorD
    local LastRdToggle = AceGUI:Create("CheckBox")
    LastRdToggle:SetLabel("Last R/D")
    LastRdToggle:SetValue(self.db.profile.options.lastRaidOrDungeon)
    LastRdToggle:SetRelativeWidth(0.13)
    LastRdToggle:SetCallback("OnValueChanged", function(_, _, val)
        self.db.profile.options.lastRaidOrDungeon = val
        selectedPage = 1
        self:RedrawTableRows(true)
    end)
    NavHeader:AddChild(LastRdToggle)

    -- Options
    RefreshBtn = AceGUI:Create("Button")
    RefreshBtn:SetText("Load")
    RefreshBtn:SetRelativeWidth(0.17)
    RefreshBtn:SetCallback("OnClick", function()
        self:RedrawTableRows(true)
    end)
    NavHeader:AddChild(RefreshBtn)

    local OptionsIcon = AceGUI:Create("Icon")
    OptionsIcon:SetImage("interface/icons/trade_engineering")
    OptionsIcon:SetRelativeWidth(0.06)
    OptionsIcon:SetImageSize(20,20)
    OptionsIcon:SetCallback("OnClick", function()
        self:InterfaceOptionsFrameOpenToCategory()
        self:CallFrame()
    end)
    NavHeader:AddChild(OptionsIcon)

end

function KLT:CreateTableContentHeader()
    local TblHeader = AceGUI:Create("SimpleGroup")
    TblHeader:SetFullWidth(true)
    TblHeader:SetLayout("Flow")
    frame:AddChild(TblHeader)

    local lbl
    lbl = AceGUI:Create("Label")
    lbl:SetRelativeWidth(0.03)
    lbl:SetText("P.")
    lbl:SetJustifyH("CENTER")
    TblHeader:AddChild(lbl)

    lbl = AceGUI:Create("Label")
    lbl:SetRelativeWidth(0.19)
    lbl:SetText("Boss")
    lbl:SetJustifyH("CENTER")
    TblHeader:AddChild(lbl)

    lbl = AceGUI:Create("Label")
    lbl:SetRelativeWidth(0.41)
    lbl:SetText("Item")
    lbl:SetJustifyH("CENTER")
    TblHeader:AddChild(lbl)

    lbl = AceGUI:Create("Label")
    lbl:SetRelativeWidth(0.19)
    lbl:SetText("Receiver")
    lbl:SetJustifyH("CENTER")
    TblHeader:AddChild(lbl)

    lbl = AceGUI:Create("Label")
    lbl:SetRelativeWidth(0.18)
    lbl:SetText("Time remaining")
    lbl:SetJustifyH("CENTER")
    TblHeader:AddChild(lbl)
end

function KLT:CreateContentScrollFrame()
    -- Content Table
    local ScrollFrameContainer = AceGUI:Create("SimpleGroup")
    ScrollFrameContainer:SetFullWidth(true)
    ScrollFrameContainer:SetHeight(350)--370
    ScrollFrameContainer:SetLayout("Fill")
    frame:AddChild(ScrollFrameContainer)

    -- Content Table * ScrollFrame
    scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    ScrollFrameContainer:AddChild(scrollFrame)
end

function KLT:CreateContentOnFirstLoad()
    filteredTableCount = 0
    self:ScanUserDataGT()
end

function KLT:CreateRows()

    scrollFrame:ReleaseChildren()

    self:DBItemLinkRep()

    local rows, totalPages, currentPage, totalActFilter = self:FilteredTableRows(KLT.ItemTypeSelect,KLT.ReceiverSelect,selectedPage)

    selectedPage = currentPage
    lTotalPages = totalPages
    --filteredTableCount = self:GetCountTableRows(rows)
    filteredTableCount = totalActFilter
    self:SetBottomPageStatus(totalPages, currentPage)
    self:GetBottomStatusTextInfo()

    for i = 1, #rows do

        local itemLink, _, _, _, itemTexture, bindType = self:GetItemValues(rows[i].itemLink,rows[i].itemID)

        if self:SortByInstance(rows[i].instanceID, rows[i].instanceDif) then
            local test = AceGUI:Create("Label")
            test:SetText("|cFF7FFFD4"..rows[i].instance.."|R")
            test:SetRelativeWidth(1)
            test:SetFont("Fonts\\ARIALN.TTF", 16 , "OUTLINE")
            test:SetJustifyH("CENTER")
            scrollFrame:AddChild(test)
        end

        local PosLbl = AceGUI:Create("Label")
        PosLbl:SetText(rows[i].lootID..".")
        PosLbl:SetRelativeWidth(0.04)
        scrollFrame:AddChild(PosLbl)

        local BossLbl = AceGUI:Create("Label")
        BossLbl:SetRelativeWidth(0.26)
        BossLbl:SetText(self:NPCNameHighlight(rows[i].boss))
        BossLbl:SetFont("Fonts\\ARIALN.TTF", 13 , "OUTLINE")
        scrollFrame:AddChild(BossLbl)

        local IconLbl = AceGUI:Create("Icon")
        --IconLbl:SetUserData("itemLink", itemLink)
        IconLbl:SetImage(itemTexture)
        IconLbl:SetRelativeWidth(0.03)
        IconLbl:SetImageSize(20,20)
        scrollFrame:AddChild(IconLbl)

        local ItemLbl = AceGUI:Create("InteractiveLabel")
        ItemLbl:SetUserData("itemLink", itemLink)
        ItemLbl:SetRelativeWidth(0.34)
        ItemLbl:SetText(itemLink)
        ItemLbl:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
            GameTooltip:SetHyperlink(widget:GetUserData("itemLink"))
            GameTooltip:Show()
        end)
        ItemLbl:SetCallback("OnLeave", function()
            GameTooltip:Hide()
        end)
        ItemLbl:SetCallback("OnClick",
                function(_, _,button)
                    self:ShareToActiveChatBox(button,itemLink)
                end)
        scrollFrame:AddChild(ItemLbl)

        local ReceiverLbl = AceGUI:Create("Label")
        ReceiverLbl:SetRelativeWidth(0.18)
        ReceiverLbl:SetText(self:PlayerNameHighlight(rows[i].receiver))
        scrollFrame:AddChild(ReceiverLbl)

        local TimeLbl = AceGUI:Create("Label")
        TimeLbl:SetJustifyH("CENTER")
        TimeLbl:SetRelativeWidth(0.14)
        TimeLbl:SetText(self:TwoHoursRemainingTime(rows[i].time, bindType, rows[i].instanceDif))
        scrollFrame:AddChild(TimeLbl)

    end

    KLT.InstanceIdGui = nil
end

function KLT:CreateBottom()

    local BottomGroup = AceGUI:Create("SimpleGroup")
    BottomGroup:SetFullWidth(true)
    BottomGroup:SetLayout("Flow")
    frame:AddChild(BottomGroup)

    BottomStatusLbl = AceGUI:Create("InteractiveLabel")
    BottomStatusLbl:SetRelativeWidth(0.68)
    BottomStatusLbl:SetText("")
    BottomGroup:AddChild(BottomStatusLbl)

    BottomPageStateLbl = AceGUI:Create("InteractiveLabel")
    BottomPageStateLbl:SetRelativeWidth(0.20)
    BottomPageStateLbl:SetText("")
    BottomPageStateLbl:SetJustifyH("RIGHT")
    BottomGroup:AddChild(BottomPageStateLbl)

    local BackBtn = AceGUI:Create("Button")
    BackBtn:SetText("<")
    BackBtn:SetWidth(40)
    BackBtn:SetCallback("OnClick", function()
        if selectedPage > 1 then
            selectedPage = selectedPage - 1
            self:CreateRows()
        end
    end)
    BottomGroup:AddChild(BackBtn)

    local NextBtn = AceGUI:Create("Button")
    NextBtn:SetText(">")
    NextBtn:SetWidth(40)
    NextBtn:SetCallback("OnClick", function()
        if lTotalPages ~= nil and selectedPage < lTotalPages then
            selectedPage = selectedPage + 1
            self:CreateRows()
        end
    end)
    BottomGroup:AddChild(NextBtn)

end

-- PopUp InstanceFrame
local DontShowToggle, IgnoreMlToggle
function KLT:CreatePopUpConfirmFrame()
    cFrame = AceGUI:Create("Window")
    cFrame:SetTitle("KLT: You are in instance..")
    cFrame:SetWidth(274) --274
    cFrame:SetHeight(200) --100
    cFrame:EnableResize(false)
    cFrame:SetLayout("Flow")

    cFrame:Hide()

    local PopHeader = AceGUI:Create("SimpleGroup")
    PopHeader:SetFullWidth(true)
    PopHeader:SetLayout("Flow")
    cFrame:AddChild(PopHeader)

    local DescribeLbl = AceGUI:Create("InteractiveLabel")
    DescribeLbl:SetFullWidth(true)
    DescribeLbl:SetJustifyH("CENTER")
    DescribeLbl:SetText("Start new item database or continue?...")
    PopHeader:AddChild(DescribeLbl)

    local ButtonPopHeader = AceGUI:Create("SimpleGroup")
    ButtonPopHeader:SetFullWidth(true)
    ButtonPopHeader:SetLayout("Flow")
    cFrame:AddChild(ButtonPopHeader)

    local ContinueBtn = AceGUI:Create("Button")
    ContinueBtn:SetText("Continue")
    ContinueBtn:SetWidth(100)
    ContinueBtn:SetCallback("OnClick", function()
        self:ClosePopUpInstanceFrame()
    end)
    ButtonPopHeader:AddChild(ContinueBtn)

    local NewBtn = AceGUI:Create("Button")
    NewBtn:SetText("Start new database")
    NewBtn:SetWidth(150)
    NewBtn:SetCallback("OnClick", function()
        self:DeleteStorage()
        self:ClosePopUpInstanceFrame()
    end)
    ButtonPopHeader:AddChild(NewBtn)

    DontShowToggle = AceGUI:Create("CheckBox")
    DontShowToggle:SetLabel("Dont show again")
    DontShowToggle:SetDescription("|CFFFFFF01Dont show again for this Raid/Dungeon|R")
    DontShowToggle:SetValue(KLT.DontShowAgain)
    DontShowToggle:SetCallback("OnValueChanged", function(_, _, val)
        KLT.DontShowAgain = val
    end)
    ButtonPopHeader:AddChild(DontShowToggle)

    IgnoreMlToggle = AceGUI:Create("CheckBox")
    IgnoreMlToggle:SetLabel("Use other item receive")
    IgnoreMlToggle:SetDescription("|CFFFFFF01"..KLT.ML_Disabled.."|R")
    IgnoreMlToggle:SetValue(KLT.db.profile.options.receiveMlEv)
    IgnoreMlToggle:SetCallback("OnValueChanged", function(_, _, val)
        KLT.db.profile.options.receiveMlEv = val
    end)
    ButtonPopHeader:AddChild(IgnoreMlToggle)
end

-- API ->
function KLT:SetBottomPageStatus(totalPages, currentPage)
    BottomPageStateLbl:SetText("On page("..self.db.profile.options.viewOnPage..") Page "..currentPage.."/"..totalPages.." ")
end

function KLT:GetBottomStatusTextInfo()
    local systemMessage = ""
    if self:GetMyTrack() then
        systemMessage = "   |cffff0000KLT is stopped!|r"
    elseif self:GetStartTrack() and not self:GetMyTrack() then
        local aws = ""
        local rd = ""

        if self:IsInInstance() == "party" and not self:IsInRaid() then
            rd = "   KLT running (Dungeon)"
        elseif self:IsInRaid() and not self:IsInInstance() ~= "party" then
            rd = "   KLT running (Raid) "
            if self.db.profile.options.awardOnTrade and self:IsInRaid() then
                aws = "with Award by trade."
            elseif self.db.profile.options.ownSystemAward and self:IsInRaid() then
                aws = "->(OwnSystemAward)"
            end
        end
            systemMessage = "   |cff33ff00"..rd..aws.."|r"
    end

    if frame ~= nil then
        BottomStatusLbl:SetText("Items in Storage ("..self:GetCountTableRows(self.db.profile.ItemStore)..") - Shown "
                ..filteredTableCount.." / "..self:GetCountTableRows(self.db.profile.ItemStore)..systemMessage)
    end
end

function KLT:TwoHoursRemainingTime(time, bindType, inst_dif)
    local result = ""

    local addTwoHours = (time + (2*60*60)) - GetServerTime()
    local min = addTwoHours / 60,000
    local remainingTime = string.format("%02d", min)

    if KLT.BindTypes[bindType] then
        if self:DebugNilInt(inst_dif) > 1 then
            if addTwoHours <= 0 then
                result = "|CFFFF0303Trade timed out|R"
            else
                result = "|CFFFFFF01"..remainingTime.." min|R"
            end
        else
            result = "|cff888888Non-tradeable|R"
        end
    else
        result = "|cFFEEE8AA BOE|R"
    end
    return result
end

function KLT:NPCNameHighlight(npc)
    if npc ~= "Trash" then
        return "|cffffcc00"..npc.."|r"
    else
        return "|cFF808080Trash|r"
    end
end

function KLT:PlayerNameHighlight(receiver)
    if receiver == KLT.playerName then
        return "|cff33ff00"..receiver.."|r"
    else
        return receiver
    end
end

function KLT:ShareToActiveChatBox(button, link)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            if ChatFrame1EditBox:IsVisible() then
                ChatFrame1EditBox:Insert(link)
            end
        end
    end
end

function KLT:ScanUserDataGT()
    if scrollFrame ~= nil then

        for i = 1, #self:ItemStore() do
            local itemLink, _, _, _, itemTexture = self:GetItemValues(self:ItemStore()[i].itemLink,self:ItemStore()[i].itemID)

            local IconLbl = AceGUI:Create("Icon")
            IconLbl:SetUserData("itemLink", itemLink)
            IconLbl:SetImage(itemTexture)
            scrollFrame:AddChild(IconLbl)

            local ItemLbl = AceGUI:Create("InteractiveLabel")
            ItemLbl:SetUserData("itemLink", itemLink)
            scrollFrame:AddChild(ItemLbl)

        end

        scrollFrame:ReleaseChildren()
    end
end

function KLT:SetIgnoreMlToggle()
    if cFrame ~= nil then
        IgnoreMlToggle:SetValue(KLT.db.profile.options.receiveMlEv)
    end
end

function KLT:SetDontShowToggle()
    if cFrame ~= nil then
        DontShowToggle:SetValue(KLT.DontShowAgain)
    end
end

function KLT:CallFrame()
    if frame == nil then
        self:CreateFrame()
        frame:Show()
    elseif frame:IsShown() then
        frame:Hide()
        elseif not frame:IsShown() then
        frame:Show()
    end
end

function KLT:RedrawTableRows(permit)
    RefreshBtn:SetText("Refresh")
    if self.db.profile.options.autoUpdate or permit then
        if scrollFrame ~= nil then
            self:CreateRows()
        end
    end
end

function KLT:CallPopUpInstanceFrame()
    if cFrame == nil then
        self:CreatePopUpConfirmFrame()
        cFrame:Show()
    elseif not cFrame:IsShown() then
        cFrame:Show()
    end
end

function KLT:ClosePopUpInstanceFrame()
    if cFrame ~= nil then
        if cFrame:IsShown() then
            cFrame:Hide()
        end
    end
end