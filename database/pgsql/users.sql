CREATE TABLE users (
  uid serial,
  username varchar(32) NOT NULL,
  email varchar(255) NOT NULL DEFAULT '',
  password varchar(255) NOT NULL DEFAULT '',
  last_login integer NOT NULL DEFAULT 0,
  created integer NOT NULL DEFAULT 0,
  CONSTRAINT users_pkey PRIMARY KEY (uid)
);
