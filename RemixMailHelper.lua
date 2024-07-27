local addonName, addonTable = ...
addonName = "Remix Mail Helper"

local XP_Calculation = _G.XP_Calculation
XP_Calculation:Initialize({
    [224407] = "Normal",
    [224408] = "Heroic",
    [220763] = "Raid"
})

local InfoWindow = addonTable.InfoWindow

local threadsItemIDs = {
    219264, 219273, 219282, 219261, 219270, 219279,
    219258, 219267, 219276, 219263, 219272, 219281,
    219260, 219269, 219278, 219257, 219266, 219275,
    219262, 219271, 219280, 219259, 219268, 219277,
    219256, 219265, 219274, 210989, 210985, 217722,
    210983, 210982, 210990, 210987, 210984, 210986
}

local xpBonusItemIDs = {
    [224407] = "Normal",
    [224408] = "Heroic",
    [220763] = "Raid"
}

local gemItemIDs = {
    221977, 218003, 219389, 220371, 219386, 216632, 219516, 220367,
    220211, 218046, 216648, 210715, 220117, 218005, 216651, 210714,
    216663, 218110, 216650, 211109, 216711, 218082, 212749, 210717,
    216671, 216630, 212916, 210716, 220120, 218045, 217957, 210681,
    219878, 218108, 216626, 221982, 218044, 212362, 216695, 217983,
    216624, 216631, 212758, 217989, 216647, 218043, 212760, 216629,
    216627, 218004, 216628, 218109, 217961, 219818, 219944, 217903,
    219523, 216649, 219801, 217964, 219777, 212694, 219527, 212759,
    217927, 212366, 219817, 219452, 216625, 212361, 212365, 217907
}

function addonTable.CountItemsInMail()
    local numItems = GetInboxNumItems()
    local threadsCount = 0
    local itemCount = 0
    local xpCounts = { Normal = 0, Heroic = 0, Raid = 0 }

    for mailIndex = 1, numItems do
        for attachmentIndex = 1, ATTACHMENTS_MAX_RECEIVE do
            local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
            if itemLink then
                local itemID = select(2, strsplit(":", itemLink))
                itemID = tonumber(itemID)
                
                local isThread = false
                for _, id in ipairs(threadsItemIDs) do
                    if itemID == id then
                        isThread = true
                        break
                    end
                end
                
                local isXPItem = false
                local quality = xpBonusItemIDs[itemID]
                if quality then
                    xpCounts[quality] = xpCounts[quality] + 1
                    isXPItem = true
                end
                
                if isThread then
                    threadsCount = threadsCount + 1
                elseif not isXPItem then
                    itemCount = itemCount + 1
                end
            end
        end
    end
    return threadsCount, itemCount, xpCounts
end

local function RetrieveItemsFromMail(filterFunc)
    local co

    local function StartLootCoroutine()
        co = coroutine.create(function()
            local numItems = GetInboxNumItems()
            local looted
            repeat
                looted = false
                for mailIndex = 1, numItems do
                    for attachmentIndex = 1, ATTACHMENTS_MAX_RECEIVE do
                        local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
                        if itemLink then
                            local itemID = select(2, strsplit(":", itemLink))
                            itemID = tonumber(itemID)
                            
                            local isXPBonusItem = xpBonusItemIDs[itemID] ~= nil
                            local isThreadItem = false
                            for _, threadID in ipairs(threadsItemIDs) do
                                if itemID == threadID then
                                    isThreadItem = true
                                    break
                                end
                            end
                            
                            if itemID and ((filterFunc and filterFunc(itemID)) or (not filterFunc and not isXPBonusItem and not isThreadItem)) then
                                TakeInboxItem(mailIndex, attachmentIndex)
                                looted = true
                                coroutine.yield()
                            end
                        end
                    end
                end
            until not looted
            InfoWindow:UpdateInfoText()
        end)
        
        local frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function()
            if coroutine.status(co) ~= "dead" then
                local success, result = coroutine.resume(co)
                if not success then
                    print("Error in coroutine: " .. result)
                end
            else
                frame:SetScript("OnUpdate", nil)
            end
        end)
    end

    StartLootCoroutine()
end

local function FilterThreads(itemID)
    for _, id in ipairs(threadsItemIDs) do
        if itemID == id then
            return true
        end
    end
    return false
end

local function FilterXPItems(itemID)
    return xpBonusItemIDs[itemID] ~= nil
end

local function FilterGems(itemID)
    for _, id in ipairs(gemItemIDs) do
        if itemID == id then
            return true
        end
    end
    return false
end

local function SnapButtonFrameToMailFrame()
    if MailFrame and ButtonFrame then
        ButtonFrame:ClearAllPoints()
        ButtonFrame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 10, 0)
    end
end

local function CreateButtonFrame()
    if not ButtonFrame then
        ButtonFrame = CreateFrame("Frame", "ButtonFrame", MailFrame, "BasicFrameTemplateWithInset")
        ButtonFrame:SetSize(150, 210)  -- Adjusted size to accommodate additional button
        ButtonFrame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 10, 0)
        ButtonFrame:SetMovable(true)
        ButtonFrame:EnableMouse(true)
        ButtonFrame:RegisterForDrag("LeftButton")
        ButtonFrame:SetScript("OnDragStart", ButtonFrame.StartMoving)
        ButtonFrame:SetScript("OnDragStop", ButtonFrame.StopMovingOrSizing)

        ButtonFrame.title = ButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        ButtonFrame.title:SetPoint("CENTER", ButtonFrame.TitleBg, "CENTER", 0, 0)
        ButtonFrame.title:SetText("Mail Helper")
    end
end

local function ShowButtonFrame()
    if ButtonFrame then
        ButtonFrame:Show()
        SnapButtonFrameToMailFrame()
    end
end

local function HideButtonFrame()
    if ButtonFrame then
        ButtonFrame:Hide()
    end
end

local function CreateButtons()
    if not RetrieveThreadsButton then
        RetrieveThreadsButton = CreateFrame("Button", "RetrieveThreadsButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveThreadsButton:SetSize(120, 30)
        RetrieveThreadsButton:SetPoint("TOP", ButtonFrame, "TOP", 0, -30)
        RetrieveThreadsButton:SetText("Retrieve Threads")
        RetrieveThreadsButton:SetScript("OnClick", function() RetrieveItemsFromMail(FilterThreads) end)
    end

    if not RetrieveItemsButton then
        RetrieveItemsButton = CreateFrame("Button", "RetrieveItemsButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveItemsButton:SetSize(120, 30)
        RetrieveItemsButton:SetPoint("TOP", RetrieveThreadsButton, "BOTTOM", 0, -5)
        RetrieveItemsButton:SetText("Retrieve Items")
        RetrieveItemsButton:SetScript("OnClick", function() RetrieveItemsFromMail() end)
    end

    if not RetrieveXPButton then
        RetrieveXPButton = CreateFrame("Button", "RetrieveXPButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveXPButton:SetSize(120, 30)
        RetrieveXPButton:SetPoint("TOP", RetrieveItemsButton, "BOTTOM", 0, -5)
        RetrieveXPButton:SetText("Retrieve XP")
        RetrieveXPButton:SetScript("OnClick", function()
            StaticPopupDialogs["CONFIRM_LOOT_XP_ITEMS"] = {
                text = "Are you sure you want to loot all XP items?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    RetrieveItemsFromMail(FilterXPItems)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("CONFIRM_LOOT_XP_ITEMS")
        end)
    end

    if not RetrieveGemsButton then
        RetrieveGemsButton = CreateFrame("Button", "RetrieveGemsButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveGemsButton:SetSize(120, 30)
        RetrieveGemsButton:SetPoint("TOP", RetrieveXPButton, "BOTTOM", 0, -5)
        RetrieveGemsButton:SetText("Retrieve Gems")
        RetrieveGemsButton:SetScript("OnClick", function() RetrieveItemsFromMail(FilterGems) end)
    end

    if not InfoButton then
        InfoButton = CreateFrame("Button", "InfoButton", ButtonFrame, "UIPanelButtonTemplate")
        InfoButton:SetSize(120, 30)
        InfoButton:SetPoint("TOP", RetrieveGemsButton, "BOTTOM", 0, -5)
        InfoButton:SetText("XP Calculation")
        InfoButton:SetScript("OnClick", function() InfoWindow:ToggleInfoText() end)
    end
end

local mailFrameLastPos = { MailFrame:GetLeft(), MailFrame:GetTop() }

local function CheckMailFramePosition()
    local currentPos = { MailFrame:GetLeft(), MailFrame:GetTop() }
    if mailFrameLastPos[1] ~= currentPos[1] or mailFrameLastPos[2] ~= currentPos[2] then
        SnapButtonFrameToMailFrame()
        mailFrameLastPos = currentPos
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SHOW" then
        CreateButtonFrame()
        CreateButtons()
        ShowButtonFrame()
        InfoWindow:CreateInfoText()
        InfoWindow:UpdateInfoText()
        self:SetScript("OnUpdate", CheckMailFramePosition)
    elseif event == "MAIL_INBOX_UPDATE" then
        InfoWindow:UpdateInfoText()
    elseif event == "MAIL_CLOSED" then
        HideButtonFrame()
        self:SetScript("OnUpdate", nil)
    end
end)

function InfoWindow:CreateInfoText()
    if not InfoTextFrame then
        InfoTextFrame = CreateFrame("Frame", "InfoTextFrame", MailFrame)
        InfoTextFrame:SetSize(300, 100)
        InfoTextFrame:SetPoint("TOPLEFT", ButtonFrame, "BOTTOMLEFT", 0, -10)
        
        InfoTextFrame.mainInfoText = InfoTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        InfoTextFrame.mainInfoText:SetPoint("TOPLEFT", InfoTextFrame, "TOPLEFT", 10, -10)
        InfoTextFrame.mainInfoText:SetJustifyH("LEFT")
        InfoTextFrame.mainInfoText:SetJustifyV("TOP")
        InfoTextFrame.mainInfoText:SetTextColor(1, 1, 1, 1)

        InfoTextFrame.experimentalInfoText = InfoTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        InfoTextFrame.experimentalInfoText:SetPoint("TOPLEFT", InfoTextFrame.mainInfoText, "BOTTOMLEFT", 0, -10)
        InfoTextFrame.experimentalInfoText:SetJustifyH("LEFT")
        InfoTextFrame.experimentalInfoText:SetJustifyV("TOP")
        InfoTextFrame.experimentalInfoText:SetTextColor(1, 1, 1, 1)
        InfoTextFrame.experimentalInfoText:Hide()
    end
end
