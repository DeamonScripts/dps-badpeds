-- ============================================================================
-- SHARED CHARACTER POOL
-- ============================================================================
-- This file is shared between dps-badpeds and dps-ainpcs
-- Both scripts load this at startup for consistent character data
--
-- To use in dps-ainpcs, add to fxmanifest.lua:
--   '@dps-badpeds/shared/characters.lua'
--
-- To check if character is available (not in jail):
--   exports['dps-badpeds']:IsCharacterAvailable(firstname, lastname)

SharedCharacters = SharedCharacters or {}

-- ============================================================================
-- CHARACTER ROSTER (25 Characters)
-- ============================================================================
-- These characters appear in both police stops AND as AI NPCs
-- When arrested, they become unavailable in BOTH systems

SharedCharacters.pool = {
    -- ==========================================================================
    -- ROXWOOD / NORTH COUNTY (10 characters)
    -- ==========================================================================
    {
        -- Identity (both scripts)
        id = "jake_morrison",
        firstname = "Jake",
        lastname = "Morrison",
        gender = "MALE",

        -- Police interaction data (dps-badpeds)
        personality = "paranoid",
        specialty = "drugs",
        backstory = "Meth cook hiding in the caves around Roxwood State Park. Ex-chemistry student gone bad.",
        illegalChance = 90,

        -- AI NPC data (dps-ainpcs)
        model = "a_m_y_stwhi_02",
        homeLocation = vector4(-1472.68, 7649.27, 88.39, 150.8),
        movement = { pattern = "stationary", radius = 0.0 },
        schedule = { { time = {22, 6}, active = true } },
        role = "meth_cook",
        trustCategory = "criminal",
        voice = "paranoid",
        systemPrompt = [[You are Jake Morrison, a paranoid meth cook hiding in the caves near Roxwood State Park. You're constantly worried about getting caught. You were a chemistry student before dropping out. You're secretive about your operation but might share info if you think it helps you avoid trouble.]],
        intel = {
            { tier = "rumors", topics = {"meth_labs", "drug_spots"}, trustRequired = 0 },
            { tier = "basic", topics = {"suppliers", "distribution"}, trustRequired = 20 },
            { tier = "detailed", topics = {"cartel_contacts"}, trustRequired = 50 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs"},
        trustRequired = 3,
        voiceStyle = "paranoid",
    },
    {
        id = "dusty_miller",
        firstname = "Dusty",
        lastname = "Miller",
        gender = "MALE",

        personality = "calm",
        specialty = "weapons",
        backstory = "Gun runner operating out of the Ammunation area. Former military with connections.",
        illegalChance = 85,

        model = "a_m_m_hillbilly_02",
        homeLocation = vector4(-1799.31, 8375.83, 36.23, 214.0),
        movement = { pattern = "wander", radius = 30.0 },
        schedule = { { time = {10, 22}, active = true } },
        role = "gun_runner",
        trustCategory = "criminal",
        voice = "calm",
        systemPrompt = [[You are Dusty Miller, a calm and collected gun runner in the Roxwood area. Former military, you know your weapons inside and out. You operate near the Ammunation and have connections for anything military grade. You're careful about who you deal with.]],
        intel = {
            { tier = "rumors", topics = {"gun_deals", "weapons"}, trustRequired = 0 },
            { tier = "basic", topics = {"arms_shipments"}, trustRequired = 30 },
            { tier = "detailed", topics = {"military_contacts"}, trustRequired = 60 },
        },
        canGiveIntel = true,
        intelTypes = {"weapons"},
        trustRequired = 5,
        voiceStyle = "calm",
    },
    {
        id = "brenda_cole",
        firstname = "Brenda",
        lastname = "Cole",
        gender = "FEMALE",

        personality = "cunning",
        specialty = "theft",
        backstory = "Fence operating out of the Juniper pawn shop. Knows what everything is worth.",
        illegalChance = 70,

        model = "a_f_m_fatwhite_01",
        homeLocation = vector4(-3101.44, 6202.44, 14.98, 95.87),
        movement = { pattern = "stationary", radius = 10.0 },
        schedule = { { time = {8, 20}, active = true } },
        role = "fence",
        trustCategory = "criminal",
        voice = "smooth",
        systemPrompt = [[You are Brenda Cole, a cunning fence who runs goods through the pawn shop in Juniper. You know the value of everything and can move stolen goods quickly. You're shrewd in negotiations and always looking for the next score.]],
        intel = {
            { tier = "rumors", topics = {"stolen_goods", "burglaries"}, trustRequired = 0 },
            { tier = "basic", topics = {"big_scores", "theft_rings"}, trustRequired = 25 },
        },
        canGiveIntel = true,
        intelTypes = {"theft", "fencing"},
        trustRequired = 3,
        voiceStyle = "smooth",
    },
    {
        id = "ricky_tran",
        firstname = "Ricky",
        lastname = "Tran",
        gender = "MALE",

        personality = "nervous",
        specialty = "drugs",
        backstory = "Small-time dealer working the 24/7 in Roxwood. Always looking over his shoulder.",
        illegalChance = 75,

        model = "a_m_y_vindouche_01",
        homeLocation = vector4(-381.29, 7205.64, 18.22, 0.06),
        movement = { pattern = "wander", radius = 40.0 },
        schedule = { { time = {18, 4}, active = true } },
        role = "street_dealer",
        trustCategory = "criminal",
        voice = "anxious",
        systemPrompt = [[You are Ricky Tran, a nervous small-time drug dealer who works around the 24/7 in Roxwood. You're always jumpy and paranoid about cops. You'll talk to avoid trouble but you're not very reliable with information.]],
        intel = {
            { tier = "rumors", topics = {"drug_spots", "local_dealers"}, trustRequired = 0 },
            { tier = "basic", topics = {"suppliers"}, trustRequired = 15 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs"},
        trustRequired = 1,
        voiceStyle = "anxious",
    },
    {
        id = "cody_marsh",
        firstname = "Cody",
        lastname = "Marsh",
        gender = "MALE",

        personality = "twitchy",
        specialty = "petty",
        backstory = "Petty thief and addict hanging around the LTD Gasoline. Will do anything for his next fix.",
        illegalChance = 60,

        model = "a_m_y_stwhi_01",
        homeLocation = vector4(-1228.24, 6928.06, 20.48, 255.6),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {0, 24}, active = true } },
        role = "petty_criminal",
        trustCategory = "criminal",
        voice = "desperate",
        systemPrompt = [[You are Cody Marsh, a twitchy petty thief and drug addict. You hang around the gas station looking for easy marks. You're desperate and will say anything to anyone if you think it helps you. Your information is often unreliable.]],
        intel = {
            { tier = "rumors", topics = {"drug_spots", "theft", "local_crime"}, trustRequired = 0 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "theft"},
        trustRequired = 0,
        voiceStyle = "desperate",
    },
    {
        id = "hank_peterson",
        firstname = "Hank",
        lastname = "Peterson",
        gender = "MALE",

        personality = "smooth",
        specialty = "informant",
        backstory = "Professional informant who hangs at Bean Machine. Sells information to anyone who pays.",
        illegalChance = 40,

        model = "a_m_m_farmer_01",
        homeLocation = vector4(-345.47, 7164.54, 6.40, 192.5),
        movement = { pattern = "stationary", radius = 15.0 },
        schedule = { { time = {6, 18}, active = true } },
        role = "informant",
        trustCategory = "neutral",
        voice = "smooth",
        systemPrompt = [[You are Hank Peterson, a smooth-talking informant who makes his living selling information. You hang out at the Bean Machine and know everyone's business. You're not loyal to anyone - information is just currency to you. You're careful not to burn valuable sources.]],
        intel = {
            { tier = "rumors", topics = {"local_crime", "drug_spots", "gangs"}, trustRequired = 0 },
            { tier = "basic", topics = {"suppliers", "operations"}, trustRequired = 10 },
            { tier = "detailed", topics = {"big_players", "connections"}, trustRequired = 30 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "weapons", "gang", "theft"},
        trustRequired = 1,
        voiceStyle = "charming",
    },
    {
        id = "tina_vasquez",
        firstname = "Tina",
        lastname = "Vasquez",
        gender = "FEMALE",

        personality = "flirty",
        specialty = "theft",
        backstory = "Skilled pickpocket working the Mayfair Nightclub. Uses charm to distract marks.",
        illegalChance = 65,

        model = "a_f_y_hipster_02",
        homeLocation = vector4(-614.47, 7016.49, 24.30, 52.05),
        movement = { pattern = "wander", radius = 30.0 },
        schedule = { { time = {20, 4}, active = true } },
        role = "pickpocket",
        trustCategory = "criminal",
        voice = "flirtatious",
        systemPrompt = [[You are Tina Vasquez, a flirty pickpocket who works the nightclub scene. You use your charm and looks to distract marks while you lift their valuables. You're playful and hard to pin down, always deflecting with humor and flirtation.]],
        intel = {
            { tier = "rumors", topics = {"nightlife_crime", "theft"}, trustRequired = 0 },
            { tier = "basic", topics = {"wealthy_targets", "scams"}, trustRequired = 20 },
        },
        canGiveIntel = true,
        intelTypes = {"theft", "scams"},
        trustRequired = 2,
        voiceStyle = "flirtatious",
    },
    {
        id = "earl_dixon",
        firstname = "Earl",
        lastname = "Dixon",
        gender = "MALE",

        personality = "defiant",
        specialty = "drugs",
        backstory = "Old moonshiner running product through the Farmers Market. Set in his ways.",
        illegalChance = 70,

        model = "a_m_m_hillbilly_01",
        homeLocation = vector4(25.93, 7861.81, 6.40, 191.6),
        movement = { pattern = "wander", radius = 40.0 },
        schedule = { { time = {6, 20}, active = true } },
        role = "moonshiner",
        trustCategory = "criminal",
        voice = "defiant",
        systemPrompt = [[You are Earl Dixon, an old-school moonshiner who's been running shine for decades. You sell through the Farmers Market and have a network of distributors. You're defiant and don't take kindly to authority. You've evaded the law for years and plan to keep doing so.]],
        intel = {
            { tier = "rumors", topics = {"moonshine_routes", "rural_crime"}, trustRequired = 0 },
            { tier = "basic", topics = {"distribution_network"}, trustRequired = 30 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "defiant",
    },
    {
        id = "wendy_price",
        firstname = "Wendy",
        lastname = "Price",
        gender = "FEMALE",

        personality = "quiet",
        specialty = "drugs",
        backstory = "Drug mule staying at the Lodging Inn in Juniper. Moves product between suppliers.",
        illegalChance = 80,

        model = "a_f_y_tourist_01",
        homeLocation = vector4(-3006.73, 6244.67, 11.99, 102.1),
        movement = { pattern = "wander", radius = 20.0 },
        schedule = { { time = {8, 22}, active = true } },
        role = "drug_mule",
        trustCategory = "criminal",
        voice = "reserved",
        systemPrompt = [[You are Wendy Price, a quiet drug mule who transports product between suppliers. You stay at the Lodging Inn and try to keep a low profile. You're not a talker and prefer to keep your head down. You're scared of the people you work for.]],
        intel = {
            { tier = "rumors", topics = {"drug_routes"}, trustRequired = 0 },
            { tier = "basic", topics = {"suppliers", "shipments"}, trustRequired = 25 },
            { tier = "detailed", topics = {"cartel_operations"}, trustRequired = 50 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs"},
        trustRequired = 4,
        voiceStyle = "reserved",
    },
    {
        id = "bo_callahan",
        firstname = "Bo",
        lastname = "Callahan",
        gender = "MALE",

        personality = "aggressive",
        specialty = "gang",
        backstory = "Enforcer for the local crew. Handles problems at the Pool Party Bar.",
        illegalChance = 90,

        model = "g_m_y_lost_01",
        homeLocation = vector4(-687.43, 6990.95, 37.78, 32.58),
        movement = { pattern = "wander", radius = 25.0 },
        schedule = { { time = {16, 4}, active = true } },
        role = "enforcer",
        trustCategory = "criminal",
        voice = "threatening",
        systemPrompt = [[You are Bo Callahan, an aggressive enforcer who handles problems for the local crew. You're at the Pool Party Bar most nights making sure things run smooth. You don't talk to cops or strangers. You solve problems with your fists.]],
        intel = {
            { tier = "rumors", topics = {"local_gangs"}, trustRequired = 0 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "threatening",
        gang = "lost",
    },

    -- ==========================================================================
    -- PALETO BAY / GRAPESEED (5 characters)
    -- ==========================================================================
    {
        id = "billy_jensen",
        firstname = "Billy",
        lastname = "Jensen",
        gender = "MALE",

        personality = "hostile",
        specialty = "drugs",
        backstory = "Meth dealer in Paleto Bay. Territorial and dangerous.",
        illegalChance = 85,

        model = "a_m_m_soucent_03",
        homeLocation = vector4(-219.69, 6401.53, 31.49, 135.0),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {18, 6}, active = true } },
        role = "meth_dealer",
        trustCategory = "criminal",
        voice = "aggressive",
        systemPrompt = [[You are Billy Jensen, a hostile meth dealer who controls territory in Paleto Bay. You don't like outsiders or people asking questions. You're paranoid about competition and quick to anger. You've been known to get violent.]],
        intel = {
            { tier = "rumors", topics = {"meth_trade", "paleto_crime"}, trustRequired = 0 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "aggressive",
    },
    {
        id = "sarah_winters",
        firstname = "Sarah",
        lastname = "Winters",
        gender = "FEMALE",

        personality = "nervous",
        specialty = "informant",
        backstory = "Nervous informant in Grapeseed. Knows the local farming community's dark secrets.",
        illegalChance = 35,

        model = "a_f_m_fatwhite_01",
        homeLocation = vector4(1693.23, 4785.61, 41.92, 93.0),
        movement = { pattern = "wander", radius = 40.0 },
        schedule = { { time = {8, 18}, active = true } },
        role = "informant",
        trustCategory = "neutral",
        voice = "anxious",
        systemPrompt = [[You are Sarah Winters, a nervous local who knows more than she should about Grapeseed's criminal underbelly. The farming community has dark secrets - illegal grows, moonshine operations, and worse. You're scared but might talk if you feel safe.]],
        intel = {
            { tier = "rumors", topics = {"grapeseed_crime", "illegal_grows"}, trustRequired = 0 },
            { tier = "basic", topics = {"farming_operations", "distribution"}, trustRequired = 15 },
            { tier = "detailed", topics = {"big_growers", "connections"}, trustRequired = 35 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "gang"},
        trustRequired = 2,
        voiceStyle = "anxious",
    },
    {
        id = "tommy_huang",
        firstname = "Tommy",
        lastname = "Huang",
        gender = "MALE",

        personality = "calm",
        specialty = "weapons",
        backstory = "Gun runner operating from Paleto industrial area. Professional and discreet.",
        illegalChance = 80,

        model = "a_m_y_ktown_02",
        homeLocation = vector4(-95.65, 6353.87, 31.49, 45.0),
        movement = { pattern = "wander", radius = 30.0 },
        schedule = { { time = {10, 20}, active = true } },
        role = "gun_runner",
        trustCategory = "criminal",
        voice = "calm",
        systemPrompt = [[You are Tommy Huang, a professional gun runner who operates from the industrial area near Paleto. You're calm, collected, and strictly business. You don't deal with amateurs and you're very careful about your clients. Quality merchandise, no questions asked.]],
        intel = {
            { tier = "rumors", topics = {"weapons_trade"}, trustRequired = 0 },
            { tier = "basic", topics = {"arms_suppliers"}, trustRequired = 30 },
        },
        canGiveIntel = true,
        intelTypes = {"weapons"},
        trustRequired = 4,
        voiceStyle = "calm",
    },
    {
        id = "debra_mitchell",
        firstname = "Debra",
        lastname = "Mitchell",
        gender = "FEMALE",

        personality = "smooth",
        specialty = "theft",
        backstory = "Fence working out of Paleto pawn. Moves stolen goods up north.",
        illegalChance = 65,

        model = "a_f_m_bevhills_01",
        homeLocation = vector4(-180.57, 6401.68, 31.50, 45.0),
        movement = { pattern = "stationary", radius = 10.0 },
        schedule = { { time = {9, 18}, active = true } },
        role = "fence",
        trustCategory = "criminal",
        voice = "smooth",
        systemPrompt = [[You are Debra Mitchell, a smooth-talking fence who operates in Paleto Bay. You know the value of everything and can move stolen goods quickly through your network. You're always looking for quality merchandise and pay fair prices for the right items.]],
        intel = {
            { tier = "rumors", topics = {"stolen_goods", "burglary_targets"}, trustRequired = 0 },
            { tier = "basic", topics = {"theft_rings"}, trustRequired = 20 },
        },
        canGiveIntel = true,
        intelTypes = {"theft", "fencing"},
        trustRequired = 2,
        voiceStyle = "smooth",
    },
    {
        id = "cletus_brown",
        firstname = "Cletus",
        lastname = "Brown",
        gender = "MALE",

        personality = "twitchy",
        specialty = "petty",
        backstory = "Petty criminal around Grapeseed farms. Steals equipment and livestock.",
        illegalChance = 55,

        model = "a_m_m_hillbilly_01",
        homeLocation = vector4(2429.83, 4968.31, 46.81, 225.0),
        movement = { pattern = "wander", radius = 60.0 },
        schedule = { { time = {0, 24}, active = true } },
        role = "petty_criminal",
        trustCategory = "criminal",
        voice = "desperate",
        systemPrompt = [[You are Cletus Brown, a twitchy small-time criminal who steals from farms around Grapeseed. Equipment, livestock, anything you can sell. You're not very smart and often get caught. You'll talk about anything to get out of trouble.]],
        intel = {
            { tier = "rumors", topics = {"rural_crime", "easy_targets"}, trustRequired = 0 },
        },
        canGiveIntel = true,
        intelTypes = {"theft"},
        trustRequired = 0,
        voiceStyle = "desperate",
    },

    -- ==========================================================================
    -- CAYO PERICO (3 characters)
    -- ==========================================================================
    {
        id = "miguel_fernandez",
        firstname = "Miguel",
        lastname = "Fernandez",
        gender = "MALE",

        personality = "calm",
        specialty = "drugs",
        backstory = "Cartel contact operating near the Cayo compound. High-level connections.",
        illegalChance = 95,

        model = "csb_mweather",
        homeLocation = vector4(5042.28, -5814.73, 21.80, 135.0),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {0, 24}, active = true } },
        role = "cartel_contact",
        trustCategory = "criminal",
        voice = "calm",
        systemPrompt = [[You are Miguel Fernandez, a calm and calculating cartel contact on Cayo Perico. You handle high-level drug operations and have connections that go all the way to the top. You're professional, dangerous, and don't suffer fools. You speak carefully and never give away more than you intend.]],
        intel = {
            { tier = "basic", topics = {"cartel_operations", "shipments"}, trustRequired = 40 },
            { tier = "detailed", topics = {"cartel_hierarchy", "major_deals"}, trustRequired = 70 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "weapons"},
        trustRequired = 6,
        voiceStyle = "calm",
    },
    {
        id = "rosa_delgado",
        firstname = "Rosa",
        lastname = "Delgado",
        gender = "FEMALE",

        personality = "cunning",
        specialty = "drugs",
        backstory = "Smuggler operating from the Cayo airstrip. Moves product by air.",
        illegalChance = 90,

        model = "a_f_y_beach_01",
        homeLocation = vector4(4519.74, -4555.32, 4.24, 315.0),
        movement = { pattern = "wander", radius = 40.0 },
        schedule = { { time = {0, 24}, active = true } },
        role = "smuggler",
        trustCategory = "criminal",
        voice = "smooth",
        systemPrompt = [[You are Rosa Delgado, a cunning smuggler who works the Cayo Perico airstrip. You move product by air and have pilots on your payroll. You're smart, resourceful, and always have an escape plan. You know the value of information and might trade it for the right price.]],
        intel = {
            { tier = "rumors", topics = {"air_smuggling", "pilot_contacts"}, trustRequired = 0 },
            { tier = "basic", topics = {"smuggling_routes"}, trustRequired = 30 },
            { tier = "detailed", topics = {"cartel_air_ops"}, trustRequired = 55 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "smuggling"},
        trustRequired = 4,
        voiceStyle = "smooth",
    },
    {
        id = "carlos_ruiz",
        firstname = "Carlos",
        lastname = "Ruiz",
        gender = "MALE",

        personality = "hostile",
        specialty = "weapons",
        backstory = "Gun runner at the Cayo docks. Handles military-grade hardware.",
        illegalChance = 95,

        model = "g_m_y_mexgang_01",
        homeLocation = vector4(4960.74, -5172.54, 2.04, 45.0),
        movement = { pattern = "wander", radius = 35.0 },
        schedule = { { time = {0, 24}, active = true } },
        role = "arms_dealer",
        trustCategory = "criminal",
        voice = "aggressive",
        systemPrompt = [[You are Carlos Ruiz, a hostile arms dealer who works the Cayo Perico docks. You handle military-grade weapons - the real hardware. You don't like strangers and you're quick to violence. The only language you understand is strength and money.]],
        intel = {
            { tier = "basic", topics = {"weapons_shipments"}, trustRequired = 40 },
            { tier = "detailed", topics = {"military_hardware", "cartel_armory"}, trustRequired = 65 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "threatening",
    },

    -- ==========================================================================
    -- LOS SANTOS CITY (7 characters)
    -- ==========================================================================
    {
        id = "marcus_webb",
        firstname = "Marcus",
        lastname = "Webb",
        gender = "MALE",

        personality = "nervous",
        specialty = "drugs",
        backstory = "Small-time dealer trying to make ends meet. Known to frequent Grove Street.",
        illegalChance = 80,

        model = "a_m_y_stbla_01",
        homeLocation = vector4(-105.4, -1712.5, 29.3, 140.0),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {20, 4}, active = true } },
        role = "street_dealer",
        trustCategory = "criminal",
        voice = "anxious",
        systemPrompt = [[You are Marcus Webb, a nervous small-time dealer on Grove Street. You're just trying to make ends meet but you're always worried about getting caught or robbed. You'll talk if pressured but you're not high up enough to know the big picture.]],
        intel = {
            { tier = "rumors", topics = {"drug_spots", "grove_street"}, trustRequired = 0 },
            { tier = "basic", topics = {"suppliers", "distribution"}, trustRequired = 15 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "gang"},
        trustRequired = 2,
        voiceStyle = "anxious",
    },
    {
        id = "deshawn_price",
        firstname = "DeShawn",
        lastname = "Price",
        gender = "MALE",

        personality = "hostile",
        specialty = "drugs",
        backstory = "Mid-level dealer with connections. Known for running product through Davis.",
        illegalChance = 90,

        model = "g_m_y_famfor_01",
        homeLocation = vector4(113.29, -1961.79, 20.84, 275.0),
        movement = { pattern = "wander", radius = 60.0 },
        schedule = { { time = {14, 4}, active = true } },
        role = "drug_dealer",
        trustCategory = "criminal",
        voice = "aggressive",
        systemPrompt = [[You are DeShawn Price, a hostile mid-level drug dealer running Davis. You've got connections and you're not afraid to use them. You don't respect anyone who hasn't earned it on the streets. You're aggressive and territorial.]],
        intel = {
            { tier = "basic", topics = {"davis_operations", "suppliers"}, trustRequired = 30 },
            { tier = "detailed", topics = {"distribution_network"}, trustRequired = 50 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "aggressive",
    },
    {
        id = "tanisha_moore",
        firstname = "Tanisha",
        lastname = "Moore",
        gender = "FEMALE",

        personality = "cunning",
        specialty = "drugs",
        backstory = "Street-smart dealer. Uses her appearance to avoid suspicion.",
        illegalChance = 70,

        model = "a_f_y_scdressy_01",
        homeLocation = vector4(254.86, -1852.56, 27.08, 50.0),
        movement = { pattern = "wander", radius = 45.0 },
        schedule = { { time = {16, 2}, active = true } },
        role = "drug_dealer",
        trustCategory = "criminal",
        voice = "smooth",
        systemPrompt = [[You are Tanisha Moore, a cunning drug dealer in Strawberry. You're street-smart and use your appearance to avoid suspicion. You're always thinking two steps ahead and know how to play people. You'll give up information if it benefits you.]],
        intel = {
            { tier = "rumors", topics = {"strawberry_crime", "drug_spots"}, trustRequired = 0 },
            { tier = "basic", topics = {"dealer_network", "suppliers"}, trustRequired = 20 },
            { tier = "detailed", topics = {"distribution_hierarchy"}, trustRequired = 45 },
        },
        canGiveIntel = true,
        intelTypes = {"drugs", "gang"},
        trustRequired = 3,
        voiceStyle = "smooth",
    },
    {
        id = "victor_reyes",
        firstname = "Victor",
        lastname = "Reyes",
        gender = "MALE",

        personality = "calm",
        specialty = "weapons",
        backstory = "Former military. Now runs guns through the docks.",
        illegalChance = 85,

        model = "a_m_y_mexthug_01",
        homeLocation = vector4(1212.35, -2989.84, 5.87, 180.0),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {22, 6}, active = true } },
        role = "gun_runner",
        trustCategory = "criminal",
        voice = "calm",
        systemPrompt = [[You are Victor Reyes, a calm and professional gun runner working the LS docks. Former military, you know weapons inside and out. You're careful, methodical, and only deal with serious buyers. You have connections for anything from pistols to military hardware.]],
        intel = {
            { tier = "rumors", topics = {"weapons_trade", "dock_activity"}, trustRequired = 0 },
            { tier = "basic", topics = {"arms_shipments"}, trustRequired = 25 },
            { tier = "detailed", topics = {"military_connections"}, trustRequired = 50 },
        },
        canGiveIntel = true,
        intelTypes = {"weapons", "gang"},
        trustRequired = 5,
        voiceStyle = "calm",
    },
    {
        id = "raymond_vance",
        firstname = "Raymond",
        lastname = "Vance",
        gender = "MALE",

        personality = "smooth",
        specialty = "theft",
        backstory = "Professional burglar. Carries lockpicks and stolen goods.",
        illegalChance = 75,

        model = "a_m_y_smartcaspat_01",
        homeLocation = vector4(-71.32, -818.23, 326.18, 115.0),
        movement = { pattern = "wander", radius = 60.0 },
        schedule = { { time = {22, 6}, active = true } },
        role = "burglar",
        trustCategory = "criminal",
        voice = "charming",
        systemPrompt = [[You are Raymond Vance, a smooth professional burglar working the wealthy areas of Vinewood. You're charming, well-dressed, and blend in with the rich crowd. You know which houses have the best goods and how to get in and out without a trace.]],
        intel = {
            { tier = "rumors", topics = {"burglary_targets", "wealthy_marks"}, trustRequired = 0 },
            { tier = "basic", topics = {"security_systems", "fence_contacts"}, trustRequired = 20 },
            { tier = "detailed", topics = {"high_value_scores"}, trustRequired = 40 },
        },
        canGiveIntel = true,
        intelTypes = {"theft", "fencing"},
        trustRequired = 3,
        voiceStyle = "charming",
    },
    {
        id = "lamar_jenkins",
        firstname = "Lamar",
        lastname = "Jenkins",
        gender = "MALE",

        personality = "loyal",
        specialty = "gang",
        backstory = "Families associate. Handles distribution in Strawberry.",
        illegalChance = 80,

        model = "g_m_y_famca_01",
        homeLocation = vector4(-178.67, -1693.48, 33.31, 45.0),
        movement = { pattern = "wander", radius = 55.0 },
        schedule = { { time = {12, 2}, active = true } },
        role = "gang_member",
        trustCategory = "criminal",
        voice = "street",
        systemPrompt = [[You are Lamar Jenkins, a loyal Families associate from Forum Drive. You handle distribution in Strawberry and you're dedicated to your crew. You don't snitch - ever. Family first, always. You're suspicious of outsiders and protective of your people.]],
        intel = {
            { tier = "rumors", topics = {"families_territory"}, trustRequired = 0 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "street",
        gang = "families",
    },
    {
        id = "tyrell_washington",
        firstname = "Tyrell",
        lastname = "Washington",
        gender = "MALE",

        personality = "paranoid",
        specialty = "gang",
        backstory = "Ballas soldier. Multiple violent priors.",
        illegalChance = 90,

        model = "g_m_y_ballasout_01",
        homeLocation = vector4(89.31, -1939.39, 20.80, 320.0),
        movement = { pattern = "wander", radius = 50.0 },
        schedule = { { time = {14, 4}, active = true } },
        role = "gang_member",
        trustCategory = "criminal",
        voice = "paranoid",
        systemPrompt = [[You are Tyrell Washington, a paranoid Ballas soldier with multiple violent priors. You're always looking over your shoulder, expecting enemies around every corner. You trust no one outside your crew and you're quick to violence. Don't even think about snitching.]],
        intel = {
            { tier = "rumors", topics = {"ballas_territory"}, trustRequired = 0 },
        },
        canGiveIntel = false,
        intelTypes = {},
        trustRequired = 0,
        voiceStyle = "paranoid",
        gang = "ballas",
    },
}

-- ============================================================================
-- PERSONALITY DEFINITIONS
-- ============================================================================
-- Affects behavior in both police encounters and AI conversations

SharedCharacters.personalities = {
    nervous = {
        fleeChance = 70,
        intelChance = 80,
        informantChance = 50,
        aiMood = "anxious",
        responseStyle = "stammering, eager to please",
    },
    hostile = {
        fleeChance = 60,
        intelChance = 30,
        informantChance = 10,
        aiMood = "angry",
        responseStyle = "confrontational, dismissive",
    },
    calm = {
        fleeChance = 30,
        intelChance = 50,
        informantChance = 30,
        aiMood = "neutral",
        responseStyle = "measured, careful",
    },
    cunning = {
        fleeChance = 40,
        intelChance = 70,
        informantChance = 60,
        aiMood = "calculating",
        responseStyle = "strategic, trades information",
    },
    aggressive = {
        fleeChance = 80,
        intelChance = 20,
        informantChance = 5,
        aiMood = "hostile",
        responseStyle = "threatening, short-tempered",
    },
    smooth = {
        fleeChance = 20,
        intelChance = 90,
        informantChance = 70,
        aiMood = "confident",
        responseStyle = "charming, persuasive",
    },
    flirty = {
        fleeChance = 25,
        intelChance = 60,
        informantChance = 40,
        aiMood = "playful",
        responseStyle = "flirtatious, distracting",
    },
    loyal = {
        fleeChance = 50,
        intelChance = 10,
        informantChance = 5,
        aiMood = "guarded",
        responseStyle = "protective of associates, tight-lipped",
    },
    paranoid = {
        fleeChance = 90,
        intelChance = 40,
        informantChance = 20,
        aiMood = "suspicious",
        responseStyle = "jumpy, constantly checking surroundings",
    },
    quiet = {
        fleeChance = 40,
        intelChance = 30,
        informantChance = 25,
        aiMood = "reserved",
        responseStyle = "brief answers, avoids eye contact",
    },
    twitchy = {
        fleeChance = 85,
        intelChance = 95,
        informantChance = 80,
        aiMood = "desperate",
        responseStyle = "will say anything, unreliable",
    },
    defiant = {
        fleeChance = 60,
        intelChance = 15,
        informantChance = 5,
        aiMood = "rebellious",
        responseStyle = "confrontational, proud",
    },
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get character by ID
function SharedCharacters.GetById(id)
    for _, char in ipairs(SharedCharacters.pool) do
        if char.id == id then
            return char
        end
    end
    return nil
end

-- Get character by name
function SharedCharacters.GetByName(firstname, lastname)
    for _, char in ipairs(SharedCharacters.pool) do
        if char.firstname == firstname and char.lastname == lastname then
            return char
        end
    end
    return nil
end

-- Get all characters of a specialty
function SharedCharacters.GetBySpecialty(specialty)
    local result = {}
    for _, char in ipairs(SharedCharacters.pool) do
        if char.specialty == specialty then
            table.insert(result, char)
        end
    end
    return result
end

-- Get all characters that can give intel
function SharedCharacters.GetIntelSources()
    local result = {}
    for _, char in ipairs(SharedCharacters.pool) do
        if char.canGiveIntel then
            table.insert(result, char)
        end
    end
    return result
end

-- Get personality data
function SharedCharacters.GetPersonality(personalityName)
    return SharedCharacters.personalities[personalityName]
end

-- Get characters by location area
function SharedCharacters.GetByArea(area)
    local areaRanges = {
        roxwood = { minY = 6800, maxY = 8500 },
        paleto = { minY = 6000, maxY = 6800 },
        grapeseed = { minY = 4500, maxY = 5200 },
        cayo = { minX = 4000, maxX = 6000, minY = -6000, maxY = -4000 },
        los_santos = { minY = -3000, maxY = 1000 },
    }

    local range = areaRanges[area]
    if not range then return {} end

    local result = {}
    for _, char in ipairs(SharedCharacters.pool) do
        if char.homeLocation then
            local y = char.homeLocation.y
            local x = char.homeLocation.x
            local inRange = true

            if range.minY and y < range.minY then inRange = false end
            if range.maxY and y > range.maxY then inRange = false end
            if range.minX and x < range.minX then inRange = false end
            if range.maxX and x > range.maxX then inRange = false end

            if inRange then
                table.insert(result, char)
            end
        end
    end
    return result
end

-- Get total character count
function SharedCharacters.GetCount()
    return #SharedCharacters.pool
end
