CREATE TABLE images
(
  code serial NOT NULL,
  name varchar(255),
  format char(3),
  original_file varchar(255) NOT NULL DEFAULT '',
  original_time integer not null default 0,
  created integer,
  author integer NOT NULL DEFAULT 0,
  width integer NOT NULL DEFAULT 0,
  height integer NOT NULL DEFAULT 0,
  inactive bool DEFAULT false,
  CONSTRAINT images_pkey PRIMARY KEY (code)
);
