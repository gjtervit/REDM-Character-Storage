local VORPcore = exports.vorp_core:GetCore()
local VORPinv = exports.vorp_inventory
-- DB is now global from database.lua, so no require neededbase

local storageCache = {}

-- Debug helper function for consistent logging
function DebugLog(message)
    if not Config.Debug then return end
    
    print("[Server Debug] " .. message)
end

-- Helper function to refresh a player's storages
function RefreshPlayerStorages(source)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    DB.GetAccessibleStorages(charId, function(storages)
        TriggerClientEvent('character_storage:receiveStorages', source, storages)
        DebugLog("Refreshed storage data for player " .. source)
    end)
end

-- Load all storages into cache on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    DB.GetAllStorages(function(result)
        if result then
            for _, storage in ipairs(result) do
                -- Register inventory for each storage
                RegisterStorageInventory(storage.id, storage.capacity)
                storageCache[storage.id] = storage
            end
            print(("Loaded %d character storages"):format(#result))
        end
    end)
end)

-- Register a custom inventory for a storage
function RegisterStorageInventory(id, capacity)
    local prefix = "character_storage_" .. id
    
    -- Get storage name from cache
    local storageName = (storageCache[id] and storageCache[id].storage_name or ("Storage #" .. id)) .. " | ID:" .. id
    
    -- Remove existing inventory if it exists to avoid conflicts
    if VORPinv:isCustomInventoryRegistered(prefix) then
        DebugLog("Removing existing inventory: " .. prefix)
        VORPinv:removeInventory(prefix)
    end
    
    -- Register the inventory with proper parameters
    DebugLog("Registering inventory: " .. prefix .. " with capacity " .. capacity)
    local data = {
        id = prefix,
        name = storageName,
        limit = capacity,
        acceptWeapons = true,
        shared = false,
        ignoreItemStackLimit = true,
        whitelistItems = false,
        UsePermissions = false, -- Changed to false to match vorp_medic pattern
        UseBlackList = false,
        whitelistWeapons = false,
    }
    
    local success = VORPinv:registerInventory(data)
    DebugLog("Inventory registration result: " .. tostring(success))
    return success
end

-- Check if player owns a storage
function IsStorageOwner(charId, storageId)
    local storage = storageCache[storageId]
    return storage and tonumber(storage.owner_charid) == tonumber(charId)
end

-- Check if player has access to a storage
function HasStorageAccess(charId, storageId)
    local storage = storageCache[storageId]
    
    if not storage then return false end
    
    -- Owner always has access
    if tonumber(storage.owner_charid) == tonumber(charId) then
        return true
    end
    
    -- Check authorized users
    local authorizedUsers = json.decode(storage.authorized_users or '[]')
    for _, id in pairs(authorizedUsers) do
        if tonumber(id) == tonumber(charId) then
            return true
        end
    end
    
    return false
end

-- Create a new storage
RegisterServerEvent('character_storage:createStorage')
AddEventHandler('character_storage:createStorage', function()
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    -- Check if player has reached max number of storages
    DB.GetPlayerStorages(charId, function(storages)
        if #storages >= Config.MaxStorages then
            VORPcore.NotifyRightTip(source, GetTranslation("max_storages_reached", Config.MaxStorages), 4000)
            return
        end
        
        -- Check if player has enough money
        if Character.money < Config.StorageCreationPrice then
            VORPcore.NotifyRightTip(source, GetTranslation("not_enough_money"), 4000)
            return
        end
        
        -- Get player position
        local coords = GetEntityCoords(GetPlayerPed(source))
        local name = Character.firstname .. "'s Storage"
        
        -- Create storage in database
        DB.CreateStorage(charId, name, coords.x, coords.y, coords.z, function(storageId)
            if storageId then
                -- Remove money from player
                Character.removeCurrency(0, Config.StorageCreationPrice)
                
                -- Register inventory for new storage
                RegisterStorageInventory(storageId, Config.DefaultCapacity)
                
                -- Cache the new storage
                DB.GetStorage(storageId, function(storage)
                    storageCache[storageId] = storage
                    
                    -- Notify client
                    VORPcore.NotifyRightTip(source, GetTranslation("storage_created", Config.StorageCreationPrice), 4000)
                    
                    -- Refresh player's storages data immediately
                    RefreshPlayerStorages(source)
                    
                    -- Update all other clients with new storage location
                    TriggerClientEvent('character_storage:updateStorageLocations', -1, {
                        id = storageId,
                        pos_x = coords.x,
                        pos_y = coords.y,
                        pos_z = coords.z,
                        owner_charid = charId,
                        storage_name = name,
                        capacity = Config.DefaultCapacity,
                        authorized_users = '[]'
                    })
                end)
            end
        end)
    end)
end)

-- Open a storage
RegisterNetEvent("character_storage:openStorage")
AddEventHandler("character_storage:openStorage", function(storageId)
    local _source = source
    
    -- Force convert to number to avoid type issues
    storageId = tonumber(storageId)
    
    DebugLog("Open storage request: ID=" .. tostring(storageId) .. " from player=" .. _source)
    
    -- Get our cached storage info
    local storage = storageCache[storageId]
    if not storage then 
        DebugLog("ERROR: Storage " .. tostring(storageId) .. " not found in cache!")
        VORPcore.NotifyRightTip(_source, "Storage not found", 3000)
        return
    end
    
    -- Get character ID of requesting player
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charId = Character.charIdentifier
    
    DebugLog("Player charId=" .. charId .. " requesting access to storage owned by " .. storage.owner_charid)
    
    -- Verify access
    local hasAccess = false
    if tonumber(storage.owner_charid) == tonumber(charId) then
        hasAccess = true
        DebugLog("Access granted: Player is owner")
    else
        -- Check authorized users
        local authorizedUsers = json.decode(storage.authorized_users or "[]")
        for _, id in pairs(authorizedUsers) do
            if tonumber(id) == tonumber(charId) then
                hasAccess = true
                DebugLog("Access granted: Player is authorized")
                break
            end
        end
    end
    
    if not hasAccess then
        DebugLog("Access denied for player " .. charId)
        VORPcore.NotifyRightTip(_source, "You don't have access to this storage", 3000)
        return
    end
    
    -- Set storage name
    local storageName = (storage.storage_name or ("Storage #" .. storageId)) .. " | ID:" .. storageId
    local inventoryName = "character_storage_" .. storageId
    
    -- Make sure inventory is registered before opening it
    if not VORPinv:isCustomInventoryRegistered(inventoryName) then
        DebugLog("Registering inventory that wasn't registered before: " .. inventoryName)
        RegisterStorageInventory(storageId, storage.capacity or Config.DefaultCapacity)
    end
    
    -- Open the inventory directly
    DebugLog("Opening inventory " .. inventoryName .. " for player " .. _source)
    VORPinv:openInventory(_source, inventoryName)
end)

-- Helper function to get storage by ID (implement according to your database structure)
function GetStorageById(id)
    local storage = nil
    -- Replace with your database query to get storage data
    exports.ghmattimysql:execute("SELECT * FROM character_storages WHERE id = @id", {
        ['@id'] = id
    }, function(result)
        if result[1] then
            storage = result[1]
        end
    end)
    
    -- Wait for the query to complete
    while storage == nil do
        Citizen.Wait(0)
    end
    
    return storage
end

-- Check if player is storage owner and respond accordingly
RegisterServerEvent('character_storage:checkOwnership')
AddEventHandler('character_storage:checkOwnership', function(storageId)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    local group = Character.group
    
    -- Check if storage exists
    if not storageCache[storageId] then
        VORPcore.NotifyRightTip(source, "Storage not found", 4000)
        return
    end
    
    -- If player is owner, show the owner menu
    if IsStorageOwner(charId, storageId) then
        TriggerClientEvent('character_storage:openOwnerMenu', source, storageId)
    -- If player has access or is admin, open storage directly
    elseif HasStorageAccess(charId, storageId) or group == "admin" then
        local prefix = "character_storage_" .. storageId
        VORPinv:openInventory(source, prefix)
    else
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
    end
end)

-- Get character id from character name
function GetCharIdFromName(firstname, lastname, callback)
    local query = "SELECT charidentifier FROM characters WHERE firstname = ? AND lastname = ?"
    exports.oxmysql:execute(query, {firstname, lastname}, function(result)
        if result and #result > 0 then
            callback(result[1].charidentifier)
        else
            callback(nil)
        end
    end)
end

-- Add user to storage access list
RegisterServerEvent('character_storage:addUser')
AddEventHandler('character_storage:addUser', function(storageId, firstname, lastname)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    -- Check if player is storage owner
    if not IsStorageOwner(charId, storageId) then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    -- Find character id from name
    GetCharIdFromName(firstname, lastname, function(targetCharId)
        if not targetCharId then
            VORPcore.NotifyRightTip(source, GetTranslation("player_not_found"), 4000)
            return
        end
        
        -- Update authorized users
        local storage = storageCache[storageId]
        local authorizedUsers = json.decode(storage.authorized_users or '[]')
        
        -- Check if user is already authorized
        for _, id in pairs(authorizedUsers) do
            if tonumber(id) == tonumber(targetCharId) then
                VORPcore.NotifyRightTip(source, GetTranslation("already_has_access"), 4000)
                return
            end
        end
        
        -- Add user to authorized users
        table.insert(authorizedUsers, targetCharId)
        
        -- Update database
        DB.UpdateAuthorizedUsers(storageId, json.encode(authorizedUsers), function(success)
            if success then
                -- Update cache
                storage.authorized_users = json.encode(authorizedUsers)
                VORPcore.NotifyRightTip(source, GetTranslation("player_added"), 4000)
                
                -- Refresh owner's storage data
                RefreshPlayerStorages(source)
                
                -- If target player is online, notify and refresh them too
                local targetSource = GetPlayerSourceFromCharId(targetCharId)
                if targetSource then
                    -- Notify target player they've been given access
                    local storageName = storage.storage_name or "Storage #" .. storageId
                    local ownerName = Character.firstname .. " " .. Character.lastname
                    TriggerClientEvent('character_storage:notifyAccessGranted', targetSource, storageName, ownerName)
                    
                    -- Update target player's storage list
                    RefreshPlayerStorages(targetSource)
                end
            end
        end)
    end)
end)

-- Helper function to find a player's source from their character ID
function GetPlayerSourceFromCharId(charId)
    for _, playerId in ipairs(GetPlayers()) do
        local user = VORPcore.getUser(playerId)
        if user then
            local character = user.getUsedCharacter
            if character and tonumber(character.charIdentifier) == tonumber(charId) then
                return tonumber(playerId)
            end
        end
    end
    return nil
end

-- Remove user from storage access list
RegisterServerEvent('character_storage:removeUser')
AddEventHandler('character_storage:removeUser', function(storageId, targetCharId)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    -- Check if player is storage owner
    if not IsStorageOwner(charId, storageId) then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    -- Update authorized users
    local storage = storageCache[storageId]
    local authorizedUsers = json.decode(storage.authorized_users or '[]')
    local newAuthorizedUsers = {}
    
    -- Filter out the target user
    for _, id in pairs(authorizedUsers) do
        if tonumber(id) ~= tonumber(targetCharId) then
            table.insert(newAuthorizedUsers, id)
        end
    end
    
    -- Update database
    DB.UpdateAuthorizedUsers(storageId, json.encode(newAuthorizedUsers), function(success)
        if success then
            -- Update cache
            storage.authorized_users = json.encode(newAuthorizedUsers)
            VORPcore.NotifyRightTip(source, GetTranslation("player_removed"), 4000)
            
            -- Refresh player's storage data
            RefreshPlayerStorages(source)
            
            -- If target player is online, notify and refresh them too
            local targetSource = GetPlayerSourceFromCharId(targetCharId)
            if targetSource then
                local storageName = storage.storage_name or "Storage #" .. storageId
                local ownerName = Character.firstname .. " " .. Character.lastname
                TriggerClientEvent('character_storage:notifyAccessRevoked', targetSource, storageName, ownerName)
                RefreshPlayerStorages(targetSource)
            end
        end
    end)
end)

-- Add a new, more direct event handler for removing access
RegisterServerEvent('character_storage:removeAccess')
AddEventHandler('character_storage:removeAccess', function(storageId, targetCharId)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local ownerCharId = Character.charIdentifier
    
    DebugLog("========== REMOVAL REQUEST START ==========")
    DebugLog("Source player: " .. source .. ", Character: " .. ownerCharId)
    DebugLog("Storage ID: " .. tostring(storageId) .. ", Target CharID: " .. tostring(targetCharId))
    
    -- Ensure proper type conversion
    storageId = tonumber(storageId)
    targetCharId = tonumber(targetCharId)
    
    if not storageId or not targetCharId then
        DebugLog("ERROR: Invalid IDs after conversion")
        VORPcore.NotifyRightTip(source, "Invalid storage or character ID", 4000)
        return
    end
    
    -- Check if storage exists
    if not storageCache[storageId] then
        DebugLog("ERROR: Storage " .. storageId .. " not found in cache")
        VORPcore.NotifyRightTip(source, "Storage not found", 4000)
        return
    end
    
    local storage = storageCache[storageId]
    DebugLog("Storage found: Name = " .. (storage.storage_name or "Unnamed") .. ", Owner = " .. storage.owner_charid)
    
    -- Check if player is storage owner
    if tonumber(storage.owner_charid) ~= tonumber(ownerCharId) then
        DebugLog("ERROR: Player " .. ownerCharId .. " is not the owner " .. storage.owner_charid)
        VORPcore.NotifyRightTip(source, "Only the storage owner can remove access", 4000)
        return
    end
    
    -- Get current authorized users
    DebugLog("Raw authorized_users JSON: " .. tostring(storage.authorized_users))
    
    local authorizedUsers = {}
    -- Safely parse JSON
    local success = pcall(function() 
        authorizedUsers = json.decode(storage.authorized_users or '[]')
    end)
    
    if not success then
        DebugLog("ERROR: Failed to parse authorized_users JSON")
        VORPcore.NotifyRightTip(source, "Error processing storage data", 4000)
        return
    end
    
    DebugLog("Current authorized users: " .. json.encode(authorizedUsers))
    
    -- Create new list without target user
    local newAuthorizedUsers = {}
    local wasRemoved = false
    local targetSource = nil
    
    for _, id in pairs(authorizedUsers) do
        if tonumber(id) ~= targetCharId then
            table.insert(newAuthorizedUsers, tonumber(id))
        else
            wasRemoved = true
            DebugLog("User " .. id .. " will be removed")
            -- Find target player's source if they're online
            targetSource = GetPlayerSourceFromCharId(targetCharId)
        end
    end
    
    if not wasRemoved then
        DebugLog("ERROR: Target user " .. targetCharId .. " not found in authorized list")
        VORPcore.NotifyRightTip(source, "Player not found in access list", 4000)
        return
    end
    
    -- Update the database directly
    local jsonData = json.encode(newAuthorizedUsers)
    DebugLog("New authorized_users JSON: " .. jsonData)
    
    -- Use a direct query for simplicity
    exports.oxmysql:execute(
        "UPDATE character_storage SET authorized_users = ? WHERE id = ?",
        {jsonData, storageId},
        function(result)
            if result and result.affectedRows > 0 then
                DebugLog("Database updated successfully - Rows affected: " .. result.affectedRows)
                
                -- Update local cache
                storage.authorized_users = jsonData
                VORPcore.NotifyRightTip(source, "Player access has been removed", 4000)
                
                -- Refresh owner's storage data
                RefreshPlayerStorages(source)
                
                -- If target player is online, notify and refresh them too
                if targetSource then
                    local storageName = storage.storage_name or "Storage #" .. storageId
                    local ownerName = Character.firstname .. " " .. Character.lastname
                    TriggerClientEvent('character_storage:notifyAccessRevoked', targetSource, storageName, ownerName)
                    RefreshPlayerStorages(targetSource)
                end
                
                DebugLog("Success - Sent storage refresh to client")
            else
                DebugLog("ERROR: Database update failed")
                VORPcore.NotifyRightTip(source, "Failed to update database", 4000)
            end
            
            DebugLog("========== REMOVAL REQUEST COMPLETE ==========")
        end
    )
end)

-- Upgrade storage capacity
RegisterServerEvent('character_storage:upgradeStorage')
AddEventHandler('character_storage:upgradeStorage', function(storageId)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    -- Check if player is storage owner
    if not IsStorageOwner(charId, storageId) then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    local storage = storageCache[storageId]
    local currentCapacity = tonumber(storage.capacity) or Config.DefaultCapacity
    
    -- Calculate the number of previous upgrades
    local previousUpgrades = math.floor((currentCapacity - Config.DefaultCapacity) / Config.StorageUpgradeSlots)
    
    -- Calculate the price with multiplier: BasePrice * (1 + Multiplier)^PreviousUpgrades
    local basePrice = Config.StorageUpgradePrice
    local multiplier = Config.StorageUpgradePriceMultiplier
    local upgradePrice = math.floor(basePrice * math.pow((1 + multiplier), previousUpgrades))
    
    -- Check if player has enough money
    if Character.money < upgradePrice then
        VORPcore.NotifyRightTip(source, GetTranslation("not_enough_money"), 4000)
        return
    end
    
    local newCapacity = currentCapacity + Config.StorageUpgradeSlots
    
    -- Update storage capacity
    DB.UpdateStorageCapacity(storageId, newCapacity, function(success)
        if success then
            -- Remove money from player
            Character.removeCurrency(0, upgradePrice)
            
            -- Update cache
            storage.capacity = newCapacity
            
            -- Update inventory limit
            local prefix = "character_storage_" .. storageId
            VORPinv:updateCustomInventorySlots(prefix, newCapacity)
            
            VORPcore.NotifyRightTip(source, GetTranslation("storage_upgraded", upgradePrice), 4000)
            
            -- Refresh the player's storage data so the client has updated capacity info
            RefreshPlayerStorages(source)
        end
    end)
end)

-- Rename storage
RegisterServerEvent('character_storage:renameStorage')
AddEventHandler('character_storage:renameStorage', function(storageId, newName)
    local source = source
    local Character = VORPcore.getUser(source).getUsedCharacter
    local charId = Character.charIdentifier
    
    -- Check if player is storage owner
    if not IsStorageOwner(charId, storageId) then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    -- Sanitize the name (remove any potential SQL injection)
    newName = newName:gsub("'", ""):gsub(";", ""):gsub("-", ""):sub(1, 50)
    
    -- Update storage name
    local query = "UPDATE character_storage SET storage_name = ? WHERE id = ?"
    exports.oxmysql:execute(query, {newName, storageId}, function(result)
        if result.affectedRows > 0 then
            -- Update cache
            storageCache[storageId].storage_name = newName
            
            -- Get the current inventory data to preserve its settings
            local prefix = "character_storage_" .. storageId
            local currentStorage = storageCache[storageId]
            
            -- Remove existing inventory and re-register with new name
            VORPinv:removeInventory(prefix)
            
            -- Re-register the inventory with the new name
            local data = {
                id = prefix,
                name = newName .. " | ID:" .. storageId,
                limit = currentStorage.capacity,
                acceptWeapons = true,
                shared = false,
                ignoreItemStackLimit = true,
                whitelistItems = false,
                UsePermissions = false,
                UseBlackList = false,
                whitelistWeapons = false
            }
            VORPinv:registerInventory(data)
            
            -- Notify client
            VORPcore.NotifyRightTip(source, GetTranslation("storage_renamed"), 4000)
            
            -- Refresh owner's storage data
            RefreshPlayerStorages(source)
            
            -- Update all clients with new storage name
            TriggerClientEvent('character_storage:updateStorageName', -1, storageId, newName)
        end
    end)
end)

-- Admin command to move a storage
RegisterCommand(Config.adminmovestorage, function(source, args, rawCommand)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local group = Character.group
    
    -- Check if player is admin
    if group ~= "admin" then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    local storageId = tonumber(args[1])
    local x = tonumber(args[2])
    local y = tonumber(args[3])
    local z = tonumber(args[4])
    
    if not storageId or not x or not y or not z then
        VORPcore.NotifyRightTip(source, "Usage: /movestorage id x y z", 4000)
        return
    end
    
    -- Check if storage exists
    if not storageCache[storageId] then
        VORPcore.NotifyRightTip(source, "Storage not found", 4000)
        return
    end
    
    -- Update storage location
    DB.UpdateStorageLocation(storageId, x, y, z, function(success)
        if success then
            -- Update cache
            storageCache[storageId].pos_x = x
            storageCache[storageId].pos_y = y
            storageCache[storageId].pos_z = z
            
            -- Update all clients with new storage location
            TriggerClientEvent('character_storage:updateStorageLocation', -1, storageId, x, y, z)
            VORPcore.NotifyRightTip(source, GetTranslation("storage_moved", storageId), 4000)
        end
    end)
end, false)

-- Admin command to delete a storage
RegisterCommand(Config.admindeletestorage, function(source, args, rawCommand)
    local Character = VORPcore.getUser(source).getUsedCharacter
    local group = Character.group
    
    -- Check if player is admin
    if group ~= "admin" then
        VORPcore.NotifyRightTip(source, GetTranslation("no_permission"), 4000)
        return
    end
    
    local storageId = tonumber(args[1])
    
    if not storageId then
        VORPcore.NotifyRightTip(source, "Usage: /deletestorage id", 4000)
        return
    end
    
    -- Check if storage exists
    if not storageCache[storageId] then
        VORPcore.NotifyRightTip(source, "Storage not found", 4000)
        return
    end
    
    -- Delete storage
    DB.DeleteStorage(storageId, function(success)
        if success then
            -- Remove from cache
            storageCache[storageId] = nil
            
            -- Remove inventory
            local prefix = "character_storage_" .. storageId
            VORPinv:removeInventory(prefix)
            
            -- Update all clients
            TriggerClientEvent('character_storage:removeStorage', -1, storageId)
            VORPcore.NotifyRightTip(source, "Storage #" .. storageId .. " deleted", 4000)
        end
    end)
end, false)

-- Get player storages
RegisterServerEvent('character_storage:getPlayerStorages')
AddEventHandler('character_storage:getPlayerStorages', function()
    local source = source
    RefreshPlayerStorages(source)
end)

-- Get all online players with their positions
RegisterServerEvent('character_storage:getOnlinePlayers')
AddEventHandler('character_storage:getOnlinePlayers', function()
    local source = source
    local _source = source
    local playersList = {}
    
    -- Loop through all players
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(playerId) ~= tonumber(_source) then -- Skip the requesting player
            local targetUser = VORPcore.getUser(playerId)
            if targetUser then
                local targetCharacter = targetUser.getUsedCharacter
                local targetPed = GetPlayerPed(playerId)
                local targetCoords = GetEntityCoords(targetPed)
                
                table.insert(playersList, {
                    serverId = playerId,
                    charId = targetCharacter.charIdentifier,
                    name = targetCharacter.firstname .. " " .. targetCharacter.lastname,
                    coords = {
                        x = targetCoords.x,
                        y = targetCoords.y,
                        z = targetCoords.z
                    }
                })
            end
        end
    end
    
    TriggerClientEvent('character_storage:receiveOnlinePlayers', source, playersList)
end)

-- Add this event handler to respond to character name requests from clients
RegisterServerEvent("character_storage:getCharacterName")
AddEventHandler("character_storage:getCharacterName", function(charId, callbackId)
    local _source = source
    
    exports.oxmysql:execute("SELECT firstname, lastname FROM characters WHERE charidentifier = ?", {charId}, function(result)
        local name = nil
        if result and #result > 0 then
            name = result[1].firstname .. " " .. result[1].lastname
        end
        TriggerClientEvent(callbackId, _source, name)
    end)
end)

-- Get authorized users for a storage
exports('GetAuthorizedUsers', function(storageId)
    local storage = storageCache[storageId]
    if storage then
        return json.decode(storage.authorized_users or '[]')
    end
    return {}
end)

-- Expose Database API for external use
exports('GetDatabaseAPI', function()
    return DB
end)

-- Helper function to get translation based on character's language
function GetTranslation(key, ...)
    local lang = Config.DefaultLanguage
    
    -- Simple format function
    local result = Config.Translations[lang][key] or key
    
    if ... then
        result = string.format(result, ...)
    end
    
    return result
end
