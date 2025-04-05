DB = {}  -- Make DB global instead of local

-- Create a new storage
function DB.CreateStorage(owner_charid, name, x, y, z, callback)
    local query = "INSERT INTO character_storage (owner_charid, storage_name, pos_x, pos_y, pos_z, authorized_users, capacity) VALUES (?, ?, ?, ?, ?, ?, ?)"
    local params = {owner_charid, name, x, y, z, '[]', Config.DefaultCapacity}
    exports.oxmysql:execute(query, params, function(result)
        if callback then
            callback(result.insertId)
        end
    end)
end

-- Get storage by ID
function DB.GetStorage(id, callback)
    local query = "SELECT * FROM character_storage WHERE id = ?"
    exports.oxmysql:execute(query, {id}, function(result)
        if callback then
            if result and #result > 0 then
                callback(result[1])
            else
                callback(nil)
            end
        end
    end)
end

-- Get all storages owned by a player
function DB.GetPlayerStorages(charid, callback)
    local query = "SELECT * FROM character_storage WHERE owner_charid = ?"
    exports.oxmysql:execute(query, {charid}, function(result)
        if callback then
            callback(result)
        end
    end)
end

-- Get all storages a player has access to (owned or authorized)
function DB.GetAccessibleStorages(charid, callback)
    -- Use LIKE instead of JSON_CONTAINS for better compatibility
    local query = "SELECT * FROM character_storage WHERE owner_charid = ? OR authorized_users LIKE ?"
    -- Format the search pattern to find the character ID in the JSON array
    local searchPattern = "%" .. tostring(charid) .. "%"
    
    exports.oxmysql:execute(query, {charid, searchPattern}, function(result)
        if callback then
            callback(result or {})  -- Return empty array if nil
        end
    end)
end

-- Update storage location
function DB.UpdateStorageLocation(id, x, y, z, callback)
    local query = "UPDATE character_storage SET pos_x = ?, pos_y = ?, pos_z = ? WHERE id = ?"
    exports.oxmysql:execute(query, {x, y, z, id}, function(result)
        if callback then
            callback(result.affectedRows > 0)
        end
    end)
end

-- Update storage capacity
function DB.UpdateStorageCapacity(id, capacity, callback)
    local query = "UPDATE character_storage SET capacity = ? WHERE id = ?"
    exports.oxmysql:execute(query, {capacity, id}, function(result)
        if callback then
            callback(result.affectedRows > 0)
        end
    end)
end

-- Update authorized users for a storage
function DB.UpdateAuthorizedUsers(id, authorizedUsers, callback)
    exports.oxmysql:execute("UPDATE character_storage SET authorized_users = ? WHERE id = ?", 
        {authorizedUsers, id}, 
        function(rowsChanged)
            if callback then
                callback(rowsChanged.affectedRows > 0)
            end
        end
    )
end

-- Update storage name
function DB.UpdateStorageName(id, name, callback)
    local query = "UPDATE character_storage SET storage_name = ? WHERE id = ?"
    exports.oxmysql:execute(query, {name, id}, function(result)
        if callback then
            callback(result.affectedRows > 0)
        end
    end)
end

-- Delete storage
function DB.DeleteStorage(id, callback)
    local query = "DELETE FROM character_storage WHERE id = ?"
    exports.oxmysql:execute(query, {id}, function(result)
        if callback then
            callback(result.affectedRows > 0)
        end
    end)
end

-- Get all storages (for admin purposes)
function DB.GetAllStorages(callback)
    local query = "SELECT * FROM character_storage"
    exports.oxmysql:execute(query, {}, function(result)
        if callback then
            callback(result)
        end
    end)
end

-- New function: Load all storages from database
function DB.LoadAllStoragesFromDatabase(callback)
    local query = "SELECT * FROM character_storage"
    exports.oxmysql:execute(query, {}, function(result)
        if callback then
            callback(result or {})
        end
    end)
end

-- New function: Register all storage inventories
function DB.RegisterAllStorageInventories(storages, registerFunction)
    if not storages or #storages == 0 then
        print("No character storages to register")
        return 0
    end
    
    local count = 0
    for _, storage in ipairs(storages) do
        local success = registerFunction(storage.id, storage.capacity, storage)
        if success then
            count = count + 1
        end
    end
    
    print(("Successfully registered %d/%d character storage inventories"):format(count, #storages))
    return count
end
