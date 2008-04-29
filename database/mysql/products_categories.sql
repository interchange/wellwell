CREATE TABLE `categories` (
  `sku` varchar(255) NOT NULL,
  `category` int unsigned NOT NULL,
  KEY (`category_id`, `sku`)
) CHARACTER SET utf8;
