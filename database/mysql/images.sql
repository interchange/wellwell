CREATE TABLE `images`
(
  `code` int unsigned NOT NULL auto_increment,
  `name` varchar(255),
  `format` char(3),
  `created` datetime,
  `author` int unsigned,
  `inactive` boolean DEFAULT FALSE,
  PRIMARY KEY (`code`)
)  CHARACTER SET utf8;
