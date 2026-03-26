-------------------------------------------------------------------------------
-- Overlord — Core.lua
-- State management, event handling, and capture logic
-- WoW API target: 3.3.5 (Interface 30300)
-- Server context: Ascension WoW Bronzebeard (Classic+, crossfaction, lvl 60 cap)
--
-- Capture mechanic:
--   Progress ranges from -100 (full Horde) to +100 (full Alliance).
--   Each player in the zone ticks ±(100/CAPTURE_DURATION) per second.
--   Reaching ±100 triggers a capture event broadcast to all Overlord players.
--
-- Adjacency rule:
--   A neutral or enemy zone can only be captured if your faction already
--   controls at least one adjacent zone (or your home base is adjacent).
--   Home bases (Stromgarde / Hammerfall) cannot be captured by anyone.
--
-- Weekly reset:
--   On Monday at or after 03:00 local time, if more than 6 days have elapsed
--   since the last stored reset, the leaderboard and all zone states are wiped.
-------------------------------------------------------------------------------

local ADDON_NAME      = "Overlord"
local ADDON_PREFIX    = "Overlord"       -- ≤16 chars, used in SendAddonMessage
local CHANNEL_NAME    = "Overlord"       -- custom open-world coordination channel
local ARATHI_EN       = "Arathi Highlands"
local ARATHI_FR       = "Hautes-terres d'Arathi"

-- Tuning constants
local CAPTURE_DURATION  = 60     -- seconds for 1 player to cap from neutral
local TICK_INTERVAL     = 1      -- OnUpdate accumulator resolution (seconds)
local SYNC_INTERVAL     = 300    -- passive full-state broadcast every 5 min
local ANNOUNCE_COOLDOWN = 8      -- min seconds between zone-capture announcements
local REMOTE_EXPIRY     = 30     -- seconds before a remote player's position expires

-- Derived
local PROGRESS_TICK = 100 / CAPTURE_DURATION  -- progress units per second per player

-------------------------------------------------------------------------------
-- SavedVariables bootstrap
-------------------------------------------------------------------------------

local function InitDB()
    if not OverlordDB then OverlordDB = {} end

    if not OverlordDB.zones then
        OverlordDB.zones = {}
    end
    if not OverlordDB.leaderboard then
        OverlordDB.leaderboard = {}
    end
    if not OverlordDB.lastReset then
        OverlordDB.lastReset = 0
    end
    if not OverlordDB.minimapAngle then
        OverlordDB.minimapAngle = 200
    end

    -- Seed missing zone states from static defaults
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
end

-------------------------------------------------------------------------------
-- Runtime state (never persisted)
-------------------------------------------------------------------------------

local S = {                      -- shorthand for the runtime state table
    inArathi        = false,
    currentSubzone  = "",
    currentZoneData = nil,       -- pointer into Overlord_ZoneData (or nil)

    faction         = "Neutral", -- updated on load and on faction change
    playerName      = "Unknown",

    channelJoined   = false,

    lastSync        = 0,         -- GetTime() of last SYNC broadcast
    announceCD      = {},        -- [zoneId] = GetTime() of last announcement

    -- Remote players seen recently: name -> {zone, faction, time}
    remotes         = {},

    -- Local capture tracking
    capActive       = false,
    capZone         = nil,       -- zone id currently being captured
    capElapsed      = 0,

    onUpdateAcc     = 0,         -- OnUpdate accumulator
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ZoneState(id)
    return OverlordDB and OverlordDB.zones and OverlordDB.zones[id]
end

local function FactionOwns(faction, zoneId)
    local st = ZoneState(zoneId)
    return st and st.faction == faction
end

-- Returns true + nil, or false + hint string
local function CanCapture(zoneId)
    local zd = Overlord_ZoneById[zoneId]
    if not zd then return false, "" end

    if zd.isBase then
        return false, OverlordL["HINT_ALREADY_OWNED"]
    end

    local st = ZoneState(zoneId)
    if st and st.faction == S.faction then
        return false, OverlordL["HINT_ALREADY_OWNED"]
    end

    if UnitIsDeadOrGhost("player") then
        return false, OverlordL["HINT_DEAD"]
    end

    if IsStealthed() then
        return false, OverlordL["HINT_STEALTHED"]
    end

    -- Must have at least one adjacent friendly zone (or the home base is adjacent)
    for _, adjId in ipairs(zd.adjacents) do
        if FactionOwns(S.faction, adjId) then
            return true, nil
        end
    end

    return false, OverlordL["HINT_NO_ADJACENT"]
end

-- Count local + remote players of each faction in a given zone
local function PlayersInZone(zoneId)
    local allies, enemies = 0, 0
    if S.currentZoneData and S.currentZoneData.id == zoneId then
        allies = 1  -- local player is here
    end
    local now = GetTime()
    for _, info in pairs(S.remotes) do
        if info.zone == zoneId and (now - info.time) < REMOTE_EXPIRY then
            if info.faction == S.faction then
                allies = allies + 1
            else
                enemies = enemies + 1
            end
        end
    end
    return allies, enemies
end

-------------------------------------------------------------------------------
-- OverlordCore — public module
-------------------------------------------------------------------------------

OverlordCore = {}

function OverlordCore.GetState()   return S            end
function OverlordCore.ZoneState(id) return ZoneState(id) end

-- Called when a zone reaches ±100 progress (locally detected or via network CAP msg)
function OverlordCore.CaptureZone(zoneId, faction, captorName)
    local st = ZoneState(zoneId)
    local zd = Overlord_ZoneById[zoneId]
    if not st or not zd or zd.isBase then return end

    st.faction         = faction
    st.captureProgress = faction == "Alliance" and 100 or -100
    st.captureTime     = time()
    st.holder          = captorName or S.playerName

    -- Leaderboard credit (only if we are the captor)
    if captorName == S.playerName or captorName == nil then
        OverlordCore.AddCapture(S.playerName, S.faction)
    end

    -- Announce (throttled)
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

function OverlordCore.AddCapture(name, faction)
    if not OverlordDB.leaderboard[name] then
        OverlordDB.leaderboard[name] = { captures = 0, kills = 0, faction = faction }
    end
    OverlordDB.leaderboard[name].captures = (OverlordDB.leaderboard[name].captures or 0) + 1
end

function OverlordCore.AddKill(name, faction)
    if not OverlordDB.leaderboard[name] then
        OverlordDB.leaderboard[name] = { captures = 0, kills = 0, faction = faction }
    end
    OverlordDB.leaderboard[name].kills = (OverlordDB.leaderboard[name].kills or 0) + 1
end

-- Score: 3 pts per capture, 1 pt per kill
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
    -- wday: 1=Sun, 2=Mon, … 7=Sat
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
-- Capture tick (called every TICK_INTERVAL seconds while in Arathi)
-------------------------------------------------------------------------------

local function ProcessTick()
    local zd = S.currentZoneData
    if not zd then return end

    local ok, hint = CanCapture(zd.id)
    if not ok then
        if S.capActive then
            -- We were capturing — stopped
            S.capActive  = false
            S.capZone    = nil
            S.capElapsed = 0
        end
        return
    end

    -- Start or continue capture
    if not S.capActive or S.capZone ~= zd.id then
        S.capActive  = true
        S.capZone    = zd.id
        S.capElapsed = 0
    end
    S.capElapsed = S.capElapsed + TICK_INTERVAL

    local st = ZoneState(zd.id)
    if not st then return end

    local allies, enemies = PlayersInZone(zd.id)

    -- Progress delta (Alliance-positive convention)
    local allyNet, enemyNet
    if S.faction == "Alliance" then
        allyNet, enemyNet = allies, enemies
    else
        allyNet, enemyNet = enemies, allies  -- Horde pushes progress negative
    end

    local delta
    if allyNet > 0 and enemyNet == 0 then
        delta = allyNet * PROGRESS_TICK
        if S.faction == "Horde" then delta = -delta end
    elseif allyNet == 0 and enemyNet > 0 then
        delta = 0  -- contested, no progress for us
    elseif allyNet > enemyNet then
        local net = allyNet - enemyNet
        delta = net * PROGRESS_TICK
        if S.faction == "Horde" then delta = -delta end
    else
        delta = 0  -- equal or outnumbered: stalemate
    end

    if delta == 0 then return end

    local prev     = st.captureProgress
    local newProg  = math.max(-100, math.min(100, prev + delta))
    st.captureProgress = newProg

    -- Check threshold crossings
    if prev < 100 and newProg >= 100 then
        OverlordCore.CaptureZone(zd.id, "Alliance")
        OverlordNetwork.BroadcastCapture(zd.id, "Alliance")
    elseif prev > -100 and newProg <= -100 then
        OverlordCore.CaptureZone(zd.id, "Horde")
        OverlordNetwork.BroadcastCapture(zd.id, "Horde")
    end

    -- Broadcast progress every 5 ticks so others can update their display
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

    -- Refresh subzone
    local sub = GetSubZoneText() or ""
    if sub ~= S.currentSubzone then
        S.currentSubzone  = sub
        S.currentZoneData = Overlord_ZoneBySubzone[sub]
        S.capActive  = false
        S.capZone    = nil
        S.capElapsed = 0
    end

    ProcessTick()

    -- Passive full sync
    local now = GetTime()
    if (now - S.lastSync) >= SYNC_INTERVAL then
        S.lastSync = now
        OverlordNetwork.BroadcastSync()
    end
end)

frame:SetScript("OnEvent", function(self, event, ...)
    local a1, a2, a3, a4, a5, a6, a7, a8, a9 = ...

    if event == "ADDON_LOADED" then
        if a1 == ADDON_NAME then
            InitDB()
            OverlordCore.CheckWeeklyReset()
            S.faction    = UnitFactionGroup("player") or "Neutral"
            S.playerName = UnitName("player") or "Unknown"

            -- Join the cross-faction coordination channel.
            -- On Ascension (crossfaction), both Alliance and Horde share it.
            JoinChannelByName(CHANNEL_NAME)
            local chNum = GetChannelName(CHANNEL_NAME)
            if chNum and chNum > 0 then
                S.channelJoined = true
            end

            DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_LOADED"])
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        S.faction    = UnitFactionGroup("player") or "Neutral"
        S.playerName = UnitName("player") or "Unknown"
        -- Refresh zone
        local zone = GetZoneText() or ""
        S.inArathi  = (zone == ARATHI_EN or zone == ARATHI_FR)
        S.currentSubzone  = GetSubZoneText() or ""
        S.currentZoneData = Overlord_ZoneBySubzone[S.currentSubzone]
        -- Request sync from peers after a brief delay (handled by Network)
        OverlordNetwork.ScheduleSyncRequest(5)

    elseif event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" then
        local zone = GetZoneText() or ""
        S.inArathi  = (zone == ARATHI_EN or zone == ARATHI_FR)
        S.currentSubzone  = GetSubZoneText() or ""
        S.currentZoneData = Overlord_ZoneBySubzone[S.currentSubzone]
        S.capActive  = false
        S.capZone    = nil
        S.capElapsed = 0
        if OverlordUI then OverlordUI.Update() end

    elseif event == "UNIT_DIED" then
        -- a1 = unitId
        if a1 == "target" and S.inArathi then
            if UnitIsPlayer("target") and not UnitIsFriend("player", "target") then
                OverlordCore.AddKill(S.playerName, S.faction)
                OverlordNetwork.BroadcastKill(S.playerName, S.faction)
                if OverlordUI then OverlordUI.UpdateLeaderboard() end
            end
        end

    elseif event == "CHAT_MSG_ADDON" then
        -- a1=prefix, a2=message, a3=channel, a4=sender
        if a1 == ADDON_PREFIX then
            OverlordNetwork.OnMessage(a2, a4)
        end

    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        -- a1=noticeType, a9=channelName (without number prefix)
        local noticeType = a1
        local chName     = a9
        if chName and chName:lower() == CHANNEL_NAME:lower() then
            if noticeType == "YOU_JOINED" then
                S.channelJoined = true
                DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_JOINED_CH"])
                OverlordNetwork.ScheduleSyncRequest(2)
            elseif noticeType == "YOU_LEFT" then
                S.channelJoined = false
            end
        end
    end
end)
