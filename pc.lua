-- PooseCommand.lua
local ADDON_NAME = "PooseComm"
local CHANNEL_NAME = "Pookick"

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

--------------------------------------------------------------------------------
-- Class colours
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

--------------------------------------------------------------------------------
-- Hardcoded entries  { name (lowercase key), class token, duration (seconds) }
-- Add your defaults here — these are always present
--------------------------------------------------------------------------------
local HARDCODED = {
    { name = "Pooseunpoose",    class = "DEATHKNIGHT",      duration = 15 },
    { name = "Arkoa",    class = "DEMONHUNTER",      duration = 15 },
    { name = "Danardz",    class = "SHAMAN",      duration = 12 },
    { name = "Phlin",    class = "WARLOCK",      duration = 24 },
    { name = "Stuperstrong",    class = "WARRIOR",      duration = 15 },
    { name = "Dawnpew",    class = "HUNTER",      duration = 24 },
    { name = "Shockbot",    class = "SHAMAN",      duration = 45 },
}
-- Build the live dictionary from hardcoded + saved entries
-- Keys are lowercase names for case-insensitive matching
local function BuildDictionary()
    local dict = {}
    for _, entry in ipairs(HARDCODED) do
        dict[entry.name:lower()] = { class = entry.class:upper(), duration = entry.duration }
    end
    -- Layer saved entries on top (they can override hardcoded)
    if PooseCommandDB.entries then
        for name, data in pairs(PooseCommandDB.entries) do
            dict[name:lower()] = { class = data.class:upper(), duration = data.duration }
        end
    end
    return dict
end
 
--------------------------------------------------------------------------------
-- Bar pool — stacked vertically, 300×26 each with 4px gap
--------------------------------------------------------------------------------
local BAR_W, BAR_H, BAR_GAP = 150, 26, 2
local activeBars = {}   -- keyed by lowercase name
 
local function GetClassColor(classToken)
    return CLASS_COLORS[classToken] or DEFAULT_COLOR
end
 
local function ColorHex(color)
    return string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
end
 
local function CreateBar(name, classToken, duration)
    local color = GetClassColor(classToken)
    local index = 0
    for _ in pairs(activeBars) do index = index + 1 end  -- slot = current count before insert
 
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(BAR_W, BAR_H)
    f:SetFrameStrata("MEDIUM")
 
    -- Position: offset from TOP of screen, stacked downward by slot
    local baseX = PooseCommandDB.x or 0
    local baseY = PooseCommandDB.y or -200
    f:SetPoint("TOP", UIParent, "TOP",
        baseX,
        baseY - index * (BAR_H + BAR_GAP))
 
    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
 
    -- Fill
    local fill = f:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT",    f, "TOPLEFT",    1, -1)
    fill:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1,  1)
    fill:SetWidth(1)
    fill:SetColorTexture(color.r, color.g, color.b, 1)
 
    -- Name label (left)
    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("LEFT", f, "LEFT", 6, 0)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetText("|cffffffff" .. name .. "|r")
 
    -- Timer label (right)
    local timeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeLabel:SetPoint("RIGHT", f, "RIGHT", -6, 0)
    timeLabel:SetJustifyH("RIGHT")
    timeLabel:SetText(tostring(duration))
 
    -- State
    f.color    = color
    f.total    = duration
    f.elapsed  = 0
    f.active   = true
    f.barName  = name
 
    f:SetScript("OnUpdate", function(self, delta)
        if not self.active then return end
 
        self.elapsed = self.elapsed + delta
        local remaining = self.total - self.elapsed
 
        if remaining <= 0 then
            self.active = false
            fill:SetWidth(BAR_W - 2)
            fill:SetColorTexture(self.color.r, self.color.g, self.color.b, 1)
            timeLabel:SetText("|cffffffffReady|r")
 
            -- Remove after 3 seconds
            C_Timer.After(60, function()
                activeBars[self.barName:lower()] = nil
                self:Hide()
                self:SetScript("OnUpdate", nil)
                -- Restack remaining bars
                local slot = 0
                for _, b in pairs(activeBars) do
                    local bx = PooseCommandDB.x or 0
                    local by = PooseCommandDB.y or -200
                    b:SetPoint("TOP", UIParent, "TOP",
                        bx, by - slot * (BAR_H + BAR_GAP))
                    slot = slot + 1
                end
            end)
            return
        end
 
        local ratio = self.elapsed / self.total
        local maxW  = BAR_W - 2
        fill:SetWidth(math.max(1, maxW * ratio))
 
        fill:SetColorTexture(self.color.r, self.color.g, self.color.b, 1)
        timeLabel:SetText(string.format("%.1f", remaining))
    end)
 
    -- Dragging moves the whole stack via saved anchor
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save offset from screen TOP-CENTER
        local screenW = UIParent:GetWidth()
        local screenH = UIParent:GetHeight()
        PooseCommandDB.x = self:GetLeft() + self:GetWidth()/2 - screenW/2
        PooseCommandDB.y = self:GetTop() - screenH
        -- Restack all bars relative to new anchor
        local slot = 0
        for _, b in pairs(activeBars) do
            b:SetPoint("TOP", UIParent, "TOP",
                PooseCommandDB.x,
                PooseCommandDB.y - slot * (BAR_H + BAR_GAP))
            slot = slot + 1
        end
    end)
 
    f:Show()
    activeBars[name:lower()] = f
end
 
--------------------------------------------------------------------------------
-- Slash commands:  /pc add <name> <class> <duration>
--                  /pc remove <name>
--                  /pc list
--------------------------------------------------------------------------------
SLASH_POOSECOMMAND1 = "/pc"
SlashCmdList["POOSECOMMAND"] = function(input)
    local cmd, arg1, arg2, arg3 = input:match("^(%S+)%s*(%S*)%s*(%S*)%s*(%S*)")
    cmd = cmd and cmd:lower() or ""
 
    if cmd == "add" then
        local name, class, dur = arg1, arg2, tonumber(arg3)
        if not name or name == "" or not class or class == "" or not dur then
            print("|cff00ff00[PC]|r Usage: /pc add <name> <class> <duration>")
            print("|cff00ff00[PC]|r Example: /pc add Innervate DRUID 10")
            return
        end
        class = class:upper()
        if not CLASS_COLORS[class] then
            print("|cff00ff00[PC]|r Unknown class: " .. class)
            print("|cff00ff00[PC]|r Valid classes: WARRIOR PALADIN HUNTER ROGUE PRIEST DEATHKNIGHT SHAMAN MAGE WARLOCK MONK DRUID DEMONHUNTER EVOKER")
            return
        end
        PooseCommandDB.entries = PooseCommandDB.entries or {}
        PooseCommandDB.entries[name:lower()] = { class = class, duration = dur }
        print(string.format("|cff00ff00[PC]|r Added: %s | %s | %ds", name, class, dur))
 
    elseif cmd == "remove" then
        local name = arg1
        if not name or name == "" then
            print("|cff00ff00[PC]|r Usage: /pc remove <name>")
            return
        end
        PooseCommandDB.entries = PooseCommandDB.entries or {}
        if PooseCommandDB.entries[name:lower()] then
            PooseCommandDB.entries[name:lower()] = nil
            print("|cff00ff00[PC]|r Removed: " .. name)
        else
            print("|cff00ff00[PC]|r Not found in saved entries: " .. name)
        end
 
    elseif cmd == "list" then
        local dict = BuildDictionary()
        print("|cff00ff00[PC]|r Current entries:")
        for name, data in pairs(dict) do
            local color = GetClassColor(data.class)
            print(string.format("  |cff%s%s|r — %s — %ds",
                ColorHex(color), name, data.class, data.duration))
        end
 
    else
        print("|cff00ff00[PC]|r Commands:")
        print("  /pc add <name> <class> <duration>")
        print("  /pc remove <name>")
        print("  /pc list")
    end
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
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Type /pc list to see entries, /pc help for commands.")
        self:RegisterEvent("CHAT_MSG_CHANNEL")
 
    elseif event == "CHAT_MSG_CHANNEL" then
        -- Args: text, playerName, languageName, channelName, playerName2, specialFlags, ...
        -- channelName is arg 4, formatted as "1. Poosecommand"
        local message, author, _, channelName = ...
        local channelBaseName = channelName:match("^%d+%.%s*(.+)$") or channelName
 
        if channelBaseName:lower() == CHANNEL_NAME:lower() then
            local shortAuthor = author:match("^([^%-]+)") or author
            local key = message:lower():gsub("%s+", "")  -- strip spaces for matching
 
            local dict = BuildDictionary()
            local entry = dict[key]
 
            if entry then
                if activeBars[key] then
                    -- Already running — restart
                    local b = activeBars[key]
                    b.elapsed = 0
                    b.active  = true
                    return
                end
                print(string.format("|cff00ff00[PC]|r %s called %s (%ds)", shortAuthor, message, entry.duration))
                CreateBar(message, entry.class, entry.duration)
            end
        end
    end
end)
