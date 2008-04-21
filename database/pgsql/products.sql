create table products (
	"sku" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"manufacturer" varchar(255),
	"description" text,
	"long_description" text,
	"price" numeric(11,2) NOT NULL DEFAULT 0,
	CONSTRAINT products_pkey PRIMARY KEY (sku)
);