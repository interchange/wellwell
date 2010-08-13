CREATE TABLE access (
  username varchar(255) NOT NULL default '',
  password varchar(255) default NULL,
  name varchar(255) default NULL,
  last_login integer NOT NULL DEFAULT 0,
  super integer default NULL,
  yes_tables text,
  no_tables text,
  upload varchar(255) default NULL,
  acl varchar(255) default NULL,
  export varchar(255) default NULL,
  edit varchar(255) default NULL,
  pages varchar(255) default NULL,
  files varchar(255) default NULL,
  config integer default NULL,
  reconfig integer default NULL,
  meta integer default NULL,
  no_functions text,
  yes_functions text,
  table_control text,
  startpage text,
  PRIMARY KEY  (username)
);


