CREATE TABLE IF NOT EXISTS `lisunio_orgs` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `short` varchar(8) NOT NULL,
  `type` enum('criminal','company') NOT NULL DEFAULT 'criminal',
  `location` varchar(64) DEFAULT NULL,
  `job` varchar(64) DEFAULT NULL,
  `created_by` varchar(64) DEFAULT NULL,
  `balance` bigint NOT NULL DEFAULT 0,
  `bank_iban` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_short` (`short`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lisunio_org_members` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` int unsigned NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `rank_id` int unsigned NOT NULL DEFAULT 1,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_member` (`org_id`,`identifier`),
  KEY `idx_identifier` (`identifier`),
  CONSTRAINT `fk_org_member_org` FOREIGN KEY (`org_id`) REFERENCES `lisunio_orgs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lisunio_org_ranks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` int unsigned NOT NULL,
  `name` varchar(32) NOT NULL,
  `level` int NOT NULL DEFAULT 1,
  `permissions` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_rank_level` (`org_id`,`level`),
  CONSTRAINT `fk_org_rank_org` FOREIGN KEY (`org_id`) REFERENCES `lisunio_orgs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lisunio_org_notes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` int unsigned NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `private` tinyint(1) NOT NULL DEFAULT 0,
  `title` varchar(100) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_notes_org` (`org_id`),
  CONSTRAINT `fk_org_notes_org` FOREIGN KEY (`org_id`) REFERENCES `lisunio_orgs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lisunio_org_shop_orders` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `org_id` int unsigned NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `item` varchar(64) NOT NULL,
  `amount` int unsigned NOT NULL,
  `price` bigint NOT NULL,
  `delivery_at` datetime NOT NULL,
  `delivered` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_delivery` (`delivery_at`,`delivered`),
  CONSTRAINT `fk_shop_org` FOREIGN KEY (`org_id`) REFERENCES `lisunio_orgs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
