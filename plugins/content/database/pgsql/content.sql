CREATE TABLE content (
  code serial NOT NULL,
  type varchar(32) NOT NULL,
  uid int8 NOT NULL,
  title varchar(255) NOT NULL,
  body text NOT NULL,
  uri varchar(255) NOT NULL,
  locale varchar(255) NOT NULL DEFAULT 'en_US',
  created integer NOT NULL DEFAULT 0,
  PRIMARY KEY (code)
);
