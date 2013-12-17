CREATE TABLE cart_products (
  carts_id integer NOT NULL,
  sku varchar(32) NOT NULL,
  cart_position integer NOT NULL,
  options varchar(500) NOT NULL, -- extra field
  quantity integer NOT NULL DEFAULT 1,
  when_added datetime NOT NULL
);
-- IC6 would have just carts_id, sku
CREATE UNIQUE INDEX cart_products_idx ON cart_products (carts_id, sku, options);
