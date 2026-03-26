-------------------------------------------------------------------------------
-- Overlord — Zones.lua
-- Arathi Highlands capture-zone definitions for WoW 3.3.5
--
-- Battlefield layout (3-lane):
--
--   STROMGARDE ─── REFUGE_POINTE ─── NORTHFOLD ─── GOSHEK ─── BOULDERGOR ─── HAMMERFALL
--        │                                              │
--   WEST_BINDING ──────────── DABYRIE ──────── EAST_BINDING ─── WITHERBARK
--
-- Alliance pushes East from Stromgarde; Horde pushes West from Hammerfall.
-- Home bases (Stromgarde, Hammerfall) are permanent strongholds — uncapturable.
-- All other nodes start Neutral and require adjacent friendly control.
--
-- mapX / mapY: approximate 0–1 fractions on the Arathi Highlands world-map tile,
-- used for future WorldMap overlay markers.
--
-- subzones: the exact strings returned by GetSubZoneText() when the player
-- stands at that capture point (verified against 3.3.5 data).
-------------------------------------------------------------------------------

Overlord_ZoneData = {
    -- ── HOME BASES ────────────────────────────────────────────────────────────
    {
        id        = "stromgarde",
        nameKey   = "ZONE_STROMGARDE",
        subzones  = { "Stromgarde Keep" },
        faction   = "Alliance",
        isBase    = true,
        adjacents = { "refuge_pointe", "west_binding" },
        mapX = 0.218, mapY = 0.715,
    },
    {
        id        = "hammerfall",
        nameKey   = "ZONE_HAMMERFALL",
        subzones  = { "Hammerfall" },
        faction   = "Horde",
        isBase    = true,
        adjacents = { "bouldergor", "east_binding" },
        mapX = 0.823, mapY = 0.418,
    },

    -- ── NORTH LANE ────────────────────────────────────────────────────────────
    {
        id        = "refuge_pointe",
        nameKey   = "ZONE_REFUGE",
        subzones  = { "Refuge Pointe" },
        faction   = "Neutral",
        adjacents = { "stromgarde", "northfold" },
        mapX = 0.275, mapY = 0.385,
    },
    {
        id        = "northfold",
        nameKey   = "ZONE_NORTHFOLD",
        subzones  = { "Northfold Manor" },
        faction   = "Neutral",
        adjacents = { "refuge_pointe", "goshek" },
        mapX = 0.355, mapY = 0.215,
    },
    {
        id        = "goshek",
        nameKey   = "ZONE_GOSHEK",
        subzones  = { "Go'Shek Farm" },
        faction   = "Neutral",
        adjacents = { "northfold", "bouldergor", "dabyrie" },
        mapX = 0.548, mapY = 0.505,
    },
    {
        id        = "bouldergor",
        nameKey   = "ZONE_BOULDERGOR",
        subzones  = { "Boulder'gor" },
        faction   = "Neutral",
        adjacents = { "goshek", "hammerfall" },
        mapX = 0.782, mapY = 0.618,
    },

    -- ── SOUTH LANE ────────────────────────────────────────────────────────────
    {
        id        = "west_binding",
        nameKey   = "ZONE_WEST_BINDING",
        subzones  = { "Circle of West Binding" },
        faction   = "Neutral",
        adjacents = { "stromgarde", "dabyrie" },
        mapX = 0.378, mapY = 0.815,
    },
    {
        id        = "dabyrie",
        nameKey   = "ZONE_DABYRIE",
        subzones  = { "Dabyrie's Farmstead" },
        faction   = "Neutral",
        adjacents = { "west_binding", "goshek", "east_binding" },
        mapX = 0.525, mapY = 0.698,
    },
    {
        id        = "east_binding",
        nameKey   = "ZONE_EAST_BINDING",
        subzones  = { "Circle of East Binding" },
        faction   = "Neutral",
        adjacents = { "dabyrie", "witherbark", "hammerfall" },
        mapX = 0.658, mapY = 0.742,
    },
    {
        id        = "witherbark",
        nameKey   = "ZONE_WITHERBARK",
        subzones  = { "Witherbark Village" },
        faction   = "Neutral",
        adjacents = { "east_binding" },
        mapX = 0.685, mapY = 0.852,
    },
}

-- ── Lookup tables built at load time ────────────────────────────────────────

Overlord_ZoneById      = {}   -- id  -> zone table
Overlord_ZoneBySubzone = {}   -- subzone string -> zone table

for _, zone in ipairs(Overlord_ZoneData) do
    Overlord_ZoneById[zone.id] = zone
    for _, sub in ipairs(zone.subzones) do
        Overlord_ZoneBySubzone[sub] = zone
    end
end
