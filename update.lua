local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
local resourceName = GetCurrentResourceName()
local githubRepo = "RosewoodRidge/REDM-Character-Storage" 

-- Function to check for updates
function CheckForUpdates()
    if Config.CheckForUpdates then
        print('^3======================================================^7')
        print('^3[Character Storage] ^5Checking for updates...^7')
        
        PerformHttpRequest("https://api.github.com/repos/"..githubRepo.."/releases/latest", function(err, text, headers)
            if err == 200 then
                local data = json.decode(text)
                if data.tag_name ~= nil then
                    local latestVersion = data.tag_name:gsub("v", "")
                    
                    -- Simple version comparison
                    local currentMajor, currentMinor, currentPatch = string.match(currentVersion, "(%d+)%.(%d+)%.(%d+)")
                    local latestMajor, latestMinor, latestPatch = string.match(latestVersion, "(%d+)%.(%d+)%.(%d+)")
                    
                    currentMajor, currentMinor, currentPatch = tonumber(currentMajor), tonumber(currentMinor), tonumber(currentPatch)
                    latestMajor, latestMinor, latestPatch = tonumber(latestMajor), tonumber(latestMinor), tonumber(latestPatch)
                    
                    local isUpdateAvailable = false
                    
                    if latestMajor > currentMajor then
                        isUpdateAvailable = true
                    elseif latestMajor == currentMajor and latestMinor > currentMinor then
                        isUpdateAvailable = true
                    elseif latestMajor == currentMajor and latestMinor == currentMinor and latestPatch > currentPatch then
                        isUpdateAvailable = true
                    end
                    
                    if isUpdateAvailable then
                        print('^3[Character Storage] ^1Update available!^7')
                        print('^3[Character Storage] ^5Current version: ^7' .. currentVersion)
                        print('^3[Character Storage] ^5Latest version: ^7' .. latestVersion)
                        print('^3[Character Storage] ^5Download: ^7' .. data.html_url)
                        if Config.ShowUpdateNotifications then
                            TriggerEvent("vorp:TipRight", "Character Storage update available: v" .. latestVersion, 10000)
                        end
                    else
                        print('^3[Character Storage] ^5You are running the latest version!^7')
                    end
                    
                    -- If auto-update is enabled
                    if isUpdateAvailable and Config.AutoUpdate then
                        print('^3[Character Storage] ^5Auto-updating...^7')
                        DownloadLatestUpdate(data)
                    end
                else
                    print('^3[Character Storage] ^1Failed to check for updates. Missing version tag.^7')
                end
            else
                print('^3[Character Storage] ^1Failed to check for updates.^7')
                print('^3[Character Storage] ^1Error: ^7' .. (err or "unknown"))
            end
        end, "GET", "", { ["Content-Type"] = "application/json" })
        
        print('^3======================================================^7')
    end
end

-- Function to download and apply updates
function DownloadLatestUpdate(releaseData)
    if releaseData and releaseData.zipball_url then
        print('^3[Character Storage] ^5Downloading update from: ^7' .. releaseData.zipball_url)
        
        -- This is a placeholder for actual update logic
        -- In a real implementation, you would:
        -- 1. Download the zipball
        -- 2. Extract it to a temp directory
        -- 3. Replace the current resource files
        -- 4. Trigger a resource restart
        
        -- Note: FiveM/RedM has limitations on what server-side scripts can do with the filesystem
        -- You might need to implement a separate update tool or provide manual update instructions
        
        print('^3[Character Storage] ^1Auto-update not fully implemented. Please download manually.^7')
    end
end

-- Admin command to check for updates manually
RegisterCommand("checkcsupdate", function(source, args, rawCommand)
    local _source = source
    -- Only allow server console or admin players to use this command
    if _source == 0 then -- Server console
        CheckForUpdates()
    else
        local User = VORPcore.getUser(_source)
        if User then
            local Character = User.getUsedCharacter
            if Character and Character.group == "admin" then
                CheckForUpdates()
                VORPcore.NotifyRightTip(_source, "Checking for Character Storage updates...", 4000)
            else
                VORPcore.NotifyRightTip(_source, "You don't have permission to use this command", 4000)
            end
        end
    end
end, false)

-- Run update check when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    -- Wait a bit to ensure Config is loaded
    Citizen.SetTimeout(3000, function()
        CheckForUpdates()
    end)
end)
