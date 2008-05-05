CREATE TABLE `product_images`
(
  `sku` varchar(64) NOT NULL,
  `image` int unsigned NOT NULL,
  PRIMARY KEY (`sku`, `image`)
) CHARACTER SET utf8;
