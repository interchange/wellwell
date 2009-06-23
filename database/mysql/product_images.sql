CREATE TABLE product_images
(
  code int unsigned NOT NULL auto_increment,
  sku varchar(64) NOT NULL,
  image int unsigned NOT NULL,
  image_group varchar(64) NOT NULL default '',
  location varchar(255) NOT NULL default '',
  PRIMARY KEY (code),
  KEY (sku, image_group)
);
