CREATE TABLE form_attributes (
  "code" serial,
  "name" varchar(255) NOT NULL DEFAULT '',
  "component" varchar(255) NOT NULL DEFAULT '',
  "attribute" varchar(255) NOT NULL DEFAULT '',
  "value" varchar(255) NOT NULL DEFAULT '',
  CONSTRAINT form_attributes_pkey PRIMARY KEY (code)
);
CREATE INDEX idx_form_attributes_name_component ON form_attributes (name,component);
