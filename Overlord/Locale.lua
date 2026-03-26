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
L["MSG_LOADED"]        = "[Overlord] Port 3.3.5 (Ascension/Bronzebeard) ready. Joining channel..."
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

-- Camp selection
-- On Ascension WoW (crossfaction), players must explicitly choose which side
-- they fight for — UnitFactionGroup() reflects race, not PvP allegiance.
L["CAMP_TITLE"]          = "Choose Your Side"
L["CAMP_BODY"]           = "Overlord is a World PvP campaign for Arathi Highlands.\nPick the side you will fight for this week.\nYou can change it at any time with  /overlord join alliance  or  /overlord join horde."
L["CAMP_BTN_ALLIANCE"]   = "Fight for the Alliance"
L["CAMP_BTN_HORDE"]      = "Fight for the Horde"
L["CAMP_BTN_LEAVE"]      = "Leave Campaign"
L["CAMP_JOINED"]         = "|cff00ccff[Overlord]|r You are now fighting for the |cff3399ffAlliance|r."
L["CAMP_JOINED_HORDE"]   = "|cff00ccff[Overlord]|r You are now fighting for the |cffcc2222Horde|r."
L["CAMP_LEFT"]           = "|cff00ccff[Overlord]|r You have left the campaign."
L["CAMP_NONE"]           = "|cffff4444[Overlord]|r You have not chosen a side yet. Type /overlord to open the panel."
L["CAMP_CURRENT_A"]      = "Current side: |cff3399ffAlliance|r"
L["CAMP_CURRENT_H"]      = "Current side: |cffcc2222Horde|r"
L["CAMP_CURRENT_NONE"]   = "Current side: |cff888888None (not enrolled)|r"
L["SLASH_USAGE"]         = "|cff00ccff[Overlord]|r Usage:\n  /overlord          - open panel\n  /overlord join alliance\n  /overlord join horde\n  /overlord leave\n  /overlord sync\n  /overlord reset    (GM only, local)"

-- Capture hints (printed to player when ineligible)
L["HINT_NOT_IN_ARATHI"] = "|cffff4444[Overlord]|r You must be in Arathi Highlands."
L["HINT_STEALTHED"]     = "|cffff4444[Overlord]|r Cannot capture while stealthed."
L["HINT_DEAD"]          = "|cffff4444[Overlord]|r Cannot capture while dead."
L["HINT_NO_ADJACENT"]   = "|cffff4444[Overlord]|r Your camp must control an adjacent zone first."
L["HINT_ALREADY_OWNED"] = "|cffff4444[Overlord]|r Already controlled by your camp."

-- ============================================================
-- French overrides
-- ============================================================

if GetLocale() == "frFR" then
    L["ZONE_STROMGARDE"]   = "Chateau de Stromgarde"
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
    L["STATUS_CONTESTED"] = "Conteste"

    L["MSG_CAPTURED"]     = "%s a capture %s !"
    L["MSG_LOST"]         = "%s a perdu %s !"
    L["MSG_CONTESTED"]    = "%s est attaque !"
    L["MSG_WEEKLY_RESET"] = "[Overlord] Reinitialisation hebdomadaire — la bataille pour Arathi recommence."
    L["MSG_LOADED"]       = "[Overlord] Port 3.3.5 (Ascension/Bronzebeard) pret. Connexion au canal..."
    L["MSG_JOINED_CH"]    = "[Overlord] Canal de coordination Overlord rejoint."
    L["MSG_SYNC_SENT"]    = "[Overlord] Synchronisation demandee."

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
    L["TT_HOLDER"]    = "Controlee par : "
    L["TT_PROGRESS"]  = "Progression : "

    L["HINT_NOT_IN_ARATHI"] = "|cffff4444[Overlord]|r Vous devez etre dans les Hautes-terres d'Arathi."
    L["HINT_STEALTHED"]     = "|cffff4444[Overlord]|r Impossible de capturer en furtivite."
    L["HINT_DEAD"]          = "|cffff4444[Overlord]|r Impossible de capturer lorsque vous etes mort."
    L["HINT_NO_ADJACENT"]   = "|cffff4444[Overlord]|r Votre camp doit controler une zone adjacente d'abord."
    L["HINT_ALREADY_OWNED"] = "|cffff4444[Overlord]|r Deja controlee par votre camp."

    -- Camp selection (FR)
    L["CAMP_TITLE"]          = "Choisissez votre camp"
    L["CAMP_BODY"]           = "Overlord est une campagne World PvP dans les Hautes-terres d'Arathi.\nChoisissez le camp que vous defenderez cette semaine.\nChangeable via /overlord join alliance ou /overlord join horde."
    L["CAMP_BTN_ALLIANCE"]   = "Combattre pour l'Alliance"
    L["CAMP_BTN_HORDE"]      = "Combattre pour la Horde"
    L["CAMP_BTN_LEAVE"]      = "Quitter la campagne"
    L["CAMP_JOINED"]         = "|cff00ccff[Overlord]|r Vous combattez desormais pour l'|cff3399ffAlliance|r."
    L["CAMP_JOINED_HORDE"]   = "|cff00ccff[Overlord]|r Vous combattez desormais pour la |cffcc2222Horde|r."
    L["CAMP_LEFT"]           = "|cff00ccff[Overlord]|r Vous avez quitte la campagne."
    L["CAMP_NONE"]           = "|cffff4444[Overlord]|r Vous n'avez pas encore choisi de camp. Tapez /overlord pour ouvrir le panneau."
    L["CAMP_CURRENT_A"]      = "Camp actuel : |cff3399ffAlliance|r"
    L["CAMP_CURRENT_H"]      = "Camp actuel : |cffcc2222Horde|r"
    L["CAMP_CURRENT_NONE"]   = "Camp actuel : |cff888888Aucun (non inscrit)|r"
    L["SLASH_USAGE"]         = "|cff00ccff[Overlord]|r Utilisation :\n  /overlord              - ouvrir le panneau\n  /overlord join alliance\n  /overlord join horde\n  /overlord leave\n  /overlord sync\n  /overlord reset        (GM uniquement, local)"
end
