CREATE TABLE coupon_discounts (
	code int NOT NULL auto_increment,
    coupon_code int NOT NULL,
	subject varchar(32) NOT NULL default '',
	mode varchar(32) NOT NULL default '',
	value decimal(11,2) NOT NULL default 0,
	PRIMARY KEY(code),
	KEY(coupon_code)
);
