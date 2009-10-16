CREATE TABLE product_attributes (
	sku varchar(32) NOT NULL,
	name varchar(255) NOT NULL,
	value text NOT NULL DEFAULT '',
	KEY(sku)
);

