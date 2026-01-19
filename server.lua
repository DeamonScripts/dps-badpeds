local QBCore = exports['qb-core']:GetCoreObject()
local activeInteractions = {}
local npcInventories = {}
local npcNames = {}
local npcIllegal = {}
local npcLocks = {}
local npcModels = {} -- Store NPC model hashes

-- Cache for item list from inventory system
local cachedItemList = nil
local filteredItemPool = nil

-- ============================================================================
-- JAIL STATUS CACHE (Performance optimization for high-pop servers)
-- ============================================================================
-- Instead of querying the database every time we need to check if a character
-- is in jail, we maintain an in-memory cache that refreshes periodically.
-- This reduces database load from potentially hundreds of queries to 1 per minute.

local jailStatusCache = {}  -- { ["Firstname_Lastname"] = true } for jailed characters
local lastCacheRefresh = 0  -- GetGameTimer() value of last refresh

-- Refresh the jail status cache from database
local function refreshJailCache()
    local now = GetGameTimer()
    local cacheTTL = (Config.jailStatusCache and Config.jailStatusCache.refreshInterval) or 60000

    -- Only refresh if cache has expired
    if now - lastCacheRefresh < cacheTTL then return end

    local results = exports.oxmysql:executeSync([[
        SELECT npc_firstname, npc_lastname, release_at
        FROM npc_jail_records
        WHERE released = 0 AND release_at > NOW()
    ]])

    -- Clear and rebuild cache
    jailStatusCache = {}
    for _, row in ipairs(results or {}) do
        local key = row.npc_firstname .. "_" .. row.npc_lastname
        jailStatusCache[key] = true
    end

    lastCacheRefresh = now

    -- Log cache refresh if debug enabled
    if Config.jailStatusCache and Config.jailStatusCache.debug then
        local count = 0
        for _ in pairs(jailStatusCache) do count = count + 1 end
        print('[dps-badpeds] Jail cache refreshed: ' .. count .. ' characters currently jailed')
    end
end

-- Check if character is in jail using cache (fast, no DB hit)
local function isCharacterJailedCached(firstname, lastname)
    refreshJailCache() -- Only hits DB if cache expired
    local key = firstname .. "_" .. lastname
    return jailStatusCache[key] == true
end

-- Immediately update cache when we arrest someone (don't wait for refresh)
local function addToJailCache(firstname, lastname)
    local key = firstname .. "_" .. lastname
    jailStatusCache[key] = true
end

-- Remove from cache when released (called by release system if implemented)
local function removeFromJailCache(firstname, lastname)
    local key = firstname .. "_" .. lastname
    jailStatusCache[key] = nil
end

-- ============================================================================
-- JAIL SYSTEM FUNCTIONS
-- ============================================================================

-- Calculate jail time based on items found
local function calculateJailTime(inventory)
    if not inventory then return Config.jailSystem.defaultJailHours or 24 end

    local baseTime = Config.jailSystem.defaultJailHours or 24
    local bonusTime = 0

    for _, item in ipairs(inventory) do
        if not item.legal then
            local itemName = item.item:lower()
            -- Weapons add more time
            if itemName:find("weapon_") then
                bonusTime = bonusTime + (Config.jailSystem.weaponBonus or 12)
            -- Large drug quantities
            elseif itemName:find("brick") then
                bonusTime = bonusTime + (Config.jailSystem.drugBrickBonus or 8)
            -- Regular drugs
            elseif itemName:find("baggy") or itemName:find("joint") or itemName:find("coke") or itemName:find("meth") then
                bonusTime = bonusTime + (Config.jailSystem.drugBonus or 4)
            -- Crime tools
            elseif itemName:find("lockpick") or itemName:find("thermite") or itemName:find("hack") then
                bonusTime = bonusTime + (Config.jailSystem.crimeToolBonus or 6)
            end
        end
    end

    local maxTime = Config.jailSystem.maxJailHours or 72
    return math.min(baseTime + bonusTime, maxTime)
end

-- Record an arrest in the database
local function recordArrest(src, netId, jailHours, gaveIntel, intelData)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local npcName = npcNames[netId]
    local npcModel = npcModels[netId] or 'unknown'
    local inventory = npcInventories[netId]

    if not npcName then return false end

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or 'Unknown'

    -- Build charges from inventory
    local charges = {}
    if inventory then
        for _, item in ipairs(inventory) do
            if not item.legal then
                table.insert(charges, {
                    item = item.item,
                    label = item.label,
                    quantity = item.qty
                })
            end
        end
    end

    -- Calculate release time (game hours to real minutes: 1 game hour = 2 real minutes by default)
    local realMinutes = jailHours * (Config.jailSystem.gameHourToRealMinutes or 2)

    local insertQuery = [[
        INSERT INTO npc_jail_records
        (npc_model, npc_firstname, npc_lastname, npc_gender, arrested_by, arrested_by_name,
         arrest_coords, arrest_street, charges, jail_time_hours, release_at, gave_intel, intel_data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE), ?, ?)
    ]]

    local citizenId = Player.PlayerData.citizenid
    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local coordsJson = json.encode({x = coords.x, y = coords.y, z = coords.z})
    local chargesJson = json.encode(charges)
    local intelJson = intelData and json.encode(intelData) or nil

    exports.oxmysql:execute(insertQuery, {
        npcModel,
        npcName.firstname,
        npcName.lastname,
        npcName.gender,
        citizenId,
        officerName,
        coordsJson,
        streetName,
        chargesJson,
        jailHours,
        realMinutes,
        gaveIntel and 1 or 0,
        intelJson
    })

    -- Immediately update jail cache (don't wait for next refresh cycle)
    addToJailCache(npcName.firstname, npcName.lastname)

    -- Notify dps-ainpcs immediately so they can remove the NPC from active spawns
    TriggerEvent('dps-ainpcs:characterArrested', npcName.firstname, npcName.lastname, jailHours)

    print('[dps-badpeds] Arrest recorded: ' .. npcName.firstname .. ' ' .. npcName.lastname .. ' - ' .. jailHours .. ' game hours')
    return true
end

-- Check if an NPC identity is currently in jail
local function isNpcInJail(firstname, lastname)
    local result = exports.oxmysql:executeSync([[
        SELECT id, release_at, TIMESTAMPDIFF(MINUTE, NOW(), release_at) as minutes_remaining
        FROM npc_jail_records
        WHERE npc_firstname = ? AND npc_lastname = ?
        AND released = 0
        AND release_at > NOW()
        ORDER BY arrested_at DESC
        LIMIT 1
    ]], {firstname, lastname})

    if result and result[1] then
        return true, result[1].minutes_remaining
    end
    return false, 0
end

-- Get arrest history for an NPC
local function getNpcArrestHistory(firstname, lastname)
    local result = exports.oxmysql:executeSync([[
        SELECT * FROM npc_jail_records
        WHERE npc_firstname = ? AND npc_lastname = ?
        ORDER BY arrested_at DESC
        LIMIT 5
    ]], {firstname, lastname})

    return result or {}
end

-- Record intel given by NPC
local function recordIntel(src, npcName, intelType, intelContent, locationHint, sourceType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local citizenId = Player.PlayerData.citizenid
    local fullName = npcName.firstname .. ' ' .. npcName.lastname

    exports.oxmysql:execute([[
        INSERT INTO npc_intel_reports
        (source_type, source_npc_name, receiving_officer, intel_type, intel_content, location_hint, reliability)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        sourceType or 'arrest',
        fullName,
        citizenId,
        intelType,
        intelContent,
        locationHint,
        3 -- Default reliability
    })

    return true
end

-- Recruit NPC as informant
local function recruitInformant(src, netId)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local npcName = npcNames[netId]
    local npcModel = npcModels[netId] or 'unknown'

    if not npcName then return false end

    local citizenId = Player.PlayerData.citizenid
    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname

    -- Check if already an informant
    local existing = exports.oxmysql:executeSync([[
        SELECT id FROM npc_informants
        WHERE npc_firstname = ? AND npc_lastname = ? AND active = 1
    ]], {npcName.firstname, npcName.lastname})

    if existing and existing[1] then
        return false, 'already_informant'
    end

    exports.oxmysql:execute([[
        INSERT INTO npc_informants
        (npc_model, npc_firstname, npc_lastname, handler_citizenid, handler_name, trust_level)
        VALUES (?, ?, ?, ?, ?, 1)
    ]], {
        npcModel,
        npcName.firstname,
        npcName.lastname,
        citizenId,
        officerName
    })

    -- Also mark in jail record if exists
    exports.oxmysql:execute([[
        UPDATE npc_jail_records SET is_informant = 1, informant_handler = ?
        WHERE npc_firstname = ? AND npc_lastname = ? AND released = 0
        ORDER BY arrested_at DESC LIMIT 1
    ]], {citizenId, npcName.firstname, npcName.lastname})

    print('[dps-badpeds] Informant recruited: ' .. npcName.firstname .. ' ' .. npcName.lastname)
    return true
end

-- Generate intel content based on type
local function generateIntelContent(intelType)
    local intelTemplates = Config.intelTemplates or {
        drugs = {
            "There's a guy who hangs around {location}, he's been moving weight lately.",
            "Check the parking lot behind {location}, deals go down there every night.",
            "I heard {name} has been cooking in a house near {location}.",
        },
        weapons = {
            "There's an arms deal happening near {location} soon.",
            "Check the trunk of cars parked at {location}, lots of heat moving through there.",
            "Some guys have been stockpiling at a warehouse near {location}.",
        },
        gang = {
            "The {gang} have been recruiting near {location}.",
            "There's beef brewing between crews at {location}.",
            "Watch {location}, something big is being planned.",
        }
    }

    local templates = intelTemplates[intelType] or intelTemplates.drugs
    local template = templates[math.random(#templates)]

    -- Replace placeholders
    local locations = Config.intelLocations or {"Grove Street", "Mirror Park", "Vinewood", "Del Perro", "Vespucci", "La Mesa", "Strawberry", "Davis"}
    local names = {"Marcus", "DeShawn", "Tyrell", "Carlos", "Jimmy", "Big Mike", "Little Ray"}
    local gangs = {"Ballas", "Vagos", "Families", "Marabunta"}

    template = template:gsub("{location}", locations[math.random(#locations)])
    template = template:gsub("{name}", names[math.random(#names)])
    template = template:gsub("{gang}", gangs[math.random(#gangs)])

    return template
end

-- ============================================================================
-- END JAIL SYSTEM FUNCTIONS
-- ============================================================================

-- Build lookup table for illegal items (faster checks)
local illegalLookup = {}
local excludedLookup = {}

local function buildLookupTables()
    for _, item in ipairs(Config.illegalItems or {}) do
        illegalLookup[item] = true
    end
    for _, item in ipairs(Config.excludedItems or {}) do
        excludedLookup[item] = true
    end
end

-- Get all items from the inventory system
local function getItemListFromInventory()
    if cachedItemList then return cachedItemList end

    local items = nil

    if Config.inventory == 'qs-inventory' then
        items = exports['qs-inventory']:GetItemList()
    elseif Config.inventory == 'ox_inventory' or Config.inventory == 'ox-inventory' then
        items = exports.ox_inventory:Items()
    else
        -- QBCore shared items
        items = QBCore.Shared.Items
    end

    if items and next(items) then
        cachedItemList = items
        print('[dps-badpeds] Loaded ' .. (tableCount(items) or 0) .. ' items from inventory system')
    else
        print('[dps-badpeds] WARNING: Could not load items from inventory, using fallback')
        cachedItemList = {}
    end

    return cachedItemList
end

-- Count table entries
function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Build filtered item pool (excludes job items, seeds, etc.)
local function getFilteredItemPool()
    if filteredItemPool then return filteredItemPool end

    local allItems = getItemListFromInventory()
    filteredItemPool = {}

    for itemName, itemData in pairs(allItems) do
        -- Skip excluded items
        if not excludedLookup[itemName] then
            -- Skip items without a label or with certain types
            local label = itemData.label or itemData.name or itemName
            local itemType = itemData.type

            -- Include regular items and some weapons, skip attachments/components
            if itemType == 'item' or itemType == 'weapon' then
                table.insert(filteredItemPool, {
                    item = itemName,
                    label = label,
                    isWeapon = (itemType == 'weapon'),
                    weight = itemData.weight or 0
                })
            end
        end
    end

    print('[dps-badpeds] Filtered item pool: ' .. #filteredItemPool .. ' items available for NPCs')

    -- If pool is empty, use fallback
    if #filteredItemPool == 0 and Config.fallbackItems then
        filteredItemPool = Config.fallbackItems
        print('[dps-badpeds] Using fallback item list')
    end

    return filteredItemPool
end

-- Check if an item is illegal
local function isItemIllegal(itemName)
    return illegalLookup[itemName] == true
end

-- Generate random inventory for an NPC
local function generateNpcInventory()
    local pool = getFilteredItemPool()
    if not pool or #pool == 0 then return {} end

    local inventory = {}
    local itemCount = math.random(Config.npcItemCount.min or 3, Config.npcItemCount.max or 6)

    for i = 1, itemCount do
        local randomItem = pool[math.random(#pool)]
        local quantity = 1

        -- Weapons always qty 1, other items random
        if not randomItem.isWeapon then
            quantity = math.random(Config.itemQuantity.min or 1, Config.itemQuantity.max or 5)
        end

        table.insert(inventory, {
            item = randomItem.item,
            label = randomItem.label,
            qty = quantity,
            legal = not isItemIllegal(randomItem.item)
        })
    end

    return inventory
end

local function validatePedNetId(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity then return false end
    if not DoesEntityExist(entity) then return false end
    if IsPedAPlayer(entity) then return false end
    return true
end

-- Distance check: returns true if player is within range of NPC
local function isPlayerNearNpc(src, netId, maxDistance)
    maxDistance = maxDistance or 5.0
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return false end

    local npcEntity = NetworkGetEntityFromNetworkId(netId)
    if not npcEntity or npcEntity == 0 then return false end

    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = GetEntityCoords(npcEntity)
    local dist = #(playerCoords - npcCoords)

    return dist <= maxDistance
end

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    buildLookupTables()

    -- Log shared character pool status
    if SharedCharacters and SharedCharacters.pool then
        print('[dps-badpeds] Loaded ' .. #SharedCharacters.pool .. ' shared characters')
    else
        print('[dps-badpeds] WARNING: SharedCharacters pool not loaded!')
    end

    -- Initialize jail cache on startup
    Citizen.SetTimeout(1000, function()
        refreshJailCache()
    end)

    -- Delay item loading to ensure inventory resource is ready
    Citizen.SetTimeout(2000, function()
        getFilteredItemPool()
    end)
end)

RegisterNetEvent('pedInteraction:request')
AddEventHandler('pedInteraction:request', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end

    if activeInteractions[src] then
      TriggerClientEvent('npc:closeMenu', src, { npc = NetworkGetEntityFromNetworkId(netId) })
    end

    if npcLocks[netId] and npcLocks[netId] ~= src then
        TriggerClientEvent('QBCore:Notify', src, 'This pedestrian is already being interacted with.', 'error')
        return
    end

    activeInteractions[src] = netId
    npcLocks[netId] = src
    TriggerClientEvent('pedInteraction:approved', src, netId)
end)

RegisterNetEvent('addinventory')
AddEventHandler('addinventory', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end

    -- Generate inventory if not exists
    if not npcInventories[netId] then
        npcInventories[netId] = generateNpcInventory()
    end

    local npcItems = {}
    local illegal = false

    for idx, item in ipairs(npcInventories[netId]) do
        if item.qty > 0 then
            local legalTag = item.legal and "" or " ~r~(illegal)~s~"
            table.insert(npcItems, {
                header = (item.label or item.item) .. " x" .. item.qty .. legalTag,
                txt = "Click to seize this item",
                icon = item.legal and "fas fa-box" or "fas fa-exclamation-triangle",
                params = {
                    event = "npc:seizeItem",
                    args = { netId = netId, itemIndex = idx }
                }
            })
        end
        if item.legal == false then illegal = true end
    end

    npcIllegal[netId] = illegal
    TriggerClientEvent('addmenu', src, illegal, npcItems, netId)
end)

-- ============================================================================
-- RECURRING CHARACTER ROTATION SYSTEM
-- ============================================================================

local activeCharactersToday = nil
local lastRotationDay = nil

-- Get current game day for rotation (changes every 48 real minutes by default)
local function getGameDay()
    local hours = GetGameTimer() / 1000 / 60 -- Real minutes since server start
    local gameDay = math.floor(hours / 48) -- Each "day" is 48 real minutes
    return gameDay
end

-- Get today's active recurring characters (uses SharedCharacters from shared/characters.lua)
local function getActiveCharacters()
    if not Config.recurringCharacters or not Config.recurringCharacters.enabled then
        return {}
    end

    local today = getGameDay()

    -- Check if we need to rotate
    if Config.recurringCharacters.rotationEnabled and (not activeCharactersToday or lastRotationDay ~= today) then
        lastRotationDay = today
        activeCharactersToday = {}

        -- Use SharedCharacters pool (loaded from shared/characters.lua)
        local allCharacters = SharedCharacters and SharedCharacters.pool or {}
        local numActive = Config.recurringCharacters.activeCharactersPerDay or 6

        -- Use day as seed for consistent rotation across server
        math.randomseed(today * 12345)

        -- Shuffle and pick active characters
        local shuffled = {}
        for i, char in ipairs(allCharacters) do
            shuffled[i] = char
        end

        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end

        for i = 1, math.min(numActive, #shuffled) do
            table.insert(activeCharactersToday, shuffled[i])
        end

        -- Reset random seed
        math.randomseed(os.time())

        -- Log rotation
        local names = {}
        for _, char in ipairs(activeCharactersToday) do
            table.insert(names, char.firstname .. ' ' .. char.lastname)
        end
        print('[dps-badpeds] Today\'s active characters: ' .. table.concat(names, ', '))

        -- Sync with dps-ainpcs if enabled
        if Config.recurringCharacters.shareWithAINpcs then
            local resourceState = GetResourceState('dps-ainpcs')
            if resourceState == 'started' then
                TriggerEvent('dps-ainpcs:server:setActiveCharacters', activeCharactersToday)
            end
        end
    end

    return activeCharactersToday or (SharedCharacters and SharedCharacters.pool) or {}
end

-- Check if a character is currently in jail (unavailable)
-- Uses cache for performance on high-pop servers
local function isCharacterInJail(firstname, lastname)
    if not Config.jailSystem or not Config.jailSystem.enabled then
        return false
    end

    -- Use cached check for better performance
    return isCharacterJailedCached(firstname, lastname)
end

-- Check if this NPC should be a recurring character
local function getRecurringCharacter(gender)
    if not Config.recurringCharacters or not Config.recurringCharacters.enabled then
        return nil
    end

    -- Roll for recurring character
    if math.random(100) > (Config.recurringCharacters.spawnChance or 25) then
        return nil
    end

    -- Get today's active characters
    local activeChars = getActiveCharacters()

    -- Filter by gender and availability (not in jail)
    local validCharacters = {}
    for _, char in ipairs(activeChars) do
        if char.gender == gender then
            -- Check if in jail
            if not isCharacterInJail(char.firstname, char.lastname) then
                table.insert(validCharacters, char)
            end
        end
    end

    if #validCharacters == 0 then return nil end

    return validCharacters[math.random(#validCharacters)]
end

-- Export for dps-ainpcs to check character availability (uses cache for performance)
exports('IsCharacterAvailable', function(firstname, lastname)
    return not isCharacterJailedCached(firstname, lastname)
end)

-- Export for dps-ainpcs to get active characters
exports('GetActiveCharacters', function()
    return getActiveCharacters()
end)

-- Export for dps-ainpcs to notify when their NPC was arrested elsewhere
exports('NotifyCharacterArrested', function(firstname, lastname)
    addToJailCache(firstname, lastname)
    print('[dps-badpeds] Character arrested via external system: ' .. firstname .. ' ' .. lastname)
end)

-- Export to get the shared character pool
exports('GetSharedCharacters', function()
    return SharedCharacters and SharedCharacters.pool or {}
end)

-- Export to get a specific character by ID
exports('GetCharacterById', function(characterId)
    return SharedCharacters and SharedCharacters.GetById(characterId) or nil
end)

-- Export to get characters by area (for location-based spawning)
exports('GetCharactersByArea', function(area)
    return SharedCharacters and SharedCharacters.GetByArea(area) or {}
end)

-- Export to force cache refresh (for admin commands)
exports('RefreshJailCache', function()
    lastCacheRefresh = 0  -- Reset timer to force refresh
    refreshJailCache()
    return true
end)

local npcCharacterData = {} -- Store recurring character data for NPCs

RegisterNetEvent("GetPedInfo")
AddEventHandler("GetPedInfo", function(netId, ped, mugshot, mugshotname, gender, modelHash)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end

    -- Store model hash for jail records
    if modelHash then
        npcModels[netId] = tostring(modelHash)
    end

    if not npcNames[netId] then
        -- Check for recurring character first
        local recurringChar = getRecurringCharacter(gender)

        if recurringChar then
            npcNames[netId] = {
                firstname = recurringChar.firstname,
                lastname = recurringChar.lastname,
                gender = recurringChar.gender
            }
            -- Store full character data for behavior modifiers
            npcCharacterData[netId] = recurringChar
            print('[dps-badpeds] Recurring character spawned: ' .. recurringChar.firstname .. ' ' .. recurringChar.lastname)
        else
            -- Random NPC
            local firstName
            local lastName = Config.lastNames[math.random(#Config.lastNames)]
            if gender == "MALE" then
                firstName = Config.malefirstNames[math.random(#Config.malefirstNames)]
            else
                firstName = Config.femalefirstNames[math.random(#Config.femalefirstNames)]
            end
            npcNames[netId] = { firstname = firstName, lastname = lastName, gender = gender }
        end
    end

    local firstname = npcNames[netId].firstname
    local lastname = npcNames[netId].lastname
    local storedGender = npcNames[netId].gender

    -- Check arrest history if jail system enabled
    local arrestHistory = {}
    local inJail = false
    local minutesRemaining = 0

    if Config.jailSystem and Config.jailSystem.enabled then
        inJail, minutesRemaining = isNpcInJail(firstname, lastname)
        arrestHistory = getNpcArrestHistory(firstname, lastname)
    end

    -- Get recurring character data if applicable
    local characterData = npcCharacterData[netId]
    local isKnownCriminal = characterData ~= nil

    TriggerClientEvent('addname', src, netId, mugshot, mugshotname, true, firstname, lastname, storedGender, arrestHistory, inJail, minutesRemaining, isKnownCriminal, characterData)
end)

-- Seize item from NPC inventory and give to player
RegisterNetEvent('npc:seizeItem:server')
AddEventHandler('npc:seizeItem:server', function(netId, itemIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end
    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end
    if activeInteractions[src] ~= netId then return end

    local inventory = npcInventories[netId]
    if not inventory or not inventory[itemIndex] then return end

    local item = inventory[itemIndex]
    if item.qty <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'This item has already been seized.', 'error')
        return
    end

    local itemName = item.item
    local quantity = item.qty
    local success = false

    -- Add item based on inventory system
    if Config.inventory == 'ox_inventory' or Config.inventory == 'ox-inventory' then
        success = exports.ox_inventory:AddItem(src, itemName, quantity)
    elseif Config.inventory == 'qs-inventory' then
        success = exports['qs-inventory']:AddItem(src, itemName, quantity)
    else
        -- qb-inventory or qbx default
        success = Player.Functions.AddItem(itemName, quantity)
        if success then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', quantity)
        end
    end

    if success then
        -- Remove from NPC inventory
        npcInventories[netId][itemIndex].qty = 0
        TriggerClientEvent('QBCore:Notify', src, 'Seized ' .. quantity .. 'x ' .. (item.label or itemName), 'success')
        -- Refresh the inventory menu
        TriggerClientEvent('npc:refreshInventory', src, netId)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to seize item - inventory full?', 'error')
    end
end)

RegisterNetEvent('additem:qb')
AddEventHandler('additem:qb', function(netId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end
    if not isPlayerNearNpc(src, netId, 10.0) then return end
    if activeInteractions[src] ~= netId then return end

    if Player.PlayerData.job.name == "police" then
        if npcIllegal[netId] then
            if Config.inventory == 'qs-inventory' then
                exports['qs-inventory']:AddItem(src, 'weapon_stungun', 1)
            else
                Player.Functions.AddItem('weapon_stungun', 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weapon_stungun'], 'add', 1)
            end
        end
    end
end)

RegisterNetEvent('additem:ox')
AddEventHandler('additem:ox', function(netId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end
    if not isPlayerNearNpc(src, netId, 10.0) then return end
    if activeInteractions[src] ~= netId then return end

    if Player.PlayerData.job.name == "police" then
        if npcIllegal[netId] then
            exports.ox_inventory:AddItem(src, 'weapon_stungun', 1)
        end
    end
end)

RegisterNetEvent('arrestnpc')
AddEventHandler('arrestnpc', function(netId, gaveIntel, intelData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end
    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 10.0) then return end
    if activeInteractions[src] ~= netId then return end

    if Player.PlayerData.job.name == "police" then
        if npcIllegal[netId] then
            -- Remove stun gun based on inventory system
            if Config.inventory == 'ox_inventory' or Config.inventory == 'ox-inventory' then
                exports.ox_inventory:RemoveItem(src, 'weapon_stungun', 1)
            elseif Config.inventory == 'qs-inventory' then
                exports['qs-inventory']:RemoveItem(src, 'weapon_stungun', 1)
            else
                -- qb-inventory or qbx default
                Player.Functions.RemoveItem('weapon_stungun', 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weapon_stungun'], 'remove', 1)
            end
        end

        -- Record arrest in database if jail system enabled
        if Config.jailSystem and Config.jailSystem.enabled then
            local jailHours = calculateJailTime(npcInventories[netId])
            recordArrest(src, netId, jailHours, gaveIntel or false, intelData)

            -- Notify about jail time
            local npcName = npcNames[netId]
            if npcName then
                local realMinutes = jailHours * (Config.jailSystem.gameHourToRealMinutes or 2)
                TriggerClientEvent('QBCore:Notify', src,
                    npcName.firstname .. ' ' .. npcName.lastname .. ' sentenced to ' .. jailHours .. ' hours (~' .. realMinutes .. ' real minutes)',
                    'success')
            end
        end

        -- Cleanup
        activeInteractions[src] = nil
        npcLocks[netId] = nil
        npcInventories[netId] = nil
        npcNames[netId] = nil
        npcIllegal[netId] = nil
        npcModels[netId] = nil
        TriggerClientEvent('deletenpc', src, netId)
    end
end)

-- ============================================================================
-- INTEL TRADING EVENTS
-- ============================================================================

-- NPC offers intel to avoid arrest (or reduce sentence)
RegisterNetEvent('npc:requestIntelOffer')
AddEventHandler('npc:requestIntelOffer', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end
    if activeInteractions[src] ~= netId then return end

    local npcName = npcNames[netId]
    local inventory = npcInventories[netId]

    if not npcName or not npcIllegal[netId] then return end

    -- Determine intel type based on what they have
    local intelType = 'drugs' -- default
    if inventory then
        for _, item in ipairs(inventory) do
            if not item.legal then
                local itemName = item.item:lower()
                if itemName:find("weapon_") then
                    intelType = 'weapons'
                    break
                end
            end
        end
    end

    -- 70% chance NPC has useful intel
    local hasIntel = math.random(100) <= 70
    local intelContent = nil

    if hasIntel then
        intelContent = generateIntelContent(intelType)
    end

    TriggerClientEvent('npc:intelOfferResponse', src, netId, hasIntel, intelType, intelContent, npcName)
end)

-- Player accepts intel deal
RegisterNetEvent('npc:acceptIntelDeal')
AddEventHandler('npc:acceptIntelDeal', function(netId, intelType, intelContent)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end
    if activeInteractions[src] ~= netId then return end

    local npcName = npcNames[netId]
    if not npcName then return end

    -- Record the intel
    local locationHint = Config.intelLocations and Config.intelLocations[math.random(#Config.intelLocations)] or nil
    recordIntel(src, npcName, intelType, intelContent, locationHint, 'arrest')

    -- If using dps-ainpcs, sync intel
    if Config.aiIntegration and Config.aiIntegration.enabled then
        local resourceState = GetResourceState('dps-ainpcs')
        if resourceState == 'started' then
            -- Try to record in dps-ainpcs intel system
            TriggerEvent('dps-ainpcs:server:recordIntel', {
                source = npcName.firstname .. ' ' .. npcName.lastname,
                type = intelType,
                content = intelContent,
                reliability = 3,
                officerId = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
            })
        end
    end

    TriggerClientEvent('QBCore:Notify', src, 'Intel recorded. NPC will receive reduced sentence.', 'success')
end)

-- Player offers to recruit NPC as informant
RegisterNetEvent('npc:offerInformantDeal')
AddEventHandler('npc:offerInformantDeal', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end
    if activeInteractions[src] ~= netId then return end

    local npcName = npcNames[netId]
    if not npcName then return end

    -- 40% chance they accept being an informant
    local accepts = math.random(100) <= 40

    if accepts then
        local success, reason = recruitInformant(src, netId)
        if success then
            TriggerClientEvent('npc:informantResponse', src, netId, true, npcName)
        else
            TriggerClientEvent('npc:informantResponse', src, netId, false, npcName, reason)
        end
    else
        TriggerClientEvent('npc:informantResponse', src, netId, false, npcName, 'refused')
    end
end)

-- Get NPC context for AI dialogue
RegisterNetEvent('npc:getAIContext')
AddEventHandler('npc:getAIContext', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if activeInteractions[src] ~= netId then return end

    local context = {
        name = npcNames[netId],
        hasIllegal = npcIllegal[netId] or false,
        inventory = npcInventories[netId],
        model = npcModels[netId]
    }

    -- Add arrest history if available
    if Config.jailSystem and Config.jailSystem.enabled and context.name then
        context.arrestHistory = getNpcArrestHistory(context.name.firstname, context.name.lastname)
        context.inJail, context.minutesRemaining = isNpcInJail(context.name.firstname, context.name.lastname)
    end

    TriggerClientEvent('npc:aiContextResponse', src, netId, context)
end)

RegisterNetEvent('exitclearance')
AddEventHandler('exitclearance', function(netId)
    local src = source

    if activeInteractions[src] == netId then
        activeInteractions[src] = nil
        npcLocks[netId] = nil
        TriggerClientEvent('Cleartasks', src, netId)
    end
end)

-- Refresh inventory callback for after seizing items
RegisterNetEvent('npc:requestInventoryRefresh')
AddEventHandler('npc:requestInventoryRefresh', function(netId)
    local src = source

    if not validatePedNetId(netId) then return end
    if not isPlayerNearNpc(src, netId, 5.0) then return end
    if activeInteractions[src] ~= netId then return end

    local inventory = npcInventories[netId]
    if not inventory then return end

    local npcItems = {}
    local illegal = false
    local hasItems = false

    for idx, item in ipairs(inventory) do
        if item.qty > 0 then
            hasItems = true
            local legalTag = item.legal and "" or " ~r~(illegal)~s~"
            table.insert(npcItems, {
                header = (item.label or item.item) .. " x" .. item.qty .. legalTag,
                txt = "Click to seize this item",
                icon = item.legal and "fas fa-box" or "fas fa-exclamation-triangle",
                params = {
                    event = "npc:seizeItem",
                    args = { netId = netId, itemIndex = idx }
                }
            })
        end
        if item.legal == false and item.qty > 0 then illegal = true end
    end

    if not hasItems then
        table.insert(npcItems, {
            header = "No items remaining",
            txt = "",
            isMenuHeader = true
        })
    end

    npcIllegal[netId] = illegal
    TriggerClientEvent('addmenu', src, illegal, npcItems, netId)
end)
