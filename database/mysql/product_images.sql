CREATE TABLE `product_images`
(
  `sku` varchar(64) NOT NULL,
  `image` int unsigned NOT NULL,
  `main` boolean DEFAULT false,
  PRIMARY KEY (`sku`, `image`)
) CHARACTER SET utf8;
