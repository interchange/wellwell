CREATE TABLE "product_categories"
(
  "sku" varchar(32) NOT NULL,
  "category" int4 NOT NULL,
  "type" varchar(16) NOT NULL,
  CONSTRAINT product_categories_pkey PRIMARY KEY ("sku", "category")
) 
WITHOUT OIDS;
CREATE INDEX idx_product_categories_sku ON product_categories (sku);
CREATE INDEX idx_product_categories_category ON product_categories (category);

