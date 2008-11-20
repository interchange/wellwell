CREATE TABLE addresses (
  aid serial,
  uid integer,
  type varchar(16) NOT NULL DEFAULT '',
  archived bool NOT NULL DEFAULT false,
  last_modified TIMESTAMP,
  company varchar(255) NOT NULL DEFAULT '',
  first_name varchar(255) NOT NULL DEFAULT '',
  last_name varchar(255) NOT NULL DEFAULT '',
  street_address varchar(255) NOT NULL DEFAULT '',
  zip varchar(16) NOT NULL DEFAULT '',
  city varchar(255) NOT NULL DEFAULT '',
  country char(3) NOT NULL DEFAULT '',
  CONSTRAINT addresses_pkey PRIMARY KEY (aid)
);

