CREATE TABLE content (
  code int unsigned NOT NULL auto_increment,
  type varchar(32) NOT NULL,
  uid int unsigned NOT NULL,
  title varchar(255) NOT NULL,
  body longtext NOT NULL,
  uri varchar(255) NOT NULL,
  locale varchar(255) NOT NULL default 'en_US',
  created integer NOT NULL DEFAULT 0,
  PRIMARY KEY (code),
  KEY (type)
);
