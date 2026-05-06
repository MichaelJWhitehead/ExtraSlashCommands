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
