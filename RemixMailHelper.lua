local addonName, addonTable = ...
addonName = "Remix Mail Helper"

local function RetrieveItemsFromMail()
    local numItems = GetInboxNumItems()

    local function ProcessNextMail(mailIndex, attachmentIndex)
        if mailIndex > numItems then
            return
        end

        local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
        if itemLink then
            local itemID = select(2, strsplit(":", itemLink))
            itemID = tonumber(itemID)
            if itemID and (itemID ~= 224408 and itemID ~= 224407 and itemID ~= 220763) then
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SHOW" then
        if not RetrieveItemsButton then
            RetrieveItemsButton = CreateFrame("Button", "RetrieveItemsButton", MailFrame, "UIPanelButtonTemplate")
            RetrieveItemsButton:SetSize(160, 30)
            RetrieveItemsButton:SetPoint("TOP", MailFrame, "TOP", 0, -30)
            RetrieveItemsButton:SetText("Retrieve Items")
            RetrieveItemsButton:SetScript("OnClick", RetrieveItemsFromMail)
        end
    end
end)
