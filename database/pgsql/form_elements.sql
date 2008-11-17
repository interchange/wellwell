CREATE TABLE "form_elements" (
  code serial,
  name varchar(255) NOT NULL DEFAULT '',
  label varchar(255) NOT NULL DEFAULT '',
  component varchar(255) NOT NULL DEFAULT '',
  priority integer NOT NULL DEFAULT '0',
  widget varchar(255) NOT NULL DEFAULT '',
  CONSTRAINT form_elements_pkey PRIMARY KEY (code)
);