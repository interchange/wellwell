CREATE TABLE form_series (
  name varchar(255) NOT NULL DEFAULT '',
  component varchar(255) NOT NULL DEFAULT '',
  label varchar(255) NOT NULL DEFAULT '',
  profile varchar(255) NOT NULL DEFAULT '',
  position int unsigned NOT NULL DEFAULT 0,
  `load` varchar(255) NOT NULL DEFAULT '',
  save varchar(255) NOT NULL DEFAULT '',
  key(name)
);