CREATE TABLE plugins (
	name varchar(32) not null default '',
	label varchar(255) not null default '',
	version varchar(16) not null default '',
	active boolean,
	PRIMARY KEY(name)
);
