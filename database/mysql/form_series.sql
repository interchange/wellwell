CREATE TABLE form_series (
  name varchar(255) NOT NULL DEFAULT '',
  part varchar(255) NOT NULL DEFAULT '',
  label varchar(255) NOT NULL DEFAULT '',
  progress_label varchar(255) NOT NULL DEFAULT '',
  template varchar(255) NOT NULL DEFAULT '',
  profile varchar(255) NOT NULL DEFAULT '',
  position int unsigned NOT NULL DEFAULT 0,
  apply varchar(255) NOT NULL DEFAULT '', 
  key(name)
);
