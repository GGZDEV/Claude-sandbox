-------------------------------------------------------------------------------
-- Overlord — Network.lua
-- Peer-to-peer synchronisation via SendAddonMessage (WoW 3.3.5)
--
-- Transport layers (in priority order):
--   1. Custom channel "Overlord"  — reaches all Overlord players on the realm,
--      cross-faction on Ascension WoW (Bronzebeard crossfaction server).
--   2. Raid  — if in a raid group.
--   3. Party — if in a party but not a raid.
--
-- In WoW 3.3.5, RegisterAddonMessagePrefix() does not exist.
-- All addon messages arrive via CHAT_MSG_ADDON (handled in Core.lua).
-- Prefix is capped at 16 characters by the engine.
--
-- Message wire format:  "MSGTYPE:payload"
--
-- Message types:
--   SYNC  — full zone state snapshot
--   CAP   — a zone just changed hands
--   PROG  — capture-progress update (lightweight, sent every ~5 s while capping)
--   KILL  — a player got a kill in Arathi
--   REQ   — request a SYNC from peers (answered with random jitter delay)
--   JOIN  — announce presence / faction on login or zone enter
--
-- Anti-flood:
--   • Per-message-type minimum interval (see THROTTLE table).
--   • Outgoing messages that arrive too soon are silently dropped (the next
--     periodic broadcast will carry the information anyway).
--   • Incoming REQ messages are answered after a random 0.5–2 s jitter to
--     prevent sync storms when many players log in at once.
-------------------------------------------------------------------------------

OverlordNetwork = {}

local ADDON_PREFIX   = "Overlord"
local CHANNEL_NAME   = "Overlord"

-- Minimum seconds between outgoing messages of each type
local THROTTLE = {
    SYNC  = 10,
    CAP   = 1,
    PROG  = 2,
    KILL  = 1,
    REQ   = 30,
    JOIN  = 5,
}

local lastSent = {}   -- [msgType] = GetTime() of last send

-- Pending delayed sync-request answer
local pendingSyncAt = nil

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function IsThrottled(msgType)
    local limit = THROTTLE[msgType] or 1
    local last  = lastSent[msgType] or 0
    if (GetTime() - last) < limit then return true end
    lastSent[msgType] = GetTime()
    return false
end

local function GetChannelNum()
    return GetChannelName(CHANNEL_NAME) or 0
end

-- Send on all available layers
local function Send(msgType, payload)
    if IsThrottled(msgType) then return end

    local msg    = msgType .. ":" .. (payload or "")
    local chNum  = GetChannelNum()

    if chNum > 0 then
        SendAddonMessage(ADDON_PREFIX, msg, "CHANNEL", chNum)
    end

    -- Also propagate inside the group so members who didn't join the channel
    -- (e.g. brand-new players) still receive updates.
    if GetNumRaidMembers() > 0 then
        SendAddonMessage(ADDON_PREFIX, msg, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage(ADDON_PREFIX, msg, "PARTY")
    end
end

-- Serialise all zone states into a compact pipe-delimited string:
--   "zoneId=faction=progress|zoneId=faction=progress|…"
local function SerialiseZones()
    local parts = {}
    for _, zd in ipairs(Overlord_ZoneData) do
        local st = OverlordCore.ZoneState(zd.id)
        if st then
            table.insert(parts,
                zd.id .. "=" .. (st.faction or "Neutral") ..
                "=" .. string.format("%.0f", st.captureProgress or 0))
        end
    end
    return table.concat(parts, "|")
end

-------------------------------------------------------------------------------
-- Outbound API (called by Core)
-------------------------------------------------------------------------------

function OverlordNetwork.BroadcastSync()
    Send("SYNC", SerialiseZones())
end

function OverlordNetwork.BroadcastCapture(zoneId, faction)
    -- Include our name so remote clients can credit the leaderboard
    local captor = UnitName("player") or "Unknown"
    Send("CAP", zoneId .. ":" .. faction .. ":" .. captor)
end

function OverlordNetwork.BroadcastProgress(zoneId, progress)
    local S = OverlordCore.GetState()
    Send("PROG", zoneId .. ":" .. string.format("%.0f", progress) .. ":" .. S.faction)
end

function OverlordNetwork.BroadcastKill(playerName, faction)
    Send("KILL", playerName .. ":" .. faction)
end

function OverlordNetwork.BroadcastJoin()
    local S = OverlordCore.GetState()
    Send("JOIN", S.faction)
end

-- Ask peers to send us their SYNC after `delaySec` seconds
function OverlordNetwork.ScheduleSyncRequest(delaySec)
    pendingSyncAt = GetTime() + (delaySec or 2)
end

-------------------------------------------------------------------------------
-- Inbound handlers
-------------------------------------------------------------------------------

local function HandleSync(payload)
    for chunk in payload:gmatch("[^|]+") do
        local zoneId, faction, progStr = chunk:match("^(.-)=(.-)=(.+)$")
        if zoneId and faction and progStr then
            local zd = Overlord_ZoneById[zoneId]
            local st = OverlordCore.ZoneState(zoneId)
            if zd and st and not zd.isBase then
                st.faction         = faction
                st.captureProgress = tonumber(progStr) or 0
            end
        end
    end
    if OverlordUI then OverlordUI.Update() end
end

local function HandleCapture(payload, sender)
    -- payload: "zoneId:faction:captorName"
    local zoneId, faction, captor = payload:match("^(.-):(.-):(.*)")
    if not zoneId then return end

    local zd = Overlord_ZoneById[zoneId]
    local st = OverlordCore.ZoneState(zoneId)
    if not zd or not st or zd.isBase then return end

    local oldFaction = st.faction
    st.faction         = faction
    st.captureProgress = faction == "Alliance" and 100 or -100
    st.captureTime     = time()
    st.holder          = captor

    -- Announce only if this is new info
    if oldFaction ~= faction then
        local zoneName = OverlordL[zd.nameKey] or zd.id
        local msg = string.format(OverlordL["MSG_CAPTURED"], captor, zoneName)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Overlord]|r " .. msg)
    end

    if OverlordUI then OverlordUI.Update() end
end

local function HandleProgress(payload, sender)
    -- payload: "zoneId:progress:faction"
    local zoneId, progStr, faction = payload:match("^(.-):(.-):(.*)")
    if not zoneId then return end

    local zd = Overlord_ZoneById[zoneId]
    local st = OverlordCore.ZoneState(zoneId)
    if not zd or not st or zd.isBase then return end

    st.captureProgress = tonumber(progStr) or 0

    -- Track this remote player's position for multi-player capture counting
    local sName = sender:match("^(.-)%-") or sender
    local S = OverlordCore.GetState()
    S.remotes[sName] = { zone = zoneId, faction = faction, time = GetTime() }
end

local function HandleKill(payload)
    -- payload: "playerName:faction"
    local name, faction = payload:match("^(.-):(.+)")
    if not name or not faction then return end

    if not OverlordDB.leaderboard[name] then
        OverlordDB.leaderboard[name] = { captures = 0, kills = 0, faction = faction }
    end
    OverlordDB.leaderboard[name].kills =
        (OverlordDB.leaderboard[name].kills or 0) + 1

    if OverlordUI then OverlordUI.UpdateLeaderboard() end
end

local function HandleJoin(payload, sender)
    local sName = sender:match("^(.-)%-") or sender
    local S = OverlordCore.GetState()
    S.remotes[sName] = { zone = nil, faction = payload, time = GetTime() }
end

local function HandleReq()
    -- Answer with jitter (0.5–2.0 s) to prevent reply storms
    local jitter = 0.5 + math.random(0, 150) / 100.0
    pendingSyncAt = GetTime() + jitter
end

-------------------------------------------------------------------------------
-- Dispatch
-------------------------------------------------------------------------------

function OverlordNetwork.OnMessage(message, sender)
    -- Ignore our own echoes
    local myName = UnitName("player") or ""
    local sName  = sender:match("^(.-)%-") or sender
    if sName == myName then return end

    local msgType, payload = message:match("^(%u+):?(.*)")
    if not msgType then return end

    if msgType == "SYNC" then
        HandleSync(payload)
    elseif msgType == "CAP" then
        HandleCapture(payload, sender)
    elseif msgType == "PROG" then
        HandleProgress(payload, sender)
    elseif msgType == "KILL" then
        HandleKill(payload)
    elseif msgType == "JOIN" then
        HandleJoin(payload, sender)
    elseif msgType == "REQ" then
        HandleReq()
    end
end

-------------------------------------------------------------------------------
-- Delayed-sync pump (checked every frame)
-------------------------------------------------------------------------------

local netFrame = CreateFrame("Frame", "OverlordNetworkFrame")
netFrame:SetScript("OnUpdate", function(self, elapsed)
    if pendingSyncAt and GetTime() >= pendingSyncAt then
        pendingSyncAt = nil
        OverlordNetwork.BroadcastSync()
    end
end)
