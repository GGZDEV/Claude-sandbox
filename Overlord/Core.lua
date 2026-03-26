-------------------------------------------------------------------------------
-- Overlord -- Core.lua
-- State management, event handling, and capture logic
-- WoW API target: 3.3.5 (Interface 30300)
-- Server context: Ascension WoW Bronzebeard (Classic+, crossfaction, lvl 60 cap)
--
-- CAMP vs FACTION
--   On Ascension WoW, the server is fully crossfaction: any race can group with
--   any other race, guilds are mixed, and UnitFactionGroup() simply reflects the
--   character race (Human -> "Alliance", Orc -> "Horde").  That has no bearing
--   on which side a player wants to fight for in a World PvP campaign.
--
--   Overlord therefore maintains a per-character CAMP choice stored in
--   OverlordCharDB.camp ("Alliance" | "Horde" | nil).  All capture and
--   leaderboard logic uses S.camp, never UnitFactionGroup().
--
-- Capture mechanic:
--   Progress ranges -100 (full Horde) to +100 (full Alliance).
--   Each player in zone ticks +/-(100/CAPTURE_DURATION) per second.
--   Reaching +/-100 triggers a capture event broadcast to all Overlord players.
--
-- Adjacency rule:
--   A zone can only be captured if your camp already controls at least one
--   adjacent node (bases included).  Home bases are permanent strongholds.
--
-- Weekly reset (Monday 03:00 local, if >6 days since last reset):
--   Leaderboard and all zone states are wiped.
-------------------------------------------------------------------------------

local ADDON_NAME   = "Overlord"
local ADDON_PREFIX = "Overlord"
local CHANNEL_NAME = "Overlord"
local ARATHI_EN    = "Arathi Highlands"
local ARATHI_FR    = "Hautes-terres d'Arathi"

-- Tuning
local CAPTURE_DURATION  = 60
local TICK_INTERVAL     = 1
local SYNC_INTERVAL     = 300
local ANNOUNCE_COOLDOWN = 8
local REMOTE_EXPIRY     = 30

local PROGRESS_TICK = 100 / CAPTURE_DURATION

-------------------------------------------------------------------------------
-- SavedVariables bootstrap
-------------------------------------------------------------------------------

local function InitDB()
    -- Realm-wide shared state
    if not OverlordDB then OverlordDB = {} end
    if not OverlordDB.zones       then OverlordDB.zones       = {} end
    if not OverlordDB.leaderboard then OverlordDB.leaderboard = {} end
    if not OverlordDB.lastReset   then OverlordDB.lastReset   = 0  end
    if not OverlordDB.minimapAngle then OverlordDB.minimapAngle = 200 end

    for _, zd in ipairs(Overlord_ZoneData) do
        if not OverlordDB.zones[zd.id] then
            OverlordDB.zones[zd.id] = {
                faction         = zd.faction,
                captureProgress = 0,
                holder          = nil,
                captureTime     = 0,
            }
        end
    end

    -- Per-character camp choice
    if not OverlordCharDB then OverlordCharDB = {} end
    -- OverlordCharDB.camp = "Alliance" | "Horde" | nil
end

-------------------------------------------------------------------------------
-- Runtime state
-------------------------------------------------------------------------------

local S = {
    inArathi        = false,
    currentSubzone  = "",
    currentZoneData = nil,

    -- The player's chosen Overlord side (nil = not enrolled).
    -- NEVER set this from UnitFactionGroup() on a crossfaction server.
    camp            = nil,
    playerName      = "Unknown",

    channelJoined   = false,

    lastSync        = 0,
    announceCD      = {},

    remotes         = {},   -- name -> { zone, camp, time }

    capActive       = false,
    capZone         = nil,
    capElapsed      = 0,

    onUpdateAcc     = 0,
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ZoneState(id)
    return OverlordDB and OverlordDB.zones and OverlordDB.zones[id]
end

local function CampOwns(camp, zoneId)
    local st = ZoneState(zoneId)
    return st and st.faction == camp
end

-- Returns true + nil, or false + hint string
local function CanCapture(zoneId)
    local zd = Overlord_ZoneById[zoneId]
    if not zd then return false, "" end

    -- Must have chosen a camp
    if not S.camp then
        return false, OverlordL["CAMP_NONE"]
    end

    if zd.isBase then
        return false, OverlordL["HINT_ALREADY_OWNED"]
    end

    local st = ZoneState(zoneId)
    if st and st.faction == S.camp then
        return false, OverlordL["HINT_ALREADY_OWNED"]
    end

    if UnitIsDeadOrGhost("player") then
        return false, OverlordL["HINT_DEAD"]
    end

    if IsStealthed() then
        return false, OverlordL["HINT_STEALTHED"]
    end

    for _, adjId in ipairs(zd.adjacents) do
        if CampOwns(S.camp, adjId) then
            return true, nil
        end
    end

    return false, OverlordL["HINT_NO_ADJACENT"]
end

local function PlayersInZone(zoneId)
    local allies, enemies = 0, 0
    if S.currentZoneData and S.currentZoneData.id == zoneId and S.camp then
        allies = 1
    end
    local now = GetTime()
    for _, info in pairs(S.remotes) do
        if info.zone == zoneId and (now - info.time) < REMOTE_EXPIRY then
            if info.camp == S.camp then
                allies = allies + 1
            else
                enemies = enemies + 1
            end
        end
    end
    return allies, enemies
end

-------------------------------------------------------------------------------
-- OverlordCore -- public module
-------------------------------------------------------------------------------

OverlordCore = {}

function OverlordCore.GetState()    return S            end
function OverlordCore.ZoneState(id) return ZoneState(id) end

-- Returns the player's chosen camp, or nil
function OverlordCore.GetCamp() return S.camp end

-- Set / change the player's camp  ("Alliance", "Horde", or nil to leave)
function OverlordCore.SetCamp(camp)
    S.camp = camp
    OverlordCharDB.camp = camp

    if camp == "Alliance" then
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_JOINED"])
        OverlordNetwork.BroadcastJoin()
    elseif camp == "Horde" then
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_JOINED_HORDE"])
        OverlordNetwork.BroadcastJoin()
    else
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_LEFT"])
    end

    -- Reset active capture if camp changed mid-capture
    S.capActive  = false
    S.capZone    = nil
    S.capElapsed = 0

    if OverlordUI then OverlordUI.Update() end
end

function OverlordCore.CaptureZone(zoneId, camp, captorName)
    local st = ZoneState(zoneId)
    local zd = Overlord_ZoneById[zoneId]
    if not st or not zd or zd.isBase then return end

    st.faction         = camp
    st.captureProgress = camp == "Alliance" and 100 or -100
    st.captureTime     = time()
    st.holder          = captorName or S.playerName

    if captorName == S.playerName or captorName == nil then
        OverlordCore.AddCapture(S.playerName, S.camp)
    end

    local now = GetTime()
    if not S.announceCD[zoneId] or (now - S.announceCD[zoneId]) > ANNOUNCE_COOLDOWN then
        S.announceCD[zoneId] = now
        local zoneName = OverlordL[zd.nameKey] or zd.id
        local captor   = captorName or S.playerName
        local msg = string.format(OverlordL["MSG_CAPTURED"], captor, zoneName)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Overlord]|r " .. msg)
    end

    if OverlordUI then OverlordUI.Update() end
end

function OverlordCore.AddCapture(name, camp)
    if not camp then return end
    if not OverlordDB.leaderboard[name] then
        OverlordDB.leaderboard[name] = { captures = 0, kills = 0, camp = camp }
    end
    OverlordDB.leaderboard[name].captures =
        (OverlordDB.leaderboard[name].captures or 0) + 1
end

function OverlordCore.AddKill(name, camp)
    if not camp then return end
    if not OverlordDB.leaderboard[name] then
        OverlordDB.leaderboard[name] = { captures = 0, kills = 0, camp = camp }
    end
    OverlordDB.leaderboard[name].kills =
        (OverlordDB.leaderboard[name].kills or 0) + 1
end

function OverlordCore.Score(entry)
    if not entry then return 0 end
    return (entry.captures or 0) * 3 + (entry.kills or 0)
end

-------------------------------------------------------------------------------
-- Weekly reset
-------------------------------------------------------------------------------

function OverlordCore.CheckWeeklyReset()
    local t   = date("*t")
    local now = time()
    if t.wday == 2 and t.hour >= 3 then
        if (now - (OverlordDB.lastReset or 0)) > (6 * 24 * 3600) then
            OverlordCore.DoWeeklyReset()
        end
    end
end

function OverlordCore.DoWeeklyReset()
    OverlordDB.leaderboard = {}
    for _, zd in ipairs(Overlord_ZoneData) do
        OverlordDB.zones[zd.id] = {
            faction         = zd.faction,
            captureProgress = 0,
            holder          = nil,
            captureTime     = 0,
        }
    end
    OverlordDB.lastReset = time()
    DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_WEEKLY_RESET"])
    if OverlordUI then OverlordUI.Update() end
end

-------------------------------------------------------------------------------
-- Capture tick
-------------------------------------------------------------------------------

local function ProcessTick()
    if not S.camp then return end  -- not enrolled

    local zd = S.currentZoneData
    if not zd then return end

    local ok, hint = CanCapture(zd.id)
    if not ok then
        if S.capActive then
            S.capActive  = false
            S.capZone    = nil
            S.capElapsed = 0
        end
        return
    end

    if not S.capActive or S.capZone ~= zd.id then
        S.capActive  = true
        S.capZone    = zd.id
        S.capElapsed = 0
    end
    S.capElapsed = S.capElapsed + TICK_INTERVAL

    local st = ZoneState(zd.id)
    if not st then return end

    local allies, enemies = PlayersInZone(zd.id)

    -- Compute signed delta (positive = Alliance pressure, negative = Horde)
    local delta
    if S.camp == "Alliance" then
        if allies > 0 and enemies == 0 then
            delta = allies * PROGRESS_TICK
        elseif allies > enemies then
            delta = (allies - enemies) * PROGRESS_TICK
        else
            delta = 0
        end
    else  -- Horde pushes progress negative
        if allies > 0 and enemies == 0 then
            delta = -(allies * PROGRESS_TICK)
        elseif allies > enemies then
            delta = -((allies - enemies) * PROGRESS_TICK)
        else
            delta = 0
        end
    end

    if delta == 0 then return end

    local prev    = st.captureProgress
    local newProg = math.max(-100, math.min(100, prev + delta))
    st.captureProgress = newProg

    if prev < 100 and newProg >= 100 then
        OverlordCore.CaptureZone(zd.id, "Alliance")
        OverlordNetwork.BroadcastCapture(zd.id, "Alliance")
    elseif prev > -100 and newProg <= -100 then
        OverlordCore.CaptureZone(zd.id, "Horde")
        OverlordNetwork.BroadcastCapture(zd.id, "Horde")
    end

    if S.capElapsed % 5 == 0 then
        OverlordNetwork.BroadcastProgress(zd.id, newProg)
    end
end

-------------------------------------------------------------------------------
-- Event frame
-------------------------------------------------------------------------------

local frame = CreateFrame("Frame", "OverlordCoreFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UNIT_DIED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")

frame:SetScript("OnUpdate", function(self, elapsed)
    S.onUpdateAcc = S.onUpdateAcc + elapsed
    if S.onUpdateAcc < TICK_INTERVAL then return end
    S.onUpdateAcc = 0

    if not S.inArathi then return end

    local sub = GetSubZoneText() or ""
    if sub ~= S.currentSubzone then
        S.currentSubzone  = sub
        S.currentZoneData = Overlord_ZoneBySubzone[sub]
        S.capActive  = false
        S.capZone    = nil
        S.capElapsed = 0
    end

    ProcessTick()

    local now = GetTime()
    if (now - S.lastSync) >= SYNC_INTERVAL then
        S.lastSync = now
        OverlordNetwork.BroadcastSync()
    end
end)

frame:SetScript("OnEvent", function(self, event, ...)
    local a1, a2, a3, a4, a5, a6, a7, a8, a9 = ...

    if event == "ADDON_LOADED" and a1 == ADDON_NAME then
        InitDB()
        OverlordCore.CheckWeeklyReset()

        -- Restore per-character camp (set before BroadcastJoin)
        S.playerName = UnitName("player") or "Unknown"
        S.camp       = OverlordCharDB.camp  -- may be nil on first login

        JoinChannelByName(CHANNEL_NAME)
        local chNum = GetChannelName(CHANNEL_NAME)
        if chNum and chNum > 0 then S.channelJoined = true end

        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_LOADED"])

    elseif event == "PLAYER_ENTERING_WORLD" then
        S.playerName      = UnitName("player") or "Unknown"
        S.camp            = OverlordCharDB and OverlordCharDB.camp or nil
        local zone        = GetZoneText() or ""
        S.inArathi        = (zone == ARATHI_EN or zone == ARATHI_FR)
        S.currentSubzone  = GetSubZoneText() or ""
        S.currentZoneData = Overlord_ZoneBySubzone[S.currentSubzone]

        -- Prompt first-time players who have not chosen a camp
        if not S.camp and OverlordUI then
            OverlordUI.ShowCampSelection()
        end

        OverlordNetwork.ScheduleSyncRequest(5)
        if S.camp then OverlordNetwork.BroadcastJoin() end

    elseif event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" then

        local zone        = GetZoneText() or ""
        S.inArathi        = (zone == ARATHI_EN or zone == ARATHI_FR)
        S.currentSubzone  = GetSubZoneText() or ""
        S.currentZoneData = Overlord_ZoneBySubzone[S.currentSubzone]
        S.capActive  = false
        S.capZone    = nil
        S.capElapsed = 0
        if OverlordUI then OverlordUI.Update() end

    elseif event == "UNIT_DIED" then
        if a1 == "target" and S.inArathi and S.camp then
            if UnitIsPlayer("target") and not UnitIsFriend("player", "target") then
                OverlordCore.AddKill(S.playerName, S.camp)
                OverlordNetwork.BroadcastKill(S.playerName, S.camp)
                if OverlordUI then OverlordUI.UpdateLeaderboard() end
            end
        end

    elseif event == "CHAT_MSG_ADDON" then
        if a1 == ADDON_PREFIX then
            OverlordNetwork.OnMessage(a2, a4)
        end

    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        local chName = a9
        if chName and chName:lower() == CHANNEL_NAME:lower() then
            if a1 == "YOU_JOINED" then
                S.channelJoined = true
                DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_JOINED_CH"])
                OverlordNetwork.ScheduleSyncRequest(2)
            elseif a1 == "YOU_LEFT" then
                S.channelJoined = false
            end
        end
    end
end)

-------------------------------------------------------------------------------
-- Slash commands:  /overlord  /ov
-------------------------------------------------------------------------------

SLASH_OVERLORD1 = "/overlord"
SLASH_OVERLORD2 = "/ov"

SlashCmdList["OVERLORD"] = function(input)
    local cmd = (input or ""):lower():match("^%s*(.-)%s*$")

    if cmd == "" then
        OverlordUI.TogglePanel()

    elseif cmd == "join alliance" then
        OverlordCore.SetCamp("Alliance")

    elseif cmd == "join horde" then
        OverlordCore.SetCamp("Horde")

    elseif cmd == "leave" then
        OverlordCore.SetCamp(nil)

    elseif cmd == "sync" then
        OverlordNetwork.BroadcastSync()
        OverlordNetwork.ScheduleSyncRequest(1)
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_SYNC_SENT"])

    elseif cmd == "reset" then
        OverlordCore.DoWeeklyReset()

    elseif cmd == "camp" or cmd == "side" or cmd == "status" then
        if S.camp == "Alliance" then
            DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_CURRENT_A"])
        elseif S.camp == "Horde" then
            DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_CURRENT_H"])
        else
            DEFAULT_CHAT_FRAME:AddMessage(OverlordL["CAMP_CURRENT_NONE"])
        end

    else
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["SLASH_USAGE"])
    end
end
