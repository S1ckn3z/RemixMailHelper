local addonName, addonTable = ...
addonName = "Remix Mail Helper"

local debugEnabled = false

local function AddToDebugLog(message)
    if debugEnabled and DebugFrame then
        if not DebugFrame:IsShown() then
            DebugFrame:Show()
        end
        DebugFrameEditBox:SetText(DebugFrameEditBox:GetText() .. message .. "\n")
    end
end

local function RetrieveItemsFromMail()
    AddToDebugLog("Retrieving items from mail...")
    local numItems = GetInboxNumItems()
    AddToDebugLog("Number of mails: " .. numItems)

    local function ProcessNextMail(mailIndex, attachmentIndex)
        if mailIndex > numItems then
            AddToDebugLog("All mails processed.")
            return
        end

        local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
        if itemLink then
            local itemID = select(2, strsplit(":", itemLink))
            itemID = tonumber(itemID)
            AddToDebugLog("Found itemID: " .. (itemID or "nil"))
            if itemID and (itemID ~= 224408 and itemID ~= 224407 and itemID ~= 220763) then
                TakeInboxItem(mailIndex, attachmentIndex)
                AddToDebugLog("Looting itemID: " .. itemID .. " from mail " .. mailIndex .. " item " .. attachmentIndex)
            else
                AddToDebugLog("Skipping itemID: " .. (itemID or "nil") .. " from mail " .. mailIndex .. " item " .. attachmentIndex)
            end
        else
            AddToDebugLog("No itemLink found for mail " .. mailIndex .. " item " .. attachmentIndex)
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

local function ToggleDebugLogging()
    debugEnabled = not debugEnabled
    if debugEnabled then
        AddToDebugLog("Debug logging enabled.")
        print("Remix Mail Helper: Debug logging enabled.")
    else
        print("Remix Mail Helper: Debug logging disabled.")
    end
end

SLASH_RMH1 = "/rmh"
SlashCmdList["RMH"] = function(msg)
    if msg == "debug" then
        ToggleDebugLogging()
    else
        print("Usage: /rmh debug - Toggle debug logging")
    end
end
