CREATE TABLE cart_products (
  cart integer NOT NULL,
  sku varchar(32) NOT NULL,
  position integer NOT NULL,
  options varchar(500) NOT NULL,
  quantity integer NOT NULL DEFAULT 1
);
CREATE UNIQUE INDEX cart_products_idx ON cart_products (cart, sku, options);
