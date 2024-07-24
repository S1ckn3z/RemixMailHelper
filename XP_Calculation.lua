local XP_Calculation = {}

local XP_Table = _G.XP_Table
local xpBonusItemIDs

function XP_Calculation:Initialize(xpBonusIDs)
    xpBonusItemIDs = xpBonusIDs
end

function XP_Calculation:GetRequiredXP(level)
    for _, data in ipairs(XP_Table) do
        if data.Lvl == level then
            return data.RequiredXP
        end
    end
    return nil
end

function XP_Calculation:GetXpTokens(level)
    for _, data in ipairs(XP_Table) do
        if data.Lvl == level then
            return data.BlueXPToken, data.EpicXPToken
        end
    end
    return 0, 0
end

function XP_Calculation:CountXpBonusItemsInMail()
    local xpCounts = { Normal = 0, Heroic = 0, Raid = 0 }
    local numItems = GetInboxNumItems()

    for mailIndex = 1, numItems do
        for attachmentIndex = 1, ATTACHMENTS_MAX_RECEIVE do
            local itemLink = GetInboxItemLink(mailIndex, attachmentIndex)
            if itemLink then
                local itemID = select(2, strsplit(":", itemLink))
                itemID = tonumber(itemID)
                local quality = xpBonusItemIDs[itemID]
                if quality then
                    xpCounts[quality] = xpCounts[quality] + 1
                end
            end
        end
    end

    return xpCounts
end

function XP_Calculation:GetCloakBonusXP()
    local cloakBonusXP = 0
    for i = 1, 40 do
        local buffData = C_UnitAuras.GetBuffDataByIndex("player", i, "HELPFUL")
        if not buffData then break end
        if buffData.spellId == 440393 then
            cloakBonusXP = tonumber(buffData.points[10]) or 0
            break
        end
    end
    return cloakBonusXP
end

function XP_Calculation:MailTokenLevel(currentLevel, currentXP, xpTokensInMail, cloakBonusXP)
    local remainingDungeonTokens = 39
    local remainingRaidTokens = 10
    local currentXP = currentXP
    for i, v in ipairs(XP_Table) do 
        if v.Lvl >= currentLevel then
            local blueXpValue = v.BlueXPToken * cloakBonusXP / 100
            local epicXpValue = v.EpicXPToken * cloakBonusXP / 100
            while (currentXP < v.RequiredXP) do
                if remainingDungeonTokens > 0 then
                    currentXP = currentXP + blueXpValue
                    remainingDungeonTokens = remainingDungeonTokens - 1
                elseif remainingRaidTokens > 0 then
                    currentXP = currentXP + remainingRaidTokens
                    remainingRaidTokens = remainingRaidTokens - 1
                else
                    return v.Lvl, 0
                end
            end

            currentXP = currentXP - v.RequiredXP
        end
    end

    return 70, remainingDungeonTokens + remainingRaidTokens
end

_G.XP_Calculation = XP_Calculation
return XP_Calculation
