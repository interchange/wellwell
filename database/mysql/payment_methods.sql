CREATE TABLE payment_methods (
	code varchar(16) NOT NULL DEFAULT '' PRIMARY KEY,
	label varchar(255) NOT NULL DEFAULT '',
    permission varchar(64) NOT NULL DEFAULT ''
);
