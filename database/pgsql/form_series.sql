CREATE TABLE "form_series" (
  name varchar(255) NOT NULL DEFAULT '',
  component varchar(255) NOT NULL DEFAULT '',
  label varchar(255) NOT NULL DEFAULT '',
  profile varchar(255) NOT NULL DEFAULT '',
  position integer NOT NULL DEFAULT 0,
  load varchar(255) NOT NULL DEFAULT '',
  save varchar(255) NOT NULL DEFAULT ''
);
CREATE INDEX form_series_name ON form_series(name);

