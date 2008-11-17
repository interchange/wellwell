CREATE TABLE `form_elements` (
  `code` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `component` varchar(255) NOT NULL,
  `priority` int(11) NOT NULL default '0',
  `widget` varchar(255) NOT NULL,
  PRIMARY KEY  (`code`)
);
