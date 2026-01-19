Config = {}

Config.target = 'qb-target' -- Options: 'qb-target', 'ox-target'
Config.inventory = 'qs-inventory' -- Options: 'qb-inventory', 'qs-inventory', 'ox_inventory'

-- ============================================================================
-- JAIL SYSTEM CONFIGURATION
-- ============================================================================
-- Requires oxmysql and running the SQL migration in sql/jail_records.sql

Config.jailSystem = {
    enabled = true,                    -- Enable jail/unavailability system
    defaultJailHours = 24,             -- Base jail time in game hours
    maxJailHours = 72,                 -- Maximum jail time
    gameHourToRealMinutes = 2,         -- How many real minutes = 1 game hour (default GTA is 2)

    -- Bonus jail time for different offense types
    weaponBonus = 12,                  -- Extra hours for weapons
    drugBrickBonus = 8,                -- Extra hours for large drug quantities
    drugBonus = 4,                     -- Extra hours for regular drugs
    crimeToolBonus = 6,                -- Extra hours for lockpicks, thermite, etc.

    -- Intel trading reduces sentence
    intelReduction = 0.5,              -- Multiplier when NPC gives intel (0.5 = 50% reduction)
}

-- ============================================================================
-- JAIL STATUS CACHE (Performance for high-pop servers)
-- ============================================================================
-- Instead of querying the database every time we need to check if a character
-- is available, we use an in-memory cache that refreshes periodically.
-- This reduces DB load from potentially hundreds of queries to 1 per minute.

Config.jailStatusCache = {
    refreshInterval = 60000,           -- How often to refresh cache in ms (60000 = 60 seconds)
    debug = false,                     -- Log cache refreshes to console
}

-- ============================================================================
-- AI INTEGRATION (dps-ainpcs)
-- ============================================================================

Config.aiIntegration = {
    enabled = false,                   -- Enable AI dialogue integration
    resource = 'dps-ainpcs',           -- AI NPC resource name
    useAIForDialogue = true,           -- Use AI to generate NPC responses
    fallbackToStatic = true,           -- Use static dialogues if AI unavailable
}

-- ============================================================================
-- INTEL SYSTEM CONFIGURATION
-- ============================================================================

-- Templates for generated intel (placeholders: {location}, {name}, {gang})
Config.intelTemplates = {
    drugs = {
        "There's a guy who hangs around {location}, he's been moving weight lately.",
        "Check the parking lot behind {location}, deals go down there every night.",
        "I heard {name} has been cooking in a house near {location}.",
        "Big shipment coming through {location} this week.",
        "The spot behind the gas station at {location} is where they stash it.",
    },
    weapons = {
        "There's an arms deal happening near {location} soon.",
        "Check the trunk of cars parked at {location}, lots of heat moving through there.",
        "Some guys have been stockpiling at a warehouse near {location}.",
        "{name} runs guns out of {location}. Everyone knows it.",
        "There's a guy at {location} who can get you anything. Military grade.",
    },
    gang = {
        "The {gang} have been recruiting near {location}.",
        "There's beef brewing between crews at {location}.",
        "Watch {location}, something big is being planned.",
        "{gang} jumped some kid near {location} last week. They're expanding.",
        "The corner at {location} belongs to {gang} now.",
    }
}

-- Locations used in intel generation
Config.intelLocations = {
    "Grove Street", "Mirror Park", "Vinewood", "Del Perro", "Vespucci",
    "La Mesa", "Strawberry", "Davis", "Rancho", "East Los Santos",
    "Pillbox Hill", "Little Seoul", "Rockford Hills", "Pacific Bluffs",
    "Paleto Bay", "Sandy Shores", "Grapeseed", "Harmony"
}

-- ============================================================================
-- MDT/DISPATCH INTEGRATION
-- ============================================================================

-- MDT/Dispatch Integration (wasabi_mdt)
Config.dispatch = {
    enabled = true,                    -- Enable dispatch notifications
    resource = 'wasabi_mdt',           -- Dispatch resource name

    -- When illegal items are found during frisk
    illegalItemsFound = {
        enabled = true,
        priority = 2,                  -- 1-5 (5 = highest priority)
        type = 'drugs',                -- Dispatch type/icon
        title = 'Contraband Located',
        description = 'Officer located contraband during pedestrian stop. Requesting backup for potential arrest.',
    },

    -- When suspect flees (chase scenario)
    suspectFleeing = {
        enabled = true,
        priority = 3,
        type = 'pursuit',
        title = 'Foot Pursuit',
        description = 'Suspect fled on foot after being confronted with contraband. Pursuing suspect.',
    },

    -- When arrest is made successfully
    arrestMade = {
        enabled = true,
        priority = 1,
        type = 'arrest',
        title = 'Arrest Made',
        description = 'Suspect apprehended and in custody.',
    },
}

-- How many items should NPCs carry? (random between min and max)
Config.npcItemCount = { min = 3, max = 6 }

-- Quantity range for items (random between min and max)
Config.itemQuantity = { min = 1, max = 5 }

-- Items that are ILLEGAL (will trigger arrest option)
-- Just list the item spawn names - no need to duplicate the whole item database
Config.illegalItems = {
    -- Drugs
    "joint", "cokebaggy", "crack_baggy", "xtcbaggy", "meth", "meth_baggy",
    "weed_brick", "coke_brick", "coke_small_brick", "oxy", "heroin",
    "weed_white-widow", "weed_skunk", "weed_purple-haze", "weed_og-kush",
    "weed_amnesia", "weed_ak47", "weed_baggy", "weed", "lsd", "ecstasy",
    "cocaine", "opium", "shrooms", "acid", "pills", "xanax",

    -- Weapons (non-police)
    "weapon_pistol", "weapon_snspistol", "weapon_heavypistol", "weapon_vintagepistol",
    "weapon_pistol50", "weapon_appistol", "weapon_combatpistol", "weapon_pistol_mk2",
    "weapon_revolver", "weapon_revolver_mk2", "weapon_doubleaction",
    "weapon_knife", "weapon_switchblade", "weapon_dagger", "weapon_machete",
    "weapon_bottle", "weapon_knuckle", "weapon_hatchet", "weapon_battleaxe",
    "weapon_microsmg", "weapon_smg", "weapon_assaultsmg", "weapon_minismg",
    "weapon_pumpshotgun", "weapon_sawnoffshotgun", "weapon_assaultshotgun",
    "weapon_assaultrifle", "weapon_carbinerifle", "weapon_advancedrifle",
    "weapon_specialcarbine", "weapon_bullpuprifle", "weapon_compactrifle",

    -- Ammo
    "pistol_ammo", "smg_ammo", "rifle_ammo", "shotgun_ammo", "sniper_ammo",
    "ammo_pistol", "ammo_smg", "ammo_rifle", "ammo_shotgun", "ammo_sniper",

    -- Crime tools
    "lockpick", "advancedlockpick", "electronickit", "thermite", "hackerdevice",
    "vpn", "laptop", "cryptostick", "trojan_usb", "usb_device",
    "handcuffs", "ziptie", "duct_tape",

    -- Stolen goods
    "markedbills", "goldbar", "rolex", "diamond", "diamond_ring", "jewels",
    "stolen_goods", "dirty_money", "evidence", "moneybag",
    "10kgoldchain", "chain", "bracelet", "necklace",

    -- Fake/forged items
    "fakeid", "fakeplate", "fake_id",
}

-- Items to EXCLUDE from spawning on NPCs (job items, unique items, materials, etc.)
Config.excludedItems = {
    -- Phone/identification (everyone has these, not interesting)
    "phone", "id_card", "driver_license",

    -- Job-specific items
    "police_badge", "ems_badge", "mechanic_badge",
    "radio", "radioscanner", "handcuffs", "weapon_stungun",
    "armor", "heavyarmor", "bodyarmor",

    -- Vehicle/housing keys
    "carkey", "housekey", "keychain",

    -- Crafting materials (boring on NPCs)
    "plastic", "glass", "metalscrap", "copper", "iron", "steel", "aluminum",
    "rubber", "cloth", "leather", "wood", "carbon",

    -- Seeds and farming
    "weed_white-widow_seed", "weed_skunk_seed", "weed_purple-haze_seed",
    "weed_og-kush_seed", "weed_amnesia_seed", "weed_ak47_seed",
    "seed", "fertilizer", "water_can",

    -- Misc excluded
    "stickynote", "empty_evidence_bag", "filled_evidence_bag",
    "parachute", "binoculars",
}

-- Fallback items if GetItemList fails or returns empty
-- These will be used as a backup
Config.fallbackItems = {
    { item = "water_bottle", label = "Water Bottle" },
    { item = "sandwich", label = "Sandwich" },
    { item = "coffee", label = "Coffee" },
    { item = "cigarette", label = "Cigarette" },
    { item = "lighter", label = "Lighter" },
    { item = "money", label = "Cash" },
    { item = "joint", label = "Joint" },
    { item = "cokebaggy", label = "Bag of Coke" },
    { item = "lockpick", label = "Lockpick" },
    { item = "weapon_knife", label = "Knife" },
}

-- ============================================================================
-- RECURRING CHARACTERS (Known Criminals)
-- ============================================================================
-- These characters have a chance to spawn instead of random NPCs
-- They build up rap sheets over time and become familiar faces

Config.recurringCharacters = {
    enabled = true,
    spawnChance = 25,             -- 25% chance a stopped NPC is a known criminal
    shareWithAINpcs = true,       -- Share character pool with dps-ainpcs
    rotationEnabled = true,       -- Rotate which characters are "active" each day
    activeCharactersPerDay = 6,   -- How many recurring characters are active at once
    rotationIntervalMinutes = 48, -- Real minutes per "day" rotation (48 = 1 GTA day)

    -- Character data is in shared/characters.lua (SharedCharacters.pool)
    -- This allows dps-ainpcs to use the same characters
    -- Edit shared/characters.lua to add/modify characters
}

-- Personality data is also in shared/characters.lua (SharedCharacters.personalities)
-- Access via: SharedCharacters.GetPersonality("nervous")

-- ============================================================================
-- RANDOM NPC NAMES
-- ============================================================================

-- Names for NPC identification
Config.malefirstNames = {
    "John", "Michael", "David", "Luis", "Kyle", "Luke", "Shawn", "Tyrone",
    "Adam", "Arthur", "Steve", "Ricardo", "James", "Pablo", "Micah", "Walter",
    "Marcus", "Derek", "Brandon", "Kevin", "Eric", "Jason", "Tyler", "Justin",
    "Carlos", "Antonio", "Raymond", "Eugene", "Trevor", "Franklin", "Lamar",
    "Robert", "William", "Joseph", "Charles", "Thomas", "Daniel", "Matthew",
    "Anthony", "Donald", "Steven", "Andrew", "Kenneth", "George", "Edward"
}

Config.femalefirstNames = {
    "Emily", "Madison", "Abigail", "Chloe", "Hailey", "Ashley", "Samantha",
    "Jessica", "Avery", "Ella", "Grace", "Brooklyn", "Natalie", "Addison",
    "Harper", "Scarlett", "Savannah", "Victoria", "Lily", "Zoey", "Maria",
    "Nicole", "Amanda", "Rachel", "Stephanie", "Michelle", "Christina",
    "Tracey", "Denise", "Tanisha", "Tonya", "Patricia", "Jennifer", "Linda",
    "Elizabeth", "Barbara", "Susan", "Margaret", "Dorothy", "Lisa", "Karen"
}

Config.lastNames = {
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis",
    "Garcia", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "White",
    "Bell", "Thompson", "Robinson", "Clark", "Lewis", "Lee", "Walker",
    "Hall", "Allen", "Young", "King", "Wright", "Scott", "Green", "Baker",
    "De Santa", "Philips", "Clinton", "Townley", "Adams", "Nelson", "Hill",
    "Mitchell", "Roberts", "Carter", "Phillips", "Evans", "Turner", "Torres"
}
