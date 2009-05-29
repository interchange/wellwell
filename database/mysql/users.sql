CREATE TABLE users (
  uid int unsigned auto_increment NOT NULL,
  username varchar(32) NOT NULL,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  last_login integer NOT NULL DEFAULT 0,
  created integer NOT NULL DEFAULT 0,
  PRIMARY KEY (uid)
);
