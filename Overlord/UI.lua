-------------------------------------------------------------------------------
-- Overlord -- UI.lua
-- Minimap button, main panel (Territory / Leaderboard tabs),
-- camp-selection popup, and in-game capture hints.
-- WoW API target: 3.3.5 (Interface 30300)
-------------------------------------------------------------------------------

OverlordUI = {}

local FACTION_COLOR = {
    Alliance = { r=0.20, g=0.45, b=1.00 },
    Horde    = { r=1.00, g=0.18, b=0.18 },
    Neutral  = { r=0.55, g=0.55, b=0.55 },
}

local function FactionHex(camp)
    if camp == "Alliance" then return "|cff3399ff"
    elseif camp == "Horde" then return "|cffcc2222"
    else                        return "|cff888888"
    end
end

-- ============================================================
-- Minimap Button
-- ============================================================

local mmAngle    = 200
local mmDragging = false

local function UpdateMMPos(btn)
    local rad = math.rad(mmAngle)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(rad) * 80, math.sin(rad) * 80)
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

local titleStr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleStr:SetPoint("TOP", panel, "TOP", 0, -14)
titleStr:SetText("|cff00ccff" .. OverlordL["UI_TITLE"] .. "|r")

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

local function MakeTabBtn(parent, label, xOffset, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 88, 22)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -42)
    b:SetText(label)
    return b
end

local tabTerritory = MakeTabBtn(panel, OverlordL["UI_STATUS"],      14)
local tabLeader    = MakeTabBtn(panel, OverlordL["UI_LEADERBOARD"], 106)
local syncBtn      = MakeTabBtn(panel, OverlordL["UI_SYNC"],        198, 68)
syncBtn:SetScript("OnClick", function()
    OverlordNetwork.BroadcastSync()
    OverlordNetwork.ScheduleSyncRequest(1)
    DEFAULT_CHAT_FRAME:AddMessage(OverlordL["MSG_SYNC_SENT"])
end)

local chanText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
chanText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 12)
chanText:SetText("|cffff9900" .. OverlordL["UI_CHANNEL_OFF"] .. "|r")

-- ============================================================
-- Territory tab
-- ============================================================

local terrScroll = CreateFrame(
    "ScrollFrame", "OverlordTerrScroll", panel, "UIPanelScrollFrameTemplate")
terrScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     12, -68)
terrScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 32)

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
    local v = idx % 2 == 0 and 0.10 or 0.05
    bg:SetTexture(v, v, v, 0.50)

    local strip = row:CreateTexture(nil, "ARTWORK")
    strip:SetWidth(5)
    strip:SetHeight(26)
    strip:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.strip = strip

    local nameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameF:SetPoint("LEFT", row, "LEFT", 10, 4)
    nameF:SetWidth(165)
    nameF:SetJustifyH("LEFT")
    row.nameText = nameF

    local facF = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    facF:SetPoint("RIGHT", row, "RIGHT", -8, 4)
    facF:SetWidth(72)
    facF:SetJustifyH("RIGHT")
    row.facText = facF

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

        local st       = OverlordDB and OverlordDB.zones and OverlordDB.zones[zd.id]
        local faction  = (st and st.faction) or zd.faction
        local progress = (st and st.captureProgress) or 0

        local dname = OverlordL[zd.nameKey] or zd.id
        if zd.isBase then dname = dname .. " " .. OverlordL["UI_BASE"] end
        row.nameText:SetText(dname)

        local fc = FACTION_COLOR[faction] or FACTION_COLOR.Neutral
        row.strip:SetTexture(fc.r, fc.g, fc.b, 1)

        local isContested = (faction == "Neutral") and math.abs(progress) > 5
        local facLabel
        if zd.isBase then
            facLabel = FactionHex(faction) ..
                       OverlordL["STATUS_" .. faction:upper()] .. "|r"
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

        if (not zd.isBase) and math.abs(progress) > 0 then
            row.progBar:Show()
            row.progBg:Show()
            local c = progress >= 0 and FACTION_COLOR.Alliance or FACTION_COLOR.Horde
            row.progBar:SetStatusBarColor(c.r, c.g, c.b)
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
lbScroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",     12, -68)
lbScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 32)
lbScroll:Hide()

local lbContent = CreateFrame("Frame", "OverlordLBContent", lbScroll)
lbContent:SetWidth(260)
lbContent:SetHeight(1)
lbScroll:SetScrollChild(lbContent)

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
    local v = idx % 2 == 0 and 0.10 or 0.05
    bg:SetTexture(v, v, v, 0.45)

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

    local entries = {}
    for name, data in pairs(OverlordDB and OverlordDB.leaderboard or {}) do
        table.insert(entries, {
            name     = name,
            captures = data.captures or 0,
            kills    = data.kills    or 0,
            -- backwards-compat: old saves used "faction" key
            camp     = data.camp or data.faction or "Neutral",
            score    = OverlordCore.Score(data),
        })
    end
    table.sort(entries, function(a, b) return a.score > b.score end)

    local y = 20  -- leave room for header
    for i, e in ipairs(entries) do
        local row = lbRows[i]
        if not row then
            row = MakeLBRow(lbContent, i)
            lbRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", lbContent, "TOPLEFT", 0, -y)
        row.rank:SetText(i .. ".")
        row.name:SetText(FactionHex(e.camp) .. e.name .. "|r")
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

    local chNum = GetChannelName("Overlord") or 0
    if chNum > 0 then
        chanText:SetText("|cff00ff00" .. OverlordL["UI_CHANNEL_ON"] ..
                         " (#" .. chNum .. ")|r")
    else
        chanText:SetText("|cffff9900" .. OverlordL["UI_CHANNEL_OFF"] .. "|r")
    end

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
    if panel:IsShown() then
        if activeTab == "territory" then RefreshTerritory()
        else RefreshLeaderboard() end
    end
    if WorldMapFrame and WorldMapFrame:IsShown() then
        OverlordUI.RefreshMapMarkers()
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
-- Capture hint (flashed above action bars)
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
    if hintTimer <= 0 then self:Hide() end
end)

function OverlordUI.ShowHint(msg, duration)
    hintText:SetText(msg)
    hintTimer = duration or 3
    hintFrame:Show()
end

-- ============================================================
-- Camp-selection popup
-- On Ascension WoW (crossfaction), UnitFactionGroup() reflects
-- race only.  Players must explicitly declare which side they
-- fight for.  This popup handles that choice.
-- ============================================================

local campPopup = CreateFrame("Frame", "OverlordCampPopup", UIParent)
campPopup:SetSize(400, 220)
campPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
campPopup:SetMovable(true)
campPopup:EnableMouse(true)
campPopup:RegisterForDrag("LeftButton")
campPopup:SetScript("OnDragStart", function(self) self:StartMoving() end)
campPopup:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
campPopup:SetFrameStrata("DIALOG")
campPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = { left=8, right=8, top=8, bottom=8 },
})
campPopup:Hide()

local cpTitle = campPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cpTitle:SetPoint("TOP", campPopup, "TOP", 0, -16)

local cpBody = campPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cpBody:SetPoint("TOP", cpTitle, "BOTTOM", 0, -10)
cpBody:SetWidth(360)
cpBody:SetJustifyH("CENTER")

local cpCurrent = campPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
cpCurrent:SetPoint("TOP", cpBody, "BOTTOM", 0, -8)
cpCurrent:SetWidth(360)
cpCurrent:SetJustifyH("CENTER")

local cpAlliance = CreateFrame("Button", nil, campPopup, "UIPanelButtonTemplate")
cpAlliance:SetSize(170, 28)
cpAlliance:SetPoint("BOTTOMLEFT", campPopup, "BOTTOMLEFT", 18, 46)
cpAlliance:SetScript("OnClick", function()
    OverlordCore.SetCamp("Alliance")
    campPopup:Hide()
    OverlordUI.Update()
end)

local cpHorde = CreateFrame("Button", nil, campPopup, "UIPanelButtonTemplate")
cpHorde:SetSize(170, 28)
cpHorde:SetPoint("BOTTOMRIGHT", campPopup, "BOTTOMRIGHT", -18, 46)
cpHorde:SetScript("OnClick", function()
    OverlordCore.SetCamp("Horde")
    campPopup:Hide()
    OverlordUI.Update()
end)

local cpLeave = CreateFrame("Button", nil, campPopup, "UIPanelButtonTemplate")
cpLeave:SetSize(120, 24)
cpLeave:SetPoint("BOTTOM", campPopup, "BOTTOM", 0, 14)
cpLeave:SetScript("OnClick", function()
    if OverlordCore.GetCamp() then OverlordCore.SetCamp(nil) end
    campPopup:Hide()
end)

local function OpenCampPopup()
    cpTitle:SetText("|cff00ccff" .. OverlordL["CAMP_TITLE"] .. "|r")
    cpBody:SetText(OverlordL["CAMP_BODY"])
    cpAlliance:SetText("|cff3399ff" .. OverlordL["CAMP_BTN_ALLIANCE"] .. "|r")
    cpHorde:SetText("|cffcc2222" .. OverlordL["CAMP_BTN_HORDE"] .. "|r")
    cpLeave:SetText(OverlordL["CAMP_BTN_LEAVE"])

    local camp = OverlordCore.GetCamp()
    if     camp == "Alliance" then cpCurrent:SetText(OverlordL["CAMP_CURRENT_A"])
    elseif camp == "Horde"    then cpCurrent:SetText(OverlordL["CAMP_CURRENT_H"])
    else                           cpCurrent:SetText(OverlordL["CAMP_CURRENT_NONE"])
    end
    campPopup:Show()
end

function OverlordUI.ShowCampSelection()
    OpenCampPopup()
end

-- ============================================================
-- "Camp" button in the main panel footer
-- ============================================================

local campBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
campBtn:SetSize(72, 22)
campBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 10)
campBtn:SetText("Camp")
campBtn:SetScript("OnClick", function() OpenCampPopup() end)
campBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    local camp = OverlordCore.GetCamp()
    if     camp == "Alliance" then GameTooltip:AddLine(OverlordL["CAMP_CURRENT_A"])
    elseif camp == "Horde"    then GameTooltip:AddLine(OverlordL["CAMP_CURRENT_H"])
    else                           GameTooltip:AddLine(OverlordL["CAMP_CURRENT_NONE"])
    end
    GameTooltip:AddLine("/overlord join alliance|horde", 1, 1, 0)
    GameTooltip:Show()
end)
campBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================
-- World Map Overlay
-- Coloured markers on each Arathi capture point when the
-- player opens the world map to Arathi Highlands.
-- mapX/mapY in Zones.lua are 0-1 fractions of the map tile.
-- ============================================================

local MAP_ARATHI_EN = "Arathi Highlands"
local MAP_ARATHI_FR = "Hautes-terres d'Arathi"

local wm_markers = {}

local function WM_IsArathi()
    local info = GetMapInfo()
    return info == MAP_ARATHI_EN or info == MAP_ARATHI_FR
end

local function WM_PlaceMarkers()
    if not WM_IsArathi() then
        for _, pin in ipairs(wm_markers) do pin:Hide() end
        return
    end

    local w = WorldMapDetailFrame:GetWidth()
    local h = WorldMapDetailFrame:GetHeight()

    for i, zd in ipairs(Overlord_ZoneData) do
        local pin = wm_markers[i]

        if not pin then
            local sz = zd.isBase and 18 or 14
            local f  = CreateFrame("Frame", nil, WorldMapDetailFrame)
            f:SetSize(sz, sz)
            f:SetFrameLevel(WorldMapDetailFrame:GetFrameLevel() + 10)
            f:EnableMouse(true)

            -- dark border
            local border = f:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints()
            border:SetTexture(0, 0, 0, 0.85)

            -- faction-coloured fill (2 px inset from border)
            local fill = f:CreateTexture(nil, "ARTWORK")
            fill:SetPoint("TOPLEFT",     f, "TOPLEFT",     2, -2)
            fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
            f.fill = fill

            -- A / H / ? label centred inside
            local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints()
            lbl:SetJustifyH("CENTER")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetTextColor(1, 1, 1, 1)
            f.lbl = lbl

            f:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                local z    = self.zd
                local name = OverlordL[z.nameKey] or z.id
                local st   = OverlordDB and OverlordDB.zones and OverlordDB.zones[z.id]
                local fac  = (st and st.faction) or z.faction
                local prog = st and (st.captureProgress or 0) or 0
                local fc   = FACTION_COLOR[fac] or FACTION_COLOR.Neutral
                GameTooltip:AddLine(name, 1, 1, 1)
                GameTooltip:AddLine(OverlordL["STATUS_" .. fac:upper()] or fac,
                    fc.r, fc.g, fc.b)
                if not z.isBase and math.abs(prog) > 0 then
                    local side = prog > 0
                        and OverlordL["STATUS_ALLIANCE"]
                        or  OverlordL["STATUS_HORDE"]
                    GameTooltip:AddLine(
                        string.format("%s %d%%", side, math.abs(prog)), 1, 1, 0)
                end
                GameTooltip:Show()
            end)
            f:SetScript("OnLeave", function() GameTooltip:Hide() end)

            f.zd = zd
            wm_markers[i] = f
            pin = f
        end

        -- position
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT",
            zd.mapX * w, -zd.mapY * h)

        -- update colour
        local st  = OverlordDB and OverlordDB.zones and OverlordDB.zones[zd.id]
        local fac = (st and st.faction) or zd.faction
        local fc  = FACTION_COLOR[fac] or FACTION_COLOR.Neutral
        pin.fill:SetTexture(fc.r, fc.g, fc.b, 1)

        -- update label
        if     fac == "Alliance" then pin.lbl:SetText("A")
        elseif fac == "Horde"    then pin.lbl:SetText("H")
        else                          pin.lbl:SetText("?")
        end

        pin:Show()
    end
end

-- refresh on WORLD_MAP_UPDATE (fires when continent/zone changes on the map)
local wmEventFrame = CreateFrame("Frame", "OverlordWorldMapFrame")
wmEventFrame:RegisterEvent("WORLD_MAP_UPDATE")
wmEventFrame:SetScript("OnEvent", function() WM_PlaceMarkers() end)

-- also refresh when the map window opens
local _wmOnShow = WorldMapFrame:GetScript("OnShow")
WorldMapFrame:SetScript("OnShow", function(self)
    if _wmOnShow then _wmOnShow(self) end
    WM_PlaceMarkers()
end)

function OverlordUI.RefreshMapMarkers()
    WM_PlaceMarkers()
end
