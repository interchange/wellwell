CREATE TABLE `menus`
(
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL DEFAULT '',
  `parent` int unsigned NOT NULL DEFAULT 0,
  `url` varchar(255) NOT NULL DEFAULT '',
  `permission` varchar(64) NOT NULL DEFAULT '',
  `menu_name` varchar(64) NOT NULL DEFAULT '',
  `weight` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`),
  KEY (`menu_name`)
) CHARACTER SET utf8;
