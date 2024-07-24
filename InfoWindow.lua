local addonName, addonTable = ...
local InfoWindow = {}
local XP_Calculation = _G.XP_Calculation

local infoTextShown = true

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

function InfoWindow:UpdateInfoText()
    if InfoTextFrame then
        local threadsCount, itemCount, xpCounts = addonTable.CountItemsInMail()

        local mainInfoText = ([[Threads: %d
Items: %d
HC Tokens in Mail: %d
Raid Tokens in Mail: %d]]):format(threadsCount, itemCount, xpCounts.Heroic, xpCounts.Raid)

        InfoTextFrame.mainInfoText:SetText(mainInfoText)

        local currentLevel, currentXP = UnitLevel("player"), UnitXP("player")
        local xpBarProgress = currentXP / UnitXPMax("player")
        local cloakBonusXP = XP_Calculation:GetCloakBonusXP()

        local requiredDungeonTokens, missingDungeonTokens, requiredRaidTokens, missingRaidTokens = XP_Calculation:CalculateTokens(currentLevel, currentXP, xpCounts, cloakBonusXP)

        local maxLevel, remainingTokens = XP_Calculation:MailTokenLevel(currentLevel, currentXP, xpCounts, cloakBonusXP)
        local openMail = "|cffFFff00MAYBE|r" 
        if maxLevel < 70 then
            openMail = "|cffFF0000NO|r"
        elseif remainingTokens > 2 then
            openMail = "|cff00FF00YES|r"
        end

        local experimentalInfoText = ([[

|cffff00ffXP Calculation|r
Current Level: %d
XP Bar Progress: %.2f%%
Cloak Bonus XP: %.2f%%

|cff00ffffTokens|r
Estimated Max Level: %.2f
Extra Tokens: %.2f
Open Mail? %s]]):format(
            currentLevel, xpBarProgress * 100, cloakBonusXP,
            maxLevel, remainingTokens, openMail
        )

        InfoTextFrame.experimentalInfoText:SetText(experimentalInfoText)
    end
end

function InfoWindow:ToggleInfoText()
    if InfoTextFrame then
        if InfoTextFrame.experimentalInfoText:IsShown() then
            InfoTextFrame.experimentalInfoText:Hide()
        else
            InfoTextFrame.experimentalInfoText:Show()
        end
    end
end

function InfoWindow:ShowInfoText()
    if InfoTextFrame then
        InfoTextFrame:Show()
        infoTextShown = true
        self:UpdateInfoText()
    end
end

function InfoWindow:HideInfoText()
    if InfoTextFrame then
        InfoTextFrame:Hide()
    end
end

function InfoWindow:IsInfoTextShown()
    return infoTextShown
end



addonTable.InfoWindow = InfoWindow
