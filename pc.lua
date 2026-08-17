-- PooseCommand.lua
local ADDON_NAME = "PooseCommand"

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

-- Slash command 5: /wishlist
-- Mastermined by Ark, coded by Claude
SLASH_WISHLIST1 = "/wishlist"
SLASH_WISHLIST2 = "/wl"
SlashCmdList["WISHLIST"] = function(msg)
    if SlashCmdList["KEYSTONELOOT"] then
        SlashCmdList["KEYSTONELOOT"](msg or "")
    else
        print("|cffff0000/wishlist only works with the KeystoneLoot addon.|r")
    end
end

-- Slash command 6: /vault, /gv -> Great Vault
-- Mastermined by Stuper, coded by Claude
SLASH_VAULT1 = "/vault"
SLASH_VAULT2 = "/gv"
SlashCmdList["VAULT"] = function(msg)
    C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
    WeeklyRewardsFrame:Show()

    -- The following code is needed to make sure the GV frame can be closed with the escape key and doesn't cause taint issues
    -- Only insert if not already registered
    for _, name in ipairs(UISpecialFrames) do
        if name == "WeeklyRewardsFrame" then return end
    end
    table.insert(UISpecialFrames, "WeeklyRewardsFrame")
end

-- Slash command: /score -> Mythic+ Score (Challenges Frame)
-- Mastermined by Ark, coded by Claude
SLASH_SCORE1 = "/score"
SlashCmdList["SCORE"] = function(msg)
    C_AddOns.LoadAddOn("Blizzard_ChallengesUI")
    PVEFrame_ShowFrame("ChallengesFrame")

    -- Register with UISpecialFrames so Escape closes it
    for _, name in ipairs(UISpecialFrames) do
        if name == "PVEFrame" then return end
    end
    table.insert(UISpecialFrames, "PVEFrame")
end

SLASH_TEMP1="/temp"
  SlashCmdList["TEMP"] = function(msg)
  local temp = msg
  CorF = string.sub(temp, -1)
  local number = temp:sub(1, -2)
  if string.lower(CorF) == "f" then

    result = (number-32)*(5/9)
    print("TEMP converted to C: " .. result .. "C")
  end
  if string.lower(CorF) == "c" then
    result = (number*1.8)+32
    print("TEMP converted to F: " .. result .. "F")
  end
end

local function CreateDelveWindow()
    if DelveFrame then
        DelveFrame:Show()
        return
    end
    
    local frame = CreateFrame("Frame", "DelveFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 300)

    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText("Raid Markers")
    
    -- Marker list 
    local markerList = {}
    local markers = {
        {name = "Star", icon = "Interface/Targetingframe/UI-RaidTargetingIcon_1"},
        {name = "Circle", icon = "Interface/Targetingframe/UI-RaidTargetingIcon_2"},
        {name = "Diamond", icon = "Interface/Targetingframe/UI-RaidTargetingIcon_3"},
        {name = "Triangle", icon = "Interface/Targetingframe/UI-RaidTargetingIcon_4"}
    }
    
    -- List 
    local listDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listDisplay:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -50)
    listDisplay:SetText("List: (empty)")
    listDisplay:SetJustifyH("LEFT")
    listDisplay:SetWidth(270)
    listDisplay:SetWordWrap(true)
    listDisplay:SetFont("Fonts/FRIZQT__.TTF", 18)
    
    local function UpdateDisplay()
        if #markerList == 0 then
            listDisplay:SetText("List: (empty)")
        else
            local iconString = ""
            for i, markerName in ipairs(markerList) do
                for _, marker in ipairs(markers) do
                    if marker.name == markerName then
                        iconString = iconString .. "|T" .. marker.icon .. ":20|t "
                        break
                    end
                end
            end
            listDisplay:SetText("List:\n" .. iconString)
        end
    end
    
    for i, markerInfo in ipairs(markers) do
        local btn = CreateFrame("Button", "DelveButton" .. i, frame, "GameMenuButtonTemplate")
        btn:SetSize(60, 50)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 12 + (i - 1) * 70, -110)
        
        local texture = btn:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        texture:SetTexture(markerInfo.icon)
        
        btn:SetText("")
        
        btn:SetScript("OnClick", function()
            table.insert(markerList, markerInfo.name)
            UpdateDisplay()
        end)
    end
    
    local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearBtn:SetSize(250, 30)
    clearBtn:SetPoint("TOP", frame, "TOP", 0, -270)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        markerList = {}
        UpdateDisplay()
    end)
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    table.insert(UISpecialFrames, "DelveFrame")
    
    frame:Show()
end

SLASH_DELVE1 = "/delve"
SlashCmdList["DELVE"] = function(msg)
    CreateDelveWindow()
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
