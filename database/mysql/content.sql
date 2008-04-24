CREATE TABLE `content` (
  `code` int unsigned NOT NULL auto_increment,
  `type` varchar(32) NOT NULL,
  `uid` int unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` longtext NOT NULL,
  `created` int unsigned NOT NULL,
  PRIMARY KEY (`code`),
  KEY (`type`)
);