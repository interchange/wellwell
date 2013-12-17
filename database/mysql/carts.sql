CREATE TABLE carts (
  carts_id serial PRIMARY KEY,
  name varchar(255) NOT NULL DEFAULT '',
  users_id integer, -- this would be NOT NULL in IC6
  username varchar(255), -- extra field
  sessions_id varchar(255) NOT NULL,
  created timestamp NOT NULL,
  last_modified timestamp NOT NULL,
  approved boolean,
  status varchar(32) NOT NULL DEFAULT ''
);
