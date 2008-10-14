CREATE TABLE `product_categories` (
  `sku` varchar(32) NOT NULL,
  `category` int unsigned NOT NULL,
  `type` varchar(16) NOT NULL,
  KEY (`sku`),
  KEY (`category`)
) CHARACTER SET utf8;
