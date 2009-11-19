create table discount_gifts (
	code int unsigned NOT NULL auto_increment,
	sku varchar(32) NOT NULL,
	quantity integer NOT NULL DEFAULT 0,
	start_date DATETIME,
	end_date DATETIME,
	min_amount numeric(11,2) NOT NULL DEFAULT 0,
	PRIMARY KEY(code)
);
