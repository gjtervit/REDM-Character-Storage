# REDM Character Storage

A comprehensive storage system for RedM servers using VORP Framework. Allow your players to create personal storage containers that can be accessed by themselves and trusted friends.

## Features
- Player-owned storage containers that persist through server restarts
- Configurable storage capacity and upgrade options
- Access management system - players can add trusted friends to access their storage
- Blips on map for easy storage location
- Admin commands for management
- Multi-language support (English and Spanish)

## Requirements
- [VORP Core](https://github.com/VORPCORE/vorp_core-lua)
- [VORP Inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [VORP Menu](https://github.com/VORPCORE/vorp_menu)
- [oxmysql](https://github.com/overextended/oxmysql)
- [syn_inputs](https://discord.com/channels/777290543406776341/903875147050655744/943606123171282945)

## Installation
1. Download the latest release from GitHub
2. Extract the zip file into your server's resources folder
3. Import the SQL file (`sql/install.sql`) into your database
4. Add `ensure character_storage` to your server.cfg
5. Configure the settings in config.lua to your liking
6. Start your server

## Usage
- Players can create a storage using `/createstorage` command
- Access storages by approaching them and pressing the G key
- Storage owners can:
  - Rename their storage
  - Upgrade storage capacity
  - Manage access permissions for other players

## Admin Commands
- `/movestorage [id] [x] [y] [z]` - Move a storage to specified coordinates
- `/deletestorage [id]` - Delete a storage
- `/checkcsupdate` - Check for script updates

## Update System
This resource includes an automatic version checking system that will notify server administrators when updates are available. You can configure the update system in the config.lua file:

```lua
Config.CheckForUpdates = true        -- Enable/disable update checks
Config.ShowUpdateNotifications = true -- Show notifications to admins
Config.AutoUpdate = false            -- Experimental auto-update feature
```

To update manually:
1. Download the latest version from GitHub 
2. Replace your existing files with the new ones
3. Restart the resource

## Configuration
See the config.lua file for detailed configuration options including:
- Storage creation and upgrade prices
- Default and maximum storage capacity
- Blip and prompt settings
- Language options

## Version History
- See version file for full change logs.

## License
[MIT License](LICENSE)

