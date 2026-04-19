-- MyFirstAddon.lua
-- A basic WoW addon template for patch 12.0

local addonName, addon = ...
local CHANNEL_NAME = "Pookick"
local ADDON_NAME = "Pookick"

PooseCommandDB = PooseCommandDB or {}
-- Create main frame
local frame = CreateFrame("Frame")

-- Initialize function
local function Initialize()
    print("")
end

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            Initialize()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
    end
end

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", OnEvent)

-- Slash command 1: /editmode
SLASH_EDITMODE1 = "/editmode"
SLASH_EDITMODE2 = "/edit"
SLASH_EDITMODE3 = "/em"
SlashCmdList["EDITMODE"] = function(msg)
    ShowUIPanel(EditModeManagerFrame)
end
-- Slash command 4: /rl
SLASH_RL1 = "/rl"
SlashCmdList["RL"] = function(msg)
  C_UI.Reload()
end

-- Slash command 4: /cd
SLASH_CD1 = "/cd"
SLASH_CD2 = "/cooldown"
SlashCmdList["CD"] = function(msg)
    CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
end

-- Slash command 4: /pull
SLASH_PULL1 = "/pull"
SlashCmdList["PULL"] = function(seconds)
  C_PartyInfo.DoCountdown(seconds)
end

SLASH_POOCOMM1 = "/poocomm"
SlashCmdList["POOCOMM"] = function(msg)
    print("Commands:\n")
    print("Edit mode:")
    print("/em /edit /editmode\n")
    print(" ")
    print("Cooldown Manager:")
    print("/cd /cooldown")
    print(" ")
    print("Reload:")
    print("/rl")
    print(" ")
    print("Pull:")
    print("/pull X")
end


-- CD Tracking test
-- WoW class colours (same as RAID_CLASS_COLORS)
--------------------------------------------------------------------------------
local CLASS_COLORS = {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
    MONK        = { r = 0.00, g = 1.00, b = 0.60 },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER      = { r = 0.20, g = 0.58, b = 0.50 },
}
 
local DEFAULT_COLOR = { r = 1, g = 1, b = 1 }
 
-- Get class colour for a player name by scanning group/raid units
--------------------------------------------------------------------------------
local function GetClassColorForPlayer(name)
    local prefix = IsInRaid() and "raid" or "party"
    local count  = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers()
 
    -- Also check "player" itself
    local units = { "player" }
    for i = 1, count do
        table.insert(units, prefix .. i)
    end

    for _, unit in ipairs(units) do
        local unitName = GetUnitName(unit, false)
        if unitName and unitName:lower() == name:lower() then
            local _, classToken = UnitClass(unit)
            if classToken then
                return CLASS_COLORS[classToken] or DEFAULT_COLOR, classToken
            end
        end
    end
 
    return DEFAULT_COLOR, nil
end
 
-- Helper: wrap a name in its class colour for chat output
--------------------------------------------------------------------------------
local function ColoredName(name)
    local color = GetClassColorForPlayer(name)
    return string.format("|cff%02x%02x%02x%s|r",
        color.r * 255, color.g * 255, color.b * 255, name)
end
 
-- Bar setup
--------------------------------------------------------------------------------
local bar = CreateFrame("Frame", ADDON_NAME .. "Bar", UIParent)
bar:SetSize(300, 30)
bar:SetFrameStrata("MEDIUM")
 
if PooseCommandDB.x and PooseCommandDB.y then
    bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", PooseCommandDB.x, PooseCommandDB.y)
else
    bar:SetPoint("TOP", UIParent, "TOP", 0, -200)
end
 
local bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.7)

local fill = bar:CreateTexture(nil, "ARTWORK")
fill:SetPoint("TOPLEFT",    bar, "TOPLEFT",    1, -1)
fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 1,  1)
fill:SetWidth(298)
fill:SetColorTexture(0.2, 0.8, 0.2, 1)
 
local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetAllPoints()
label:SetJustifyH("CENTER")
label:SetText("")
 
-- Sender name tag on the left of the bar
local senderLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
senderLabel:SetPoint("LEFT", bar, "LEFT", 6, 0)
senderLabel:SetJustifyH("LEFT")
senderLabel:SetText("")
 
bar:Hide()
 
bar:SetMovable(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
 
bar:SetScript("OnDragStart", function(self) self:StartMoving() end)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    PooseCommandDB.x = self:GetLeft()
    PooseCommandDB.y = self:GetTop() - UIParent:GetHeight()
end)
 
--------------------------------------------------------------------------------
-- Countdown state
--------------------------------------------------------------------------------
local countdown = { active = false, total = 0, remaining = 0, elapsed = 0 }
 
-- Track the colour of whoever started the current countdown
local barColor = { r = 0.2, g = 0.8, b = 0.2 }
 
bar:SetScript("OnUpdate", function(self, delta)
    if not countdown.active then return end
 
    countdown.elapsed   = countdown.elapsed + delta
    countdown.remaining = countdown.total - countdown.elapsed
 
    if countdown.remaining <= 0 then
        countdown.remaining = 0
        countdown.active    = false
        fill:SetWidth(bar:GetWidth() - 2)
        fill:SetColorTexture(0.8, 0.1, 0.1, 1)
        label:SetText("Ready")
        return
    end
 
    -- elapsed ratio: 0 at start → 1 at end (bar fills left to right)
    local ratio = countdown.elapsed / countdown.total
    local maxW  = bar:GetWidth() - 2
    fill:SetWidth(math.max(1, maxW * ratio))
 
    -- Fade from class colour → dark red as time runs out
    fill:SetColorTexture(
        barColor.r * (1 - ratio) + 0.8 * ratio,
        barColor.g * (1 - ratio) + 0.1 * ratio,
        barColor.b * (1 - ratio) + 0.1 * ratio,
        1
    )
 
    label:SetText(string.format("%.1f", countdown.remaining))
end)
 
--------------------------------------------------------------------------------
-- Start countdown, coloured by the sender's class
--------------------------------------------------------------------------------
local function StartCountdown(seconds, senderName)
    local color, classToken = GetClassColorForPlayer(senderName)
    barColor = color
 
    countdown.total     = seconds
    countdown.remaining = seconds
    countdown.elapsed   = 0
    countdown.active    = true
 
    fill:SetWidth(1)
    fill:SetColorTexture(color.r, color.g, color.b, 1)
    label:SetText(tostring(seconds))
    senderLabel:SetText(ColoredName(senderName))
    bar:Show()
end
 
--------------------------------------------------------------------------------
-- Event handling
--------------------------------------------------------------------------------
local frame = CreateFrame("Frame", ADDON_NAME .. "Frame")
frame:RegisterEvent("PLAYER_LOGIN")
 
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        JoinChannelByName(CHANNEL_NAME)
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Listening to channel: " .. CHANNEL_NAME)
        self:RegisterEvent("CHAT_MSG_CHANNEL")
 
    elseif event == "CHAT_MSG_CHANNEL" then
        local message, author, _, _, _, _, _, _, channelName = ...
        local normalizedChannel = channelName:match("^%d*%.?%s*(.+)") or channelName
 
        if normalizedChannel:lower() == CHANNEL_NAME:lower() then
            local shortAuthor = author:match("^([^%-]+)") or author
            print(ColoredName(shortAuthor) .. " : " .. message)
 
            local seconds = tonumber(message)
            if seconds and seconds > 0 then
                StartCountdown(seconds, shortAuthor)
            end
        end
    end
end)
 
