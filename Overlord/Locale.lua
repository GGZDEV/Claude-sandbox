-------------------------------------------------------------------------------
-- Overlord — Locale.lua
-- Supports: enUS, enGB (default) and frFR
-- Port for Ascension WoW 3.3.5 (Bronzebeard)
-------------------------------------------------------------------------------

local L = {}
OverlordL = L

-- ============================================================
-- English (default)
-- ============================================================

-- Zone names
L["ZONE_STROMGARDE"]   = "Stromgarde Keep"
L["ZONE_HAMMERFALL"]   = "Hammerfall"
L["ZONE_REFUGE"]       = "Refuge Pointe"
L["ZONE_NORTHFOLD"]    = "Northfold Manor"
L["ZONE_GOSHEK"]       = "Go'Shek Farm"
L["ZONE_DABYRIE"]      = "Dabyrie's Farmstead"
L["ZONE_WEST_BINDING"] = "Circle of West Binding"
L["ZONE_EAST_BINDING"] = "Circle of East Binding"
L["ZONE_WITHERBARK"]   = "Witherbark Village"
L["ZONE_BOULDERGOR"]   = "Boulder'gor"

-- Faction / status
L["STATUS_ALLIANCE"]  = "Alliance"
L["STATUS_HORDE"]     = "Horde"
L["STATUS_NEUTRAL"]   = "Neutral"
L["STATUS_CONTESTED"] = "Contested"

-- Chat announcements
L["MSG_CAPTURED"]      = "%s captured %s!"
L["MSG_LOST"]          = "%s has lost %s!"
L["MSG_CONTESTED"]     = "%s is under attack!"
L["MSG_WEEKLY_RESET"]  = "[Overlord] Weekly reset — the battle for Arathi begins anew."
L["MSG_LOADED"]        = "[Overlord] Port 3.3.5 (Ascension/Bronzebeard) ready. Joining channel…"
L["MSG_JOINED_CH"]     = "[Overlord] Joined the Overlord coordination channel."
L["MSG_SYNC_SENT"]     = "[Overlord] Sync requested."

-- UI panel
L["UI_TITLE"]        = "Overlord"
L["UI_STATUS"]       = "Territory"
L["UI_LEADERBOARD"]  = "Leaderboard"
L["UI_SYNC"]         = "Sync"
L["UI_BASE"]         = "(Base)"
L["UI_PLAYER"]       = "Player"
L["UI_CAPTURES"]     = "Captures"
L["UI_KILLS"]        = "Kills"
L["UI_POINTS"]       = "Pts"
L["UI_CHANNEL_ON"]   = "Channel: Online"
L["UI_CHANNEL_OFF"]  = "Channel: Offline"
L["UI_WEEKLY_RESET"] = "Weekly Reset"

-- Tooltips
L["TT_MINIMAP"]   = "Overlord\nLeft-click: Toggle panel\nRight-click: Sync status"
L["TT_HOLDER"]    = "Holder: "
L["TT_PROGRESS"]  = "Progress: "

-- Capture hints (printed to player when ineligible)
L["HINT_NOT_IN_ARATHI"] = "|cffff4444[Overlord]|r You must be in Arathi Highlands."
L["HINT_STEALTHED"]     = "|cffff4444[Overlord]|r Cannot capture while stealthed."
L["HINT_DEAD"]          = "|cffff4444[Overlord]|r Cannot capture while dead."
L["HINT_NO_ADJACENT"]   = "|cffff4444[Overlord]|r Your faction must control an adjacent zone first."
L["HINT_ALREADY_OWNED"] = "|cffff4444[Overlord]|r Already controlled by your faction."

-- ============================================================
-- French overrides
-- ============================================================

if GetLocale() == "frFR" then
    L["ZONE_STROMGARDE"]   = "Château de Stromgarde"
    L["ZONE_HAMMERFALL"]   = "Hammerfall"
    L["ZONE_REFUGE"]       = "Refuge Pointe"
    L["ZONE_NORTHFOLD"]    = "Manoir de Northfold"
    L["ZONE_GOSHEK"]       = "Ferme de Go'Shek"
    L["ZONE_DABYRIE"]      = "Ferme de Dabyrie"
    L["ZONE_WEST_BINDING"] = "Cercle des liens de l'ouest"
    L["ZONE_EAST_BINDING"] = "Cercle des liens de l'est"
    L["ZONE_WITHERBARK"]   = "Village de Witherbark"
    L["ZONE_BOULDERGOR"]   = "Boulder'gor"

    L["STATUS_ALLIANCE"]  = "Alliance"
    L["STATUS_HORDE"]     = "Horde"
    L["STATUS_NEUTRAL"]   = "Neutre"
    L["STATUS_CONTESTED"] = "Contesté"

    L["MSG_CAPTURED"]     = "%s a capturé %s !"
    L["MSG_LOST"]         = "%s a perdu %s !"
    L["MSG_CONTESTED"]    = "%s est attaqué !"
    L["MSG_WEEKLY_RESET"] = "[Overlord] Réinitialisation hebdomadaire — la bataille pour Arathi recommence."
    L["MSG_LOADED"]       = "[Overlord] Port 3.3.5 (Ascension/Bronzebeard) prêt. Connexion au canal…"
    L["MSG_JOINED_CH"]    = "[Overlord] Canal de coordination Overlord rejoint."
    L["MSG_SYNC_SENT"]    = "[Overlord] Synchronisation demandée."

    L["UI_TITLE"]        = "Overlord"
    L["UI_STATUS"]       = "Territoires"
    L["UI_LEADERBOARD"]  = "Classement"
    L["UI_SYNC"]         = "Sync"
    L["UI_BASE"]         = "(Base)"
    L["UI_PLAYER"]       = "Joueur"
    L["UI_CAPTURES"]     = "Captures"
    L["UI_KILLS"]        = "Kills"
    L["UI_POINTS"]       = "Pts"
    L["UI_CHANNEL_ON"]   = "Canal : En ligne"
    L["UI_CHANNEL_OFF"]  = "Canal : Hors ligne"
    L["UI_WEEKLY_RESET"] = "Reset hebdo"

    L["TT_MINIMAP"]   = "Overlord\nClic gauche : Afficher/masquer\nClic droit : Sync"
    L["TT_HOLDER"]    = "Contrôlée par : "
    L["TT_PROGRESS"]  = "Progression : "

    L["HINT_NOT_IN_ARATHI"] = "|cffff4444[Overlord]|r Vous devez être dans les Hautes-terres d'Arathi."
    L["HINT_STEALTHED"]     = "|cffff4444[Overlord]|r Impossible de capturer en furtivité."
    L["HINT_DEAD"]          = "|cffff4444[Overlord]|r Impossible de capturer lorsque vous êtes mort."
    L["HINT_NO_ADJACENT"]   = "|cffff4444[Overlord]|r Votre faction doit contrôler une zone adjacente d'abord."
    L["HINT_ALREADY_OWNED"] = "|cffff4444[Overlord]|r Déjà contrôlée par votre faction."
end
