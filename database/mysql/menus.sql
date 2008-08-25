CREATE TABLE `menus`
(
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255),
  `parent` int unsigned NOT NULL DEFAULT 0,
  `url` varchar(255),
  `menu_name` varchar(64),
  `weight` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`),
  KEY (`menu_name`)
) CHARACTER SET utf8;
