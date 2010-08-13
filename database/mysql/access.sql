--
-- Table structure for table `access`
--

CREATE TABLE access (
  username varchar(255) NOT NULL default '',
  password varchar(255) default NULL,
  name varchar(255) default NULL,
  last_login timestamp(14) NOT NULL,
  super int(1) default NULL,
  yes_tables text,
  no_tables text,
  upload varchar(255) default NULL,
  acl varchar(255) default NULL,
  export varchar(255) default NULL,
  edit varchar(255) default NULL,
  pages varchar(255) default NULL,
  files varchar(255) default NULL,
  config int(1) default NULL,
  reconfig int(1) default NULL,
  meta int(1) default NULL,
  no_functions text,
  yes_functions text,
  table_control text,
  startpage text,
  PRIMARY KEY  (username)
) TYPE=MyISAM;


