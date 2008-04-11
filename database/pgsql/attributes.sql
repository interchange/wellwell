-- DROP TABLE attributes;

CREATE TABLE attributes
(
  "component" varchar(255) NOT NULL,
  "selector" varchar(255) NOT NULL,
  "name" varchar(255) NOT NULL,
  "value" varchar(255),
  CONSTRAINT attributes_pkey PRIMARY KEY (component, selector, name)
) 
WITHOUT OIDS;
COMMENT ON TABLE attributes IS 'This table stores attribute definitions for components. It defines selectors, attributes and their values.';
