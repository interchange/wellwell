-- DROP TABLE products;

CREATE TABLE products
(
  "sku" varchar(32) NOT NULL,
  "name" varchar(255) NOT NULL,
  "manufacturer" varchar(255),
  "short_description" text,
  "long_description" text,
  CONSTRAINT products_pkey PRIMARY KEY (sku)
 ) 
WITHOUT OIDS;
COMMENT ON TABLE products IS 'Table containing products definitions';
