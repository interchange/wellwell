CREATE TABLE coupons (
	code int NOT NULL auto_increment,
	coupon_number varchar(32) not null default '',
    amount decimal(11,2) NOT NULL DEFAULT 0,
	inactive boolean NOT NULL DEFAULT FALSE,
	PRIMARY KEY(code)
);
