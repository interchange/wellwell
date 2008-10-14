CREATE TABLE `categories` (
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `type` varchar(16) NOT NULL,
  `parent` int unsigned NOT NULL,
  `priority` int NOT NULL,
  `uri` varchar(255) NOT NULL,
  `inactive` boolean NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`code`),
  KEY `parent` (`parent`, `type`),
  KEY `uri` (`uri`)
) CHARACTER SET utf8;
