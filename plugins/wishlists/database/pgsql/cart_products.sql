CREATE TABLE cart_products (
  cart integer NOT NULL,
  sku varchar(32) NOT NULL,
  position integer NOT NULL,
  quantity integer NOT NULL DEFAULT 1,
  CONSTRAINT cart_products_pkey PRIMARY KEY (cart, sku)
);
