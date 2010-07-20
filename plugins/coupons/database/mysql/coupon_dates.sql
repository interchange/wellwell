CREATE TABLE coupon_dates (
	code int NOT NULL auto_increment,
    coupon_code int NOT NULL,
	valid_from datetime,
	valid_to datetime,
	PRIMARY KEY(code),
	KEY(coupon_code)
);
