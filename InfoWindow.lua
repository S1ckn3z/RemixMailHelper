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

        local overflowDungeonXP = XP_Calculation:CalculateOverflowXP(currentLevel, missingDungeonTokens, "BlueXPToken", cloakBonusXP)
        local overflowRaidXP = XP_Calculation:CalculateOverflowXP(currentLevel, missingRaidTokens, "EpicXPToken", cloakBonusXP)

        local openMailDungeon = missingDungeonTokens <= 0 and "|cff00FF00YES|r" or "|cffFF0000NO|r"
        local openMailRaid = requiredRaidTokens > 0 and (missingRaidTokens <= 0 and "|cff00FF00YES|r" or "|cffFF0000NO|r") or ""
        local openMail = (missingDungeonTokens <= 0 and missingRaidTokens <= 0) and "|cff00FF00YES|r" or "|cffFF0000NO|r"

        local experimentalInfoText = ([[

|cffff00ffXP Calculation|r
Current Level: %d
XP Bar Progress: %.2f%%
Cloak Bonus XP: %.2f%%

|cff00ffffHC Dungeon Tokens|r
Required: %.2f
Missing: %.2f
Open Mail? %s
Overflow XP: %d

|cffff8000Raid Tokens|r
Required: %.2f
Missing: %.2f
Open Mail? %s
Overflow XP: %d]]):format(
            currentLevel, xpBarProgress * 100, cloakBonusXP,
            requiredDungeonTokens, missingDungeonTokens, openMailDungeon, overflowDungeonXP,
            requiredRaidTokens, missingRaidTokens, openMailRaid, overflowRaidXP
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
