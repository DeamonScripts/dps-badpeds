-- AC-PedInteraction Jail Records Table
-- Run this SQL to enable the jail/unavailability system for arrested NPCs

CREATE TABLE IF NOT EXISTS `npc_jail_records` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `npc_model` VARCHAR(100) NOT NULL,
    `npc_firstname` VARCHAR(50) NOT NULL,
    `npc_lastname` VARCHAR(50) NOT NULL,
    `npc_gender` VARCHAR(10) NOT NULL,
    `arrested_by` VARCHAR(50) NOT NULL COMMENT 'CitizenID of arresting officer',
    `arrested_by_name` VARCHAR(100) DEFAULT NULL COMMENT 'Officer name for display',
    `arrest_coords` VARCHAR(100) DEFAULT NULL COMMENT 'JSON coords where arrested',
    `arrest_street` VARCHAR(200) DEFAULT NULL,
    `charges` TEXT DEFAULT NULL COMMENT 'JSON array of charges/items found',
    `jail_time_hours` INT(11) NOT NULL DEFAULT 24 COMMENT 'Game hours of jail time',
    `arrested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `release_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'When NPC becomes available again',
    `released` TINYINT(1) NOT NULL DEFAULT 0,
    `gave_intel` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Did NPC trade intel?',
    `intel_data` TEXT DEFAULT NULL COMMENT 'JSON intel if any was given',
    `is_informant` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Recruited as informant?',
    `informant_handler` VARCHAR(50) DEFAULT NULL COMMENT 'CitizenID of handling officer',
    PRIMARY KEY (`id`),
    INDEX `idx_npc_name` (`npc_firstname`, `npc_lastname`),
    INDEX `idx_released` (`released`),
    INDEX `idx_release_at` (`release_at`),
    INDEX `idx_informant` (`is_informant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Informant relationships table (for long-term informant system)
CREATE TABLE IF NOT EXISTS `npc_informants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `npc_model` VARCHAR(100) NOT NULL,
    `npc_firstname` VARCHAR(50) NOT NULL,
    `npc_lastname` VARCHAR(50) NOT NULL,
    `handler_citizenid` VARCHAR(50) NOT NULL,
    `handler_name` VARCHAR(100) DEFAULT NULL,
    `recruited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `trust_level` INT(11) NOT NULL DEFAULT 1 COMMENT '1-5 trust level',
    `intel_given_count` INT(11) NOT NULL DEFAULT 0,
    `last_contact` TIMESTAMP NULL DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    INDEX `idx_handler` (`handler_citizenid`),
    INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Intel reports table (tracks intel given by NPCs)
CREATE TABLE IF NOT EXISTS `npc_intel_reports` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `source_type` ENUM('arrest', 'informant', 'conversation') NOT NULL,
    `source_npc_name` VARCHAR(100) NOT NULL,
    `receiving_officer` VARCHAR(50) NOT NULL,
    `intel_type` VARCHAR(50) NOT NULL COMMENT 'drugs, weapons, gang, etc',
    `intel_content` TEXT NOT NULL,
    `location_hint` VARCHAR(200) DEFAULT NULL,
    `reliability` INT(11) NOT NULL DEFAULT 3 COMMENT '1-5 reliability score',
    `acted_upon` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_officer` (`receiving_officer`),
    INDEX `idx_type` (`intel_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
