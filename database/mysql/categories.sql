CREATE TABLE `categories` (
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `parent` int unsigned NOT NULL,
  `priority` int NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`code`)
) CHARACTER SET utf8;
