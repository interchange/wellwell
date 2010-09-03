CREATE TABLE coupon_targets (
	code int NOT NULL auto_increment,
    discount_code int NOT NULL,
	value varchar(255) NOT NULL default '',
	PRIMARY KEY(code),
	KEY(discount_code)
);