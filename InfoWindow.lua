local addonName, addonTable = ...
local InfoWindow = {}
local XP_Calculation = _G.XP_Calculation

local infoTextShown = true

function InfoWindow:CreateInfoText()
    if not InfoTextFrame then
        InfoTextFrame = CreateFrame("Frame", "InfoTextFrame", MailFrame)
        InfoTextFrame:SetSize(300, 200)
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
Tokens: %d]]):format(threadsCount, itemCount, xpCounts.Heroic)

        InfoTextFrame.mainInfoText:SetText(mainInfoText)

        local currentLevel, currentXP = UnitLevel("player"), UnitXP("player")
        local xpBarProgress = currentXP / UnitXPMax("player")
        local cloakBonusXP = XP_Calculation:GetCloakBonusXP()

        local requiredHCTokens, missingHCTokens = XP_Calculation:CalculateHCTokensOnly(currentLevel, currentXP, xpCounts, cloakBonusXP)
        local overflowHCXP = XP_Calculation:CalculateOverflowXP(currentLevel, missingHCTokens, "BlueXPToken", cloakBonusXP)
        local openMailHC = missingHCTokens <= 0 and "|cff00FF00READY|r" or "|cffFF0000NOT READY|r"

        local experimentalInfoText = ([[

|cffff00ffXP Calculation|r
Current Level: %d
XP Bar Progress: %.2f%%
Cloak Bonus XP: %.2f%%
Missing Tokens: %.0f
Ready to collect: %s

|cffffff00Info|r
Run HC dungeons until collect is |cff00FF00READY|r,
should be around level 36/37.
You need around 140%% bonus xp.
]]):format(
            currentLevel, xpBarProgress * 100, cloakBonusXP,
            missingHCTokens, openMailHC
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
return InfoWindow
