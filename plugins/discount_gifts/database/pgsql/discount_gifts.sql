create table discount_gifts (
	code serial NOT NULL,
	sku varchar(32) NOT NULL,
	quantity integer NOT NULL DEFAULT 0,
	start_date TIMESTAMP,
	end_date TIMESTAMP,
	min_amount numeric(11,2) NOT NULL DEFAULT 0,
	PRIMARY KEY(code)
);

