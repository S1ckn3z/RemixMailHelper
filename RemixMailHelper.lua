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
    210983, 210982, 210990
}

local xpBonusItemIDs = {
    [224407] = "Normal",
    [224408] = "Heroic",
    [220763] = "Raid"
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
    local numItems = GetInboxNumItems()

    local function ProcessNextMail(mailIndex, attachmentIndex)
        if mailIndex > numItems then
            InfoWindow:UpdateInfoText()
            return
        end

        local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
        if itemLink then
            local itemID = select(2, strsplit(":", itemLink))
            itemID = tonumber(itemID)
            local isXPBonusItem = xpBonusItemIDs[itemID] ~= nil
            if itemID and not isXPBonusItem and (not filterFunc or filterFunc(itemID)) then
                TakeInboxItem(mailIndex, attachmentIndex)
            end
        end

        attachmentIndex = attachmentIndex + 1
        if attachmentIndex > ATTACHMENTS_MAX_RECEIVE then
            mailIndex = mailIndex + 1
            attachmentIndex = 1
        end
        C_Timer.After(0.1, function() ProcessNextMail(mailIndex, attachmentIndex) end)
    end

    ProcessNextMail(1, 1)
end

local function FilterThreads(itemID)
    for _, id in ipairs(threadsItemIDs) do
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
        ButtonFrame:SetSize(150, 140)
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
    if not RetrieveItemsButton then
        RetrieveItemsButton = CreateFrame("Button", "RetrieveItemsButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveItemsButton:SetSize(120, 30)
        RetrieveItemsButton:SetPoint("TOP", ButtonFrame, "TOP", 0, -30)
        RetrieveItemsButton:SetText("Retrieve Items")
        RetrieveItemsButton:SetScript("OnClick", function() RetrieveItemsFromMail() end)
    end

    if not RetrieveThreadsButton then
        RetrieveThreadsButton = CreateFrame("Button", "RetrieveThreadsButton", ButtonFrame, "UIPanelButtonTemplate")
        RetrieveThreadsButton:SetSize(120, 30)
        RetrieveThreadsButton:SetPoint("TOP", RetrieveItemsButton, "BOTTOM", 0, -5)
        RetrieveThreadsButton:SetText("Retrieve Threads")
        RetrieveThreadsButton:SetScript("OnClick", function() RetrieveItemsFromMail(FilterThreads) end)
    end

    if not InfoButton then
        InfoButton = CreateFrame("Button", "InfoButton", ButtonFrame, "UIPanelButtonTemplate")
        InfoButton:SetSize(120, 30)
        InfoButton:SetPoint("TOP", RetrieveThreadsButton, "BOTTOM", 0, -5)
        InfoButton:SetText("Show More Info")
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