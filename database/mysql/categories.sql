CREATE TABLE `categories` (
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `parent` int unsigned NOT NULL,
  KEY (`code`)
) CHARACTER SET utf8;
