CREATE TABLE coupon_log (
	code int NOT NULL auto_increment,
    coupon_code int NOT NULL,
    uid int unsigned NOT NULL default 0,
	session_id char(8) NOT NULL default '',
	entered datetime NOT NULL,
    order_number varchar(14) NOT NULL default '',
	PRIMARY KEY(code),
	KEY(coupon_code)
);
