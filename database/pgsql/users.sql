CREATE TABLE users (
  uid serial,
  username varchar(32) NOT NULL,
  email varchar(255) NOT NULL DEFAULT '',
  password varchar(255) NOT NULL DEFAULT '',
  CONSTRAINT users_pkey PRIMARY KEY (uid)
);
