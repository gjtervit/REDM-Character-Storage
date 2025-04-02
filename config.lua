Config = {}

-- Enable/disable debug messages
Config.Debug = false

-- Price to create a storage
Config.StorageCreationPrice = 500

-- Price to increase storage capacity
Config.StorageUpgradePrice = 100

-- Amount to increase storage by
Config.StorageUpgradeSlots = 20

-- Maximum number of storages a player can own
Config.MaxStorages = 2

-- Default storage capacity (items)
Config.DefaultCapacity = 200

-- Storage access radius (in units)
Config.AccessRadius = 2.0

-- Blip settings
Config.UseBlips = true
Config.BlipSprite = -1138864184

-- Prompt settings
Config.PromptKey = 0x760A9C6F -- G key

-- Commands for handling storages
Config.menustorage = 'createstorage'
Config.adminmovestorage = 'movestorage'
Config.admindeletestorage = 'deletestorage'

-- Language system
Config.DefaultLanguage = "english" -- Default language: "english" or "spanish"

-- Update system configuration
Config.CheckForUpdates = true        -- Whether to check for updates on script start
Config.ShowUpdateNotifications = true -- Show notifications to admins when updates are available
Config.AutoUpdate = false            -- Attempt to automatically update (not fully implemented)

-- Translation system
Config.Translations = {
    ["english"] = {
        -- Notifications
        ["storage_created"] = "Storage created for $%d",
        ["storage_moved"] = "Storage #%d moved successfully",
        ["storage_upgraded"] = "Storage capacity upgraded for $%d",
        ["not_enough_money"] = "You don't have enough money",
        ["max_storages_reached"] = "You've reached the maximum number of storages (%d)",
        ["player_added"] = "Player added to storage access list",
        ["player_removed"] = "Player removed from storage access list",
        ["no_permission"] = "You don't have permission to do this",
        ["too_far_away"] = "You are too far away from the storage",
        ["player_not_found"] = "Player not found",
        ["storage_not_found"] = "Storage not found",
        ["storage_renamed"] = "Storage name updated successfully",
        ["invalid_name"] = "Invalid storage name",
        ["already_has_access"] = "This player already has access",
        ["error_removing"] = "Error removing player access",
        ["removal_success"] = "Removing access for %s",
        
        -- Access notifications 
        ["access_granted"] = "%s has given you access to %s",
        ["access_revoked"] = "%s has removed your access to %s",
        
        -- Menu titles
        ["storage_title"] = "Storage #%d",
        ["storage_management"] = "Storage Management",
        ["access_management"] = "Manage Access",
        ["authorized_players"] = "Authorized Players",
        ["add_player"] = "Add Player",
        ["confirm_removal"] = "Confirm Removal",
        ["create_storage"] = "Create Storage",
        ["nearby_players"] = "Nearby Players",
        ["add_player_title"] = "Add Player to Storage #%d",
        ["select_method"] = "Select method",
        
        -- Menu options
        ["open_storage"] = "Open Storage",
        ["rename_storage"] = "Rename Storage",
        ["access_management_option"] = "Access Management",
        ["upgrade_storage"] = "Upgrade Storage ($%d)",
        ["back_menu"] = "Back",
        ["close_menu"] = "Close",
        ["yes_remove"] = "Yes, remove access",
        ["no_cancel"] = "No, cancel",
        ["search_nearby"] = "Search Nearby Players",
        ["enter_player_name"] = "Enter Player Name",
        ["view_remove_player"] = "View / Remove Player",
        ["no_players_found"] = "No players found",
        
        -- Descriptions
        ["open_storage_desc"] = "Access the storage contents",
        ["rename_storage_desc"] = "Change the name of your storage",
        ["manage_access_desc"] = "Add or remove players who can access this storage",
        ["upgrade_storage_desc"] = "Increase storage capacity by %d slots",
        ["create_storage_desc"] = "Create a storage at your current location",
        ["create_cost"] = "Cost: $%d",
        ["remove_access_desc"] = "Remove %s's access to this storage",
        ["keep_access_desc"] = "Keep their access",
        ["remove_access_text"] = "Remove access for %s?",
        ["manage_players_desc"] = "Manage player access to your storage",
        ["player_info_loading"] = "Loading player %d...",
        ["player_info_wait"] = "Please wait while player info loads",
        ["add_remove_desc"] = "Click to remove this player's access to your storage",
        ["nearby_player_desc"] = "Character ID: %d\nServer ID: %d",
        ["manual_player_desc"] = "Manually enter player name",
        ["nearby_players_desc"] = "Look for players in your vicinity",
        
        -- Inputs
        ["confirm"] = "Confirm",
        ["enter_new_name"] = "Enter new name",
        ["enter_first_name"] = "Enter Player First Name",
        ["enter_last_name"] = "Enter Player Last Name",
        ["confirm_upgrade"] = "Upgrade by %d slots for $%d",
        ["upgrade_confirmation"] = "Confirm Upgrade",
        ["upgrade_confirm_desc"] = "This will increase your storage capacity",
        
        -- Prompts
        ["create_storage_prompt"] = "Create Storage",
        ["open_storage_prompt"] = "Open Storage",
        
        -- Commands
        ["usage_movestorage"] = "Usage: ".. Config.adminmovestorage .." id x y z",
        ["usage_deletestorage"] = "Usage: ".. Config.admindeletestorage .." id",
        ["storage_deleted"] = "Storage #%d deleted",
        ["invalid_location"] = "You cannot create a storage here"
    },
    
    ["spanish"] = {
        -- Notifications
        ["storage_created"] = "Almacenamiento creado por $%d",
        ["storage_moved"] = "Almacenamiento #%d movido con éxito",
        ["storage_upgraded"] = "Capacidad de almacenamiento mejorada por $%d",
        ["not_enough_money"] = "No tienes suficiente dinero",
        ["max_storages_reached"] = "Has alcanzado el número máximo de almacenes (%d)",
        ["player_added"] = "Jugador añadido a la lista de acceso",
        ["player_removed"] = "Jugador eliminado de la lista de acceso",
        ["no_permission"] = "No tienes permiso para hacer esto",
        ["too_far_away"] = "Estás demasiado lejos del almacén",
        ["player_not_found"] = "Jugador no encontrado",
        ["storage_not_found"] = "Almacenamiento no encontrado",
        ["storage_renamed"] = "Nombre de almacenamiento actualizado con éxito",
        ["invalid_name"] = "Nombre de almacenamiento inválido",
        ["already_has_access"] = "Este jugador ya tiene acceso",
        ["error_removing"] = "Error al eliminar el acceso del jugador",
        ["removal_success"] = "Eliminando acceso para %s",
        
        -- Access notifications
        ["access_granted"] = "%s te ha dado acceso a %s",
        ["access_revoked"] = "%s ha eliminado tu acceso a %s",
        
        -- Menu titles
        ["storage_title"] = "Almacén #%d",
        ["storage_management"] = "Gestión de Almacenamiento",
        ["access_management"] = "Gestión de Acceso",
        ["authorized_players"] = "Jugadores Autorizados",
        ["add_player"] = "Añadir Jugador",
        ["confirm_removal"] = "Confirmar Eliminación",
        ["create_storage"] = "Crear Almacenamiento",
        ["nearby_players"] = "Jugadores Cercanos",
        ["add_player_title"] = "Añadir Jugador al Almacén #%d",
        ["select_method"] = "Seleccionar método",
        
        -- Menu options
        ["open_storage"] = "Abrir Almacén",
        ["rename_storage"] = "Renombrar Almacén",
        ["access_management_option"] = "Gestión de Acceso",
        ["upgrade_storage"] = "Mejorar Almacén ($%d)",
        ["back_menu"] = "Atrás",
        ["close_menu"] = "Cerrar",
        ["yes_remove"] = "Sí, eliminar acceso",
        ["no_cancel"] = "No, cancelar",
        ["search_nearby"] = "Buscar Jugadores Cercanos",
        ["enter_player_name"] = "Introducir Nombre del Jugador",
        ["view_remove_player"] = "Ver / Eliminar Jugador",
        ["no_players_found"] = "No se encontraron jugadores",
        
        -- Descriptions
        ["open_storage_desc"] = "Acceder al contenido del almacén",
        ["rename_storage_desc"] = "Cambiar el nombre de tu almacén",
        ["manage_access_desc"] = "Añadir o eliminar jugadores que pueden acceder a este almacén",
        ["upgrade_storage_desc"] = "Aumentar la capacidad de almacenamiento en %d espacios",
        ["create_storage_desc"] = "Crear un almacén en tu ubicación actual",
        ["create_cost"] = "Costo: $%d",
        ["remove_access_desc"] = "Eliminar el acceso de %s a este almacén",
        ["keep_access_desc"] = "Mantener su acceso",
        ["remove_access_text"] = "¿Eliminar acceso para %s?",
        ["manage_players_desc"] = "Gestionar el acceso de jugadores a tu almacén",
        ["player_info_loading"] = "Cargando jugador %d...",
        ["player_info_wait"] = "Por favor espera mientras se carga la información",
        ["add_remove_desc"] = "Haz clic para eliminar el acceso de este jugador a tu almacén",
        ["nearby_player_desc"] = "ID de Personaje: %d\nID de Servidor: %d",
        ["manual_player_desc"] = "Introduce manualmente el nombre del jugador",
        ["nearby_players_desc"] = "Buscar jugadores en tu vecindad",
        
        -- Inputs
        ["confirm"] = "Confirmar",
        ["enter_new_name"] = "Introducir nuevo nombre",
        ["enter_first_name"] = "Introducir Nombre del Jugador",
        ["enter_last_name"] = "Introducir Apellido del Jugador",
        ["confirm_upgrade"] = "Mejorar en %d espacios por $%d",
        ["upgrade_confirmation"] = "Confirmar Mejora",
        ["upgrade_confirm_desc"] = "Esto aumentará la capacidad de tu almacenamiento",
        
        -- Prompts
        ["create_storage_prompt"] = "Crear Almacén",
        ["open_storage_prompt"] = "Abrir Almacén",
        
        -- Commands
        ["usage_movestorage"] = "Uso: ".. Config.adminmovestorage .." id x y z",
        ["usage_deletestorage"] = "Uso: ".. Config.admindeletestorage .." id",
        ["storage_deleted"] = "Almacén #%d eliminado",
        ["invalid_location"] = "No puedes crear un almacén aquí"
    }
}
