CREATE TABLE carts (
  code serial PRIMARY KEY,
  name varchar(255) NOT NULL default '',
  type varchar(32) NOT NULL default '',
  status varchar(32) NOT NULL default '',
  uid varchar(255) NOT NULL,
  session_id varchar(32) NOT NULL,
  created integer NOT NULL,
  last_modified integer NOT NULL default 0
);
