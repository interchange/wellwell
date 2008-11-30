CREATE TABLE product_attributes (
	sku varchar(32) NOT NULL,
	name varchar(255) NOT NULL,
	value text NOT NULL DEFAULT ''
);
CREATE INDEX product_attributes_sku ON product_attributes (sku);
