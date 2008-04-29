CREATE TABLE `categories` (
  `category_id` int unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `parent` int unsigned NOT NULL,
  KEY (`category_id`)
) CHARACTER SET utf8;
