local npcList
local QBCore = exports['qb-core']:GetCoreObject()
local addedTargets = {}
local activeScenes = {}
local dispatchSentForNpc = {} -- Track which NPCs we've already dispatched for

-- Get current location info for dispatch
local function GetLocationInfo()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    local location = streetName
    if crossingName and crossingName ~= "" then
        location = location .. " & " .. crossingName
    end
    if zoneName and zoneName ~= "BLNK" then
        location = location .. ", " .. zoneName
    end

    return {
        coords = coords,
        street = streetName,
        location = location
    }
end

-- Send dispatch via wasabi_mdt
local function SendDispatch(dispatchType, npcNetId, customData)
    if not Config.dispatch or not Config.dispatch.enabled then return end

    local dispatchConfig = Config.dispatch[dispatchType]
    if not dispatchConfig or not dispatchConfig.enabled then return end

    -- Check if dispatch resource is available
    local resourceState = GetResourceState(Config.dispatch.resource)
    if resourceState ~= 'started' then
        print('[dps-badpeds] Dispatch resource not running: ' .. Config.dispatch.resource)
        return
    end

    local locInfo = GetLocationInfo()

    -- Build dispatch data
    local dispatchData = {
        type = dispatchConfig.type or 'other',
        title = customData and customData.title or dispatchConfig.title,
        description = customData and customData.description or dispatchConfig.description,
        location = locInfo.location,
        coords = { x = locInfo.coords.x, y = locInfo.coords.y, z = locInfo.coords.z },
        priority = dispatchConfig.priority or 2
    }

    -- Send via export
    if Config.dispatch.resource == 'wasabi_mdt' then
        exports['wasabi_mdt']:CreateDispatch(dispatchData)
    elseif Config.dispatch.resource == 'ps-dispatch' then
        -- ps-dispatch compatibility
        TriggerServerEvent('ps-dispatch:server:notify', {
            dispatchcodename = dispatchConfig.type,
            dispatchCode = dispatchConfig.priority .. '-' .. dispatchConfig.type,
            firstStreet = locInfo.street,
            gender = false,
            model = false,
            plate = false,
            priority = dispatchConfig.priority,
            firstColor = false,
            automaticGunfire = false,
            origin = {
                x = locInfo.coords.x,
                y = locInfo.coords.y,
                z = locInfo.coords.z
            },
            dispatchMessage = dispatchConfig.title,
            job = { 'police' }
        })
    elseif Config.dispatch.resource == 'cd_dispatch' then
        -- cd_dispatch compatibility
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = { 'police' },
            coords = locInfo.coords,
            title = dispatchConfig.title,
            message = dispatchConfig.description,
            flash = 0,
            unique_id = tostring(npcNetId),
            sound = 1,
            blip = {
                sprite = 161,
                scale = 1.2,
                colour = 1,
                flashes = false,
                text = dispatchConfig.title,
                time = 5,
                radius = 0,
            }
        })
    end

    print('[dps-badpeds] Dispatch sent: ' .. dispatchConfig.title)
end

Citizen.CreateThread(function()
    while true do
        Wait(1500) -- Optimized: NPCs don't spawn/despawn fast enough to need 500ms checks

        local ped = PlayerPedId()
        local data = QBCore.Functions.GetPlayerData()
        if not data or not data.job or not data.job.name then goto skip end
        if data.job.name ~= "police" then goto skip end

        npcList = GetGamePool('CPed')

        for _, npc in ipairs(npcList) do
            if DoesEntityExist(npc) and not IsPedAPlayer(npc) then
                if not addedTargets[npc] then
                        local dist = #(GetEntityCoords(ped) - GetEntityCoords(npc))
                        if dist < 20.0 then
                            NetworkRegisterEntityAsNetworked(npc)
                            if Config.target == 'qb-target' then
                                exports['qb-target']:AddTargetEntity(npc, {
                                    options = {
                                        {
                                            type = "client",
                                            icon = "fas fa-comment",
                                            label = "Talk to the pedestrian",
                                            action = function(entity)
                                                TriggerEvent('my:ped:interaction', entity)
                                            end,
                                            canInteract = function(entity, distance)
                                                local Player = QBCore.Functions.GetPlayerData()
                                                return Player and Player.job and Player.job.name == 'police'
                                            end
                                        }
                                    },
                                    distance = 2.5
                                })
                                elseif Config.target == 'ox-target' then
                                    exports.ox_target:addLocalEntity(npc, { {
                                        name = 'talk',
                                        label = 'Talk to the pedestrian',
                                        icon = 'fas fa-comment',
                                        distance = 2.5,
                                        canInteract = function(entity)
                                            local Player = QBCore.Functions.GetPlayerData()
                                            return Player and Player.job.name == 'police'
                                        end,
                                        onSelect = function(data)
                                            TriggerEvent('my:ped:interaction', { npc = data.entity })
                                        end
                                    } })
                                end
                            addedTargets[npc] = true
                        end
                    end
                end
            end
        ::skip::
    end
end)

RegisterNetEvent('playSyncedScene')
AddEventHandler('playSyncedScene', function(entity, dict, anim)
    if not DoesEntityExist(entity) then 
        return 
    end

    local coords = GetEntityCoords(entity)
    local rot = GetEntityRotation(entity)

    NetworkRequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do 
        Wait(100) 
    end

    local scene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 2, false, true, 1.0, 0.0, 1.0)

    NetworkAddPedToSynchronisedScene(entity, scene, dict, anim, 16.0, -16.0, -1, 1, 1.0, 0)

    local netId = NetworkGetNetworkIdFromEntity(entity)
    activeScenes[netId] = scene

    NetworkStartSynchronisedScene(scene)
end)

local function StopPedScene(netId)
    local scene = activeScenes[netId]
    local ped = PlayerPedId()
    local entity = NetworkGetEntityFromNetworkId(netId)

    if scene then
        NetworkStopSynchronisedScene(scene)
        activeScenes[netId] = nil
        NetworkRequestControlOfEntity(entity)
        SetBlockingOfNonTemporaryEvents(entity, true)
        TaskTurnPedToFaceEntity(entity, ped, -1)
    end
end

RegisterNetEvent('my:ped:interaction')
AddEventHandler('my:ped:interaction', function(entity)
    local npc = entity
    local jobData = QBCore.Functions.GetPlayerData()
    if jobData.job.name ~= 'police' then
        QBCore.Functions.Notify('You are not police', 'error')
        return
    end

    TriggerEvent('showmenu', { npc = npc })
end)

RegisterNetEvent('showmenu')
AddEventHandler('showmenu', function(data)
    local npc = data.npc
    local netId = NetworkGetNetworkIdFromEntity(npc)
    local test = NetworkGetEntityIsNetworked(npc)
    print(test)
    if not npc or not DoesEntityExist(npc) or IsPedDeadOrDying(npc, true) then return end

    TriggerServerEvent('pedInteraction:request', netId)
end)

RegisterNetEvent('pedInteraction:approved')
AddEventHandler('pedInteraction:approved', function(netId)
    local npc = NetworkGetEntityFromNetworkId(netId)
    if not npc or not DoesEntityExist(npc) then return end
    
    local ped = PlayerPedId()
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskTurnPedToFaceEntity(npc, ped, -1)

    PlayAmbientSpeech2(npc, "GENERIC_HI", "SPEECH_PARAMS_FORCE")

        local menuItems = {
        { header = "Police Menu", txt = "Interact with Pedestrians", isMenuHeader = true },
        { header = "Check ID-card", txt = "Check the identity of the pedestrian", icon = "fa-solid fa-id-card", params = { event = "npc:showIdCard", args = { npc = npc } } },
        { header = "Frisk the pedestrian", txt = "Check the pedestrian for illegal items", icon = "fas fa-search", params = { event = "npc:inventory", args = { npc = npc } } },
        { header = "Close Menu", txt = "", params = { event = "npc:closeMenu", args = { npc = npc } } }
    }

    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('npc:inventory')
AddEventHandler('npc:inventory', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    local netId = NetworkGetNetworkIdFromEntity(npc)
    local entity = NetworkGetEntityFromNetworkId(netId)
    TriggerEvent('playSyncedScene', entity, "nm@hands", "hands_up")
    TriggerServerEvent('addinventory', netId)
end)

RegisterNetEvent('addmenu')
AddEventHandler('addmenu', function(isIllegal, npcItems, netId)
    local npc = NetworkGetEntityFromNetworkId(netId)

    -- Send dispatch when illegal items found (only once per NPC)
    if isIllegal and not dispatchSentForNpc[netId] then
        dispatchSentForNpc[netId] = true
        SendDispatch('illegalItemsFound', netId)
    end

    if isIllegal then
        table.insert(npcItems, {
            header = "Back",
            txt = "Return to the main menu",
            params = { event = "arrestmenu", args = { npc = npc } }
        })
    else
        table.insert(npcItems, {
            header = "Back",
            txt = "Return to the main menu",
            params = { event = "showmenu", args = { npc = npc } }
        })
    end
    exports['qb-menu']:openMenu(npcItems)
end)

RegisterNetEvent('arrestmenu')
AddEventHandler('arrestmenu', function(data)
    local npc = data.npc
    local netId = NetworkGetNetworkIdFromEntity(npc)
    if not npc or not DoesEntityExist(npc) then return end

    StopPedScene(netId)

    local menuItems = {
        { header = "Police Menu", txt = "Contraband found - Choose action", isMenuHeader = true },
        { header = "Frisk Again", txt = "Search the pedestrian for more items", icon = "fas fa-search", params = { event = "npc:inventory", args = { npc = npc } } },
        { header = "Negotiate Intel", txt = "See if suspect will talk for a deal", icon = "fas fa-comments", params = { event = "npc:requestIntel", args = { npc = npc } } },
        { header = "Arrest", txt = "Arrest the pedestrian (full charges)", icon = "fa-solid fa-handcuffs", params = { event = "npc:arrest", args = { npc = npc } } },
    }

    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('npc:showIdCard')
AddEventHandler('npc:showIdCard', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    local netId = NetworkGetNetworkIdFromEntity(npc)
    local ped = PlayerPedId()
    local gender = IsPedMale(npc) and "MALE" or "FEMALE"
    local modelHash = GetEntityModel(npc)

    local mugshot = RegisterPedheadshot(npc)
    while not IsPedheadshotReady(mugshot) do Wait(10) end
    local mugshotname = GetPedheadshotTxdString(mugshot)
    RequestStreamedTextureDict(mugshotname, false)

    TriggerServerEvent("GetPedInfo", netId, ped, mugshot, mugshotname, gender, modelHash)
end)

RegisterNetEvent('addname')
AddEventHandler('addname', function(netId, mugshot, mugshotname, showingId, firstname, lastname, gender, arrestHistory, inJail, minutesRemaining, isKnownCriminal, characterData)
    Citizen.CreateThread(function()
        local hasHistory = arrestHistory and #arrestHistory > 0

        while showingId do
            Wait(0)
            local dict = "idcard"
            local tex = "ID-card"

            RequestStreamedTextureDict(dict, true)
            while not HasStreamedTextureDictLoaded(dict) do Wait(0) end

            DrawSprite(dict, tex, 0.80, 0.40, 0.35, 0.42, 0.0, 255, 255, 255, 255)

            if HasStreamedTextureDictLoaded(mugshotname) then
                DrawSprite(mugshotname, mugshotname, 0.69, 0.42, 0.12, 0.31, 0.0, 255, 255, 255, 255)
                DrawSprite(mugshotname, mugshotname, 0.87, 0.48, 0.04, 0.095, 0.0, 255, 255, 255, 255)
            end

            DrawText2D(0.78, 0.37, firstname, 0.4, 4, 0, 0, 0, 255, false)
            DrawText2D(0.81, 0.52, gender, 0.35, 4, 0, 0, 0, 255, false)
            DrawText2D(0.78, 0.345, lastname, 0.35, 4, 0, 0, 0, 255, false)

            local yOffset = 0.57

            -- Show KNOWN CRIMINAL badge for recurring characters
            if isKnownCriminal then
                DrawText2D(0.78, yOffset, "~p~** KNOWN CRIMINAL **~s~", 0.32, 4, 128, 0, 128, 255, false)
                yOffset = yOffset + 0.025
                if characterData and characterData.specialty then
                    local specialties = {
                        drugs = "Drug Trafficking",
                        weapons = "Weapons Offenses",
                        theft = "Theft/Burglary",
                        gang = "Gang Activity",
                        petty = "Petty Crimes"
                    }
                    local specLabel = specialties[characterData.specialty] or characterData.specialty
                    DrawText2D(0.78, yOffset, "Known for: " .. specLabel, 0.25, 4, 100, 100, 100, 255, false)
                    yOffset = yOffset + 0.02
                end
            end

            -- Show arrest history indicator
            if hasHistory then
                DrawText2D(0.78, yOffset, "~r~CRIMINAL RECORD~s~", 0.3, 4, 255, 0, 0, 255, false)
                yOffset = yOffset + 0.02
                DrawText2D(0.78, yOffset, #arrestHistory .. " prior arrest(s)", 0.25, 4, 100, 100, 100, 255, false)
                yOffset = yOffset + 0.02
            end

            -- Show if currently in jail (shouldn't happen but just in case)
            if inJail then
                DrawText2D(0.78, yOffset, "~o~IN CUSTODY~s~", 0.3, 4, 255, 150, 0, 255, false)
            end

            if IsControlJustReleased(0, 194) then
                showingId = false
            end
        end

        if mugshot and mugshot > 0 then UnregisterPedheadshot(mugshot) end
        if mugshotname then SetStreamedTextureDictAsNoLongerNeeded(mugshotname) end

        TriggerEvent('showmenu', { npc = NetworkGetEntityFromNetworkId(netId) })
    end)
end)

function DrawText2D(x, y, text, scale, font, r, g, b, a, center)
    text = tostring(text)
    SetTextFont(font or 4)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    if center then SetTextCentre(true) end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

RegisterNetEvent('npc:arrest')
AddEventHandler('npc:arrest', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    local ped = PlayerPedId()
    local pednetId = NetworkGetNetworkIdFromEntity(ped)
    local stungun = GetHashKey('WEAPON_STUNGUN')
    local arrestScenario = math.random(1, 2)
    local netId = NetworkGetNetworkIdFromEntity(npc)
    local entity = NetworkGetEntityFromNetworkId(netId)

    RequestAnimDict('missminuteman_1ig_2')
    while not HasAnimDictLoaded('missminuteman_1ig_2') do
        Wait(100)
    end

    if arrestScenario == 1 then
        -- Compliant arrest - no chase needed
        ClearPedTasksImmediately(npc)
        TriggerEvent("playSyncedScene", entity, "missminuteman_1ig_2", "handsup_base")
        Wait(750)
        DoScreenFadeOut(500)
        Wait(800)
        TriggerServerEvent('arrestnpc', netId)

        -- Send arrest completed dispatch
        SendDispatch('arrestMade', netId)
        dispatchSentForNpc[netId] = nil -- Clean up tracking

        Wait(100)
        Wait(100)
        StopPedScene(netId)
        StopPedScene(pednetId)
        Wait(500)
        DoScreenFadeIn(500)
        return
    end

    -- Scenario 2: Suspect flees - send pursuit dispatch
    SendDispatch('suspectFleeing', netId)

    if Config.inventory == 'qb-inventory' then
        TriggerServerEvent('additem:qb', netId)
    else
        TriggerServerEvent('additem:ox', netId)
    end

    if IsPedMale(npc) then
        BeginTextCommandPrint('STRING')
        AddTextComponentString('Do not let the ~y~suspect~s~ escape! Use your stun gun to stop him.')
        EndTextCommandPrint(7000, false)
    else
        BeginTextCommandPrint('STRING')
        AddTextComponentString('Do not let the ~y~suspect~s~ escape! Use your stun gun to stop her.')
        EndTextCommandPrint(7000, false)
    end

    NetworkRequestControlOfEntity(npc)
    Wait(100)
    TaskSmartFleePed(npc, ped, 600.0, -1, true, false)

    Citizen.CreateThread(function()
        local arrested = false
        local animated = false

        while not arrested do
            Wait(0)

            local pedCoords = GetEntityCoords(ped)
            local npcCoords = GetEntityCoords(npc)
            local dist = #(npcCoords - pedCoords)

            if HasPedBeenDamagedByWeapon(npc, stungun, 0) and not animated then
                animated = true
                ClearPedTasksImmediately(npc)
                NetworkRequestControlOfEntity(npc)
                SetPedConfigFlag(npc, 249, true)
                SetEntityAsMissionEntity(npc, true, true)
                Wait(50)
                TriggerEvent('playSyncedScene', entity, "missminuteman_1ig_2", "handsup_base")
                SetBlockingOfNonTemporaryEvents(npc, true)
                FreezeEntityPosition(npc, true)
            end

            if animated and dist < 5.0 and HasPedBeenDamagedByWeapon(npc, stungun, 0) then
                AddTextEntry('pedinteraction', 'Press ~INPUT_CONTEXT~ to arrest the pedestrian')
                BeginTextCommandDisplayHelp('pedinteraction')
                EndTextCommandDisplayHelp(0, false, false, -1)
            end

            if IsControlJustReleased(0, 38) and dist < 5.0 and HasPedBeenDamagedByWeapon(npc, stungun, 0) then
                Wait(500)
                DoScreenFadeOut(500)
                Wait(800)
                TriggerServerEvent('arrestnpc', netId)

                -- Send arrest completed dispatch after chase
                SendDispatch('arrestMade', netId)
                dispatchSentForNpc[netId] = nil -- Clean up tracking

                Wait(100)
                Wait(100)
                StopPedScene(netId)
                StopPedScene(pednetId)
                Wait(500)
                DoScreenFadeIn(500)
                arrested = true
            end
        end
    end)
end)

RegisterNetEvent('npc:closeMenu')
AddEventHandler('npc:closeMenu', function(data)
    local npc = data.npc
    local netId = NetworkGetNetworkIdFromEntity(npc)

    if npc and DoesEntityExist(npc) then
        TriggerServerEvent('exitclearance', netId)
        -- Clean up dispatch tracking (NPC released without arrest)
        dispatchSentForNpc[netId] = nil
    end
end)

RegisterNetEvent('Cleartasks')
AddEventHandler('Cleartasks', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if DoesEntityExist(entity) and IsEntityAPed(entity) then
        ClearPedTasks(entity)
    end
end)

RegisterNetEvent('deletenpc')
AddEventHandler('deletenpc', function(netId)
    local npc = NetworkGetEntityFromNetworkId(netId)
    if npc and DoesEntityExist(npc) then
        DeleteEntity(npc)
    end
    -- Clean up dispatch tracking
    dispatchSentForNpc[netId] = nil
end)

-- Seize item from NPC - triggered by menu click
RegisterNetEvent('npc:seizeItem')
AddEventHandler('npc:seizeItem', function(data)
    local netId = data.netId
    local itemIndex = data.itemIndex

    if not netId or not itemIndex then return end

    local npc = NetworkGetEntityFromNetworkId(netId)
    if not npc or not DoesEntityExist(npc) then return end

    -- Request server to process the seizure
    TriggerServerEvent('npc:seizeItem:server', netId, itemIndex)
end)

-- Refresh inventory menu after seizing an item
RegisterNetEvent('npc:refreshInventory')
AddEventHandler('npc:refreshInventory', function(netId)
    if not netId then return end

    local npc = NetworkGetEntityFromNetworkId(netId)
    if not npc or not DoesEntityExist(npc) then return end

    -- Small delay to let notification show
    Wait(300)
    -- Request updated inventory from server
    TriggerServerEvent('npc:requestInventoryRefresh', netId)
end)

-- ============================================================================
-- INTEL TRADING SYSTEM
-- ============================================================================

local currentIntelOffer = nil

-- Request intel from NPC before arrest
RegisterNetEvent('npc:requestIntel')
AddEventHandler('npc:requestIntel', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    local netId = NetworkGetNetworkIdFromEntity(npc)
    TriggerServerEvent('npc:requestIntelOffer', netId)

    -- Show loading notification
    QBCore.Functions.Notify('Questioning suspect...', 'primary', 2000)
end)

-- Server responds with intel offer
RegisterNetEvent('npc:intelOfferResponse')
AddEventHandler('npc:intelOfferResponse', function(netId, hasIntel, intelType, intelContent, npcName)
    local npc = NetworkGetEntityFromNetworkId(netId)
    if not npc or not DoesEntityExist(npc) then return end

    if hasIntel then
        currentIntelOffer = {
            netId = netId,
            type = intelType,
            content = intelContent,
            npcName = npcName
        }

        -- NPC dialogue based on personality (could integrate with AI later)
        local dialogues = {
            "Look, I know things... I can help you out if you help me.",
            "Wait, wait! I got info. You want to know about the real players?",
            "Don't book me, man. I know people. I can give you something.",
            "Alright, look... I can tell you where the real stuff is going down."
        }

        QBCore.Functions.Notify(dialogues[math.random(#dialogues)], 'primary', 4000)

        local menuItems = {
            { header = "Intel Negotiation", txt = npcName.firstname .. " " .. npcName.lastname .. " has information", isMenuHeader = true },
            { header = "Hear Intel", txt = "Listen to what they know", icon = "fas fa-ear-listen",
              params = { event = "npc:hearIntel", args = { netId = netId } } },
            { header = "Accept Deal", txt = "Record intel, reduce sentence", icon = "fas fa-handshake",
              params = { event = "npc:acceptIntel", args = { netId = netId } } },
            { header = "Reject & Arrest", txt = "No deals, full charges", icon = "fas fa-gavel",
              params = { event = "npc:arrest", args = { npc = npc } } },
            { header = "Offer Informant Deal", txt = "Recruit as long-term informant", icon = "fas fa-user-secret",
              params = { event = "npc:offerInformant", args = { netId = netId } } },
        }

        exports['qb-menu']:openMenu(menuItems)
    else
        -- NPC has no useful intel
        local noInfoDialogues = {
            "I don't know nothing, man. I swear!",
            "I'm just out here trying to survive. I don't know anybody.",
            "You got the wrong guy. I ain't no snitch anyway."
        }

        QBCore.Functions.Notify(noInfoDialogues[math.random(#noInfoDialogues)], 'error', 3000)

        -- Return to arrest menu
        TriggerEvent('arrestmenu', { npc = npc })
    end
end)

-- Hear the intel before deciding
RegisterNetEvent('npc:hearIntel')
AddEventHandler('npc:hearIntel', function(data)
    if not currentIntelOffer then return end

    local intelTypeLabels = {
        drugs = "Drug Activity",
        weapons = "Weapons Trade",
        gang = "Gang Activity"
    }

    local typeLabel = intelTypeLabels[currentIntelOffer.type] or "Criminal Activity"

    QBCore.Functions.Notify("~y~[" .. typeLabel .. "]~s~ " .. currentIntelOffer.content, 'primary', 8000)

    -- Small delay then show options again
    Wait(2000)

    local npc = NetworkGetEntityFromNetworkId(data.netId)
    local menuItems = {
        { header = "Intel Decision", txt = "What will you do with this information?", isMenuHeader = true },
        { header = "Accept Deal", txt = "Record intel, reduce sentence", icon = "fas fa-handshake",
          params = { event = "npc:acceptIntel", args = { netId = data.netId } } },
        { header = "Reject & Arrest", txt = "No deals, full charges", icon = "fas fa-gavel",
          params = { event = "npc:arrest", args = { npc = npc } } },
        { header = "Offer Informant Deal", txt = "Recruit as long-term informant", icon = "fas fa-user-secret",
          params = { event = "npc:offerInformant", args = { netId = data.netId } } },
    }

    exports['qb-menu']:openMenu(menuItems)
end)

-- Accept intel deal
RegisterNetEvent('npc:acceptIntel')
AddEventHandler('npc:acceptIntel', function(data)
    if not currentIntelOffer then
        QBCore.Functions.Notify('No active intel offer', 'error')
        return
    end

    TriggerServerEvent('npc:acceptIntelDeal', data.netId, currentIntelOffer.type, currentIntelOffer.content)

    -- Proceed to arrest with intel flag
    local npc = NetworkGetEntityFromNetworkId(data.netId)
    currentIntelOffer = nil

    -- Modified arrest - with intel recorded
    TriggerEvent('npc:arrestWithIntel', { npc = npc, gaveIntel = true })
end)

-- Arrest with intel flag
RegisterNetEvent('npc:arrestWithIntel')
AddEventHandler('npc:arrestWithIntel', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    local ped = PlayerPedId()
    local netId = NetworkGetNetworkIdFromEntity(npc)
    local entity = NetworkGetEntityFromNetworkId(netId)

    RequestAnimDict('missminuteman_1ig_2')
    while not HasAnimDictLoaded('missminuteman_1ig_2') do
        Wait(100)
    end

    -- Intel cooperators don't run
    ClearPedTasksImmediately(npc)
    TriggerEvent("playSyncedScene", entity, "missminuteman_1ig_2", "handsup_base")
    Wait(750)
    DoScreenFadeOut(500)
    Wait(800)
    TriggerServerEvent('arrestnpc', netId, true, currentIntelOffer)

    SendDispatch('arrestMade', netId)
    dispatchSentForNpc[netId] = nil

    Wait(100)
    StopPedScene(netId)
    Wait(500)
    DoScreenFadeIn(500)
end)

-- Offer informant deal
RegisterNetEvent('npc:offerInformant')
AddEventHandler('npc:offerInformant', function(data)
    TriggerServerEvent('npc:offerInformantDeal', data.netId)
    QBCore.Functions.Notify('Making informant offer...', 'primary', 2000)
end)

-- Informant response from server
RegisterNetEvent('npc:informantResponse')
AddEventHandler('npc:informantResponse', function(netId, accepted, npcName, reason)
    local npc = NetworkGetEntityFromNetworkId(netId)

    if accepted then
        QBCore.Functions.Notify(npcName.firstname .. ' agreed to become an informant!', 'success', 5000)

        local menuItems = {
            { header = "Informant Recruited", txt = npcName.firstname .. " " .. npcName.lastname .. " is now your CI", isMenuHeader = true },
            { header = "Release (No Charges)", txt = "Let them go to maintain cover", icon = "fas fa-door-open",
              params = { event = "npc:releaseInformant", args = { netId = netId } } },
            { header = "Arrest Anyway", txt = "Book them despite cooperation", icon = "fas fa-gavel",
              params = { event = "npc:arrest", args = { npc = npc } } },
        }

        exports['qb-menu']:openMenu(menuItems)
    else
        if reason == 'already_informant' then
            QBCore.Functions.Notify(npcName.firstname .. ' is already a registered informant', 'error')
        else
            local refusalDialogues = {
                "I ain't no rat! Do what you gotta do.",
                "You think I'm stupid? My life wouldn't be worth nothing.",
                "Nah man, I'd rather do time than snitch."
            }
            QBCore.Functions.Notify(refusalDialogues[math.random(#refusalDialogues)], 'error', 4000)
        end

        -- Return to arrest menu
        TriggerEvent('arrestmenu', { npc = npc })
    end
end)

-- Release informant without charges
RegisterNetEvent('npc:releaseInformant')
AddEventHandler('npc:releaseInformant', function(data)
    local netId = data.netId
    local npc = NetworkGetEntityFromNetworkId(netId)

    if npc and DoesEntityExist(npc) then
        QBCore.Functions.Notify('Informant released. Stay in touch.', 'success')
        TriggerServerEvent('exitclearance', netId)
        dispatchSentForNpc[netId] = nil
        currentIntelOffer = nil
    end
end)

-- ============================================================================
-- AI DIALOGUE INTEGRATION (for dps-ainpcs)
-- ============================================================================

-- Request AI-generated dialogue for this interaction
RegisterNetEvent('npc:requestAIDialogue')
AddEventHandler('npc:requestAIDialogue', function(data)
    local npc = data.npc
    if not npc or not DoesEntityExist(npc) then return end

    if not Config.aiIntegration or not Config.aiIntegration.enabled then
        QBCore.Functions.Notify('AI dialogue not enabled', 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(npc)

    -- Check if dps-ainpcs is available
    local resourceState = GetResourceState('dps-ainpcs')
    if resourceState ~= 'started' then
        QBCore.Functions.Notify('AI NPC system not available', 'error')
        return
    end

    -- Request context from server then send to AI
    TriggerServerEvent('npc:getAIContext', netId)
end)

-- Receive AI context and generate dialogue
RegisterNetEvent('npc:aiContextResponse')
AddEventHandler('npc:aiContextResponse', function(netId, context)
    if not context or not context.name then return end

    -- Build prompt for dps-ainpcs
    local situation = "stopped by police"
    if context.hasIllegal then
        situation = "stopped by police while carrying contraband"
    end

    local systemPrompt = string.format([[
You are %s %s, a pedestrian in Los Santos who has been %s.
You are nervous and trying to figure out how to handle this situation.
%s
Respond naturally in 1-2 sentences. Stay in character.
    ]],
        context.name.firstname,
        context.name.lastname,
        situation,
        context.hasIllegal and "You know you're carrying illegal items and are very worried." or "You have nothing to hide but are still annoyed."
    )

    -- Try to use dps-ainpcs chat export
    local success = pcall(function()
        exports['dps-ainpcs']:SendPoliceInteractionPrompt(netId, systemPrompt, context)
    end)

    if not success then
        -- Fallback to basic dialogue
        local fallbackLines = context.hasIllegal and {
            "Look, officer, I don't want any trouble...",
            "Is there a problem? I'm just walking here.",
            "What's this about? I haven't done anything.",
        } or {
            "What seems to be the problem, officer?",
            "I'm just minding my own business here.",
            "Can I help you with something?",
        }

        QBCore.Functions.Notify(fallbackLines[math.random(#fallbackLines)], 'primary', 4000)
    end
end)
