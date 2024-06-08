local addonName, addonTable = ...
addonName = "Remix Mail Helper"

-- Thread ids
local threadsItemIDs = {
    219264, 219273, 219282, 219261, 219270, 219279,
    219258, 219267, 219276, 219263, 219272, 219281,
    219260, 219269, 219278, 219257, 219266, 219275,
    219262, 219271, 219280, 219259, 219268, 219277,
    219256, 219265, 219274
}

-- XP Bonis ids
local xpBonusItemIDs = {
    [224407] = "Normal",
    [224408] = "Heroic",
    [220763] = "Raid"
}

local function CountItemsInMail()
    local numItems = GetInboxNumItems()
    local threadsCount = 0
    local xpCounts = { Normal = 0, Heroic = 0, Raid = 0 }

    for mailIndex = 1, numItems do
        for attachmentIndex = 1, ATTACHMENTS_MAX_RECEIVE do
            local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
            if itemLink then
                local itemID = select(2, strsplit(":", itemLink))
                itemID = tonumber(itemID)
                for _, id in ipairs(threadsItemIDs) do
                    if itemID == id then
                        threadsCount = threadsCount + 1
                        break
                    end
                end
                local quality = xpBonusItemIDs[itemID]
                if quality then
                    xpCounts[quality] = xpCounts[quality] + 1
                end
            end
        end
    end

    return threadsCount, xpCounts
end

local function UpdateItemCountFrame()
    local threadsCount, xpCounts = CountItemsInMail()
    if ItemCountFrame then
        ItemCountFrame.threadsText:SetText("Threads: " .. threadsCount)
        local xpText = "XP Boni: "
        local first = true
        for quality, count in pairs(xpCounts) do
            if count > 0 then
                if not first then
                    xpText = xpText .. " | "
                end
                xpText = xpText .. quality .. ": " .. count
                first = false
            end
        end
        if first then
            ItemCountFrame.xpBonusText:Hide()
        else
            ItemCountFrame.xpBonusText:SetText(xpText)
            ItemCountFrame.xpBonusText:Show()
        end
    end
end

local function RetrieveItemsFromMail(filterFunc)
    local numItems = GetInboxNumItems()

    local function ProcessNextMail(mailIndex, attachmentIndex)
        if mailIndex > numItems then
            UpdateItemCountFrame()
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

local function CreateItemCountFrame()
    if not ItemCountFrame then
        ItemCountFrame = CreateFrame("Frame", "ItemCountFrame", MailFrame)
        ItemCountFrame:SetSize(200, 20)
        ItemCountFrame:SetPoint("TOP", MailFrame, "TOP", 0, 20)

        ItemCountFrame.threadsText = ItemCountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ItemCountFrame.threadsText:SetPoint("LEFT", ItemCountFrame, "LEFT", 10, 0)
        ItemCountFrame.threadsText:SetText("Threads: 0")

        ItemCountFrame.xpBonusText = ItemCountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ItemCountFrame.xpBonusText:SetPoint("LEFT", ItemCountFrame.threadsText, "RIGHT", 20, 0)
        ItemCountFrame.xpBonusText:SetText("")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SHOW" then
        CreateItemCountFrame()
        UpdateItemCountFrame()
        if not RetrieveItemsButton then
            RetrieveItemsButton = CreateFrame("Button", "RetrieveItemsButton", MailFrame, "UIPanelButtonTemplate")
            RetrieveItemsButton:SetSize(120, 25)
            RetrieveItemsButton:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 55, -30)
            RetrieveItemsButton:SetText("Retrieve Items")
            RetrieveItemsButton:SetScript("OnClick", function() RetrieveItemsFromMail() end)
        end
        if not RetrieveThreadsButton then
            RetrieveThreadsButton = CreateFrame("Button", "RetrieveThreadsButton", MailFrame, "UIPanelButtonTemplate")
            RetrieveThreadsButton:SetSize(120, 25)
            RetrieveThreadsButton:SetPoint("LEFT", RetrieveItemsButton, "RIGHT", 10, 0)
            RetrieveThreadsButton:SetText("Retrieve Threads")
            RetrieveThreadsButton:SetScript("OnClick", function() RetrieveItemsFromMail(FilterThreads) end)
        end
    elseif event == "MAIL_INBOX_UPDATE" then
        UpdateItemCountFrame()
    end
end)
