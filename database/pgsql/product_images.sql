CREATE TABLE product_images
(
  code serial,
  sku varchar(64) NOT NULL,
  image int4 NOT NULL,
  image_group varchar(64) NOT NULL default '',
  location varchar(255) NOT NULL default '',
  CONSTRAINT product_images_pkey PRIMARY KEY (code)
);
CREATE INDEX product_images_sku_group ON product_images (sku, image_group);

