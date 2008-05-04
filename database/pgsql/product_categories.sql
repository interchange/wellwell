CREATE TABLE "product_categories"
(
  "sku" varchar(32) NOT NULL,
  "category" int4 NOT NULL,
  CONSTRAINT product_categories_pkey PRIMARY KEY ("sku", "category")
) 
WITHOUT OIDS;
