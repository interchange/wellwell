CREATE TABLE `menus`
(
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255),
  `parent` int unsigned NOT NULL DEFAULT 0,
  `url` varchar(255),
  `menu_name` varchar(64),
  KEY (`code`)
) CHARACTER SET utf8;
