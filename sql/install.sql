CREATE TABLE IF NOT EXISTS `character_storage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_charid` int(11) NOT NULL,
  `storage_name` varchar(50) NOT NULL,
  `pos_x` float(10,6) NOT NULL,
  `pos_y` float(10,6) NOT NULL,
  `pos_z` float(10,6) NOT NULL,
  `authorized_users` LONGTEXT NULL,
  `capacity` int(11) NOT NULL DEFAULT 50,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_charid` (`owner_charid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
