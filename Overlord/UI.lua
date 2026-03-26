-------------------------------------------------------------------------------
-- Overlord — UI.lua
-- Minimap button, main panel (Territory / Leaderboard tabs), and in-game hints
-- WoW API target: 3.3.5 (Interface 30300)
-------------------------------------------------------------------------------

OverlordUI = {}

-- ============================================================
-- Constants / helpers
-- ============================================================

local FACTION_COLOR = {
    Alliance = { r=0.20, g=0.45, b=1.00 },
    Horde    = { r=1.00, g=0.18, b=0.18 },
    Neutral  = { r=0.55, g=0.55, b=0.55 },
}

local function FactionHex(faction)
    if faction == "Alliance" then return "|cff3399ff"
    elseif faction == "Horde" then return "|cffcc2222"
    else                           return "|cff888888"
    end
end

-- ============================================================
-- Minimap Button
-- ============================================================

local mmAngle   = 200   -- degrees, clockwise from East
local mmDragging = false

local function UpdateMMPos(btn)
    local rad = math.rad(mmAngle)
    local x   = math.cos(rad) * 80
    local y   = math.sin(rad) * 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local mmBtn = CreateFrame("Button", "OverlordMinimapBtn", Minimap)
mmBtn:SetWidth(32)
mmBtn:SetHeight(32)
mmBtn:SetFrameLevel(Minimap:GetFrameLevel() + 5)
mmBtn:SetClampedToScreen(true)
mmBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mmTex = mmBtn:CreateTexture(nil, "BACKGROUND")
mmTex:SetWidth(24)
mmTex:SetHeight(24)
mmTex:SetPoint("CENTER")
mmTex:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")

UpdateMMPos(mmBtn)
mmBtn:Show()

-- Drag to reposition along the minimap rim
mmBtn:RegisterForDrag("LeftButton")
mmBtn:SetScript("OnDragStart", function(self)
    mmDragging = true
    self:SetScript("OnUpdate", function(btn)
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        local s      = UIParent:GetEffectiveScale()
        mx, my       = mx / s, my / s
        mmAngle      = math.deg(math.atan2(my - cy, mx - cx))
        UpdateMMPos(btn)
    end)
end)

mmBtn:SetScript("OnDragStop", function(self)
    mmDragging = false
    self:SetScript("OnUpdate", nil)
    if OverlordDB then OverlordDB.minimapAngle = mmAngle end
end)

mmBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmBtn:SetScript("OnClick", function(self, btn)
    if mmDragging then return end
    if btn == "LeftButton" then
        OverlordUI.TogglePanel()
    elseif btn == "RightButton" then
        OverlordNetwork.BroadcastSync()
        OverlordNetwork.ScheduleSyncRequest(1)
        DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_SYNC_SENT"])
    end
end)

mmBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00ccff" .. OverlordL["UI_TITLE"] .. "|r")
    GameTooltip:AddLine(OverlordL["TT_MINIMAP"], 1, 1, 1)
    GameTooltip:Show()
end)
mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================
-- Main Panel
-- ============================================================

local panel = CreateFrame("Frame", "OverlordPanel", UIParent)
panel:SetWidth(310)
panel:SetHeight(420)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
panel:SetFrameStrata("HIGH")
panel:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = { left=8, right=8, top=8, bottom=8 },
})
panel:Hide()

-- Title
local titleStr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleStr:SetPoint("TOP", panel, "TOP", 0, -14)
titleStr:SetText("|cff00ccff" .. OverlordL["UI_TITLE"] .. "|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

-- ── Tab buttons ─────────────────────────────────────────────
local function MakeTabBtn(parent, label, xOffset)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(88, 22)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -42)
    b:SetText(label)
    return b
end

local tabTerritory  = MakeTabBtn(panel, OverlordL["UI_STATUS"],      14)
local tabLeader     = MakeTabBtn(panel, OverlordL["UI_LEADERBOARD"], 106)

local syncBtn = MakeTabBtn(panel, OverlordL["UI_SYNC"], 198)
syncBtn:SetWidth(68)
syncBtn:SetScript("OnClick", function()
    OverlordNetwork.BroadcastSync()
    OverlordNetwork.ScheduleSyncRequest(1)
    DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_SYNC_SENT"])
end)

-- ── Channel status (bottom) ──────────────────────────────────
local chanText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
chanText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 12)
chanText:SetText("|cffff9900" .. OverlordL["UI_CHANNEL_OFF"] .. "|r")

-- ============================================================
-- Territory tab
-- ============================================================

local terrScroll = CreateFrame(
    "ScrollFrame", "OverlordTerrScroll", panel, "UIPanelScrollFrameTemplate")
terrScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     12,  -68)
terrScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30,  28)

local terrContent = CreateFrame("Frame", "OverlordTerrContent", terrScroll)
terrContent:SetWidth(260)
terrContent:SetHeight(1)
terrScroll:SetScrollChild(terrContent)

local zoneRows = {}

local function MakeZoneRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(30)
    row:SetWidth(260)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(
        idx % 2 == 0 and 0.10 or 0.05,
        idx % 2 == 0 and 0.10 or 0.05,
        idx % 2 == 0 and 0.10 or 0.05,
        0.50)

    -- Faction colour strip (left edge)
    local strip = row:CreateTexture(nil, "ARTWORK")
    strip:SetWidth(5)
    strip:SetHeight(26)
    strip:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.strip = strip

    -- Zone name
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", row, "LEFT", 10, 4)
    name:SetWidth(165)
    name:SetJustifyH("LEFT")
    row.nameText = name

    -- Faction label (right)
    local fac = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fac:SetPoint("RIGHT", row, "RIGHT", -8, 4)
    fac:SetWidth(72)
    fac:SetJustifyH("RIGHT")
    row.facText = fac

    -- Capture progress bar (thin bar along bottom of row)
    local barBg = CreateFrame("StatusBar", nil, row)
    barBg:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  10, 2)
    barBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 2)
    barBg:SetHeight(3)
    barBg:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetStatusBarColor(0.25, 0.25, 0.25, 0.8)
    barBg:SetMinMaxValues(-100, 100)
    barBg:SetValue(0)

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  10, 2)
    bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 2)
    bar:SetHeight(3)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(-100, 100)
    bar:SetValue(0)
    row.progBar = bar
    row.progBg  = barBg

    return row
end

local function RefreshTerritory()
    -- Hide stale rows
    for _, r in ipairs(zoneRows) do r:Hide() end

    local y = 0
    for i, zd in ipairs(Overlord_ZoneData) do
        local row = zoneRows[i]
        if not row then
            row = MakeZoneRow(terrContent, i)
            zoneRows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", terrContent, "TOPLEFT", 0, -y)

        local st      = OverlordDB and OverlordDB.zones and OverlordDB.zones[zd.id]
        local faction = (st and st.faction) or zd.faction
        local progress = (st and st.captureProgress) or 0

        -- Zone name (append base tag)
        local dname = OverlordL[zd.nameKey] or zd.id
        if zd.isBase then dname = dname .. " " .. OverlordL["UI_BASE"] end
        row.nameText:SetText(dname)

        -- Colour strip
        local fc = FACTION_COLOR[faction] or FACTION_COLOR.Neutral
        row.strip:SetTexture(fc.r, fc.g, fc.b, 1)

        -- Faction label text
        local isContested = (faction == "Neutral") and math.abs(progress) > 5
        local facLabel
        if zd.isBase then
            facLabel = FactionHex(faction) .. OverlordL["STATUS_" .. faction:upper()] .. "|r"
        elseif isContested then
            local side = progress > 0 and "A" or "H"
            facLabel   = "|cffffff00" .. OverlordL["STATUS_CONTESTED"] ..
                         " (" .. side .. ")|r"
            row.strip:SetTexture(1, 1, 0, 1)
        elseif faction == "Neutral" then
            facLabel = "|cff888888" .. OverlordL["STATUS_NEUTRAL"] .. "|r"
        else
            facLabel = FactionHex(faction) ..
                       OverlordL["STATUS_" .. faction:upper()] .. "|r"
        end
        row.facText:SetText(facLabel)

        -- Progress bar (only for contested / in-capture zones)
        if (not zd.isBase) and math.abs(progress) > 0 then
            row.progBar:Show()
            row.progBg:Show()
            if progress >= 0 then
                row.progBar:SetStatusBarColor(
                    FACTION_COLOR.Alliance.r,
                    FACTION_COLOR.Alliance.g,
                    FACTION_COLOR.Alliance.b)
            else
                row.progBar:SetStatusBarColor(
                    FACTION_COLOR.Horde.r,
                    FACTION_COLOR.Horde.g,
                    FACTION_COLOR.Horde.b)
            end
            row.progBar:SetValue(progress)
        else
            row.progBar:Hide()
            row.progBg:Hide()
        end

        row:Show()
        y = y + 30
    end

    terrContent:SetHeight(math.max(y, 1))
end

-- ============================================================
-- Leaderboard tab
-- ============================================================

local lbScroll = CreateFrame(
    "ScrollFrame", "OverlordLBScroll", panel, "UIPanelScrollFrameTemplate")
lbScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     12,  -68)
lbScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30,  28)
lbScroll:Hide()

local lbContent = CreateFrame("Frame", "OverlordLBContent", lbScroll)
lbContent:SetWidth(260)
lbContent:SetHeight(1)
lbScroll:SetScrollChild(lbContent)

-- Column header
local lbHeader = CreateFrame("Frame", nil, panel)
lbHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -68)
lbHeader:SetSize(260, 18)
lbHeader:Hide()

local function HeaderLabel(x, w, text, justify)
    local f = lbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f:SetPoint("LEFT", lbHeader, "LEFT", x, 0)
    f:SetWidth(w)
    f:SetJustifyH(justify or "LEFT")
    f:SetText("|cffffcc00" .. text .. "|r")
end
HeaderLabel(  2,  22, "#")
HeaderLabel( 26, 105, OverlordL["UI_PLAYER"])
HeaderLabel(132,  36, OverlordL["UI_CAPTURES"], "CENTER")
HeaderLabel(170,  36, OverlordL["UI_KILLS"],    "CENTER")
HeaderLabel(210,  40, OverlordL["UI_POINTS"],   "RIGHT")

local lbRows = {}

local function MakeLBRow(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(22)
    row:SetWidth(260)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(
        idx % 2 == 0 and 0.10 or 0.05,
        idx % 2 == 0 and 0.10 or 0.05,
        idx % 2 == 0 and 0.10 or 0.05, 0.45)

    local function Col(x, w, justify)
        local f = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f:SetPoint("LEFT", row, "LEFT", x, 0)
        f:SetWidth(w)
        f:SetJustifyH(justify or "LEFT")
        return f
    end

    row.rank  = Col(  2,  22)
    row.name  = Col( 26, 105)
    row.cap   = Col(132,  36, "CENTER")
    row.kill  = Col(170,  36, "CENTER")
    row.score = Col(210,  40, "RIGHT")

    return row
end

local function RefreshLeaderboard()
    for _, r in ipairs(lbRows) do r:Hide() end

    -- Sort by score desc
    local entries = {}
    for name, data in pairs(OverlordDB and OverlordDB.leaderboard or {}) do
        table.insert(entries, {
            name     = name,
            captures = data.captures or 0,
            kills    = data.kills    or 0,
            faction  = data.faction  or "Neutral",
            score    = OverlordCore.Score(data),
        })
    end
    table.sort(entries, function(a, b) return a.score > b.score end)

    -- Header offset: 20px so rows start below the header
    local y = 20
    for i, e in ipairs(entries) do
        local row = lbRows[i]
        if not row then
            row = MakeLBRow(lbContent, i)
            lbRows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", lbContent, "TOPLEFT", 0, -y)

        row.rank:SetText(i .. ".")
        row.name:SetText(FactionHex(e.faction) .. e.name .. "|r")
        row.cap:SetText(e.captures)
        row.kill:SetText(e.kills)
        row.score:SetText("|cffffcc00" .. e.score .. "|r")

        row:Show()
        y = y + 22
    end

    lbContent:SetHeight(math.max(y, 1))
end

-- ============================================================
-- Tab switching
-- ============================================================

local activeTab = "territory"

local function ShowTerritory()
    activeTab = "territory"
    terrScroll:Show()
    lbScroll:Hide()
    lbHeader:Hide()
    RefreshTerritory()
end

local function ShowLeaderboard()
    activeTab = "leaderboard"
    terrScroll:Hide()
    lbScroll:Show()
    lbHeader:Show()
    RefreshLeaderboard()
end

tabTerritory:SetScript("OnClick", ShowTerritory)
tabLeader:SetScript("OnClick",    ShowLeaderboard)

-- ============================================================
-- Panel auto-refresh (1 s while open)
-- ============================================================

local uiTick = 0
panel:SetScript("OnUpdate", function(self, elapsed)
    uiTick = uiTick + elapsed
    if uiTick < 1 then return end
    uiTick = 0

    -- Update channel indicator
    local chNum = GetChannelName("Overlord") or 0
    if chNum > 0 then
        chanText:SetText("|cff00ff00" .. OverlordL["UI_CHANNEL_ON"] ..
                         " (#" .. chNum .. ")|r")
    else
        chanText:SetText("|cffff9900" .. OverlordL["UI_CHANNEL_OFF"] .. "|r")
    end

    -- Refresh current tab
    if activeTab == "territory" then
        RefreshTerritory()
    else
        RefreshLeaderboard()
    end
end)

-- ============================================================
-- Public API
-- ============================================================

function OverlordUI.TogglePanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
        ShowTerritory()
    end
end

function OverlordUI.Update()
    if not panel:IsShown() then return end
    if activeTab == "territory" then
        RefreshTerritory()
    else
        RefreshLeaderboard()
    end
end

function OverlordUI.UpdateLeaderboard()
    if panel:IsShown() and activeTab == "leaderboard" then
        RefreshLeaderboard()
    end
end

-- ============================================================
-- Restore minimap position from SavedVariables
-- ============================================================

local uiInitFrame = CreateFrame("Frame")
uiInitFrame:RegisterEvent("ADDON_LOADED")
uiInitFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Overlord" then
        -- Delay one frame to ensure OverlordDB is initialised by Core
        self:SetScript("OnUpdate", function(self2)
            self2:SetScript("OnUpdate", nil)
            if OverlordDB and OverlordDB.minimapAngle then
                mmAngle = OverlordDB.minimapAngle
                UpdateMMPos(mmBtn)
            end
            ShowTerritory()
        end)
    end
end)

-- ============================================================
-- Capture hint display
-- Shown above the action bars when the player enters a zone
-- where capture is blocked, so they know why nothing happens.
-- ============================================================

local hintFrame = CreateFrame("Frame", "OverlordHintFrame", UIParent)
hintFrame:SetSize(320, 32)
hintFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180)
hintFrame:Hide()

local hintBg = hintFrame:CreateTexture(nil, "BACKGROUND")
hintBg:SetAllPoints()
hintBg:SetTexture(0, 0, 0, 0.65)

local hintText = hintFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hintText:SetAllPoints()
hintText:SetJustifyH("CENTER")
hintText:SetJustifyV("MIDDLE")

local hintTimer = 0

hintFrame:SetScript("OnUpdate", function(self, elapsed)
    hintTimer = hintTimer - elapsed
    if hintTimer <= 0 then
        self:Hide()
    end
end)

-- Called by Core or externally to flash a short message above action bars
function OverlordUI.ShowHint(msg, duration)
    hintText:SetText(msg)
    hintTimer = duration or 3
    hintFrame:Show()
end
