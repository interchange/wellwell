CREATE TABLE form_components (
  name varchar(255) NOT NULL DEFAULT '',
  part varchar(255) NOT NULL DEFAULT '',
  component varchar(255) NOT NULL DEFAULT '',
  location varchar(255) NOT NULL DEFAULT '',
  priority integer NOT NULL DEFAULT 0
);
CREATE INDEX form_components_name_part ON form_components(name,part);