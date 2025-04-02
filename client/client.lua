local VORPcore = exports.vorp_core:GetCore()
local storageBlips = {}
local playerStorages = {}
local nearestStorage = nil

-- Prompt variables
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local StoragePrompt

-- Helper function to get translation
function GetTranslation(key, ...)
    local lang = Config.DefaultLanguage
    if Config.Translations[lang] and Config.Translations[lang][key] then
        local text = Config.Translations[lang][key]
        if ... then
            return string.format(text, ...)
        end
        return text
    end
    return key
end

-- Initialize the script
Citizen.CreateThread(function()
    -- Initialize prompts
    InitializePrompts()
    
    -- Request initial player storages data from server
    TriggerServerEvent('character_storage:getPlayerStorages')
    
    -- Start the main loop
    MainLoop()
end)

-- Initialize prompts using native system
function InitializePrompts()
    -- Storage Access Prompt only - remove the create prompt
    StoragePrompt = PromptRegisterBegin()
    PromptSetControlAction(StoragePrompt, Config.PromptKey)
    local str = CreateVarString(10, 'LITERAL_STRING', GetTranslation("open_storage_prompt"))
    PromptSetText(StoragePrompt, str)
    PromptSetEnabled(StoragePrompt, true)
    PromptSetVisible(StoragePrompt, true)
    PromptSetStandardMode(StoragePrompt, true)
    PromptSetGroup(StoragePrompt, PromptGroup)
    PromptRegisterEnd(StoragePrompt)
end

-- Main loop to check for storage interactions
function MainLoop()
    Citizen.CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local wait = 1000
            local showPrompt = false
            
            -- Check if player is near any storage
            for _, storage in pairs(playerStorages) do
                if storage and storage.pos_x then
                    local storageCoords = vector3(storage.pos_x, storage.pos_y, storage.pos_z)
                    local dist = #(coords - storageCoords)
                    
                    if dist <= Config.AccessRadius then
                        -- Found a storage within range
                        nearestStorage = storage
                        showPrompt = true
                        wait = 0
                        
                        -- Show the prompt with storage name
                        local storageName = (storage.storage_name or ("Storage #" .. storage.id)) .. " | ID:" .. storage.id
                        local label = CreateVarString(10, 'LITERAL_STRING', storageName)
                        PromptSetActiveGroupThisFrame(PromptGroup, label)
                        
                        if PromptHasStandardModeCompleted(StoragePrompt) then
                            -- Check if player is owner to show menu or directly open storage
                            TriggerServerEvent('character_storage:checkOwnership', nearestStorage.id)
                            Wait(1000) -- Prevent spamming
                        end
                        
                        -- Only show for the closest storage
                        break
                    end
                end
            end
            
            -- If we're not showing a prompt, clear the nearest storage
            if not showPrompt then
                nearestStorage = nil
            end
            
            Citizen.Wait(wait)
        end
    end)
end

-- Create blips for player storages
function CreateStorageBlips()
    -- Remove existing blips
    for _, blip in pairs(storageBlips) do
        RemoveBlip(blip)
    end
    storageBlips = {}
    
    -- Create new blips
    if Config.UseBlips then
        for _, storage in pairs(playerStorages) do
            if storage and storage.pos_x then
                local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, storage.pos_x, storage.pos_y, storage.pos_z)
                SetBlipSprite(blip, Config.BlipSprite, 1)
                SetBlipScale(blip, 0.2)
                local storageName = storage.storage_name or GetTranslation("storage_title", storage.id)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, storageName)
                table.insert(storageBlips, blip)
            end
        end
    end
end

-- Register command for players to create a storage
RegisterCommand(Config.menustorage, function(source, args, rawCommand)
    local canCreate = true
    
    if canCreate then
        -- Use the menu function from menu.lua
        exports["character_storage"]:OpenCreateStorageMenu()
    else
        TriggerEvent('vorp:TipRight', GetTranslation("invalid_location"), 4000)
    end
end, false)

-- Add a suggestion for the command
TriggerEvent("chat:addSuggestion", "/createstorage", GetTranslation("create_storage_desc"))

-- Network event handlers
RegisterNetEvent('character_storage:receiveStorages')
AddEventHandler('character_storage:receiveStorages', function(storages)
    playerStorages = storages or {}
    -- Update the storages in menu.lua
    exports["character_storage"]:UpdateStorages(playerStorages)
    CreateStorageBlips()
    
    -- Debug message to track updates
    if Config.Debug then
        print("[DEBUG] Storage data refreshed: " .. #playerStorages .. " storages available")
    end
end)

RegisterNetEvent('character_storage:updateStorageLocation')
AddEventHandler('character_storage:updateStorageLocation', function(id, x, y, z)
    for i, storage in ipairs(playerStorages) do
        if storage.id == id then
            playerStorages[i].pos_x = x
            playerStorages[i].pos_y = y
            playerStorages[i].pos_z = z
            break
        end
    end
    exports["character_storage"]:UpdateStorages(playerStorages)
    CreateStorageBlips()
end)

RegisterNetEvent('character_storage:updateStorageLocations')
AddEventHandler('character_storage:updateStorageLocations', function(storage)
    table.insert(playerStorages, storage)
    exports["character_storage"]:UpdateStorages(playerStorages)
    CreateStorageBlips()
end)

RegisterNetEvent('character_storage:removeStorage')
AddEventHandler('character_storage:removeStorage', function(id)
    for i, storage in ipairs(playerStorages) do
        if storage.id == id then
            table.remove(playerStorages, i)
            break
        end
    end
    exports["character_storage"]:UpdateStorages(playerStorages)
    CreateStorageBlips()
end)

RegisterNetEvent('character_storage:updateStorageName')
AddEventHandler('character_storage:updateStorageName', function(id, newName)
    for i, storage in ipairs(playerStorages) do
        if storage.id == id then
            playerStorages[i].storage_name = newName
            break
        end
    end
    exports["character_storage"]:UpdateStorages(playerStorages)
    CreateStorageBlips() 
end)

-- Clean up resources on stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(storageBlips) do
            RemoveBlip(blip)
        end
    end
end)
