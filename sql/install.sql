-- =========================================
-- FULL INSTALL (new users)
-- =========================================
CREATE TABLE IF NOT EXISTS `character_storage` (
  `id`               INT(11) NOT NULL AUTO_INCREMENT,
  `owner_charid`     INT(11) NOT NULL,
  `storage_name`     VARCHAR(50)   NOT NULL,
  `pos_x`            FLOAT(10,6)   NOT NULL,
  `pos_y`            FLOAT(10,6)   NOT NULL,
  `pos_z`            FLOAT(10,6)   NOT NULL,
  `authorized_users` LONGTEXT       NULL,
  `authorized_jobs`  TEXT           NOT NULL DEFAULT '{}',
  `capacity`         INT(11)       NOT NULL DEFAULT 50,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_charid` (`owner_charid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;


-- =========================================
-- UPGRADE EXISTING TABLE (1.0.2 → 1.0.3)
-- =========================================
ALTER TABLE `character_storage`
  ADD COLUMN `authorized_jobs` TEXT NOT NULL DEFAULT '{}';
