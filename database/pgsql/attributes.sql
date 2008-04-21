create table attributes (
	"component" varchar(255) NOT NULL,
	"selector" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"value" varchar(255),
	CONSTRAINT attributes_pkey PRIMARY KEY (component, selector, name)
);
