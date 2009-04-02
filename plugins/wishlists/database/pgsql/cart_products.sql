CREATE TABLE cart_products (
  cart integer NOT NULL,
  sku varchar(32) NOT NULL,
  position integer NOT NULL,
  CONSTRAINT cart_products_pkey PRIMARY KEY (cart, position)
);
