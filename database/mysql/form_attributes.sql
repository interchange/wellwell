CREATE TABLE `form_attributes` (
  `code` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `component` varchar(255) NOT NULL,
  `attribute` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY  (`code`),
  KEY (`name`, `component`)
);
