CREATE TABLE images
(
  code int unsigned NOT NULL auto_increment,
  name varchar(255),
  format char(3),
  original_file varchar(255) NOT NULL DEFAULT '',
  original_time integer unsigned not null default 0,
  created integer,
  author int unsigned NOT NULL DEFAULT 0,
  width integer unsigned NOT NULL DEFAULT 0,
  height integer unsigned NOT NULL DEFAULT 0,
  inactive boolean DEFAULT FALSE,
  PRIMARY KEY (code)
)
