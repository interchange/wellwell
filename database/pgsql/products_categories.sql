CREATE TABLE "products_categories"
(
  "sku" varchar(32) NOT NULL,
  "category" int4 NOT NULL,
  CONSTRAINT products_categories_pkey PRIMARY KEY ("sku", "category")
) 
WITHOUT OIDS;
